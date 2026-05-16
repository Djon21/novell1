-- main/data/scenes/shop.lua
-- Сцены AVOS — раздел: shop.
-- См. main/data/scenes/_shared.lua для STYLE_* и helper'ов.

local s = require "main.data.scenes._shared"
local STYLE_NAV         = s.STYLE_NAV
local STYLE_INSPECT     = s.STYLE_INSPECT
local STYLE_PICKUP      = s.STYLE_PICKUP
local STYLE_USE         = s.STYLE_USE
local STYLE_ITEM_TARGET = s.STYLE_ITEM_TARGET
local STYLE_STORY       = s.STYLE_STORY

return {


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
                rect = { x = 930, y = 365, w = 135, h = 135 },
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
                rect = { x = 705, y = 245, w = 135, h = 135 },
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
                rect = { x = 160, y = 405, w = 135, h = 135 },
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

}
