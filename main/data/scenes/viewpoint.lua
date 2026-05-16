-- main/data/scenes/viewpoint.lua
-- Сцены AVOS — раздел: viewpoint.
-- См. main/data/scenes/_shared.lua для STYLE_* и helper'ов.

local s = require "main.data.scenes._shared"
local STYLE_NAV         = s.STYLE_NAV
local STYLE_INSPECT     = s.STYLE_INSPECT
local STYLE_PICKUP      = s.STYLE_PICKUP
local STYLE_USE         = s.STYLE_USE
local STYLE_ITEM_TARGET = s.STYLE_ITEM_TARGET
local STYLE_STORY       = s.STYLE_STORY

return {


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

}
