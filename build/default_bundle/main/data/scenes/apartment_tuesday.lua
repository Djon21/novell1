-- main/data/scenes/apartment_tuesday.lua
-- Сцены AVOS — раздел: apartment_tuesday. См. _shared.lua для recipes.
--
-- Отдельные scene_id на тех же фонах. Вторник не переиспользует
-- воскресные/понедельничные флаги, чтобы порядок действий не ломался.

local s = require "main.data.scenes._shared"

local function tuesday_ready_to_leave(gs)
    return gs.has_item("phone")
       and gs.has_item("card")
       and gs.get_flag("tuesday_phone_checked")
       and gs.get_flag("tuesday_washed_up")
       and gs.get_flag("tuesday_ready_to_leave")
end

return {

    tuesday_apartment_bedroom_morning = {
        bg = "bg_apartment_bedroom_day",
        label = "Спальня",
        on_enter = {
            knot = "tue_home_bedroom_intro",
            condition = function(gs)
                return not gs.get_flag("tue_home_bedroom_seen")
            end,
        },
        hotspots = {
            s.inspect{
                id = "tue_bed",
                rect = { x = 460, y = 200, w = 135, h = 135 },
                label = "Кровать",
                knot = "tue_home_bed",
            },
            s.use{
                id = "tue_phone_check",
                rect = { x = 125, y = 205, w = 135, h = 135 },
                label = "Телефон",
                icon = "phone",
                knot = "tue_home_check_phone",
                icon_offset_x = 0,
                visible_when = function(gs)
                    return not gs.get_flag("tuesday_phone_checked")
                end,
            },
            s.inspect{
                id = "tue_bedroom_desk",
                rect = { x = 710, y = 335, w = 135, h = 135 },
                label = "Рабочий стол",
                knot = "tue_home_bedroom_desk",
            },
            s.use{
                id = "tue_bathroom_wash",
                rect = { x = 920, y = 145, w = 125, h = 480 },
                label = "Умыться",
                knot = "tue_home_wash_up",
                visible_when = function(gs)
                    return not gs.get_flag("tuesday_washed_up")
                end,
            },
            s.nav_scene{
                id = "tue_to_hall_from_bedroom",
                rect = { x = 1035, y = 70, w = 190, h = 260 },
                label = "В коридор",
                icon = "down",
                scene = "tuesday_apartment_hall_morning",
            },
        },
    },

    tuesday_apartment_hall_morning = {
        bg = "bg_apartment_hall_day",
        label = "Коридор",
        on_enter = {
            knot = "tue_home_hall_intro",
            condition = function(gs)
                return not gs.get_flag("tue_home_hall_seen")
            end,
        },
        hotspots = {
            s.nav_scene{
                id = "tue_to_bedroom",
                rect = { x = 110, y = 90, w = 175, h = 500 },
                label = "В спальню",
                icon = "left",
                scene = "tuesday_apartment_bedroom_morning",
            },
            s.nav_scene{
                id = "tue_to_kitchen",
                rect = { x = 990, y = 90, w = 175, h = 500 },
                label = "На кухню",
                icon = "right",
                scene = "tuesday_apartment_kitchen_morning",
            },
            s.inspect{
                id = "tue_hall_mirror",
                rect = { x = 360, y = 410, w = 135, h = 135 },
                label = "Зеркало",
                knot = "tue_home_hall_mirror",
            },
            s.use{
                id = "tue_get_ready",
                rect = { x = 800, y = 155, w = 115, h = 250 },
                label = "Обувь и куртка",
                knot = "tue_home_get_ready",
                visible_when = function(gs)
                    return not gs.get_flag("tuesday_ready_to_leave")
                end,
            },
            s.story{
                id = "tue_exit_apartment_locked",
                rect = { x = 575, y = 215, w = 155, h = 345 },
                label = "Выйти",
                icon = "up",
                knot = "tue_home_leave_apartment_locked",
                visible_when = function(gs)
                    return not tuesday_ready_to_leave(gs)
                end,
            },
            s.nav_ink{
                id = "tue_exit_apartment",
                rect = { x = 575, y = 215, w = 155, h = 345 },
                label = "Выйти",
                icon = "up",
                knot = "tue_home_leave_apartment",
                -- has_item("key") убран: key-pickup в локациях нет (item
                -- был выпилен ранее). Если ключи вернутся — снова добавить
                -- gs.has_item("key") сюда И в apartment_monday.lua.
                visible_when = tuesday_ready_to_leave,
            },
        },
    },

    tuesday_apartment_kitchen_morning = {
        bg = "bg_apartment_kitchen_day",
        label = "Кухня",
        on_enter = {
            knot = "tue_home_kitchen_intro",
            condition = function(gs)
                return not gs.get_flag("tue_home_kitchen_seen")
            end,
        },
        hotspots = {
            s.use{
                id = "tue_kitchen_coffee",
                rect = { x = 280, y = 270, w = 135, h = 135 },
                label = "Кофе",
                icon = "coffee",
                knot = "tue_home_kitchen_coffee",
                visible_when = function(gs)
                    return not gs.get_flag("tuesday_coffee_done")
                end,
            },
            s.inspect{
                id = "tue_kitchen_coffee_after",
                rect = { x = 280, y = 270, w = 135, h = 135 },
                label = "Кружка",
                icon = "coffee",
                knot = "tue_home_kitchen_coffee_after",
                visible_when = function(gs)
                    return gs.get_flag("tuesday_coffee_done")
                end,
            },
            s.use{
                id = "tue_kitchen_water",
                rect = { x = 835, y = 210, w = 135, h = 135 },
                label = "Вода",
                knot = "tue_home_kitchen_water",
                visible_when = function(gs)
                    return not gs.get_flag("tuesday_water_drunk")
                end,
            },
            s.inspect{
                id = "tue_kitchen_window",
                rect = { x = 455, y = 360, w = 155, h = 215 },
                label = "Окно",
                knot = "tue_home_kitchen_window",
            },
            s.nav_scene{
                id = "tue_back_to_hall_from_kitchen",
                rect = { x = 25, y = 95, w = 205, h = 520 },
                label = "В коридор",
                icon = "left",
                scene = "tuesday_apartment_hall_morning",
            },
        },
    },
}
