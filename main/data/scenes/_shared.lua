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
        return "bg_apartment_" .. room .. "_morning"
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

return M
