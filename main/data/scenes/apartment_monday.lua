-- main/data/scenes/apartment_monday.lua
-- Сцены AVOS — раздел: apartment_monday.
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
                icon = "down",
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
                icon = "left",
                hotspot_style = STYLE_NAV,
                action = { type = "goto_scene", scene = "monday_apartment_bedroom_morning" },
            },
            {
                id = "mon_to_kitchen",
                rect = { x = 990, y = 90, w = 175, h = 500 },
                label = "На кухню",
                icon = "right",
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
                icon = "up",
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
                icon = "left",
                hotspot_style = STYLE_NAV,
                action = { type = "goto_scene", scene = "monday_apartment_hall_morning" },
            },
        },
    },
}
