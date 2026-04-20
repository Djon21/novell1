-- scene_controller.lua
-- Движок сцен point-and-click слоя. Рендерит фон через UI-интерфейс,
-- показывает hotspot'ы, обрабатывает клики.
--
-- UI-интерфейс (регистрируется через set_ui):
--   set_background(bg_image_name)
--   set_hotspot(i, {rect, label, locked}) — или nil чтобы спрятать слот
--   max_hotspots() -> N
--   request_ink_knot(knot_name)  — вернуться в dialogue-режим на узел
--   on_exit_explore()            — (опционально) UI-сторона знает что вышли

local scenes = require "main.scripts.scenes"
local gs     = require "main.scripts.game_state"

local M = {}

local _active        = false
local _scene_id      = nil
local _scene_data    = nil
local _last_scene_id = nil   -- запоминаем последнюю exploration-сцену,
                             -- чтобы вернуться после ink-монолога
local _ui            = nil

function M.set_ui(iface)
    _ui = iface
end

-- Возвращает все hotspot'ы сцены, с пометкой locked (true если condition
-- есть и вернул false). Раньше locked-hotspot'ы просто скрывались —
-- но это плохо для point-and-click UX: игрок не видит что там есть
-- интерактив. Теперь показываем все, но тусклые.
local function visible_hotspots()
    if not _scene_data then return {} end
    local list = {}
    for _, h in ipairs(_scene_data.hotspots) do
        -- visible_when(gs)→false полностью прячет hotspot (нет даже тусклого).
        -- Отличается от condition: condition делает hotspot «locked» (видимым,
        -- но некликабельным). Используй visible_when когда hotspot'ы накладываются
        -- друг на друга (например, кофемашина без кружки vs с кружкой).
        local visible = true
        if h.visible_when then visible = h.visible_when(gs) end
        if visible then
            local locked = h.condition and not h.condition(gs) or false
            table.insert(list, { ref = h, locked = locked })
        end
    end
    return list
end

-- Объекты сцены (спрайты поверх фона: телефон на тумбочке, ключи,
-- предметы и т.д.). Видимость определяется visible_when(gs) → bool.
-- По умолчанию (без visible_when) — видны всегда.
local function visible_objects()
    if not _scene_data or not _scene_data.objects then return {} end
    local list = {}
    for _, obj in ipairs(_scene_data.objects) do
        local ok = true
        if obj.visible_when then ok = obj.visible_when(gs) end
        if ok then table.insert(list, obj) end
    end
    return list
end

local function render()
    if not _active or not _ui then return end
    _ui.set_background(_scene_data.bg)

    -- Объекты сцены (спрайты-оверлеи)
    if _ui.set_scene_object and _ui.max_scene_objects then
        local objs = visible_objects()
        for i = 1, _ui.max_scene_objects() do
            _ui.set_scene_object(i, objs[i])  -- nil прячет слот
        end
    end

    local visible = visible_hotspots()
    for i = 1, _ui.max_hotspots() do
        local entry = visible[i]
        if entry then
            _ui.set_hotspot(i, {
                rect   = entry.ref.rect,
                label  = entry.ref.label,
                icon   = entry.ref.icon,
                locked = entry.locked,
            })
        else
            _ui.set_hotspot(i, nil)  -- слот пустой → UI прячет
        end
    end
end

function M.enter(scene_id)
    local data = scenes.get(scene_id)
    if not data then
        print("[scene_controller] не известна сцена: " .. tostring(scene_id))
        return
    end
    print("[scene_controller] enter scene:", scene_id)
    _active     = true
    _scene_id   = scene_id
    _scene_data = data
    gs.set_scene(scene_id)
    render()
    print("[scene_controller] render() called, objects rendered")

    -- Автотриггер on_enter-knot: проверяем condition и запускаем ink-монолог.
    if data.on_enter then
        local oe = data.on_enter
        local ok = true
        if oe.condition then ok = oe.condition(gs) end
        print("[scene_controller] on_enter check:", oe.knot, "condition:", ok)
        if ok and oe.knot then
            print("[scene_controller] triggering on_enter knot:", oe.knot)
            M.exit()
            if _ui and _ui.request_ink_knot then
                _ui.request_ink_knot(oe.knot, data.bg)
            end
        end
    end
end

function M.exit()
    -- Перед сбросом запоминаем текущую сцену — чтобы ink-монолог,
    -- запущенный через ink_knot-hotspot, мог вернуться обратно
    -- по тэгу # return_to_scene.
    if _active and _scene_id then
        _last_scene_id = _scene_id
    end
    _active     = false
    _scene_id   = nil
    _scene_data = nil
    gs.set_scene(nil)
end

-- Возврат в последнюю exploration-сцену (после короткого ink-монолога).
-- Вызывается из gui_script при обработке команды return_to_scene.
function M.return_to_last_scene()
    if _last_scene_id then
        M.enter(_last_scene_id)
    end
end

function M.is_active() return _active end

-- Доступ для редактора хотспотов: вернуть таблицу текущей сцены
-- (_scene_data из scenes.lua). Нужен, чтобы редактор мог мутировать
-- rect'ы hotspot'ов прямо в рантайме.
function M.get_current_scene_data() return _scene_data end
function M.get_current_scene_id()   return _scene_id   end

-- Публичный re-render (редактор хотспотов после правки rect'а
-- перерисовывает сцену, чтобы изменения были видны сразу).
function M.render_now() render() end

-- Вызывается gui_script при клике. index — 1-based номер слота-ноды,
-- соответствует visible_hotspots()[index]. Возвращает true если обработано.
function M.on_hotspot_click(index)
    if not _active then return false end
    local visible = visible_hotspots()
    local entry = visible[index]
    if not entry then return false end

    -- Locked-hotspot виден, но кликабелен визуально «мёртво» — просто
    -- игнорируем клик. (В будущем можно показать подсказку-тултип.)
    if entry.locked then return false end

    local h = entry.ref
    local action = h.action
    if not action then return false end

    if action.type == "goto_scene" then
        M.enter(action.scene)
    elseif action.type == "set_flag" then
        gs.set_flag(action.flag, action.value)
        render()
    elseif action.type == "add_item" then
        gs.add_item(action.item)
        render()
    elseif action.type == "remove_item" then
        gs.remove_item(action.item)
        render()
    elseif action.type == "phone_close" then
        -- Закрыть телефон и вернуться в сцену-вызыватель.
        local caller = gs.get_flag("_phone_return_scene")
        if caller then
            gs.set_flag("_phone_return_scene", nil)
            M.enter(caller)
        else
            M.return_to_last_scene()
        end
    elseif action.type == "ink_knot" then
        -- Сохраняем фон текущей сцены, чтобы короткий ink-монолог
        -- (drink_coffee/take_phone/…) играл на том же фоне, а не на
        -- «последнем ink-фоне» (обычно коридор apartment_hub).
        local scene_bg = _scene_data and _scene_data.bg
        M.exit()
        if _ui and _ui.request_ink_knot then
            _ui.request_ink_knot(action.knot, scene_bg)
        end
    else
        print("[scene_controller] неизвестный action.type: " .. tostring(action.type))
    end
    return true
end

return M
