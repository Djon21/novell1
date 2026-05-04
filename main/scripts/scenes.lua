-- scenes.lua
-- Каталог сцен point-and-click слоя. Данные, не код.
-- rect = { x, y, w, h } — x/y это ЛЕВЫЙ-НИЖНИЙ угол прямоугольника
-- в коорд. системе .gui (1280×720, origin левый-нижний).
-- scene_controller сам пересчитает в центр+size при выставлении ноды.
--
-- action.type:
--   "goto_scene"  — перейти в другую сцену (scene=...)
--   "set_flag"    — gs.set_flag(flag, value)
--   "add_item"    — gs.add_item(item)
--   "ink_knot"    — выйти из exploration и прыгнуть в ink-узел (knot=...)
--
-- condition(gs) → bool — если задано и вернуло false, hotspot показывается
-- «тусклым» (locked) и клик по нему не срабатывает.

local M = {}

M.scenes = {    -- =====================================================================
    -- ДОМ / КВАРТИРА ГГ — утренний onboarding-flow
    --
    -- Runtime-home entrypoint остаётся apartment_hub, потому что карта телефона
    -- уже ведёт домой через poi_home -> apartment_hub.
    -- =====================================================================

    -- Точка входа карты телефона (poi_home → apartment_hub) и hub воскресного
    -- дня после встречи. Hotspots, иконки и стили совпадают с
    -- apartment_hall_morning ниже — отличается только on_enter, который
    -- автоматически открывает sunday_home_after_date_router.
    apartment_hub = {
        bg = "bg_apartment_hall_morning",
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
                id = "to_bedroom_morning",
                rect = { x = 90, y = 115, w = 245, h = 500 },
                label = "В спальню",
                icon = "arrow_back",
                icon_offset_x = -4,
                icon_offset_y = 0,
                hotspot_style = {
                    circle_color = { r = 0.06, g = 0.06, b = 0.10 },
                    ring_color = { r = 1.00, g = 1.00, b = 1.00 },
                    icon_color = { r = 1.00, g = 1.00, b = 1.00 },
                    circle_alpha = 0.78,
                    ring_alpha = 0.90,
                },
                action = { type = "goto_scene", scene = "apartment_bedroom_morning" },
            },
            {
                id = "to_kitchen_morning",
                rect = { x = 965, y = 100, w = 250, h = 520 },
                label = "На кухню",
                icon = "arrow_forward",
                icon_offset_x = -4,
                icon_offset_y = 0,
                hotspot_style = {
                    circle_color = { r = 0.06, g = 0.06, b = 0.10 },
                    ring_color = { r = 1.00, g = 1.00, b = 1.00 },
                    icon_color = { r = 1.00, g = 1.00, b = 1.00 },
                    circle_alpha = 0.78,
                    ring_alpha = 0.90,
                },
                action = { type = "goto_scene", scene = "apartment_kitchen_morning" },
                visible_when = function(gs)
                    return gs.get_flag("washed_up")
                end,
            },
            {
                id = "exit_apartment_morning",
                rect = { x = 525, y = 185, w = 260, h = 430 },
                label = "Выйти",
                icon = "arrow_up",
                icon_offset_x = -4,
                icon_offset_y = 0,
                hotspot_style = {
                    circle_color = { r = 0.06, g = 0.06, b = 0.10 },
                    ring_color = { r = 1.00, g = 1.00, b = 1.00 },
                    icon_color = { r = 1.00, g = 1.00, b = 1.00 },
                    circle_alpha = 0.78,
                    ring_alpha = 0.90,
                },
                action = { type = "ink_knot", knot = "leave_apartment" },
                condition = function(gs)
                    return gs.has_item("phone") and gs.get_flag("coffee_drunk") and gs.get_flag("date_agreed")
                end,
            },
            {
                id = "hall_mirror",
                rect = { x = 355, y = 330, w = 135, h = 280 },
                label = "Зеркало",
                icon = "left_click",
                icon_offset_x = -4,
                icon_offset_y = 0,
                hotspot_style = {
                    circle_color = { r = 0.06, g = 0.06, b = 0.10 },
                    ring_color = { r = 1.00, g = 1.00, b = 1.00 },
                    icon_color = { r = 1.00, g = 1.00, b = 1.00 },
                    circle_alpha = 0.78,
                    ring_alpha = 0.90,
                },
                action = { type = "ink_knot", knot = "look_hall_mirror" },
            },
        },
    },

    apartment_hall_morning = {
        bg = "bg_apartment_hall_morning",
        label = "Коридор",
        hotspots = {
            {
                id = "to_bedroom_morning",
                rect = { x = 90, y = 115, w = 245, h = 500 },
                label = "В спальню",
                icon = "arrow_back",
				icon_offset_x = -4,
				icon_offset_y = 0,
                hotspot_style = {
                    circle_color = { r = 0.06, g = 0.06, b = 0.10 },
                    ring_color = { r = 1.00, g = 1.00, b = 1.00 },
                    icon_color = { r = 1.00, g = 1.00, b = 1.00 },
                    circle_alpha = 0.78,
                    ring_alpha = 0.90,
                },
                action = { type = "goto_scene", scene = "apartment_bedroom_morning" },
            },
            {
                id = "to_kitchen_morning",
                rect = { x = 965, y = 100, w = 250, h = 520 },
                label = "На кухню",
                icon = "arrow_forward",
				icon_offset_x = -4,
				icon_offset_y = 0,
                hotspot_style = {
                    circle_color = { r = 0.06, g = 0.06, b = 0.10 },
                    ring_color = { r = 1.00, g = 1.00, b = 1.00 },
                    icon_color = { r = 1.00, g = 1.00, b = 1.00 },
                    circle_alpha = 0.78,
                    ring_alpha = 0.90,
                },
                action = { type = "goto_scene", scene = "apartment_kitchen_morning" },
                visible_when = function(gs)
                    return gs.get_flag("washed_up")
                end,
            },
            {
                id = "exit_apartment_morning",
                rect = { x = 525, y = 185, w = 260, h = 430 },
                label = "Выйти",
				icon = "arrow_up",
				icon_offset_x = -4,
				icon_offset_y = 0,
                hotspot_style = {
                    circle_color = { r = 0.06, g = 0.06, b = 0.10 },
                    ring_color = { r = 1.00, g = 1.00, b = 1.00 },
                    icon_color = { r = 1.00, g = 1.00, b = 1.00 },
                    circle_alpha = 0.78,
                    ring_alpha = 0.90,
                },
                action = { type = "ink_knot", knot = "leave_apartment" },
                condition = function(gs)
                    return gs.has_item("phone") and gs.get_flag("coffee_drunk") and gs.get_flag("date_agreed")
                end,
            },
            {
                id = "hall_mirror",
                rect = { x = 355, y = 330, w = 135, h = 280 },
                label = "Зеркало",
				icon = "left_click",
				icon_offset_x = -4,
				icon_offset_y = 0,
                hotspot_style = {
                    circle_color = { r = 0.06, g = 0.06, b = 0.10 },
                    ring_color = { r = 1.00, g = 1.00, b = 1.00 },
                    icon_color = { r = 1.00, g = 1.00, b = 1.00 },
                    circle_alpha = 0.78,
                    ring_alpha = 0.90,
                },
                action = { type = "ink_knot", knot = "look_hall_mirror" },
            },
        },
    },

    apartment_bedroom_morning = {
        bg = "bg_apartment_bedroom_morning",
        label = "Спальня",
        on_enter = {
            knot = "apartment_bedroom_intro",
            condition = function(gs)
                return not gs.get_flag("bedroom_morning_seen")
            end,
        },
        objects = {
            {
                id    = "phone_obj",
                image = "mobile",
                pos   = { x = 105, y = 185 },
                size  = { w = 52, h = 22 },
                visible_when = function(gs)
                    return not gs.has_item("phone")
                end,
            },
        },
        hotspots = {
            {
                id = "phone_on_bedside",
                rect = { x = 135, y = 205, w = 220, h = 155 },
                label = "Телефон",
                icon = "phone",
                circle_color = { r = 0.03, g = 0.10, b = 0.18 },
                ring_color = { r = 0.40, g = 0.90, b = 1.00 },
                icon_color = { r = 0.85, g = 0.98, b = 1.00 },
                action = { type = "ink_knot", knot = "take_phone" },
                visible_when = function(gs)
                    return not gs.has_item("phone")
                end,
            },
            {
                id = "bedroom_desk",
                rect = { x = 690, y = 190, w = 245, h = 245 },
                label = "Рабочий стол",
				icon = "left_click",
				icon_offset_x = -4,
				icon_offset_y = 0,
                hotspot_style = {
                    circle_color = { r = 0.06, g = 0.06, b = 0.10 },
                    ring_color = { r = 1.00, g = 1.00, b = 1.00 },
                    icon_color = { r = 1.00, g = 1.00, b = 1.00 },
                    circle_alpha = 0.78,
                    ring_alpha = 0.90,
                },
                action = { type = "ink_knot", knot = "bedroom_desk_morning" },
                visible_when = function(gs)
                    return gs.get_flag("got_out_of_bed")
                end,
            },
            {
                id = "bedroom_bed",
                rect = { x = 205, y = 105, w = 460, h = 225 },
                label = "Кровать",
				icon = "left_click",
				icon_offset_x = -4,
				icon_offset_y = 0,
                hotspot_style = {
                    circle_color = { r = 0.06, g = 0.06, b = 0.10 },
                    ring_color = { r = 1.00, g = 1.00, b = 1.00 },
                    icon_color = { r = 1.00, g = 1.00, b = 1.00 },
                    circle_alpha = 0.78,
                    ring_alpha = 0.90,
                },
                action = { type = "ink_knot", knot = "look_bed_morning" },
                visible_when = function(gs)
                    return gs.get_flag("date_agreed")
                        and not gs.get_flag("got_out_of_bed")
                        and not gs.get_flag("sunday_evening_started")
                end,
            },
            {
                id = "bedroom_bed_sleep_sunday",
                rect = { x = 205, y = 105, w = 460, h = 225 },
                label = "Лечь спать",
                icon = "left_click",
				icon_offset_x = -4,
				icon_offset_y = 0,
                hotspot_style = {
                    circle_color = { r = 0.06, g = 0.06, b = 0.10 },
                    ring_color = { r = 1.00, g = 1.00, b = 1.00 },
                    icon_color = { r = 1.00, g = 1.00, b = 1.00 },
                    circle_alpha = 0.78,
                    ring_alpha = 0.90,
                },
                action = { type = "ink_knot", knot = "sunday_sleep_in_bed" },
                visible_when = function(gs)
                    return gs.get_flag("sunday_evening_started")
                        and not gs.get_flag("sunday_finished")
                end,
            },
            {
                id = "bathroom_door_locked",
                rect = { x = 920, y = 145, w = 125, h = 480 },
                label = "Умыться",
				icon = "left_click",
				icon_offset_x = -4,
				icon_offset_y = 0,
                hotspot_style = {
                    circle_color = { r = 0.06, g = 0.06, b = 0.10 },
                    ring_color = { r = 1.00, g = 1.00, b = 1.00 },
                    icon_color = { r = 1.00, g = 1.00, b = 1.00 },
                    circle_alpha = 0.78,
                    ring_alpha = 0.90,
                },
                action = { type = "ink_knot", knot = "wash_up_morning" },
                visible_when = function(gs)
                    return gs.get_flag("got_out_of_bed") and not gs.get_flag("washed_up")
                end,
            },
            {
                id = "back_to_hall_from_bedroom",
                rect = { x = 1035, y = 70, w = 190, h = 260 },
                label = "В коридор",
                icon = "arrow_down",
				icon_offset_x = -4,
				icon_offset_y = 0,
                hotspot_style = {
                    circle_color = { r = 0.06, g = 0.06, b = 0.10 },
                    ring_color = { r = 1.00, g = 1.00, b = 1.00 },
                    icon_color = { r = 1.00, g = 1.00, b = 1.00 },
                    circle_alpha = 0.78,
                    ring_alpha = 0.90,
                },
                action = { type = "goto_scene", scene = "apartment_hall_morning" },
                visible_when = function(gs)
                    return gs.get_flag("washed_up")
                end,
            },
        },
    },

    apartment_kitchen_morning = {
        bg = "bg_apartment_kitchen_morning",
        label = "Кухня",
        on_enter = {
            knot = "enter_kitchen_morning_first",
            condition = function(gs)
                return not gs.get_flag("kitchen_morning_seen")
            end,
        },
        hotspots = {
            {
                id = "coffee_setup",
                rect = { x = 420, y = 245, w = 190, h = 150 },
                label = "Кофе",
                icon = "coffee",
                circle_color = { r = 0.18, g = 0.10, b = 0.04 },
                ring_color = { r = 1.00, g = 0.68, b = 0.28 },
                icon_color = { r = 1.00, g = 0.90, b = 0.68 },
                action = { type = "ink_knot", knot = "use_coffee_setup_no_mug" },
                visible_when = function(gs)
                    return not gs.get_flag("coffee_drunk")
                end,
            },
            {
                id = "take_mug_kitchen",
                rect = { x = 910, y = 230, w = 165, h = 140 },
                label = "Кружка",
                icon = "mug",
                circle_color = { r = 0.16, g = 0.12, b = 0.08 },
                ring_color = { r = 0.95, g = 0.80, b = 0.50 },
                icon_color = { r = 1.00, g = 0.92, b = 0.74 },
                action = { type = "ink_knot", knot = "take_mug" },
                visible_when = function(gs)
                    return not gs.has_item("mug")
                end,
            },
            {
                id = "kitchen_window",
                rect = { x = 600, y = 335, w = 210, h = 230 },
                label = "Окно",
                icon = "left_click",
                action = { type = "ink_knot", knot = "look_kitchen_window" },
            },
            {
                id = "back_to_hall_from_kitchen",
                rect = { x = 25, y = 95, w = 205, h = 520 },
                label = "В коридор",
                icon = "arrow_back",
                action = { type = "goto_scene", scene = "apartment_hall_morning" },
            },
        },
    },

-- =====================================================================
-- ВОСКРЕСЕНЬЕ / КВАРТИРА ГГ — ночь после возвращения домой
-- =====================================================================
-- Использует уже зарегистрированный ночной фон спальни:
-- bg_apartment_bedroom_night

sunday_apartment_bedroom_night = {
    bg = "bg_apartment_bedroom_night",
    label = "Спальня",
    hotspots = {
        {
            id = "sun_night_bed_sleep",
            rect = { x = 205, y = 105, w = 460, h = 225 },
            label = "Лечь спать",
            icon = "left_click",
            icon_offset_x = -4,
            icon_offset_y = 0,
            hotspot_style = {
                circle_color = { r = 0.06, g = 0.06, b = 0.10 },
                ring_color = { r = 1.00, g = 1.00, b = 1.00 },
                icon_color = { r = 1.00, g = 1.00, b = 1.00 },
                circle_alpha = 0.78,
                ring_alpha = 0.90,
            },
            action = { type = "ink_knot", knot = "sunday_sleep_in_bed" },
            visible_when = function(gs)
                return gs.get_flag("sunday_evening_started")
                    and not gs.get_flag("sunday_finished")
            end,
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
                rect = { x = 205, y = 105, w = 460, h = 225 },
                label = "Кровать",
                icon = "left_click",
                action = { type = "ink_knot", knot = "mon_home_bed" },
            },
            {
                id = "mon_bedroom_desk",
                rect = { x = 690, y = 190, w = 245, h = 245 },
                label = "Рабочий стол",
                icon = "left_click",
                action = { type = "ink_knot", knot = "mon_home_bedroom_desk" },
            },
            {
                id = "mon_bathroom_wash",
                rect = { x = 920, y = 145, w = 125, h = 480 },
                label = "Умыться",
                icon = "left_click",
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
                rect = { x = 90, y = 115, w = 245, h = 500 },
                label = "В спальню",
                icon = "arrow_back",
                action = { type = "goto_scene", scene = "monday_apartment_bedroom_morning" },
            },
            {
                id = "mon_to_kitchen",
                rect = { x = 965, y = 100, w = 250, h = 520 },
                label = "На кухню",
                icon = "arrow_forward",
                action = { type = "goto_scene", scene = "monday_apartment_kitchen_morning" },
            },
            {
                id = "mon_hall_mirror",
                rect = { x = 355, y = 330, w = 135, h = 280 },
                label = "Зеркало",
                icon = "left_click",
                action = { type = "ink_knot", knot = "mon_home_hall_mirror" },
            },
            {
                id = "mon_work_card",
                rect = { x = 795, y = 305, w = 220, h = 250 },
                label = "Пропуск",
                icon = "note",
                action = { type = "ink_knot", knot = "mon_home_take_work_card" },
                visible_when = function(gs)
                    return not gs.has_item("card")
                end,
            },
            {
                id = "mon_get_dressed",
                rect = { x = 815, y = 80, w = 300, h = 220 },
                label = "Обувь и куртка",
                icon = "left_click",
                action = { type = "ink_knot", knot = "mon_home_get_dressed" },
                visible_when = function(gs)
                    return not gs.get_flag("monday_dressed")
                end,
            },
            {
                id = "mon_exit_apartment",
                rect = { x = 525, y = 185, w = 260, h = 430 },
                label = "Выйти",
                icon = "arrow_up",
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
                rect = { x = 420, y = 245, w = 190, h = 150 },
                label = "Кофе",
                icon = "coffee",
                action = { type = "ink_knot", knot = "mon_home_kitchen_coffee" },
                visible_when = function(gs)
                    return not gs.get_flag("monday_coffee_done")
                end,
            },
            {
                id = "mon_kitchen_window",
                rect = { x = 600, y = 335, w = 210, h = 230 },
                label = "Окно",
                icon = "left_click",
                action = { type = "ink_knot", knot = "mon_home_kitchen_window" },
            },
            {
                id = "mon_back_to_hall_from_kitchen",
                rect = { x = 25, y = 95, w = 205, h = 520 },
                label = "В коридор",
                icon = "arrow_back",
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
                rect = { x = 205, y = 105, w = 460, h = 225 },
                label = "Кровать",
                icon = "left_click",
                action = { type = "ink_knot", knot = "tue_home_bed" },
            },
            {
                id = "tue_phone_check",
                rect = { x = 135, y = 205, w = 220, h = 155 },
                label = "Телефон",
                icon = "phone",
                circle_color = { r = 0.03, g = 0.10, b = 0.18 },
                ring_color = { r = 0.40, g = 0.90, b = 1.00 },
                icon_color = { r = 0.85, g = 0.98, b = 1.00 },
                action = { type = "ink_knot", knot = "tue_home_check_phone" },
                visible_when = function(gs)
                    return not gs.get_flag("tuesday_phone_checked")
                end,
            },
            {
                id = "tue_bedroom_desk",
                rect = { x = 690, y = 190, w = 245, h = 245 },
                label = "Рабочий стол",
                icon = "left_click",
                action = { type = "ink_knot", knot = "tue_home_bedroom_desk" },
            },
            {
                id = "tue_bathroom_wash",
                rect = { x = 920, y = 145, w = 125, h = 480 },
                label = "Умыться",
                icon = "left_click",
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
                rect = { x = 90, y = 115, w = 245, h = 500 },
                label = "В спальню",
                icon = "arrow_back",
                action = { type = "goto_scene", scene = "tuesday_apartment_bedroom_morning" },
            },
            {
                id = "tue_to_kitchen",
                rect = { x = 965, y = 100, w = 250, h = 520 },
                label = "На кухню",
                icon = "arrow_forward",
                action = { type = "goto_scene", scene = "tuesday_apartment_kitchen_morning" },
            },
            {
                id = "tue_hall_mirror",
                rect = { x = 355, y = 330, w = 135, h = 280 },
                label = "Зеркало",
                icon = "left_click",
                action = { type = "ink_knot", knot = "tue_home_hall_mirror" },
            },
            {
                id = "tue_get_ready",
                rect = { x = 815, y = 80, w = 300, h = 220 },
                label = "Обувь и куртка",
                icon = "left_click",
                action = { type = "ink_knot", knot = "tue_home_get_ready" },
                visible_when = function(gs)
                    return not gs.get_flag("tuesday_ready_to_leave")
                end,
            },
            {
                id = "tue_exit_apartment",
                rect = { x = 525, y = 185, w = 260, h = 430 },
                label = "Выйти",
                icon = "arrow_up",
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
                rect = { x = 420, y = 245, w = 190, h = 150 },
                label = "Кофе",
                icon = "coffee",
                action = { type = "ink_knot", knot = "tue_home_kitchen_coffee" },
                visible_when = function(gs)
                    return not gs.get_flag("tuesday_coffee_done")
                end,
            },
            {
                id = "tue_kitchen_window",
                rect = { x = 600, y = 335, w = 210, h = 230 },
                label = "Окно",
                icon = "left_click",
                action = { type = "ink_knot", knot = "tue_home_kitchen_window" },
            },
            {
                id = "tue_back_to_hall_from_kitchen",
                rect = { x = 25, y = 95, w = 205, h = 520 },
                label = "В коридор",
                icon = "arrow_back",
                action = { type = "goto_scene", scene = "tuesday_apartment_hall_morning" },
            },
        },
    },

    -- =====================================================================
    -- ХАБЫ КАРТЫ — точки перемещения из phone_map POI
    -- =====================================================================
    -- Чтобы добавить новый хаб:
    --   1. Создай фон (PNG) → добавь в main/images/backgrounds/bg_NAME.atlas
    --   2. Зарегистрируй сцену здесь (скопируй шаблон ниже)
    --   3. В phone_map.gui_script в таблице POI_SCENES добавь:
    --        poi_NAME = "NAME_hub"
    --   4. Hotspot'ы: rect = { x, y, w, h } где x/y — левый-нижний угол
    --      в координатах 1280×720 (начало — левый-нижний угол экрана).
    -- =====================================================================

    work_hub = {
        bg = "bg_office_lobby_day",
        -- on_enter = {
        --     knot = "enter_work_first_time",
        --     condition = function(gs) return not gs.get_flag("work_intro_seen") end,
        -- },
        hotspots = {
            {
                id = "work_desk",
                rect = { x = 400, y = 200, w = 300, h = 300 },
                label = "Рабочий стол",
                icon = "",
                action = { type = "ink_knot", knot = "work_desk_interact" },
            },
            {
                id = "leave_work",
                rect = { x = 0, y = 0, w = 150, h = 200 },
                label = "Выйти",
                icon = "",
                action = { type = "ink_knot", knot = "leave_work" },
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
                action = { type = "ink_knot", knot = "cafe_bar_interact" },
            },
            {
                id = "leave_cafe",
                rect = { x = 0, y = 0, w = 170, h = 220 },
                label = "Выйти",
                icon = "arrow_back",
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
                rect = { x = 430, y = 135, w = 320, h = 220 },
                label = "Скамейка",
                icon = "left_click",
                action = { type = "ink_knot", knot = "park_bench_interact" },
            },
            {
                id = "park_river_view",
                rect = { x = 760, y = 250, w = 360, h = 260 },
                label = "Река",
                icon = "left_click",
                action = { type = "ink_knot", knot = "park_river_view" },
                visible_when = function(gs)
                    return gs.get_flag("met_npc_sunday")
                end,
            },
            {
                id = "leave_park",
                rect = { x = 0, y = 0, w = 170, h = 220 },
                label = "Уйти",
                icon = "arrow_back",
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
                return gs.get_flag("sunday_after_date_active")
                    and not gs.get_flag("sunday_second_stop_done")
            end,
        },
        hotspots = {
            {
                id = "shop_counter",
                rect = { x = 350, y = 150, w = 400, h = 300 },
                label = "Прилавок",
                icon = "",
                action = { type = "ink_knot", knot = "shop_counter_interact" },
            },
            {
                id = "leave_shop",
                rect = { x = 0, y = 0, w = 150, h = 200 },
                label = "Выйти",
                icon = "",
                action = { type = "ink_knot", knot = "leave_shop" },
            },
        },
    },

    bar_hub = {
        bg = "bg_bar_maybe_night",
        hotspots = {
            {
                id = "bar_counter",
                rect = { x = 300, y = 150, w = 500, h = 300 },
                label = "Стойка бара",
                icon = "",
                action = { type = "ink_knot", knot = "bar_counter_interact" },
            },
            {
                id = "leave_bar",
                rect = { x = 0, y = 0, w = 150, h = 200 },
                label = "Выйти",
                icon = "",
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
                action = { type = "ink_knot", knot = "view_railing_interact" },
            },
            {
                id = "leave_view",
                rect = { x = 0, y = 0, w = 150, h = 200 },
                label = "Уйти",
                icon = "",
                action = { type = "ink_knot", knot = "leave_viewpoint" },
            },
        },
    },

    archive_hub = {
        bg = "bg_archive_day",
        hotspots = {
            {
                id = "archive_shelves",
                rect = { x = 150, y = 100, w = 900, h = 400 },
                label = "Стеллажи",
                icon = "",
                action = { type = "ink_knot", knot = "archive_shelves_interact" },
            },
            {
                id = "leave_archive",
                rect = { x = 0, y = 0, w = 150, h = 200 },
                label = "Выйти",
                icon = "",
                action = { type = "ink_knot", knot = "leave_archive" },
            },
        },
    },
}

function M.get(id) return M.scenes[id] end

return M
