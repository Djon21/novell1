-- main/data/scenes/locations.lua
-- Сцены AVOS — раздел: locations.
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
