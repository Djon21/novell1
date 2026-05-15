-- main/data/scenes/apartment.lua
-- Сцены AVOS — раздел: apartment.
-- См. main/data/scenes/_shared.lua для STYLE_* и helper'ов.

local s = require "main.data.scenes._shared"
local STYLE_NAV         = s.STYLE_NAV
local STYLE_INSPECT     = s.STYLE_INSPECT
local STYLE_PICKUP      = s.STYLE_PICKUP
local STYLE_USE         = s.STYLE_USE
local STYLE_ITEM_TARGET = s.STYLE_ITEM_TARGET
local STYLE_STORY       = s.STYLE_STORY
local STYLE_NEUTRAL     = s.STYLE_NEUTRAL
local apartment_bg      = s.apartment_bg
local office_bg         = s.office_bg
local is_apartment_night = s.is_apartment_night
local is_office_night   = s.is_office_night
local is_sunday_apartment_night = s.is_sunday_apartment_night
local is_monday_apartment_night = s.is_monday_apartment_night

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
                action = { type = "ink_knot", knot = "leave_apartment_prompt" },
                visible_when = function(gs)
                    return not is_apartment_night(gs)
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
                       and gs.get_flag("date_agreed")
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
                label = "Встать",
                icon = "arrow_up",
                hotspot_style = STYLE_STORY,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "ink_knot", knot = "look_bed_morning" },
                visible_when = function(gs)
                    return not is_apartment_night(gs)
                       and gs.has_item("phone")
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
                id = "to_bathroom_from_bedroom",
                rect = { x = 920, y = 145, w = 125, h = 480 },
                label = "В ванную",
                icon = "arrow_forward",
                hotspot_style = STYLE_NAV,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "goto_scene", scene = "apartment_bathroom" },
                visible_when = function(gs)
                    return is_apartment_night(gs) or gs.get_flag("got_out_of_bed")
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
            {
                id = "bathroom_mirror",
                rect = { x = 1025, y = 465, w = 180, h = 105 },
                label = "Зеркало",
                icon = "left_click",
                hotspot_style = STYLE_INSPECT,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "ink_knot", knot = "look_bathroom_mirror" },
            },
            {
                id = "bathroom_toothbrush",
                rect = { x = 870, y = 300, w = 105, h = 105 },
                label = "Щётка",
                icon = "left_click",
                hotspot_style = STYLE_PICKUP,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "ink_knot", knot = "take_toothbrush" },
                visible_when = function(gs)
                    return not gs.get_flag("teeth_brushed")
                       and not gs.has_item("toothbrush")
                       and not gs.has_item("toothbrush_pasted")
                end,
            },
            {
                id = "bathroom_toothpaste",
                rect = { x = 1115, y = 290, w = 105, h = 105 },
                label = "Паста",
                icon = "left_click",
                hotspot_style = STYLE_PICKUP,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "ink_knot", knot = "take_toothpaste" },
                visible_when = function(gs)
                    return not gs.get_flag("teeth_brushed")
                       and not gs.has_item("toothpaste")
                       and not gs.has_item("toothbrush_pasted")
                end,
            },
            {
                id = "bathroom_sink",
                rect = { x = 985, y = 175, w = 105, h = 105 },
                label = "Раковина",
                icon = "left_click",
                hotspot_style = STYLE_ITEM_TARGET,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "ink_knot", knot = "bathroom_sink_prompt" },
                visible_when = function(gs)
                    return not gs.get_flag("washed_up")
                end,
            },
            {
                id = "bathroom_exit_locked",
                rect = { x = 85, y = 70, w = 180, h = 560 },
                label = "В спальню",
                icon = "arrow_back",
                hotspot_style = STYLE_STORY,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "ink_knot", knot = "bathroom_exit_locked" },
                visible_when = function(gs)
                    return not is_apartment_night(gs)
                       and not gs.get_flag("washed_up")
                end,
            },
            {
                id = "back_to_bedroom_from_bathroom",
                rect = { x = 85, y = 70, w = 180, h = 560 },
                label = "В спальню",
                icon = "arrow_back",
                hotspot_style = STYLE_NAV,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "goto_scene", scene = "apartment_bedroom" },
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
            {
                id = "coffee_setup",
                rect = { x = 280, y = 395, w = 135, h = 135 },
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
                rect = { x = 980, y = 95, w = 135, h = 135 },
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
                rect = { x = 1120, y = 230, w = 135, h = 135 },
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
                rect = { x = 845, y = 375, w = 125, h = 125 },
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
}
