-- main/data/scenes/_shared.lua
-- Общие helper-функции и hotspot-стили для scenes. Раньше всё это жило
-- в начале scenes.lua. Извлекли в отдельный модуль чтобы per-location
-- файлы могли его require и использовать.

local M = {}

-- ---------------------------------------------------------------------------
-- State helpers — определение времени суток в локациях
-- ---------------------------------------------------------------------------

local function is_sunday_apartment_night(gs)
    return gs.get_flag("sunday_evening_started")
       and not gs.get_flag("sunday_finished")
end

local function is_monday_apartment_night(gs)
    return gs.get_flag("monday_office_finished")
       and not gs.get_flag("tuesday_morning_started")
end

local function is_apartment_night(gs)
    return is_sunday_apartment_night(gs)
        or is_monday_apartment_night(gs)
end

local function apartment_bg(room)
    return function(gs)
        if is_apartment_night(gs) then
            return "bg_apartment_" .. room .. "_night"
        end
        return "bg_apartment_" .. room .. "_day"
    end
end

local function is_office_night(gs)
    -- Понедельничный офисный вечер живёт до старта вторника.
    -- Вторничный офис становится ночным только после разбора следа.
    return (gs.get_flag("monday_office_finished") and not gs.get_flag("tuesday_morning_started"))
        or gs.get_flag("tuesday_investigation_done")
        or gs.get_flag("tuesday_rooftop_reached")
end

local function office_bg(room)
    return function(gs)
        if is_office_night(gs) then
            return "bg_office_" .. room .. "_night"
        end
        return "bg_office_" .. room .. "_day"
    end
end

M.is_sunday_apartment_night = is_sunday_apartment_night
M.is_monday_apartment_night = is_monday_apartment_night
M.is_apartment_night        = is_apartment_night
M.apartment_bg              = apartment_bg
M.is_office_night           = is_office_night
M.office_bg                 = office_bg

-- ---------------------------------------------------------------------------
-- Hotspot styles
-- ---------------------------------------------------------------------------
--
-- Типы хотспотов по игровому глаголу.
-- Палитра снята с текущего phone/map/terminal HUD:
--   base navy/purple: phone_bg / phone_screen / hud rings
--   cream text:       0.953, 0.925, 0.851
--   cyan system:      терминал, координаты, camera/calls
--   magenta alert:    SMS/mail/badges/P1 accent
--   amber operation:  terminal/map action, cafe/view accents
--   violet intel:     quests/clues/archive/home accents
--   green valid:      OK/work/park/positive route
--
-- Цвет кодирует действие, а не предмет:
--   NAV         = куда-то перейти
--   INSPECT     = осмотреть / получить описание
--   PICKUP      = забрать предмет
--   USE         = совершить действие с объектом
--   ITEM_TARGET = сюда можно применить предмет
--   STORY       = важный сюжетный gate / обязательный переход

M.STYLE_NAV = {
    -- Переход внутри point-and-click сцены: системный cyan/teal.
    circle_color = { r = 0.020, g = 0.045, b = 0.105 },
    ring_color   = { r = 0.300, g = 0.950, b = 1.000 },
    icon_color   = { r = 0.680, g = 0.985, b = 1.000 },
    circle_alpha = 0.52,
    ring_alpha   = 0.66,
    icon_alpha   = 0.96,
    scale = 0.90,
}

M.STYLE_INSPECT = {
    -- Осмотреть / прочитать окружение: violet/intel, мягче NAV/USE/PICKUP.
    circle_color = { r = 0.055, g = 0.035, b = 0.135 },
    ring_color   = { r = 0.660, g = 0.360, b = 1.000 },
    icon_color   = { r = 0.880, g = 0.760, b = 1.000 },
    circle_alpha = 0.46,
    ring_alpha   = 0.56,
    icon_alpha   = 0.90,
    scale = 0.84,
}

M.STYLE_PICKUP = {
    -- Забрать предмет в инвентарь: magenta/new-data, как SMS/mail/badge-акцент.
    circle_color = { r = 0.120, g = 0.020, b = 0.080 },
    ring_color   = { r = 1.000, g = 0.200, b = 0.560 },
    icon_color   = { r = 1.000, g = 0.620, b = 0.820 },
    circle_alpha = 0.56,
    ring_alpha   = 0.72,
    icon_alpha   = 0.98,
    scale = 0.92,
}

M.STYLE_USE = {
    -- Совершить действие с объектом: amber/operation, как terminal/map active-акцент.
    circle_color = { r = 0.115, g = 0.065, b = 0.015 },
    ring_color   = { r = 1.000, g = 0.640, b = 0.180 },
    icon_color   = { r = 1.000, g = 0.820, b = 0.430 },
    circle_alpha = 0.56,
    ring_alpha   = 0.72,
    icon_alpha   = 0.98,
    scale = 0.92,
}

M.STYLE_ITEM_TARGET = {
    -- Цель для применения предмета из инвентаря: green/valid target.
    -- Пока в scenes.lua почти не используется напрямую, но оставлен как заготовка.
    circle_color = { r = 0.025, g = 0.100, b = 0.055 },
    ring_color   = { r = 0.410, g = 0.960, b = 0.530 },
    icon_color   = { r = 0.760, g = 1.000, b = 0.820 },
    circle_alpha = 0.56,
    ring_alpha   = 0.74,
    icon_alpha   = 0.98,
    scale = 0.94,
}

M.STYLE_STORY = {
    -- Важный сюжетный gate / обязательное действие: hot magenta-alert.
    -- Не использовать для обычных выходов.
    circle_color = { r = 0.135, g = 0.018, b = 0.070 },
    ring_color   = { r = 1.000, g = 0.120, b = 0.470 },
    icon_color   = { r = 1.000, g = 0.520, b = 0.760 },
    circle_alpha = 0.62,
    ring_alpha   = 0.82,
    icon_alpha   = 1.00,
    scale = 0.96,
}

-- Старое имя как alias для совместимости со сценами/черновиками.
M.STYLE_NEUTRAL = M.STYLE_INSPECT

-- Упорядоченный список стилей. Используется hotspot-редактором (F1) для
-- цикличного перебора кнопками `,` / `.` и для печати в консоль читаемого
-- имени стиля. NEUTRAL пропущен (это alias на INSPECT).
M.STYLES = {
    { name = "STYLE_NAV",         style = M.STYLE_NAV },
    { name = "STYLE_INSPECT",     style = M.STYLE_INSPECT },
    { name = "STYLE_PICKUP",      style = M.STYLE_PICKUP },
    { name = "STYLE_USE",         style = M.STYLE_USE },
    { name = "STYLE_ITEM_TARGET", style = M.STYLE_ITEM_TARGET },
    { name = "STYLE_STORY",       style = M.STYLE_STORY },
}

-- ---------------------------------------------------------------------------
-- Hotspot recipes
-- ---------------------------------------------------------------------------
--
-- Готовые билдеры под типовые хотспоты. Принимают таблицу opts с обязательными
-- полями (rect/id/label/knot или scene в зависимости от рецепта) и возвращают
-- полную hotspot-таблицу. Все дефолты:
--   icon_offset_x = -4  (универсальная компенсация Material Icons по X)
--   icon_offset_y = 0   (= центр кружка)
-- Переопределяй через opts.icon_offset_x / opts.icon_offset_y когда glyph
-- визуально не центрирован.
--
-- Опциональные поля для всех рецептов:
--   visible_when = function(gs) ... end
--   condition    = function(gs) ... end
--   icon_offset_x, icon_offset_y
--
-- Примеры использования см. в любом scene-файле.
--
-- Override: любой рецепт можно перебить точечно, передав в opts:
--   hotspot_style = s.STYLE_X  — поменять стиль для конкретного хотспота
--   action        = { type=..., ... }  — поменять полностью action
--   icon          = "name"     — поменять иконку
--   icon_offset_x / icon_offset_y — точечный сдвиг glyph'а
-- Дефолт рецепта применяется только если соответствующее поле в opts отсутствует.

local function build(style, icon_default, action, opts)
    return {
        id            = opts.id,
        rect          = opts.rect,
        label         = opts.label,
        icon          = opts.icon or icon_default,
        hotspot_style = opts.hotspot_style or style,
        action        = opts.action or action,
        icon_offset_x = opts.icon_offset_x or -4,
        icon_offset_y = opts.icon_offset_y,
        visible_when  = opts.visible_when,
        condition     = opts.condition,
    }
end

-- Переход в другую exploration-сцену внутри хаба (sub-scene navigation).
-- Обязательные: id, rect, label, icon, scene.
function M.nav_scene(opts)
    return build(M.STYLE_NAV, opts.icon, { type = "goto_scene", scene = opts.scene }, opts)
end

-- Навигация через ink-knot (например leave_park со специальным narrative).
-- Обязательные: id, rect, label, icon, knot.
function M.nav_ink(opts)
    return build(M.STYLE_NAV, opts.icon, { type = "ink_knot", knot = opts.knot }, opts)
end

-- Осмотреть / прочитать. icon default = "left_click".
function M.inspect(opts)
    return build(M.STYLE_INSPECT, "left_click", { type = "ink_knot", knot = opts.knot }, opts)
end

-- Забрать предмет. icon default = "left_click".
function M.pickup(opts)
    return build(M.STYLE_PICKUP, "left_click", { type = "ink_knot", knot = opts.knot }, opts)
end

-- Совершить действие с объектом. icon default = "left_click".
function M.use(opts)
    return build(M.STYLE_USE, "left_click", { type = "ink_knot", knot = opts.knot }, opts)
end

-- Сюжетный gate / обязательное действие. icon default = "left_click".
function M.story(opts)
    return build(M.STYLE_STORY, "left_click", { type = "ink_knot", knot = opts.knot }, opts)
end

-- Цель для применения предмета. icon default = "left_click".
function M.item_target(opts)
    return build(M.STYLE_ITEM_TARGET, "left_click", { type = "ink_knot", knot = opts.knot }, opts)
end

-- Выход из локации. STYLE_NAV + icon "left" + label "Выйти" (можно переопределить).
-- Обязательные: id, rect, knot.
function M.leave(opts)
    return build(
        M.STYLE_NAV,
        opts.icon or "left",
        { type = "ink_knot", knot = opts.knot },
        {
            id            = opts.id,
            rect          = opts.rect,
            label         = opts.label or "Выйти",
            icon          = opts.icon,
            icon_offset_x = opts.icon_offset_x,
            icon_offset_y = opts.icon_offset_y,
            visible_when  = opts.visible_when,
            condition     = opts.condition,
        }
    )
end

return M
