-- main/data/scenes/archive.lua
-- Сцены AVOS — раздел: archive.
-- См. main/data/scenes/_shared.lua для STYLE_* и helper'ов.

local s = require "main.data.scenes._shared"
local STYLE_NAV         = s.STYLE_NAV
local STYLE_INSPECT     = s.STYLE_INSPECT
local STYLE_PICKUP      = s.STYLE_PICKUP
local STYLE_USE         = s.STYLE_USE
local STYLE_ITEM_TARGET = s.STYLE_ITEM_TARGET
local STYLE_STORY       = s.STYLE_STORY

return {


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
