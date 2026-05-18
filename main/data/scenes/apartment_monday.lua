-- main/data/scenes/apartment_monday.lua
-- Сцены AVOS — раздел: apartment_monday. См. _shared.lua для recipes.
--
-- Важно: это отдельные scene_id, хотя фоны те же, что в воскресенье.
-- Так воскресные флаги (date_agreed, coffee_drunk, left_apartment)
-- не смешиваются с рабочим понедельничным маршрутом.

local s = require "main.data.scenes._shared"

local function monday_ready_to_leave(gs)
    return gs.has_item("card")
       and gs.get_flag("monday_washed_up")
       and gs.get_flag("monday_dressed")
       and gs.get_flag("monday_breakfast_done")
end

return {

    monday_apartment_bedroom_morning = {
        bg = "bg_apartment_bedroom_day",
        label = "Спальня",
        on_enter = {
            knot = "mon_home_bedroom_intro",
            condition = function(gs)
                return not gs.get_flag("mon_home_bedroom_seen")
            end,
        },
        hotspots = {
            s.inspect{
                id = "mon_bed",
                rect = { x = 425, y = 150, w = 135, h = 135 },
                label = "Кровать",
                knot = "mon_home_bed",
            },
            s.inspect{
                id = "mon_bedroom_desk",
                rect = { x = 710, y = 335, w = 135, h = 135 },
                label = "Рабочий стол",
                knot = "mon_home_bedroom_desk",
            },
            s.use{
                id = "mon_bathroom_wash",
                rect = { x = 920, y = 145, w = 125, h = 480 },
                label = "Умыться",
                knot = "mon_home_wash_up",
                visible_when = function(gs)
                    return not gs.get_flag("monday_washed_up")
                end,
            },
            s.nav_scene{
                id = "mon_to_hall_from_bedroom",
                rect = { x = 1035, y = 70, w = 190, h = 260 },
                label = "В коридор",
                icon = "down",
                scene = "monday_apartment_hall_morning",
            },
        },
    },

    monday_apartment_hall_morning = {
        bg = "bg_apartment_hall_day",
        label = "Коридор",
        on_enter = {
            knot = "mon_home_hall_intro",
            condition = function(gs)
                return not gs.get_flag("mon_home_hall_seen")
            end,
        },
        hotspots = {
            s.nav_scene{
                id = "mon_to_bedroom",
                rect = { x = 110, y = 90, w = 175, h = 500 },
                label = "В спальню",
                icon = "left",
                scene = "monday_apartment_bedroom_morning",
            },
            s.nav_scene{
                id = "mon_to_kitchen",
                rect = { x = 990, y = 90, w = 175, h = 500 },
                label = "На кухню",
                icon = "right",
                scene = "monday_apartment_kitchen_morning",
            },
            s.inspect{
                id = "mon_hall_mirror",
                rect = { x = 360, y = 410, w = 135, h = 135 },
                label = "Зеркало",
                knot = "mon_home_hall_mirror",
            },
            s.pickup{
                id = "mon_work_card",
                rect = { x = 395, y = 165, w = 135, h = 135 },
                label = "Пропуск",
                icon = "note",
                knot = "mon_home_take_work_card",
                visible_when = function(gs)
                    return not gs.has_item("card")
                end,
            },
            s.use{
                id = "mon_get_dressed",
                rect = { x = 805, y = 135, w = 105, h = 305 },
                label = "Обувь и куртка",
                knot = "mon_home_get_dressed",
                visible_when = function(gs)
                    return not gs.get_flag("monday_dressed")
                end,
            },
            s.story{
                id = "mon_exit_apartment_locked",
                rect = { x = 575, y = 215, w = 155, h = 345 },
                label = "Выйти",
                icon = "up",
                knot = "mon_home_leave_apartment_locked",
                visible_when = function(gs)
                    return not monday_ready_to_leave(gs)
                end,
            },
            s.nav_ink{
                id = "mon_exit_apartment",
                rect = { x = 575, y = 215, w = 155, h = 345 },
                label = "Выйти",
                icon = "up",
                knot = "mon_home_leave_apartment",
                -- has_item("phone") не нужен: телефон после воскресного утра
                -- постоянный предмет игрока и не должен быть условием выхода.
                -- has_item("key") убран: key-pickup в локациях нет (item
                -- был выпилен ранее). Если ключи вернутся как item — снова
                -- добавить gs.has_item("key") сюда И в apartment_tuesday.lua.
                visible_when = monday_ready_to_leave,
            },
        },
    },

    monday_apartment_kitchen_morning = {
        bg = "bg_apartment_kitchen_day",
        label = "Кухня",
        on_enter = {
            knot = "mon_home_kitchen_intro",
            condition = function(gs)
                return not gs.get_flag("mon_home_kitchen_seen")
            end,
        },
        hotspots = {
            s.use{
                id = "mon_kitchen_coffee",
                rect = { x = 280, y = 270, w = 135, h = 135 },
                label = "Кофе",
                icon = "coffee",
                knot = "mon_home_kitchen_coffee",
                visible_when = function(gs)
                    return not gs.get_flag("monday_coffee_done")
                end,
            },
            s.inspect{
                id = "mon_kitchen_coffee_after",
                rect = { x = 280, y = 270, w = 135, h = 135 },
                label = "Кружка",
                icon = "coffee",
                knot = "mon_home_kitchen_coffee_after",
                visible_when = function(gs)
                    return gs.get_flag("monday_coffee_done")
                end,
            },
            s.use{
                id = "mon_kitchen_breakfast",
                rect = { x = 625, y = 205, w = 190, h = 135 },
                label = "Завтрак",
                knot = "mon_home_kitchen_breakfast",
                visible_when = function(gs)
                    return not gs.get_flag("monday_breakfast_done")
                end,
            },
            s.inspect{
                id = "mon_kitchen_breakfast_after",
                rect = { x = 625, y = 205, w = 190, h = 135 },
                label = "Стол",
                knot = "mon_home_kitchen_breakfast_after",
                visible_when = function(gs)
                    return gs.get_flag("monday_breakfast_done")
                end,
            },
            s.inspect{
                id = "mon_kitchen_window",
                rect = { x = 455, y = 360, w = 155, h = 215 },
                label = "Окно",
                knot = "mon_home_kitchen_window",
            },
            s.nav_scene{
                id = "mon_back_to_hall_from_kitchen",
                rect = { x = 25, y = 95, w = 205, h = 520 },
                label = "В коридор",
                icon = "left",
                scene = "monday_apartment_hall_morning",
            },
        },
    },
}
