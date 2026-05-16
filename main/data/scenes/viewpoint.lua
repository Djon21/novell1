-- main/data/scenes/viewpoint.lua
-- Сцены AVOS — раздел: viewpoint. См. _shared.lua для recipes.

local s = require "main.data.scenes._shared"

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
            s.inspect{
                id = "view_railing",
                rect = { x = 200, y = 200, w = 800, h = 150 },
                label = "Поручни",
                icon = "",
                knot = "view_railing_interact",
            },
            s.leave{
                id = "leave_view",
                rect = { x = 0, y = 0, w = 150, h = 200 },
                label = "Уйти",
                icon = "",
                knot = "leave_viewpoint",
            },
        },
    },

}
