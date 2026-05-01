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

    apartment_hub = {
        bg = "bg_apartment_hall_morning",
        label = "Коридор",
        hotspots = {
            {
                id = "to_bedroom_morning",
                rect = { x = 45, y = 115, w = 245, h = 500 },
                label = "В спальню",
                icon = "",
                action = { type = "goto_scene", scene = "apartment_bedroom_morning" },
            },
            {
                id = "to_kitchen_morning",
                rect = { x = 985, y = 100, w = 250, h = 520 },
                label = "На кухню",
                icon = "",
                action = { type = "goto_scene", scene = "apartment_kitchen_morning" },
                visible_when = function(gs)
                    return gs.get_flag("washed_up")
                end,
            },
            {
                id = "exit_apartment_morning",
                rect = { x = 525, y = 185, w = 260, h = 430 },
                label = "Выйти",
                icon = "",
                action = { type = "ink_knot", knot = "leave_apartment" },
                condition = function(gs)
                    return gs.get_flag("has_phone") and gs.get_flag("coffee_drunk")
                end,
            },
            {
                id = "hall_mirror",
                rect = { x = 330, y = 230, w = 135, h = 280 },
                label = "Зеркало",
                icon = "",
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
                rect = { x = 45, y = 115, w = 245, h = 500 },
                label = "В спальню",
                icon = "",
                action = { type = "goto_scene", scene = "apartment_bedroom_morning" },
            },
            {
                id = "to_kitchen_morning",
                rect = { x = 985, y = 100, w = 250, h = 520 },
                label = "На кухню",
                icon = "",
                action = { type = "goto_scene", scene = "apartment_kitchen_morning" },
                visible_when = function(gs)
                    return gs.get_flag("washed_up")
                end,
            },
            {
                id = "exit_apartment_morning",
                rect = { x = 525, y = 185, w = 260, h = 430 },
                label = "Выйти",
                icon = "",
                action = { type = "ink_knot", knot = "leave_apartment" },
                condition = function(gs)
                    return gs.get_flag("has_phone") and gs.get_flag("coffee_drunk")
                end,
            },
            {
                id = "hall_mirror",
                rect = { x = 330, y = 230, w = 135, h = 280 },
                label = "Зеркало",
                icon = "",
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
                pos   = { x = 620, y = 260 },
                size  = { w = 52, h = 22 },
                visible_when = function(gs)
                    return gs.get_flag("morning_ritual_done") and not gs.get_flag("has_phone")
                end,
            },
        },
        hotspots = {
            {
                id = "phone_on_bedside",
                rect = { x = 565, y = 230, w = 180, h = 135 },
                label = "Телефон",
                icon = "phone",
                circle_color = { r = 0.03, g = 0.10, b = 0.18 },
                ring_color = { r = 0.40, g = 0.90, b = 1.00 },
                icon_color = { r = 0.85, g = 0.98, b = 1.00 },
                action = { type = "ink_knot", knot = "take_phone" },
                visible_when = function(gs)
                    return gs.get_flag("morning_ritual_done") and not gs.get_flag("has_phone")
                end,
            },
            {
                id = "bedroom_desk",
                rect = { x = 720, y = 210, w = 165, h = 225 },
                label = "Рабочий стол",
                icon = "",
                action = { type = "ink_knot", knot = "bedroom_desk_morning" },
                visible_when = function(gs)
                    return gs.get_flag("got_out_of_bed")
                end,
            },
            {
                id = "bedroom_bed",
                rect = { x = 225, y = 115, w = 435, h = 200 },
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
                    return not gs.get_flag("got_out_of_bed")
                end,
            },
            {
                id = "bathroom_door_locked",
                rect = { x = 920, y = 145, w = 125, h = 480 },
                label = "Умыться",
                icon = "",
                action = { type = "ink_knot", knot = "wash_up_morning" },
                visible_when = function(gs)
                    return gs.get_flag("got_out_of_bed") and not gs.get_flag("washed_up")
                end,
            },
            {
                id = "back_to_hall_from_bedroom",
                rect = { x = 1035, y = 70, w = 170, h = 220 },
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
                id = "coffee_setup_empty",
                rect = { x = 545, y = 255, w = 290, h = 260 },
                label = "Кофе",
                icon = "coffee",
                circle_color = { r = 0.18, g = 0.10, b = 0.04 },
                ring_color = { r = 1.00, g = 0.68, b = 0.28 },
                icon_color = { r = 1.00, g = 0.90, b = 0.68 },
                action = { type = "ink_knot", knot = "use_coffee_machine_no_cup" },
                visible_when = function(gs)
                    return not gs.get_flag("has_mug") and not gs.get_flag("coffee_drunk")
                end,
            },
            {
                id = "coffee_setup_brew",
                rect = { x = 545, y = 255, w = 290, h = 260 },
                label = "Сварить кофе",
                icon = "coffee",
                circle_color = { r = 0.18, g = 0.10, b = 0.04 },
                ring_color = { r = 1.00, g = 0.68, b = 0.28 },
                icon_color = { r = 1.00, g = 0.90, b = 0.68 },
                hotspot_scale = 1.08,
                action = { type = "ink_knot", knot = "use_coffee_machine_with_cup" },
                visible_when = function(gs)
                    return gs.get_flag("has_mug") and not gs.get_flag("coffee_drunk")
                end,
            },
            {
                id = "take_mug_kitchen",
                rect = { x = 830, y = 115, w = 260, h = 230 },
                label = "Кружка",
                icon = "mug",
                circle_color = { r = 0.16, g = 0.12, b = 0.08 },
                ring_color = { r = 0.95, g = 0.80, b = 0.50 },
                icon_color = { r = 1.00, g = 0.92, b = 0.74 },
                action = { type = "ink_knot", knot = "take_mug" },
                visible_when = function(gs)
                    return not gs.get_flag("has_mug")
                end,
            },
            {
                id = "kitchen_window",
                rect = { x = 950, y = 340, w = 285, h = 290 },
                label = "Окно",
                icon = "",
                action = { type = "ink_knot", knot = "look_kitchen_window" },
            },
            {
                id = "back_to_hall_from_kitchen",
                rect = { x = 0, y = 95, w = 235, h = 515 },
                label = "В коридор",
                icon = "arrow_back",
                action = { type = "goto_scene", scene = "apartment_hall_morning" },
            },
        },
    },

    -- =====================================================================
    -- LEGACY: старые сцены квартиры оставлены для безопасного отката/сверки.
    -- Новый основной маршрут использует apartment_*_morning выше.
    -- =====================================================================

    apartment_hub_legacy = {
        bg = "bg_apartment",
        hotspots = {
            {
                id = "to_kitchen",
                rect = { x = 95, y = 0, w = 225, h = 680 },
                label = "На кухню",
                icon = "arrow_back",
                action = { type = "goto_scene", scene = "kitchen_legacy" },
            },
            {
                id = "to_bathroom",
                rect = { x = 805, y = 145, w = 135, h = 370 },
                label = "В ванную",
                icon = "arrow_forward",
                action = { type = "goto_scene", scene = "bathroom_legacy" },
            },
            {
                id = "to_bedroom_day",
                rect = { x = 1055, y = 75, w = 130, h = 515 },
                label = "В спальню",
                icon = "arrow_forward",
                action = { type = "goto_scene", scene = "bedroom_day_legacy" },
            },
            {
                id = "leave_home",
                rect = { x = 550, y = 160, w = 175, h = 365 },
                label = "Выйти",
                icon = "arrow_up",
                action = { type = "ink_knot", knot = "leave_apartment" },
                condition = function(gs)
                    return gs.get_flag("has_phone") and gs.get_flag("coffee_drunk")
                end,
            },
        },
    },

    kitchen_legacy = {
        bg = "bg_kitchen",
        -- Автотриггер knot при входе. condition проверяет флаг first-visit.
        on_enter = {
            knot = "enter_kitchen",
            condition = function(gs) return not gs.get_flag("kitchen_intro_seen") end,
        },
        hotspots = {
            -- Кофемашина без кружки — первый клик, подскажет искать кружку.
            {
                id = "coffee_maker_empty",
                rect = { x = 290, y = 405, w = 160, h = 155 },
                label = "Кофемашина",
                -- U+E541 coffee_maker
                icon = "coffee",
                action = { type = "ink_knot", knot = "use_coffee_machine_no_cup" },
                visible_when = function(gs)
                    return not gs.get_flag("has_mug") and not gs.get_flag("coffee_drunk")
                end,
            },
            -- Та же кофемашина, с кружкой — варим кофе.
            {
                id = "coffee_maker_brew",
                rect = { x = 280, y = 275, w = 160, h = 155 },
                label = "Сварить кофе",
                icon = "coffee",
                action = { type = "ink_knot", knot = "use_coffee_machine_with_cup" },
                visible_when = function(gs)
                    return gs.get_flag("has_mug") and not gs.get_flag("coffee_drunk")
                end,
            },
            -- Ящик с кружкой — виден пока кружку не взяли.
            {
                id = "mug_drawer",
                rect = { x = 695, y = 470, w = 160, h = 140 },
                label = "Ящик",
                -- U+E2C7 inventory
                icon = "note",
                action = { type = "ink_knot", knot = "take_mug" },
                visible_when = function(gs) return not gs.get_flag("has_mug") end,
            },
            {
                id = "back_from_kitchen",
                rect = { x = 95, y = 35, w = 140, h = 640 },
                label = "Назад",
                -- U+E5C4 arrow_back
                icon = "arrow_back",
                action = { type = "goto_scene", scene = "apartment_hub_legacy" },
            },
        },
    },

    bathroom_legacy = {
        bg = "bg_bathroom",
        on_enter = {
            knot = "inspect_bathroom",
            condition = function(gs) return not gs.get_flag("bathroom_seen") end,
        },
        hotspots = {
            {
                id = "back_from_bathroom",
                rect = { x = 30, y = 30, w = 140, h = 80 },
                label = "Назад",
                icon = "arrow_back",
                action = { type = "goto_scene", scene = "apartment_hub_legacy" },
            },
        },
    },

    bedroom_day_legacy = {
        bg = "bg_bedroom_03",
        on_enter = {
            knot = "spot_phone_after_coffee",
            condition = function(gs)
                return gs.get_flag("coffee_drunk")
                    and not gs.get_flag("has_phone")
                    and not gs.get_flag("spot_phone_after_coffee_seen")
            end,
        },
        objects = {
            {
                id    = "phone_obj",
                image = "mobile",           -- имя в main/images/scene_objects.atlas
                pos   = { x = 575, y = 290 }, -- левый-нижний угол спрайта
                size  = { w = 52, h = 22 },
                -- Телефон "материализуется" только после кофе.
                visible_when = function(gs)
                    return gs.get_flag("coffee_drunk") and not gs.get_flag("has_phone")
                end,
            },
        },
        hotspots = {
            {
                id = "look_at_monitor",
                rect = { x = 895, y = 355, w = 280, h = 215 },
                label = "Монитор",
                icon = "phone",
                action = { type = "ink_knot", knot = "bedroom_monitor" },
            },
            {
                id = "phone_on_desk",
                rect = { x = 510, y = 300, w = 180, h = 160 },
                label = "Телефон",
                icon = "phone",
                action = { type = "ink_knot", knot = "take_phone" },
                -- Не видим пока кофе не выпит (phone_obj тоже скрыт).
                visible_when = function(gs)
                    return gs.get_flag("coffee_drunk") and not gs.get_flag("has_phone")
                end,
            },
            {
                id = "back_from_bedroom",
                rect = { x = 1100, y = 0, w = 175, h = 235 },
                label = "Назад",
                icon = "arrow_back",
                action = { type = "goto_scene", scene = "apartment_hub_legacy" },
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
        bg = "bg_office",        -- заменить на bg_work когда будет фон
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
        bg = "bg_office",        -- заменить на bg_cafe
        hotspots = {
            {
                id = "cafe_bar",
                rect = { x = 400, y = 200, w = 400, h = 250 },
                label = "Стойка",
                icon = "",
                action = { type = "ink_knot", knot = "cafe_bar_interact" },
            },
            {
                id = "leave_cafe",
                rect = { x = 0, y = 0, w = 150, h = 200 },
                label = "Выйти",
                icon = "",
                action = { type = "ink_knot", knot = "leave_cafe" },
            },
        },
    },

    park_hub = {
        bg = "bg_rooftop",       -- заменить на bg_park
        hotspots = {
            {
                id = "park_bench",
                rect = { x = 450, y = 150, w = 300, h = 200 },
                label = "Скамейка",
                icon = "",
                action = { type = "ink_knot", knot = "park_bench_interact" },
            },
            {
                id = "leave_park",
                rect = { x = 0, y = 0, w = 150, h = 200 },
                label = "Уйти",
                icon = "",
                action = { type = "ink_knot", knot = "leave_park" },
            },
        },
    },

    shop_hub = {
        bg = "bg_office",        -- заменить на bg_shop
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
        bg = "bg_office",        -- заменить на bg_bar
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
        bg = "bg_rooftop",       -- заменить на bg_viewpoint
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
        bg = "bg_office",        -- заменить на bg_archive
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
