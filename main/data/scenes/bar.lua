-- main/data/scenes/bar.lua
-- Сцены AVOS — раздел: bar.
-- См. main/data/scenes/_shared.lua для STYLE_* и helper'ов.

local s = require "main.data.scenes._shared"
local STYLE_NAV         = s.STYLE_NAV
local STYLE_INSPECT     = s.STYLE_INSPECT
local STYLE_PICKUP      = s.STYLE_PICKUP
local STYLE_USE         = s.STYLE_USE
local STYLE_ITEM_TARGET = s.STYLE_ITEM_TARGET
local STYLE_STORY       = s.STYLE_STORY

return {


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

}
