-- hotspot_editor.lua
-- Дев-инструмент: редактор координат hotspot'ов и спрайтов-объектов
-- прямо в игре. Включается клавишей F1 (когда scene_controller активен).
--
-- Управление:
--   F1      — вкл/выкл режим редактирования
--   Esc     — выйти из режима
--   Tab     — следующий ВИДИМЫЙ элемент (циклит hotspot'ы → objects → hotspot'ы)
--   Клик    — выбрать видимый hotspot
--   ← → ↑ ↓ — двигать (5 px, Shift = 20 px)
--   [  ]    — ширина −/+
--   ;  '    — высота −/+
--   ,  .    — предыдущий / следующий стиль (только для hotspot'ов)
--   P       — напечатать координаты + стиль в консоль Defold
--
-- Изменения в памяти — scene-файлы на диск НЕ пишутся,
-- копируй строки из консоли через P.
--
-- Скрытые хотспоты (`visible_when` → false) в редакторе НЕ выбираются
-- ни кликом, ни Tab — иначе игрок не понимает что выбрано. Чтобы
-- отредактировать скрытый — временно убери visible_when в коде.

local scene_controller = require "main.scripts.scene_controller"
local shared = require "main.data.scenes._shared"
local log = require "main.scripts.log"

local M = {}

local _active = false

-- Единый указатель «что редактируем».
--   kind       = "hotspot" | "object"
--   full_index = индекс в _scene_data.hotspots / _scene_data.objects
-- Для hotspot'ов используется ПОЛНЫЙ индекс, не slot. Маппинг slot↔full
-- делается через scene_controller.get_visible_hotspot_indices().
local _sel = { kind = "hotspot", full_index = 1 }

-- ------------------------------------------------------------
-- Внутреннее: доступ к данным сцены
-- ------------------------------------------------------------

local function data()
    return scene_controller.get_current_scene_data()
end

local function hotspots() local d = data(); return d and d.hotspots or {} end
local function objects()  local d = data(); return d and d.objects  or {} end

local function visible_hotspot_indices()
    return scene_controller.get_visible_hotspot_indices and
           scene_controller.get_visible_hotspot_indices() or {}
end

-- ------------------------------------------------------------
-- slot ↔ full-index маппинг
-- ------------------------------------------------------------

-- Найти slot для текущего выделения. -1 если выбран object или скрытый
-- hotspot (для UI highlight это значит «не подсвечивать ни один слот»).
local function current_slot()
    if _sel.kind ~= "hotspot" then return -1 end
    local visible = visible_hotspot_indices()
    for slot, full_i in ipairs(visible) do
        if full_i == _sel.full_index then return slot end
    end
    return -1
end

local function current_item()
    if _sel.kind == "hotspot" then
        return hotspots()[_sel.full_index]
    else
        return objects()[_sel.full_index]
    end
end

-- ------------------------------------------------------------
-- Переход к следующему элементу
-- ------------------------------------------------------------

-- Tab крутит ТОЛЬКО видимые hotspot'ы + объекты. Скрытые игнорируются.
local function advance_selection()
    local visible = visible_hotspot_indices()
    local os = objects()

    if _sel.kind == "hotspot" then
        -- Найти текущую позицию в видимом списке
        local cur_pos = 0
        for i, full_i in ipairs(visible) do
            if full_i == _sel.full_index then cur_pos = i; break end
        end
        if cur_pos == 0 then
            -- Текущий выбор не в visible (например, был скрыт после правки
            -- visible_when) — начнём с первого видимого.
            if #visible > 0 then
                _sel.full_index = visible[1]
                return
            end
            -- видимых нет, переходим к объектам если они есть
            if #os > 0 then _sel.kind, _sel.full_index = "object", 1; return end
            return
        end
        if cur_pos < #visible then
            _sel.full_index = visible[cur_pos + 1]
        elseif #os > 0 then
            _sel.kind, _sel.full_index = "object", 1
        else
            _sel.full_index = visible[1]  -- цикл по видимым
        end
    else  -- _sel.kind == "object"
        if _sel.full_index < #os then
            _sel.full_index = _sel.full_index + 1
        elseif #visible > 0 then
            _sel.kind, _sel.full_index = "hotspot", visible[1]
        else
            _sel.full_index = 1
        end
    end
end

-- ------------------------------------------------------------
-- Описание текущего выбора
-- ------------------------------------------------------------

local function describe()
    local it = current_item()
    local name = it and it.id or "—"
    if _sel.kind == "hotspot" then
        local slot = current_slot()
        local slot_str = slot > 0 and ("slot " .. slot) or "hidden"
        return ("hotspot #%d %s (%s)"):format(_sel.full_index, slot_str, name)
    else
        return ("object #%d (%s)"):format(_sel.full_index, name)
    end
end

local function find_style_index(style_tbl)
    if not style_tbl then return 0 end
    for i, s in ipairs(shared.STYLES) do
        if s.style == style_tbl then return i end
    end
    return 0
end

-- ------------------------------------------------------------
-- Публичное API
-- ------------------------------------------------------------

function M.is_active() return _active end

-- Slot для подсветки в gui_script. -1 если object / скрытый / неактивен.
function M.selected_slot()
    if not _active then return -1 end
    return current_slot()
end

-- Старое имя — оставляем для совместимости, отдаём slot.
M.selected_index = M.selected_slot

function M.toggle()
    if not scene_controller.is_active() then
        log.info("hotspot_editor", "scene_controller не активен — нечего редактировать")
        return
    end
    _active = not _active
    -- При входе ставим выбор на первый видимый hotspot (или object).
    local visible = visible_hotspot_indices()
    if #visible > 0 then
        _sel.kind, _sel.full_index = "hotspot", visible[1]
    elseif #objects() > 0 then
        _sel.kind, _sel.full_index = "object", 1
    end
    if _active then
        print(("[hotspot_editor] ВКЛЮЧЁН. Сцена: %s. Выбран %s")
            :format(tostring(scene_controller.get_current_scene_id()), describe()))
        print("  F1/Esc=выйти  Tab=след  стрелки=двигать  []=ширина  ;'=высота  ,.=стиль  P=напечатать  Shift=×4")
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

-- Клик по СЛОТУ #slot_i (1..N visible) → выбрать соответствующий hotspot.
function M.select(slot_i)
    if not _active then return end
    local visible = visible_hotspot_indices()
    local full_i = visible[slot_i]
    if not full_i then return end
    _sel.kind, _sel.full_index = "hotspot", full_i
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

-- Цикл по стилям из shared.STYLES. direction = -1 или +1.
-- Для object'ов ничего не делает.
function M.cycle_style(direction)
    if not _active then return end
    if _sel.kind ~= "hotspot" then return end
    local it = current_item()
    if not it then return end

    local n = #shared.STYLES
    if n == 0 then return end
    local cur = find_style_index(it.hotspot_style)
    -- Если стиль не найден среди известных — стартуем с 1, иначе сдвигаемся.
    local nxt = cur == 0 and 1 or ((cur - 1 + direction) % n + 1)
    local picked = shared.STYLES[nxt]
    it.hotspot_style = picked.style
    print(("[hotspot_editor] %s → %s"):format(it.id, picked.name))
    scene_controller.render_now()
end

function M.print_current()
    if not _active then return end
    local it = current_item()
    if not it then return end

    local scene_id = tostring(scene_controller.get_current_scene_id())
    if _sel.kind == "hotspot" then
        local r = it.rect
        local style_idx = find_style_index(it.hotspot_style)
        local style_name = style_idx > 0 and shared.STYLES[style_idx].name or "—"
        print(("[hotspot_editor] %s / hotspot %s →"):format(scene_id, it.id))
        print(("    rect = { x = %d, y = %d, w = %d, h = %d },")
            :format(r.x, r.y, r.w, r.h))
        if style_idx > 0 then
            print(("    -- стиль: %s (если рецепт не совпадает — добавь hotspot_style = s.%s,)")
                :format(style_name, style_name))
        end
    else
        local p, s = it.pos, it.size
        print(("[hotspot_editor] %s / object %s →"):format(scene_id, it.id))
        print(("    pos  = { x = %d, y = %d },"):format(p.x, p.y))
        print(("    size = { w = %d, h = %d },"):format(s.w, s.h))
    end
end

return M
