-- main/data/scenes/apartment.lua
-- Сцены AVOS — раздел: apartment (воскресная база).
-- См. _shared.lua для recipes.

local s = require "main.data.scenes._shared"
local apartment_bg              = s.apartment_bg
local is_apartment_night        = s.is_apartment_night
local is_sunday_apartment_night = s.is_sunday_apartment_night

return {

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
            s.nav_scene{
                id = "to_bedroom",
                rect = { x = 110, y = 90, w = 175, h = 500 },
                label = "В спальню",
                icon = "left",
                scene = "apartment_bedroom",
            },
            s.nav_scene{
                id = "to_kitchen",
                rect = { x = 990, y = 90, w = 175, h = 500 },
                label = "На кухню",
                icon = "right",
                scene = "apartment_kitchen",
                visible_when = function(gs)
                    return is_apartment_night(gs) or gs.get_flag("washed_up")
                end,
            },
            s.nav_ink{
                id = "exit_apartment",
                rect = { x = 575, y = 215, w = 155, h = 345 },
                label = "Выйти",
                icon = "up",
                knot = "leave_apartment_prompt",
                visible_when = function(gs)
                    return not is_apartment_night(gs)
                end,
            },
            s.inspect{
                id = "hall_mirror",
                rect = { x = 360, y = 410, w = 135, h = 135 },
                label = "Зеркало",
                knot = "look_hall_mirror",
            },
            s.use{
                id = "hall_jacket_shoes",
                rect = { x = 805, y = 135, w = 135, h = 305 },
                label = "Куртка и обувь",
                knot = "sunday_get_dressed",
                visible_when = function(gs)
                    return not is_apartment_night(gs)
                       and (gs.get_flag("date_agreed")
                            or gs.get_flag("loop2_first_invite_rejected")
                            or (gs.get_flag("loop2_fake_wednesday_started")
                                and not gs.get_flag("loop2_work_check_done")))
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
            s.pickup{
                id = "phone_on_bedside",
                rect = { x = 130, y = 215, w = 135, h = 135 },
                label = "Телефон",
                icon = "phone",
                knot = "take_phone",
                icon_offset_x = 0,  -- phone glyph центрируется штатно
                visible_when = function(gs)
                    return not is_apartment_night(gs)
                       and not gs.has_item("phone")
                end,
            },
            s.inspect{
                id = "bedroom_desk",
                rect = { x = 710, y = 335, w = 135, h = 135 },
                label = "Рабочий стол",
                knot = "bedroom_desk_morning",
                visible_when = function(gs)
                    return not is_apartment_night(gs)
                       and gs.get_flag("got_out_of_bed")
                end,
            },
            s.story{
                id = "bedroom_bed",
                rect = { x = 425, y = 150, w = 135, h = 135 },
                label = "Встать",
                icon = "up",
                knot = "look_bed_morning",
                visible_when = function(gs)
                    return not is_apartment_night(gs)
                       and gs.has_item("phone")
                       and not gs.get_flag("got_out_of_bed")
                end,
            },
            s.story{
                id = "bedroom_bed_sleep_sunday",
                rect = { x = 425, y = 150, w = 135, h = 135 },
                label = "Лечь спать",
                knot = "sunday_sleep_in_bed",
                visible_when = is_sunday_apartment_night,
            },
            s.nav_scene{
                id = "to_bathroom_from_bedroom",
                rect = { x = 920, y = 145, w = 125, h = 480 },
                label = "В ванную",
                icon = "right",
                scene = "apartment_bathroom",
                visible_when = function(gs)
                    return is_apartment_night(gs) or gs.get_flag("got_out_of_bed")
                end,
            },
            s.inspect{
                id = "bedroom_window",
                rect = { x = 540, y = 330, w = 135, h = 190 },
                label = "Окно",
                knot = "look_bedroom_window",
                visible_when = function(gs)
                    return not is_apartment_night(gs)
                       and gs.get_flag("got_out_of_bed")
                       and not gs.get_flag("sunday_bedroom_window_seen")
                end,
            },
            s.nav_scene{
                id = "back_to_hall_from_bedroom",
                rect = { x = 1035, y = 70, w = 190, h = 260 },
                label = "В коридор",
                icon = "down",
                scene = "apartment_hub",
                visible_when = function(gs)
                    return is_apartment_night(gs) or gs.get_flag("washed_up")
                end,
            },
        },
    },

    apartment_bathroom = {
        bg = apartment_bg("bathroom"),
        label = "Ванная",
        on_enter = {
            knot = "enter_bathroom_morning_first",
            condition = function(gs)
                return not is_apartment_night(gs)
                   and not gs.get_flag("bathroom_morning_seen")
            end,
        },
        hotspots = {
            s.inspect{
                id = "bathroom_mirror",
                rect = { x = 1025, y = 465, w = 180, h = 105 },
                label = "Зеркало",
                knot = "look_bathroom_mirror",
            },
            s.pickup{
                id = "bathroom_toothbrush",
                rect = { x = 870, y = 300, w = 105, h = 105 },
                label = "Щётка",
                knot = "take_toothbrush",
                visible_when = function(gs)
                    return not is_apartment_night(gs)
                       and not gs.get_flag("teeth_brushed")
                       and not gs.has_item("toothbrush")
                       and not gs.has_item("toothbrush_pasted")
                end,
            },
            s.pickup{
                id = "bathroom_toothpaste",
                rect = { x = 1115, y = 290, w = 105, h = 105 },
                label = "Паста",
                knot = "take_toothpaste",
                visible_when = function(gs)
                    return not is_apartment_night(gs)
                       and not gs.get_flag("teeth_brushed")
                       and not gs.has_item("toothpaste")
                       and not gs.has_item("toothbrush_pasted")
                end,
            },
            s.item_target{
                id = "bathroom_sink",
                rect = { x = 985, y = 175, w = 105, h = 105 },
                label = "Раковина",
                knot = "bathroom_sink_prompt",
                visible_when = function(gs)
                    return not is_apartment_night(gs)
                       and not gs.get_flag("washed_up")
                end,
            },
            s.story{
                id = "bathroom_exit_locked",
                rect = { x = 85, y = 70, w = 180, h = 560 },
                label = "В спальню",
                icon = "left",
                knot = "bathroom_exit_locked",
                visible_when = function(gs)
                    return not is_apartment_night(gs)
                       and not gs.get_flag("washed_up")
                end,
            },
            s.nav_scene{
                id = "back_to_bedroom_from_bathroom",
                rect = { x = 85, y = 70, w = 180, h = 560 },
                label = "В спальню",
                icon = "left",
                scene = "apartment_bedroom",
                visible_when = function(gs)
                    return is_apartment_night(gs)
                        or gs.get_flag("washed_up")
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
            s.use{
                id = "coffee_setup",
                rect = { x = 280, y = 395, w = 135, h = 135 },
                label = "Кофе",
                icon = "coffee",
                knot = "use_coffee_setup_no_mug",
                visible_when = function(gs)
                    return not is_apartment_night(gs)
                       and not gs.get_flag("coffee_drunk")
                end,
            },
            s.pickup{
                id = "take_mug_kitchen",
                rect = { x = 980, y = 95, w = 135, h = 135 },
                label = "Кружка",
                icon = "mug",
                knot = "take_mug",
                visible_when = function(gs)
                    return not is_apartment_night(gs)
                       and not gs.has_item("mug")
                end,
            },
            s.pickup{
                id = "kitchen_apples",
                rect = { x = 1120, y = 230, w = 135, h = 135 },
                label = "Яблоко",
                knot = "take_kitchen_apple",
                visible_when = function(gs)
                    return not is_apartment_night(gs)
                       and not gs.get_flag("breakfast_done")
                end,
            },
            s.inspect{
                id = "kitchen_fridge",
                rect = { x = 845, y = 375, w = 125, h = 125 },
                label = "Холодильник",
                knot = "look_kitchen_fridge",
                visible_when = function(gs)
                    return not is_apartment_night(gs)
                       and not gs.get_flag("fridge_checked")
                end,
            },
            s.inspect{
                id = "kitchen_window",
                rect = { x = 455, y = 360, w = 155, h = 215 },
                label = "Окно",
                knot = "look_kitchen_window",
            },
            s.nav_scene{
                id = "back_to_hall_from_kitchen",
                rect = { x = 25, y = 95, w = 205, h = 520 },
                label = "В коридор",
                icon = "left",
                scene = "apartment_hub",
            },
        },
    },
}
