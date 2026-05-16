-- main/data/scenes/cafe.lua
-- Сцены AVOS — раздел: cafe.
-- См. main/data/scenes/_shared.lua для STYLE_* и helper'ов.

local s = require "main.data.scenes._shared"
local STYLE_NAV         = s.STYLE_NAV
local STYLE_INSPECT     = s.STYLE_INSPECT
local STYLE_PICKUP      = s.STYLE_PICKUP
local STYLE_USE         = s.STYLE_USE
local STYLE_ITEM_TARGET = s.STYLE_ITEM_TARGET
local STYLE_STORY       = s.STYLE_STORY

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
                icon = "left",
                hotspot_style = STYLE_NAV,
                action = { type = "ink_knot", knot = "leave_cafe" },
            },
        },
    },

}
