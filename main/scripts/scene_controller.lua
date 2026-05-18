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

local scenes   = require "main.scripts.scenes"
local gs       = require "main.scripts.game_state"
local ui_state = require "main.scripts.ui_state"
local log = require "main.scripts.log"

local M = {}

local _active        = false
local _scene_id      = nil
local _scene_data    = nil
local _scene_stack   = {}    -- стек exploration-сцен для возврата после
                             -- вложенных ink-монологов/телефона/модалок
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

local function make_hotspot_payload(entry)
    local payload = {}
    for key, value in pairs(entry.ref) do
        payload[key] = value
    end
    payload.locked = entry.locked
    return payload
end

-- bg может быть строкой ("bg_kitchen") или функцией (gs) -> string.
-- Функция вызывается на каждом render, чтобы фон менялся в зависимости от
-- состояния игры (утро/день/ночь, день недели и т.п.) без необходимости
-- заводить отдельные сцены под каждый вариант.
local function resolve_bg(scene_data)
    if not scene_data then return nil end
    local bg = scene_data.bg
    if type(bg) == "function" then
        local ok, value = pcall(bg, gs)
        if not ok then
            log.info("scene", "bg function failed:", tostring(value))
            return nil
        end
        return value
    end
    return bg
end

local function render()
    if not _active or not _ui then return end
    _ui.set_background(resolve_bg(_scene_data))

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
            _ui.set_hotspot(i, make_hotspot_payload(entry))
        else
            _ui.set_hotspot(i, nil)  -- слот пустой → UI прячет
        end
    end
end

-- enter(scene_id, opts)
--   opts.skip_on_enter — не триггерить on_enter-knot (используется при restore).
--   opts.preserve_stack — НЕ чистить scene_stack (только для return_to_last_scene).
--
-- ВАЖНО про scene_stack: стек существует ТОЛЬКО для return_to_last_scene
-- из короткого ink-монолога (hotspot ink_knot, scene_character click, inv_knot).
-- Любой explicit переход (map_travel, прямая enter из ink-тэга, choose) делает
-- старый стек невалидным: игрок осознанно сменил сцену, возвращаться в
-- предыдущую через ink-END уже не должно. Без этого стек растёт навечно
-- (apt_hub → shop → park → ...), и потом случайный # return_to_scene
-- закидывает игрока в орфанную сцену вроде shop_street вместо park.
function M.enter(scene_id, opts)
    opts = opts or {}
    local data = scenes.get(scene_id)
    if not data then
        log.info("scene", "не известна сцена: " .. tostring(scene_id))
        return
    end
    log.info("scene", "enter scene:", scene_id)
    if not opts.preserve_stack then
        _scene_stack = {}
    end
    _active     = true
    _scene_id   = scene_id
    _scene_data = data
    gs.set_scene(scene_id)

    -- Автотриггер on_enter-knot проверяем ДО render().
    -- Если on_enter сразу уводит в Ink, не надо сначала рисовать сцену-роутер:
    -- для apartment_hub после воскресной встречи это давало дневной кадр
    -- перед ночным вечерним блоком.
    if data.on_enter and not opts.skip_on_enter then
        local oe = data.on_enter
        local ok = true
        if oe.condition then ok = oe.condition(gs) end
        log.info("scene", "on_enter check:", oe.knot, "condition:", ok)
        if ok and oe.knot then
            log.info("scene", "triggering on_enter knot:", oe.knot)
            local scene_bg = resolve_bg(data)
            M.exit()
            if _ui and _ui.request_ink_knot then
                _ui.request_ink_knot(oe.knot, scene_bg)
            end
            return
        end
    end

    render()
    log.info("scene", "render() called, objects rendered")
end

function M.exit()
    -- Перед сбросом запоминаем текущую сцену в стек — чтобы ink-монолог,
    -- запущенный через ink_knot-hotspot, мог вернуться обратно
    -- по тэгу # return_to_scene.
    if _active and _scene_id then
        table.insert(_scene_stack, _scene_id)
    end
    _active     = false
    _scene_id   = nil
    _scene_data = nil
    gs.set_scene(nil)
end

-- Возврат в последнюю exploration-сцену (после короткого ink-монолога).
-- Вызывается из gui_script при обработке команды return_to_scene.
-- Использует стек, чтобы корректно работать при вложенных переходах
-- (сцена → телефон → ink-монолог → return).
function M.return_to_last_scene()
    if #_scene_stack > 0 then
        local last_id = table.remove(_scene_stack)  -- pop со стека
        -- preserve_stack=true: если в стеке остались вложенные return-точки
        -- (например scene→ink→inv_knot→ink), они должны пережить этот enter.
        M.enter(last_id, { preserve_stack = true })
    end
end

function M.reset()
    _active = false
    _scene_id = nil
    _scene_data = nil
    _scene_stack = {}
    gs.set_scene(nil)
end

function M.is_active() return _active end

-- Доступ для редактора хотспотов: вернуть таблицу текущей сцены
-- (_scene_data из scenes.lua). Нужен, чтобы редактор мог мутировать
-- rect'ы hotspot'ов прямо в рантайме.
function M.get_current_scene_data() return _scene_data end
function M.get_current_scene_id()   return _scene_id   end

-- Список индексов хотспотов в _scene_data.hotspots, прошедших visible_when.
-- Порядок совпадает с порядком отрисовки в GUI (visible[1] = слот 1).
-- Используется hotspot_editor чтобы корректно мапить slot ↔ full-index при
-- click-select / Tab / highlight в сценах со скрытыми хотспотами.
function M.get_visible_hotspot_indices()
    if not _scene_data or not _scene_data.hotspots then return {} end
    local out = {}
    for i, h in ipairs(_scene_data.hotspots) do
        local ok = true
        if h.visible_when then ok = h.visible_when(gs) end
        if ok then table.insert(out, i) end
    end
    return out
end

-- Резолвит текущий bg сцены: если scene.bg — функция, вызывает её с gs
-- и возвращает имя bg как строку. Используется ui_manager_v2 для keep_bg
-- при прыжках в side-knot (use-on-target, sms thread, и т.п.).
function M.get_current_bg() return resolve_bg(_scene_data) end

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

    -- Armed-state инвентаря: игрок выбрал предмет с verb=use в инвентаре.
    -- Вместо обычного action запускаем inv_use_<item>_on_<hotspot> цепочку
    -- через ui_manager_v2 (callback request_use_on_hotspot).
    local armed = ui_state.get_armed and ui_state.get_armed()
    if armed and h and h.id and _ui and _ui.request_use_on_hotspot then
        if _ui.request_use_on_hotspot(h.id) then
            return true
        end
    end

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
    elseif action.type == "ink_knot" then
        -- Сохраняем фон текущей сцены, чтобы короткий ink-монолог
        -- (drink_coffee/take_phone/…) играл на том же фоне, а не на
        -- «последнем ink-фоне» (обычно коридор apartment_hub).
        local scene_bg = resolve_bg(_scene_data)
        M.exit()
        if _ui and _ui.request_ink_knot then
            _ui.request_ink_knot(action.knot, scene_bg)
        end
    else
        log.info("scene", "неизвестный action.type: " .. tostring(action.type))
    end
    return true
end

-- Сериализация состояния для сохранений
function M.serialize()
    return {
        scene_stack = _scene_stack,
        active = _active,
        scene_id = _scene_id,
    }
end

-- Восстановление состояния из сохранения
function M.deserialize(data)
    if not data then
        M.reset()
        return
    end

    _scene_stack = data.scene_stack or {}
    _active = false
    _scene_id = nil
    _scene_data = nil
    gs.set_scene(nil)
    -- Не восстанавливаем _active/_scene_id напрямую — это делается через
    -- enter() при загрузке, чтобы корректно отрендерить сцену
end

return M
