-- gui_utils.lua
-- Общие хелперы для gui_script'ов проекта. Раньше каждый gui_script держал
-- свои локальные копии get_node/set_text/set_node_enabled/set_color/...
-- (~30-40 строк дубликата ×10 файлов). Теперь — один модуль.
--
-- Использование:
--
--   local U = require "main.gui.modules.gui_utils"
--
--   U.set_text("title", "Привет")
--   U.set_node_enabled("badge", true)
--   U.set_color("bg", COLORS.accent, 0.8)
--   local clamped = U.clamp_text(long_string, 32)
--
-- Все id-based функции pcall-safe: если node по id не существует, тихо
-- игнорируют. Удобно для шаблонных gui где набор нод варьируется.
--
-- См. также docs/guides/GUI_UTILS.md для подробного руководства.

local M = {}

-- ===========================================================================
-- Node lookup
-- ===========================================================================

-- Безопасный gui.get_node. Возвращает nil если ноды нет — обычная
-- gui.get_node кидает ошибку. Используем pcall чтобы gui_script не падал
-- когда обращаемся к ноде из шаблона которого может не быть в layout'е.
function M.get_node(id)
    if type(id) ~= "string" then return id end  -- уже нода
    local ok, n = pcall(gui.get_node, id)
    if ok then return n end
    return nil
end

-- Алиас для совместимости с прошлой версией модуля.
M.get_node_safe = M.get_node

-- ===========================================================================
-- Enable / visibility
-- ===========================================================================

function M.set_node_enabled(id, enabled)
    local n = M.get_node(id)
    if n then gui.set_enabled(n, enabled and true or false) end
end

-- ids = массив строк-id или нод. enabled = bool.
function M.set_nodes_enabled(ids, enabled)
    if type(ids) ~= "table" then return end
    for _, id in ipairs(ids) do
        M.set_node_enabled(id, enabled)
    end
end

-- ===========================================================================
-- Text
-- ===========================================================================

function M.set_text(id, value)
    local n = M.get_node(id)
    if n then gui.set_text(n, value ~= nil and tostring(value) or "") end
end

-- UTF-8-aware truncation. "Привет!" — 7 codepoints, но 13 байт. Обрезает
-- по кодпойнтам, добавляет ellipsis если длиннее лимита.
-- ellipsis по умолчанию — "…" (1 codepoint).
function M.clamp_text(s, max_len, ellipsis)
    if s == nil then return "" end
    s = tostring(s)
    max_len = tonumber(max_len) or 32
    if max_len <= 0 then return "" end
    ellipsis = ellipsis ~= nil and tostring(ellipsis) or "…"

    if utf8 and utf8.len then
        local len = utf8.len(s)
        if not len or len <= max_len then return s end
        local ell_len = utf8.len(ellipsis) or #ellipsis
        local keep = math.max(0, max_len - ell_len)
        local cut_byte = utf8.offset(s, keep + 1)
        if not cut_byte then return s end
        return s:sub(1, cut_byte - 1) .. ellipsis
    end

    -- Fallback (только ASCII).
    if #s <= max_len then return s end
    return s:sub(1, math.max(1, max_len - #ellipsis)) .. ellipsis
end

-- ===========================================================================
-- Color / alpha
-- ===========================================================================

-- color = vmath.vector3/vector4 ИЛИ таблица { x, y, z [, w] }.
-- alpha опц.: задано — перебивает color.w, иначе берётся color.w или 1.
function M.set_color(id, color, alpha)
    local n = M.get_node(id)
    if not n or not color then return end
    local cw = alpha or color.w or 1
    gui.set_color(n, vmath.vector4(color.x or 0, color.y or 0, color.z or 0, cw))
end

-- Меняет только rgb, оставляет текущую альфу.
function M.set_color_keep_alpha(id, color)
    local n = M.get_node(id)
    if not n or not color then return end
    local cur = gui.get_color(n)
    gui.set_color(n, vmath.vector4(color.x or 0, color.y or 0, color.z or 0, cur.w))
end

-- Меняет только альфу.
function M.set_alpha(id, alpha)
    local n = M.get_node(id)
    if not n or alpha == nil then return end
    local c = gui.get_color(n)
    gui.set_color(n, vmath.vector4(c.x, c.y, c.z, alpha))
end

function M.get_alpha(id)
    local n = M.get_node(id)
    if not n then return 0 end
    return gui.get_color(n).w
end

-- ===========================================================================
-- Position / size
-- ===========================================================================

function M.set_pos(id, x, y, z)
    local n = M.get_node(id)
    if n then gui.set_position(n, vmath.vector3(x or 0, y or 0, z or 0)) end
end

function M.set_size(id, w, h)
    local n = M.get_node(id)
    if n then gui.set_size(n, vmath.vector3(w or 0, h or 0, 0)) end
end

function M.set_pos_size(id, x, y, z, w, h)
    M.set_pos(id, x, y, z)
    M.set_size(id, w, h)
end

-- Удобный комбайн для box-нод: позиция + размер + (опц.) цвет с альфой.
function M.set_box(id, x, y, w, h, color, alpha, z)
    M.set_pos(id, x, y, z or 0)
    M.set_size(id, w, h)
    if color then M.set_color(id, color, alpha) end
end

-- ===========================================================================
-- Adaptive layout
-- ===========================================================================

-- Центрирует canvas (base_w x base_h) в viewport с равномерным scale.
-- Для компонентов v2-телефона: все ноды должны быть потомками root-ноды.
-- root_id = id ноды-контейнера (ставится ADJUST_FIT).
-- base_w / base_h = базовое разрешение (default 1280x720).
function M.apply_adaptive_layout(root_id, base_w, base_h)
    local root = M.get_node(root_id)
    if not root then return end
    base_w = base_w or 1280
    base_h = base_h or 720
    local screen_w, screen_h = gui.get_width() or base_w, gui.get_height() or base_h
    local scale = math.min(screen_w / base_w, screen_h / base_h)
    if scale <= 0 then scale = 1 end
    local pos = gui.get_position(root)
    pos.x = math.floor(((screen_w - base_w * scale) * 0.5) + 0.5)
    pos.y = math.floor(((screen_h - base_h * scale) * 0.5) + 0.5)
    gui.set_position(root, pos)
    gui.set_scale(root, vmath.vector3(scale, scale, 1))
end

-- ===========================================================================
-- Hit testing
-- ===========================================================================

-- Точечная проверка по rect-параметрам (без gui.pick_node — если ноды нет
-- или нужно проверить произвольную область).
function M.point_in_rect(x, y, rx, ry, rw, rh)
    return x >= rx and x <= rx + rw and y >= ry and y <= ry + rh
end

-- Удобная проверка попадания в ноду по её id (через gui.pick_node).
function M.pick_node(id, x, y)
    local n = M.get_node(id)
    if not n or not gui.is_enabled(n) then return false end
    return gui.pick_node(n, x, y) and true or false
end

-- ===========================================================================
-- Animations / feedback
-- ===========================================================================

-- Короткий flash через color.w. Стандартный визуальный feedback на тап
-- по UI-элементу. Принимает либо строку-id, либо саму ноду.
-- opts = { low = 0.3, dur_down = 0.08, dur_up = 0.18 }
function M.flash_node(id_or_node, opts)
    local n = id_or_node
    if type(n) == "string" then n = M.get_node(n) end
    if not n then return end
    opts = opts or {}
    local low      = opts.low or 0.3
    local dur_down = opts.dur_down or 0.08
    local dur_up   = opts.dur_up or 0.18
    local c        = gui.get_color(n)
    local c0w      = c.w
    gui.animate(n, "color.w",
        math.max(0.25, c0w * low),
        gui.EASING_OUTQUAD, dur_down, 0,
        function()
            gui.animate(n, "color.w", c0w, gui.EASING_OUTQUAD, dur_up)
        end)
end

-- Отменяет основные анимации на ноде. Полезно перед перезапуском
-- собственной анимации, чтобы старая не конкурировала с новой.
function M.cancel_animations(id_or_node)
    local n = id_or_node
    if type(n) == "string" then n = M.get_node(n) end
    if not n then return end
    gui.cancel_animation(n, "position")
    gui.cancel_animation(n, "position.x")
    gui.cancel_animation(n, "position.y")
    gui.cancel_animation(n, "position.z")
    gui.cancel_animation(n, "color")
    gui.cancel_animation(n, "color.w")
    gui.cancel_animation(n, "scale")
    gui.cancel_animation(n, "rotation")
end

-- ===========================================================================
-- Tree (clone / delete)
-- ===========================================================================

function M.clone_tree(id_or_node)
    local n = id_or_node
    if type(n) == "string" then n = M.get_node(n) end
    if not n then return nil end
    return gui.clone_tree(n)
end

function M.delete_tree(node)
    if node then gui.delete_node(node) end
end

-- ===========================================================================
-- Vector shortcuts
-- ===========================================================================

function M.color4(r, g, b, a)
    return vmath.vector4(r or 0, g or 0, b or 0, a or 1)
end

function M.vec3(x, y, z)
    return vmath.vector3(x or 0, y or 0, z or 0)
end

return M
