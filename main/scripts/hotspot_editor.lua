-- hotspot_editor.lua
-- Дев-инструмент: редактор координат hotspot'ов И спрайтов-объектов
-- прямо в игре. Включается клавишей F1 (когда scene_controller активен).
--
-- Управление:
--   F1      — вкл/выкл режим редактирования
--   Esc     — выйти из режима
--   Tab     — следующий элемент (циклит hotspot'ы → objects → hotspot'ы)
--   Клик    — выбрать hotspot (по объектам клик пока не ловится)
--   ← → ↑ ↓ — двигать (5 px, Shift = 20 px)
--   [  ]    — ширина −/+
--   ;  '    — высота −/+
--   P       — напечатать координаты в консоль Defold
--
-- Изменения в памяти — scenes.lua на диск НЕ пишется,
-- копируй строки из консоли через P.

local scene_controller = require "main.scripts.scene_controller"
local log = require "main.scripts.log"

local M = {}

local _active   = false

-- Единый указатель «что редактируем».
--   kind = "hotspot" | "object"
--   index = номер в массиве scene_data.hotspots / scene_data.objects
local _sel = { kind = "hotspot", index = 1 }

-- Шаги клавиатуры (5 px / Shift = 20 px) хардкодом в hotspots_v2.gui_script
-- на вызовах nudge — здесь не дублируем.

-- ------------------------------------------------------------
-- Внутреннее
-- ------------------------------------------------------------

local function data()
    return scene_controller.get_current_scene_data()
end

local function hotspots() local d = data(); return d and d.hotspots or {} end
local function objects()  local d = data(); return d and d.objects  or {} end

local function current_item()
    if _sel.kind == "hotspot" then
        return hotspots()[_sel.index]
    else
        return objects()[_sel.index]
    end
end

-- Переход к следующему элементу: сначала крутим hotspot'ы, потом objects,
-- потом обратно к hotspot'ам. Пропускаем пустые массивы.
local function advance_selection()
    local hs = hotspots()
    local os = objects()
    if _sel.kind == "hotspot" then
        if _sel.index < #hs then
            _sel.index = _sel.index + 1
        elseif #os > 0 then
            _sel.kind, _sel.index = "object", 1
        else
            _sel.index = 1  -- только hotspot'ы, начинаем сначала
        end
    else  -- _sel.kind == "object"
        if _sel.index < #os then
            _sel.index = _sel.index + 1
        elseif #hs > 0 then
            _sel.kind, _sel.index = "hotspot", 1
        else
            _sel.index = 1
        end
    end
end

local function describe()
    local it = current_item()
    local name = it and it.id or "—"
    return ("%s #%d (%s)"):format(_sel.kind, _sel.index, name)
end

-- ------------------------------------------------------------
-- Публичное API
-- ------------------------------------------------------------

function M.is_active() return _active end

-- Для подсветки бокса в gui_script (работает только для hotspot'ов)
function M.selected_index()
    if _sel.kind == "hotspot" then return _sel.index end
    return -1
end

function M.toggle()
    if not scene_controller.is_active() then
        log.info("hotspot_editor", "scene_controller не активен — нечего редактировать")
        return
    end
    _active = not _active
    _sel.kind, _sel.index = "hotspot", 1
    if not current_item() then
        -- нет hotspot'ов, но есть объекты — начнём с них
        if #objects() > 0 then _sel.kind, _sel.index = "object", 1 end
    end
    if _active then
        print(("[hotspot_editor] ВКЛЮЧЁН. Сцена: %s. Выбран %s")
            :format(tostring(scene_controller.get_current_scene_id()), describe()))
        print("  F1/Esc=выйти  Tab=след  стрелки=двигать  []=ширина  ;'=высота  P=напечатать  Shift=×4")
    else
        log.info("hotspot_editor", "ВЫКЛЮЧЕН.")
    end
    scene_controller.render_now()
end

function M.exit_mode()
    if not _active then return end
    _active = false
    log.info("hotspot_editor", "ВЫКЛЮЧЕН.")
    scene_controller.render_now()
end

-- Клик по hotspot'у #i в режиме редактирования → выбираем его
function M.select(i)
    if not _active then return end
    local hs = hotspots()
    if i < 1 or i > #hs then return end
    _sel.kind, _sel.index = "hotspot", i
    print(("[hotspot_editor] выбран %s"):format(describe()))
    scene_controller.render_now()
end

function M.next()
    if not _active then return end
    advance_selection()
    print(("[hotspot_editor] выбран %s"):format(describe()))
    scene_controller.render_now()
end

-- Движение/ресайз. Для hotspot'а мутируем rect, для object'а — pos/size.
function M.nudge(dx, dy, dw, dh)
    if not _active then return end
    local it = current_item()
    if not it then return end

    if _sel.kind == "hotspot" then
        local r = it.rect
        if not r then return end
        r.x = r.x + (dx or 0)
        r.y = r.y + (dy or 0)
        r.w = math.max(10, r.w + (dw or 0))
        r.h = math.max(10, r.h + (dh or 0))
    else  -- object
        it.pos  = it.pos  or { x = 0, y = 0 }
        it.size = it.size or { w = 50, h = 50 }
        it.pos.x  = it.pos.x  + (dx or 0)
        it.pos.y  = it.pos.y  + (dy or 0)
        it.size.w = math.max(5, it.size.w + (dw or 0))
        it.size.h = math.max(5, it.size.h + (dh or 0))
    end
    scene_controller.render_now()
end

function M.print_current()
    if not _active then return end
    local it = current_item()
    if not it then return end

    local scene_id = tostring(scene_controller.get_current_scene_id())
    if _sel.kind == "hotspot" then
        local r = it.rect
        print(("[hotspot_editor] %s / hotspot %s →"):format(scene_id, it.id))
        print(("    rect = { x = %d, y = %d, w = %d, h = %d },")
            :format(r.x, r.y, r.w, r.h))
    else
        local p, s = it.pos, it.size
        print(("[hotspot_editor] %s / object %s →"):format(scene_id, it.id))
        print(("    pos  = { x = %d, y = %d },"):format(p.x, p.y))
        print(("    size = { w = %d, h = %d },"):format(s.w, s.h))
    end
end

return M
