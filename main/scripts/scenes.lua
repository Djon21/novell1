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
                rect = { x = 0, y = 0, w = 220, h = 640 },
                label = "На кухню",
                icon = "",
                action = { type = "goto_scene", scene = "kitchen" },
            },
            {
                id = "to_bathroom",
                rect = { x = 620, y = 115, w = 135, h = 370 },
                label = "В ванную",
                icon = "",
                action = { type = "goto_scene", scene = "bathroom" },
            },
            {
                id = "to_bedroom_day",
                rect = { x = 830, y = 75, w = 130, h = 515 },
                label = "В спальню",
                icon = "",
                action = { type = "goto_scene", scene = "bedroom_day" },
            },
            {
                id = "leave_home",
                rect = { x = 390, y = 130, w = 175, h = 365 },
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
                rect = { x = 155, y = 250, w = 160, h = 155 },
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
                rect = { x = 155, y = 250, w = 160, h = 155 },
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
                rect = { x = 420, y = 180, w = 160, h = 140 },
                label = "Ящик",
                -- U+E2C7 inventory
                icon = string.char(0xEE, 0x8B, 0x87),
                action = { type = "ink_knot", knot = "take_mug" },
                visible_when = function(gs) return not gs.get_flag("has_mug") end,
            },
            {
                id = "back_from_kitchen",
                rect = { x = 0, y = 0, w = 140, h = 640 },
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
            condition = function(gs) return not gs.get_flag("bathroom_intro_seen") end,
        },
        hotspots = {
            {
                id = "back_from_bathroom",
                rect = { x = 30, y = 30, w = 140, h = 80 },
                label = "Назад",
                icon = "",
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
                image = "mobile",           -- имя в backgrounds.atlas
                pos   = { x = 385, y = 260 }, -- левый-нижний угол спрайта
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
                rect = { x = 680, y = 300, w = 280, h = 215 },
                label = "Монитор",
                icon = "",
                action = { type = "ink_knot", knot = "bedroom_monitor" },
            },
            {
                id = "phone_on_desk",
                rect = { x = 400, y = 300, w = 180, h = 160 },
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
                rect = { x = 785, y = 0, w = 175, h = 235 },
                label = "Назад",
                icon = "",
                action = { type = "goto_scene", scene = "apartment_hub" },
            },
        },
    },

    -- Главный экран телефона. Это обычная point-and-click сцена поверх
    -- bg_phone.jpg (960×640, имитирует корпус смартфона).
    -- Вход: S.ui.open_phone_ui → scene_controller.enter("phone_home"),
    -- предварительно сохранив текущую сцену в gs-флаг _phone_return_scene.
    -- Выход: hotspot "phone_close" → ink knot phone_close → тег # phone:close.
    -- Координаты «экрана» (см. tools/gen_bg_phone.py):
    --   GUI x: [80..880], GUI y: [60..580]  (origin левый-нижний).
    phone_home = {
        bg = "bg_phone",
        -- Сетка 4x2 приложений (под bg_phone v2). Центры ячеек (gui origin BL):
        --   row 1: y=400, x=[160,360,560,760]   — SMS/Звонки/Карта/Улики
        --   row 2: y=240, x=[160,360,560,760]   — День/Почта/Камера/Терминал
        -- 4 основных (SMS/tasks/notes/contacts) ведут в ink-knot'ы как и раньше,
        -- 4 новых (Звонки/Карта/Камера/Терминал) — ink_knot "phone_stub_soon".
        hotspots = {
            -- Закрыть — ПЕРВЫЙ в списке, чтобы точно попасть в лимит 6 hotspot'ов
            {
                id = "phone_close",
                rect = { x = 360, y = 80, w = 240, h = 100 },
                label = "Закрыть",
                icon = string.char(0xEE, 0x97, 0x8D),  -- U+E5CD close
                action = { type = "phone_close" },
            },
            -- row 1
            {
                id = "phone_app_sms",
                rect = { x = 160 - 70, y = 400 - 70, w = 140, h = 140 },
                label = "SMS",
                icon = string.char(0xEE, 0x82, 0xB7),  -- U+E0B7 chat
                action = { type = "ink_knot", knot = "phone_sms" },
            },
            {
                id = "phone_app_call",
                rect = { x = 360 - 70, y = 400 - 70, w = 140, h = 140 },
                label = "Звонки",
                icon = string.char(0xEE, 0x83, 0x8D),  -- U+E0CD call
                action = { type = "ink_knot", knot = "phone_stub_soon" },
            },
            {
                id = "phone_app_map",
                rect = { x = 560 - 70, y = 400 - 70, w = 140, h = 140 },
                label = "Карта",
                icon = string.char(0xEE, 0x95, 0x9B),  -- U+E55B map
                action = { type = "ink_knot", knot = "phone_stub_soon" },
            },
            {
                id = "phone_app_notes",
                rect = { x = 760 - 70, y = 400 - 70, w = 140, h = 140 },
                label = "Улики",
                icon = string.char(0xEE, 0xA1, 0xB3),  -- U+E873 description
                action = { type = "ink_knot", knot = "phone_notes" },
            },
            -- row 2
            {
                id = "phone_app_tasks",
                rect = { x = 160 - 70, y = 240 - 70, w = 140, h = 140 },
                label = "День",
                icon = string.char(0xEE, 0xA1, 0x9D),  -- U+E85D assignment
                action = { type = "ink_knot", knot = "phone_tasks" },
            },
            -- ВНИМАНИЕ: Контакты, Камера и Терминал НЕ ВЛЕЗАЮТ в лимит 6 hotspot'ов!
            -- Они будут скрыты. Нужно либо увеличить GUI-ноды, либо убрать эти приложения.
        },
    },
}

function M.get(id) return M.scenes[id] end

return M
