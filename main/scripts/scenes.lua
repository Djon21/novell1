-- scenes.lua
-- Source of truth for point-and-click scenes.
--
-- Responsibilities:
--   - map scene_id -> background, hotspots, objects, optional on_enter
--   - keep exploration routes data-driven
--   - keep day/night variants in universal hubs when only background changes
--
-- Coordinates:
--   rect = { x, y, w, h } uses GUI space 1280x720, origin at bottom-left.
--
-- Supported action.type:
--   "goto_scene"  -- switch to another scene_id
--   "ink_knot"    -- leave exploration and jump to an Ink knot
--   "set_flag"    -- set a game_state flag
--   "add_item"    -- add an inventory item
--
-- Hotspot visibility:
--   visible_when(gs) -> false  hides hotspot completely
--   condition(gs)    -> false  keeps hotspot visible but locked/dimmed
--
-- Keep Ink contracts in sync:
--   every action = { type = "ink_knot", knot = "..." } must exist as
--   === ... === in an included .ink file, unless the scene is a locked future POI.

local M = {}

-- -----------------------------------------------------------------------------
-- State helpers
-- -----------------------------------------------------------------------------

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

-- -----------------------------------------------------------------------------
-- Shared hotspot styles
-- -----------------------------------------------------------------------------

-- Типы хотспотов по игровому глаголу.
-- Безопасный вариант: используем только уже поддерживаемый hotspot_style,
-- не добавляем новые поля и не трогаем scene_flow/gui_script.
--
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

local STYLE_NAV = {
    -- Переход внутри point-and-click сцены: системный cyan/teal.
    circle_color = { r = 0.020, g = 0.045, b = 0.105 },
    ring_color   = { r = 0.300, g = 0.950, b = 1.000 },
    icon_color   = { r = 0.680, g = 0.985, b = 1.000 },
    circle_alpha = 0.52,
    ring_alpha   = 0.66,
    icon_alpha   = 0.96,
    scale = 0.90,
}

local STYLE_INSPECT = {
    -- Осмотреть / прочитать окружение: violet/intel, мягче NAV/USE/PICKUP.
    circle_color = { r = 0.055, g = 0.035, b = 0.135 },
    ring_color   = { r = 0.660, g = 0.360, b = 1.000 },
    icon_color   = { r = 0.880, g = 0.760, b = 1.000 },
    circle_alpha = 0.46,
    ring_alpha   = 0.56,
    icon_alpha   = 0.90,
    scale = 0.84,
}

local STYLE_PICKUP = {
    -- Забрать предмет в инвентарь: magenta/new-data, как SMS/mail/badge-акцент.
    circle_color = { r = 0.120, g = 0.020, b = 0.080 },
    ring_color   = { r = 1.000, g = 0.200, b = 0.560 },
    icon_color   = { r = 1.000, g = 0.620, b = 0.820 },
    circle_alpha = 0.56,
    ring_alpha   = 0.72,
    icon_alpha   = 0.98,
    scale = 0.92,
}

local STYLE_USE = {
    -- Совершить действие с объектом: amber/operation, как terminal/map active-акцент.
    circle_color = { r = 0.115, g = 0.065, b = 0.015 },
    ring_color   = { r = 1.000, g = 0.640, b = 0.180 },
    icon_color   = { r = 1.000, g = 0.820, b = 0.430 },
    circle_alpha = 0.56,
    ring_alpha   = 0.72,
    icon_alpha   = 0.98,
    scale = 0.92,
}

local STYLE_ITEM_TARGET = {
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

local STYLE_STORY = {
    -- Важный сюжетный gate / обязательное действие: hot magenta-alert. Не использовать для обычных выходов.
    circle_color = { r = 0.135, g = 0.018, b = 0.070 },
    ring_color   = { r = 1.000, g = 0.120, b = 0.470 },
    icon_color   = { r = 1.000, g = 0.520, b = 0.760 },
    circle_alpha = 0.62,
    ring_alpha   = 0.82,
    icon_alpha   = 1.00,
    scale = 0.96,
}

-- Старое имя оставлено как alias для совместимости со сценами/черновиками,
-- где ещё может использоваться STYLE_NEUTRAL.
local STYLE_NEUTRAL = STYLE_INSPECT

M.scenes = {
    -- =====================================================================
    -- ДОМ / КВАРТИРА ГГ — универсальный hub утро/ночь
    -- =====================================================================
    -- apartment_hub / apartment_bedroom / apartment_kitchen используют один
    -- набор hotspot'ов и переключают фон через bg = function(gs).
    -- Утро: bg_apartment_*_morning.
    -- Ночь: bg_apartment_*_night, когда:
    --   sunday_evening_started=true и sunday_finished=false;
    --   или monday_office_finished=true и tuesday_morning_started=false.
    --
    -- Старые scene_id apartment_*_morning и sunday_apartment_bedroom_night
    -- оставлены алиасами внизу файла для совместимости со старым Ink/save.

    apartment_hub = {
        bg = apartment_bg("hall"),
        label = "Коридор",
        on_enter = {
            knot = "sunday_home_after_date_router",
            condition = function(gs)
                return gs.get_flag("sunday_after_date_active")
                    and not gs.get_flag("sunday_finished")
                    and gs.get_flag("met_npc_sunday")
                    and not gs.get_flag("sunday_evening_started")
            end,
        },
        hotspots = {
            {
                id = "to_bedroom",
                rect = { x = 110, y = 90, w = 175, h = 500 },
                label = "В спальню",
                icon = "arrow_back",
                hotspot_style = STYLE_NAV,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "goto_scene", scene = "apartment_bedroom" },
            },
            {
                id = "to_kitchen",
                rect = { x = 990, y = 90, w = 175, h = 500 },
                label = "На кухню",
                icon = "arrow_forward",
                hotspot_style = STYLE_NAV,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "goto_scene", scene = "apartment_kitchen" },
                visible_when = function(gs)
                    return is_apartment_night(gs) or gs.get_flag("washed_up")
                end,
            },
            {
                id = "exit_apartment",
                rect = { x = 575, y = 215, w = 155, h = 345 },
                label = "Выйти",
                icon = "arrow_up",
                hotspot_style = STYLE_NAV,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "ink_knot", knot = "leave_apartment" },
                visible_when = function(gs)
                    return not is_apartment_night(gs)
                end,
                condition = function(gs)
                    return gs.has_item("phone") and gs.has_item("key") and gs.get_flag("date_agreed") and gs.get_flag("washed_up") and gs.get_flag("sunday_dressed")
                end,
            },
            {
                id = "hall_mirror",
                rect = { x = 360, y = 410, w = 135, h = 135 },
                label = "Зеркало",
                icon = "left_click",
                hotspot_style = STYLE_INSPECT,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "ink_knot", knot = "look_hall_mirror" },
            },
            {
                id = "hall_console_keys",
                rect = { x = 385, y = 165, w = 135, h = 135 },
                label = "Ключи",
                icon = "note",
                hotspot_style = STYLE_PICKUP,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "ink_knot", knot = "take_sunday_keys" },
                visible_when = function(gs)
                    return not is_apartment_night(gs)
                       and not gs.has_item("key")
                end,
            },
            {
                id = "hall_jacket_shoes",
                rect = { x = 805, y = 135, w = 135, h = 305 },
                label = "Куртка и обувь",
                icon = "left_click",
                hotspot_style = STYLE_USE,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "ink_knot", knot = "sunday_get_dressed" },
                visible_when = function(gs)
                    return not is_apartment_night(gs)
                       and not gs.get_flag("sunday_dressed")
                end,
            },
        },
    },

    apartment_bedroom = {
        bg = apartment_bg("bedroom"),
        label = "Спальня",
        on_enter = {
            knot = "apartment_bedroom_intro",
            condition = function(gs)
                return not is_apartment_night(gs)
                   and not gs.get_flag("bedroom_morning_seen")
            end,
        },
        objects = {
            {
                id    = "phone_obj",
                image = "mobile",
                pos   = { x = 105, y = 185 },
                size  = { w = 52, h = 22 },
                visible_when = function(gs)
                    return not is_apartment_night(gs)
                       and not gs.has_item("phone")
                end,
            },
        },
        hotspots = {
            {
                id = "phone_on_bedside",
                rect = { x = 130, y = 215, w = 135, h = 135 },
                label = "Телефон",
                icon = "phone",
                hotspot_style = STYLE_PICKUP,
                action = { type = "ink_knot", knot = "take_phone" },
                visible_when = function(gs)
                    return not is_apartment_night(gs)
                       and not gs.has_item("phone")
                end,
            },
            {
                id = "bedroom_desk",
                rect = { x = 710, y = 335, w = 135, h = 135 },
                label = "Рабочий стол",
                icon = "left_click",
                hotspot_style = STYLE_INSPECT,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "ink_knot", knot = "bedroom_desk_morning" },
                visible_when = function(gs)
                    return not is_apartment_night(gs)
                       and gs.get_flag("got_out_of_bed")
                end,
            },
            {
                id = "bedroom_bed",
                rect = { x = 425, y = 150, w = 135, h = 135 },
                label = "Кровать",
                icon = "left_click",
                hotspot_style = STYLE_INSPECT,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "ink_knot", knot = "look_bed_morning" },
                visible_when = function(gs)
                    return not is_apartment_night(gs)
                       and gs.get_flag("date_agreed")
                       and not gs.get_flag("got_out_of_bed")
                end,
            },
            {
                id = "bedroom_bed_sleep_sunday",
                rect = { x = 425, y = 150, w = 135, h = 135 },
                label = "Лечь спать",
                icon = "left_click",
                hotspot_style = STYLE_STORY,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "ink_knot", knot = "sunday_sleep_in_bed" },
                visible_when = function(gs)
                    return is_sunday_apartment_night(gs)
                end,
            },
            {
                id = "bathroom_door_locked",
                rect = { x = 920, y = 145, w = 125, h = 480 },
                label = "Умыться",
                icon = "left_click",
                hotspot_style = STYLE_USE,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "ink_knot", knot = "wash_up_morning" },
                visible_when = function(gs)
                    return not is_apartment_night(gs)
                       and gs.get_flag("got_out_of_bed")
                       and not gs.get_flag("washed_up")
                end,
            },
            {
                id = "bedroom_window",
                rect = { x = 540, y = 330, w = 135, h = 190 },
                label = "Окно",
                icon = "left_click",
                hotspot_style = STYLE_INSPECT,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "ink_knot", knot = "look_bedroom_window" },
                visible_when = function(gs)
                    return not is_apartment_night(gs)
                       and gs.get_flag("got_out_of_bed")
                       and not gs.get_flag("sunday_bedroom_window_seen")
                end,
            },
            {
                id = "back_to_hall_from_bedroom",
                rect = { x = 1035, y = 70, w = 190, h = 260 },
                label = "В коридор",
                icon = "arrow_down",
                hotspot_style = STYLE_NAV,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "goto_scene", scene = "apartment_hub" },
                visible_when = function(gs)
                    return is_apartment_night(gs) or gs.get_flag("washed_up")
                end,
            },
        },
    },

    apartment_kitchen = {
        bg = apartment_bg("kitchen"),
        label = "Кухня",
        on_enter = {
            knot = "enter_kitchen_morning_first",
            condition = function(gs)
                return not is_apartment_night(gs)
                   and not gs.get_flag("kitchen_morning_seen")
            end,
        },
        hotspots = {
            {
                id = "coffee_setup",
                rect = { x = 290, y = 285, w = 135, h = 135 },
                label = "Кофе",
                icon = "coffee",
                hotspot_style = STYLE_USE,
                action = { type = "ink_knot", knot = "use_coffee_setup_no_mug" },
                visible_when = function(gs)
                    return not is_apartment_night(gs)
                       and not gs.get_flag("coffee_drunk")
                end,
            },
            {
                id = "take_mug_kitchen",
                rect = { x = 980, y = 155, w = 135, h = 135 },
                label = "Кружка",
                icon = "mug",
                hotspot_style = STYLE_PICKUP,
                action = { type = "ink_knot", knot = "take_mug" },
                visible_when = function(gs)
                    return not is_apartment_night(gs)
                       and not gs.has_item("mug")
                end,
            },
            {
                id = "kitchen_apples",
                rect = { x = 760, y = 150, w = 135, h = 135 },
                label = "Яблоко",
                icon = "left_click",
                hotspot_style = STYLE_PICKUP,
                action = { type = "ink_knot", knot = "take_kitchen_apple" },
                visible_when = function(gs)
                    return not is_apartment_night(gs)
                       and not gs.get_flag("breakfast_done")
                end,
            },
            {
                id = "kitchen_fridge",
                rect = { x = 1030, y = 210, w = 150, h = 330 },
                label = "Холодильник",
                icon = "left_click",
                hotspot_style = STYLE_INSPECT,
                action = { type = "ink_knot", knot = "look_kitchen_fridge" },
                visible_when = function(gs)
                    return not is_apartment_night(gs)
                       and not gs.get_flag("fridge_checked")
                end,
            },
            {
                id = "kitchen_window",
                rect = { x = 455, y = 360, w = 155, h = 215 },
                label = "Окно",
                icon = "left_click",
                hotspot_style = STYLE_INSPECT,
                action = { type = "ink_knot", knot = "look_kitchen_window" },
            },
            {
                id = "back_to_hall_from_kitchen",
                rect = { x = 25, y = 95, w = 205, h = 520 },
                label = "В коридор",
                icon = "arrow_back",
                hotspot_style = STYLE_NAV,
                action = { type = "goto_scene", scene = "apartment_hub" },
            },
        },
    },

    -- =====================================================================
    -- ПОНЕДЕЛЬНИК / КВАРТИРА ГГ — отдельный рабочий morning-flow
    -- =====================================================================
    -- Важно: это отдельные scene_id, хотя фоны те же, что в воскресенье.
    -- Так воскресные флаги (date_agreed, coffee_drunk, left_apartment)
    -- не смешиваются с рабочим понедельничным маршрутом.

    monday_apartment_bedroom_morning = {
        bg = "bg_apartment_bedroom_morning",
        label = "Спальня",
        on_enter = {
            knot = "mon_home_bedroom_intro",
            condition = function(gs)
                return not gs.get_flag("mon_home_bedroom_seen")
            end,
        },
        hotspots = {
            {
                id = "mon_bed",
                rect = { x = 425, y = 150, w = 135, h = 135 },
                label = "Кровать",
                icon = "left_click",
                hotspot_style = STYLE_INSPECT,
                action = { type = "ink_knot", knot = "mon_home_bed" },
            },
            {
                id = "mon_bedroom_desk",
                rect = { x = 710, y = 335, w = 135, h = 135 },
                label = "Рабочий стол",
                icon = "left_click",
                hotspot_style = STYLE_INSPECT,
                action = { type = "ink_knot", knot = "mon_home_bedroom_desk" },
            },
            {
                id = "mon_bathroom_wash",
                rect = { x = 920, y = 145, w = 125, h = 480 },
                label = "Умыться",
                icon = "left_click",
                hotspot_style = STYLE_USE,
                action = { type = "ink_knot", knot = "mon_home_wash_up" },
                visible_when = function(gs)
                    return not gs.get_flag("monday_washed_up")
                end,
            },
            {
                id = "mon_to_hall_from_bedroom",
                rect = { x = 1035, y = 70, w = 190, h = 260 },
                label = "В коридор",
                icon = "arrow_down",
                hotspot_style = STYLE_NAV,
                action = { type = "goto_scene", scene = "monday_apartment_hall_morning" },
            },
        },
    },

    monday_apartment_hall_morning = {
        bg = "bg_apartment_hall_morning",
        label = "Коридор",
        on_enter = {
            knot = "mon_home_hall_intro",
            condition = function(gs)
                return not gs.get_flag("mon_home_hall_seen")
            end,
        },
        hotspots = {
            {
                id = "mon_to_bedroom",
                rect = { x = 110, y = 90, w = 175, h = 500 },
                label = "В спальню",
                icon = "arrow_back",
                hotspot_style = STYLE_NAV,
                action = { type = "goto_scene", scene = "monday_apartment_bedroom_morning" },
            },
            {
                id = "mon_to_kitchen",
                rect = { x = 990, y = 90, w = 175, h = 500 },
                label = "На кухню",
                icon = "arrow_forward",
                hotspot_style = STYLE_NAV,
                action = { type = "goto_scene", scene = "monday_apartment_kitchen_morning" },
            },
            {
                id = "mon_hall_mirror",
                rect = { x = 360, y = 410, w = 135, h = 135 },
                label = "Зеркало",
                icon = "left_click",
                hotspot_style = STYLE_INSPECT,
                action = { type = "ink_knot", knot = "mon_home_hall_mirror" },
            },
            {
                id = "mon_work_card",
                rect = { x = 395, y = 165, w = 135, h = 135 },
                label = "Пропуск",
                icon = "note",
                hotspot_style = STYLE_PICKUP,
                action = { type = "ink_knot", knot = "mon_home_take_work_card" },
                visible_when = function(gs)
                    return not gs.has_item("card")
                end,
            },
            {
                id = "mon_get_dressed",
                rect = { x = 805, y = 135, w = 105, h = 305 },
                label = "Обувь и куртка",
                icon = "left_click",
                hotspot_style = STYLE_USE,
                action = { type = "ink_knot", knot = "mon_home_get_dressed" },
                visible_when = function(gs)
                    return not gs.get_flag("monday_dressed")
                end,
            },
            {
                id = "mon_exit_apartment",
                rect = { x = 575, y = 215, w = 155, h = 345 },
                label = "Выйти",
                icon = "arrow_up",
                hotspot_style = STYLE_NAV,
                action = { type = "ink_knot", knot = "mon_home_leave_apartment" },
                condition = function(gs)
                    return gs.has_item("phone")
                        and gs.has_item("key")
                        and gs.has_item("card")
                        and gs.get_flag("monday_washed_up")
                        and gs.get_flag("monday_dressed")
                end,
            },
        },
    },

    monday_apartment_kitchen_morning = {
        bg = "bg_apartment_kitchen_morning",
        label = "Кухня",
        on_enter = {
            knot = "mon_home_kitchen_intro",
            condition = function(gs)
                return not gs.get_flag("mon_home_kitchen_seen")
            end,
        },
        hotspots = {
            {
                id = "mon_kitchen_coffee",
                rect = { x = 280, y = 270, w = 135, h = 135 },
                label = "Кофе",
                icon = "coffee",
                hotspot_style = STYLE_USE,
                action = { type = "ink_knot", knot = "mon_home_kitchen_coffee" },
                visible_when = function(gs)
                    return not gs.get_flag("monday_coffee_done")
                end,
            },
            {
                id = "mon_kitchen_window",
                rect = { x = 455, y = 360, w = 155, h = 215 },
                label = "Окно",
                icon = "left_click",
                hotspot_style = STYLE_INSPECT,
                action = { type = "ink_knot", knot = "mon_home_kitchen_window" },
            },
            {
                id = "mon_back_to_hall_from_kitchen",
                rect = { x = 25, y = 95, w = 205, h = 520 },
                label = "В коридор",
                icon = "arrow_back",
                hotspot_style = STYLE_NAV,
                action = { type = "goto_scene", scene = "monday_apartment_hall_morning" },
            },
        },
    },


    -- =====================================================================
    -- ВТОРНИК / КВАРТИРА ГГ — consequences-flow
    -- =====================================================================
    -- Отдельные scene_id на тех же фонах. Вторник не переиспользует
    -- воскресные/понедельничные флаги, чтобы порядок действий не ломался.

    tuesday_apartment_bedroom_morning = {
        bg = "bg_apartment_bedroom_morning",
        label = "Спальня",
        on_enter = {
            knot = "tue_home_bedroom_intro",
            condition = function(gs)
                return not gs.get_flag("tue_home_bedroom_seen")
            end,
        },
        hotspots = {
            {
                id = "tue_bed",
                rect = { x = 460, y = 200, w = 135, h = 135 },
                label = "Кровать",
                icon = "left_click",
                hotspot_style = STYLE_INSPECT,
                action = { type = "ink_knot", knot = "tue_home_bed" },
            },
            {
                id = "tue_phone_check",
                rect = { x = 125, y = 205, w = 135, h = 135 },
                label = "Телефон",
                icon = "phone",
                hotspot_style = STYLE_USE,
                action = { type = "ink_knot", knot = "tue_home_check_phone" },
                visible_when = function(gs)
                    return not gs.get_flag("tuesday_phone_checked")
                end,
            },
            {
                id = "tue_bedroom_desk",
                rect = { x = 710, y = 335, w = 135, h = 135 },
                label = "Рабочий стол",
                icon = "left_click",
                hotspot_style = STYLE_INSPECT,
                action = { type = "ink_knot", knot = "tue_home_bedroom_desk" },
            },
            {
                id = "tue_bathroom_wash",
                rect = { x = 920, y = 145, w = 125, h = 480 },
                label = "Умыться",
                icon = "left_click",
                hotspot_style = STYLE_USE,
                action = { type = "ink_knot", knot = "tue_home_wash_up" },
                visible_when = function(gs)
                    return not gs.get_flag("tuesday_washed_up")
                end,
            },
            {
                id = "tue_to_hall_from_bedroom",
                rect = { x = 1035, y = 70, w = 190, h = 260 },
                label = "В коридор",
                icon = "arrow_down",
                hotspot_style = STYLE_NAV,
                action = { type = "goto_scene", scene = "tuesday_apartment_hall_morning" },
            },
        },
    },

    tuesday_apartment_hall_morning = {
        bg = "bg_apartment_hall_morning",
        label = "Коридор",
        on_enter = {
            knot = "tue_home_hall_intro",
            condition = function(gs)
                return not gs.get_flag("tue_home_hall_seen")
            end,
        },
        hotspots = {
            {
                id = "tue_to_bedroom",
                rect = { x = 110, y = 90, w = 175, h = 500 },
                label = "В спальню",
                icon = "arrow_back",
                hotspot_style = STYLE_NAV,
                action = { type = "goto_scene", scene = "tuesday_apartment_bedroom_morning" },
            },
            {
                id = "tue_to_kitchen",
                rect = { x = 990, y = 90, w = 175, h = 500 },
                label = "На кухню",
                icon = "arrow_forward",
                hotspot_style = STYLE_NAV,
                action = { type = "goto_scene", scene = "tuesday_apartment_kitchen_morning" },
            },
            {
                id = "tue_hall_mirror",
                rect = { x = 360, y = 410, w = 135, h = 135 },
                label = "Зеркало",
                icon = "left_click",
                hotspot_style = STYLE_INSPECT,
                action = { type = "ink_knot", knot = "tue_home_hall_mirror" },
            },
            {
                id = "tue_get_ready",
                rect = { x = 800, y = 155, w = 115, h = 250 },
                label = "Обувь и куртка",
                icon = "left_click",
                hotspot_style = STYLE_USE,
                action = { type = "ink_knot", knot = "tue_home_get_ready" },
                visible_when = function(gs)
                    return not gs.get_flag("tuesday_ready_to_leave")
                end,
            },
            {
                id = "tue_exit_apartment",
                rect = { x = 575, y = 215, w = 155, h = 345 },
                label = "Выйти",
                icon = "arrow_up",
                hotspot_style = STYLE_NAV,
                action = { type = "ink_knot", knot = "tue_home_leave_apartment" },
                condition = function(gs)
                    return gs.has_item("phone")
                        and gs.has_item("key")
                        and gs.has_item("card")
                        and gs.get_flag("tuesday_phone_checked")
                        and gs.get_flag("tuesday_washed_up")
                        and gs.get_flag("tuesday_ready_to_leave")
                end,
            },
        },
    },

    tuesday_apartment_kitchen_morning = {
        bg = "bg_apartment_kitchen_morning",
        label = "Кухня",
        on_enter = {
            knot = "tue_home_kitchen_intro",
            condition = function(gs)
                return not gs.get_flag("tue_home_kitchen_seen")
            end,
        },
        hotspots = {
            {
                id = "tue_kitchen_coffee",
                rect = { x = 280, y = 270, w = 135, h = 135 },
                label = "Кофе",
                icon = "coffee",
                hotspot_style = STYLE_USE,
                action = { type = "ink_knot", knot = "tue_home_kitchen_coffee" },
                visible_when = function(gs)
                    return not gs.get_flag("tuesday_coffee_done")
                end,
            },
            {
                id = "tue_kitchen_window",
                rect = { x = 455, y = 360, w = 155, h = 215 },
                label = "Окно",
                icon = "left_click",
                hotspot_style = STYLE_INSPECT,
                action = { type = "ink_knot", knot = "tue_home_kitchen_window" },
            },
            {
                id = "tue_back_to_hall_from_kitchen",
                rect = { x = 25, y = 95, w = 205, h = 520 },
                label = "В коридор",
                icon = "arrow_back",
                hotspot_style = STYLE_NAV,
                action = { type = "goto_scene", scene = "tuesday_apartment_hall_morning" },
            },
        },
    },

    -- =====================================================================
    -- ХАБЫ КАРТЫ — точки перемещения из phone_map POI
    -- =====================================================================
    -- Сами POI живут в phone_map.gui_script. Здесь только scene_id, фон,
    -- hotspots и on_enter. Фоны регистрируются по HOW_TO_ADD_SCENES.md.
    --
    -- ВАЖНО: future-хабы можно держать здесь как заготовки, но POI должны
    -- быть закрыты через map allow/lock, пока все их Ink-knot'ы не готовы.
    -- =====================================================================

    -- =====================================================================
    -- ОФИС — универсальный hub день/ночь
    -- =====================================================================
    -- work_hub / office_workspace / office_meeting_room используют один набор
    -- hotspot'ов и переключают фон через bg = function(gs).
    -- День: bg_office_*_day.
    -- Ночь: bg_office_*_night, когда офисный день уже ушёл в вечерний слой.

    work_hub = {
        bg = office_bg("lobby"),
        label = "Офис — лобби",
        hotspots = {
            {
                id = "office_turnstile",
                rect = { x = 885, y = 255, w = 135, h = 135 },
                label = "Турникет",
                icon = "left_click",
                hotspot_style = STYLE_USE,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "ink_knot", knot = "office_turnstile_prompt" },
                visible_when = function(gs)
                    return not gs.get_flag("monday_checked_in_office")
                end,
            },
            {
                id = "office_to_workspace",
                rect = { x = 785, y = 400, w = 190, h = 135 },
                label = "К рабочему месту",
                icon = "arrow_up",
                hotspot_style = STYLE_NAV,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "goto_scene", scene = "office_workspace" },
                condition = function(gs)
                    return gs.get_flag("monday_checked_in_office")
                end,
            },
            {
                id = "office_to_meeting_room",
                rect = { x = 390, y = 325, w = 150, h = 220 },
                label = "В переговорку",
                icon = "arrow_up",
                hotspot_style = STYLE_NAV,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "goto_scene", scene = "office_meeting_room" },
                condition = function(gs)
                    return gs.get_flag("monday_checked_in_office")
                        and gs.get_flag("monday_mail_read")
                end,
            },
            {
                id = "leave_work",
                rect = { x = 0, y = 0, w = 170, h = 220 },
                label = "Выйти",
                icon = "arrow_back",
                hotspot_style = STYLE_NAV,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "ink_knot", knot = "leave_work" },
            },
        },
    },

    office_workspace = {
        bg = office_bg("workspace"),
        label = "Рабочее место",
        npc = "npc",
        hotspots = {
            {
                id = "work_desk_mail",
                rect = { x = 400, y = 170, w = 365, h = 330 },
                label = "Рабочий стол",
                icon = "left_click",
                hotspot_style = STYLE_USE,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "ink_knot", knot = "work_desk_read_mail" },
                visible_when = function(gs)
                    return not gs.get_flag("monday_mail_read")
                end,
            },
            {
                id = "work_desk_waiting",
                rect = { x = 295, y = 210, w = 130, h = 130 },
                label = "Рабочий стол",
                icon = "left_click",
                hotspot_style = STYLE_INSPECT,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "ink_knot", knot = "work_desk_needs_case_file" },
                visible_when = function(gs)
                    return gs.get_flag("monday_mail_read")
                        and not gs.get_flag("monday_case_file_assembled")
                end,
            },
            {
                id = "work_desk_submit",
                rect = { x = 290, y = 205, w = 135, h = 135 },
                label = "Рабочий стол",
                icon = "left_click",
                hotspot_style = STYLE_USE,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "ink_knot", knot = "work_desk_case_file_prompt" },
                visible_when = function(gs)
                    return gs.get_flag("monday_case_file_assembled")
                        and not gs.get_flag("monday_case_file_submitted")
                end,
            },
            {
                id = "work_desk_done",
                rect = { x = 400, y = 170, w = 365, h = 330 },
                label = "Рабочий стол",
                icon = "left_click",
                hotspot_style = STYLE_INSPECT,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "ink_knot", knot = "work_desk_done" },
                visible_when = function(gs)
                    return gs.get_flag("monday_case_file_submitted")
                end,
            },
            {
                id = "workspace_to_meeting_room",
                rect = { x = 635, y = 290, w = 95, h = 240 },
                label = "В переговорку",
                icon = "arrow_up",
                hotspot_style = STYLE_NAV,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "goto_scene", scene = "office_meeting_room" },
                condition = function(gs)
                    return gs.get_flag("monday_mail_read")
                end,
            },
            {
                id = "workspace_back_to_lobby",
                rect = { x = 480, y = 35, w = 395, h = 180 },
                label = "В лобби",
                icon = "arrow_down",
                hotspot_style = STYLE_NAV,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "goto_scene", scene = "work_hub" },
            },
        },
    },

    office_meeting_room = {
        bg = office_bg("meeting_room"),
        label = "Переговорка",
        hotspots = {
            {
                id = "meeting_room_table_folder",
                rect = { x = 515, y = 175, w = 200, h = 150 },
                label = "Стол",
                icon = "left_click",
                hotspot_style = STYLE_PICKUP,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "ink_knot", knot = "meeting_room_take_folder" },
                visible_when = function(gs)
                    return not gs.get_flag("monday_folder_taken")
                        and not gs.get_flag("monday_case_file_assembled")
                end,
            },
            {
                id = "meeting_room_table_after",
                rect = { x = 320, y = 135, w = 610, h = 315 },
                label = "Стол",
                icon = "left_click",
                hotspot_style = STYLE_INSPECT,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "ink_knot", knot = "meeting_room_table_after" },
                visible_when = function(gs)
                    return gs.get_flag("monday_folder_taken")
                        or gs.get_flag("monday_case_file_assembled")
                end,
            },
            {
                id = "meeting_room_to_workspace",
                rect = { x = 900, y = 245, w = 110, h = 255 },
                label = "К рабочему месту",
                icon = "arrow_up",
                hotspot_style = STYLE_NAV,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "goto_scene", scene = "office_workspace" },
            },
            {
                id = "meeting_room_back_to_lobby",
                rect = { x = 1130, y = 170, w = 135, h = 410 },
                label = "В лобби",
                icon = "arrow_forward",
                hotspot_style = STYLE_NAV,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "goto_scene", scene = "work_hub" },
            },
        },
    },

    cafe_hub = {
        bg = "bg_cafe_morning",
        label = "Кафе",
        npc = "npc",       -- для inventory verb=give: inv_give_<item>_on_npc

        on_enter = {
            knot = "sunday_date_cafe_arrival",
            condition = function(gs)
                return gs.get_flag("date_place_cafe") and not gs.get_flag("met_npc_sunday")
            end,
        },
        hotspots = {
            {
                id = "cafe_window_table",
                rect = { x = 680, y = 170, w = 300, h = 270 },
                label = "Столик у окна",
                icon = "left_click",
                hotspot_style = STYLE_INSPECT,
                action = { type = "ink_knot", knot = "cafe_window_table" },
                visible_when = function(gs)
                    return gs.get_flag("met_npc_sunday")
                end,
            },
            {
                id = "cafe_bar",
                rect = { x = 360, y = 205, w = 380, h = 280 },
                label = "Стойка",
                icon = "coffee",
                hotspot_style = STYLE_USE,
                action = { type = "ink_knot", knot = "cafe_bar_interact" },
            },
            {
                id = "leave_cafe",
                rect = { x = 0, y = 0, w = 170, h = 220 },
                label = "Выйти",
                icon = "arrow_back",
                hotspot_style = STYLE_NAV,
                action = { type = "ink_knot", knot = "leave_cafe" },
            },
        },
    },

    park_hub = {
        bg = "bg_park_by_the_river_morning",
        label = "Парк у реки",
        npc = "npc",       -- для inventory verb=give: inv_give_<item>_on_npc

        on_enter = {
            knot = "sunday_date_park_arrival",
            condition = function(gs)
                return gs.get_flag("date_place_park") and not gs.get_flag("met_npc_sunday")
            end,
        },
        hotspots = {
            {
                id = "park_bench",
                rect = { x = 730, y = 120, w = 135, h = 135 },
                label = "Скамейка",
                icon = "left_click",
                hotspot_style = STYLE_INSPECT,
                action = { type = "ink_knot", knot = "park_bench_interact" },
            },
            {
                id = "park_river_view",
                rect = { x = 990, y = 155, w = 135, h = 135 },
                label = "Река",
                icon = "left_click",
                hotspot_style = STYLE_INSPECT,
                action = { type = "ink_knot", knot = "park_river_view" },
                visible_when = function(gs)
                    return gs.get_flag("met_npc_sunday")
                end,
            },
            {
                id = "leave_park",
                rect = { x = 60, y = 60, w = 170, h = 220 },
                label = "Уйти",
                icon = "arrow_back",
                hotspot_style = STYLE_NAV,
                action = { type = "ink_knot", knot = "leave_park" },
            },
        },
    },

    shop_hub = {
        bg = "bg_shop_day",
        label = "Магазин 24/7",
        on_enter = {
            knot = "sunday_shop_arrival",
            condition = function(gs)
                return (not gs.get_flag("met_npc_sunday") and not gs.get_flag("sunday_shop_pre_date_visited"))
                    or (gs.get_flag("sunday_after_date_active") and not gs.get_flag("sunday_second_stop_done") and not gs.get_flag("sunday_shop_with_npc_seen"))
            end,
        },
        hotspots = {
            {
                id = "shop_drinks",
                rect = { x = 900, y = 240, w = 300, h = 300 },
                label = "Напитки",
                icon = "left_click",
                hotspot_style = STYLE_PICKUP,
                action = { type = "ink_knot", knot = "shop_drinks_interact" },
                visible_when = function(gs)
                    return not gs.get_flag("sunday_shop_done")
                end,
            },
            {
                id = "shop_snacks",
                rect = { x = 520, y = 170, w = 260, h = 330 },
                label = "Снеки",
                icon = "left_click",
                hotspot_style = STYLE_PICKUP,
                action = { type = "ink_knot", knot = "shop_snacks_interact" },
                visible_when = function(gs)
                    return not gs.get_flag("sunday_shop_done")
                end,
            },
            {
                id = "shop_counter",
                rect = { x = 0, y = 240, w = 400, h = 300 },
                label = "Прилавок",
                icon = "left_click",
                hotspot_style = STYLE_INSPECT,
                action = { type = "ink_knot", knot = "shop_counter_interact" },
            },
            {
                id = "leave_shop",
                rect = { x = 505, y = 320, w = 115, h = 210 },
                label = "Выйти",
                icon = "arrow_up",
                hotspot_style = STYLE_NAV,
                action = { type = "ink_knot", knot = "leave_shop" },
            },
        },
    },

    -- Минимальный хаб бара: один фон, осмотр стойки, выход через карту.
    bar_hub = {
        bg = "bg_bar_maybe_night",
        label = "Бар Maybe",
        hotspots = {
            {
                id = "bar_counter",
                rect = { x = 300, y = 150, w = 500, h = 300 },
                label = "Стойка бара",
                icon = "",
                hotspot_style = STYLE_INSPECT,
                action = { type = "ink_knot", knot = "bar_counter_interact" },
            },
            {
                id = "leave_bar",
                rect = { x = 0, y = 0, w = 150, h = 200 },
                label = "Выйти",
                icon = "",
                hotspot_style = STYLE_NAV,
                action = { type = "ink_knot", knot = "leave_bar" },
            },
        },
    },

    view_hub = {
        bg = "bg_observation_day",
        label = "Смотровая",
        on_enter = {
            knot = "sunday_viewpoint_arrival",
            condition = function(gs)
                return gs.get_flag("sunday_after_date_active")
                    and not gs.get_flag("sunday_second_stop_done")
            end,
        },
        hotspots = {
            {
                id = "view_railing",
                rect = { x = 200, y = 200, w = 800, h = 150 },
                label = "Поручни",
                icon = "",
                hotspot_style = STYLE_INSPECT,
                action = { type = "ink_knot", knot = "view_railing_interact" },
            },
            {
                id = "leave_view",
                rect = { x = 0, y = 0, w = 150, h = 200 },
                label = "Уйти",
                icon = "",
                hotspot_style = STYLE_NAV,
                action = { type = "ink_knot", knot = "leave_viewpoint" },
            },
        },
    },

    -- Минимальный хаб архива: один фон, осмотр стеллажей, выход через карту.
    archive_hub = {
        bg = "bg_archive_day",
        label = "Архив",
        hotspots = {
            {
                id = "archive_shelves",
                rect = { x = 150, y = 100, w = 900, h = 400 },
                label = "Стеллажи",
                icon = "",
                hotspot_style = STYLE_INSPECT,
                action = { type = "ink_knot", knot = "archive_shelves_interact" },
            },
            {
                id = "leave_archive",
                rect = { x = 0, y = 0, w = 150, h = 200 },
                label = "Выйти",
                icon = "",
                hotspot_style = STYLE_NAV,
                action = { type = "ink_knot", knot = "leave_archive" },
            },
        },
    },
}

-- -----------------------------------------------------------------------------
-- Backwards-compatible aliases
-- -----------------------------------------------------------------------------
-- These point to canonical scene tables, not duplicated data. Keep them until old
-- saves and old Ink scene ids are no longer supported.
M.scenes.apartment_hall_morning = M.scenes.apartment_hub
M.scenes.apartment_bedroom_morning = M.scenes.apartment_bedroom
M.scenes.apartment_kitchen_morning = M.scenes.apartment_kitchen
M.scenes.sunday_apartment_bedroom_night = M.scenes.apartment_bedroom

-- Backwards-compatible aliases for office naming.
M.scenes.office_lobby = M.scenes.work_hub
M.scenes.work_hub_day = M.scenes.work_hub
M.scenes.work_hub_night = M.scenes.work_hub

function M.get(id) return M.scenes[id] end

return M
