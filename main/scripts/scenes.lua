-- scenes.lua
-- Каталог сцен point-and-click слоя. Данные, не код.
-- rect = { x, y, w, h } — x/y это ЛЕВЫЙ-НИЖНИЙ угол прямоугольника
-- в коорд. системе .gui (960×640, origin левый-нижний).
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

M.scenes = {
    apartment_hub = {
        bg = "bg_apartment",
        hotspots = {
            {
                id = "to_kitchen",
                rect = { x = 95, y = 0, w = 225, h = 680 },
                label = "На кухню",
                icon = "",
                action = { type = "goto_scene", scene = "kitchen" },
            },
            {
                id = "to_bathroom",
                rect = { x = 805, y = 145, w = 135, h = 370 },
                label = "В ванную",
                icon = "",
                action = { type = "goto_scene", scene = "bathroom" },
            },
            {
                id = "to_bedroom_day",
                rect = { x = 1055, y = 75, w = 130, h = 515 },
                label = "В спальню",
                icon = "",
                action = { type = "goto_scene", scene = "bedroom_day" },
            },
            {
                id = "leave_home",
                rect = { x = 550, y = 160, w = 175, h = 365 },
                label = "Выйти",
                icon = "",
                action = { type = "ink_knot", knot = "leave_apartment" },
                condition = function(gs)
                    return gs.get_flag("has_phone") and gs.get_flag("coffee_drunk")
                end,
            },
        },
    },

    kitchen = {
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
                icon = string.char(0xEE, 0x95, 0x81),
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
                icon = string.char(0xEE, 0x95, 0x81),
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
                icon = string.char(0xEE, 0x8B, 0x87),
                action = { type = "ink_knot", knot = "take_mug" },
                visible_when = function(gs) return not gs.get_flag("has_mug") end,
            },
            {
                id = "back_from_kitchen",
                rect = { x = 95, y = 35, w = 140, h = 640 },
                label = "Назад",
                -- U+E5C4 arrow_back
                icon = string.char(0xEE, 0x97, 0x84),
                action = { type = "goto_scene", scene = "apartment_hub" },
            },
        },
    },

    bathroom = {
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
                icon = string.char(0xEE, 0x97, 0x84),  -- U+E5C4 arrow_back
                action = { type = "goto_scene", scene = "apartment_hub" },
            },
        },
    },

    bedroom_day = {
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
                icon = "",
                action = { type = "ink_knot", knot = "bedroom_monitor" },
            },
            {
                id = "phone_on_desk",
                rect = { x = 510, y = 300, w = 180, h = 160 },
                label = "Телефон",
                icon = string.char(0xEE, 0xA4, 0x93),  -- U+E913 smartphone
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
                icon = "",
                action = { type = "goto_scene", scene = "apartment_hub" },
            },
        },
    },
}

function M.get(id) return M.scenes[id] end

return M
