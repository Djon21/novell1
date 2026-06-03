-- main/data/scenes/bar.lua
-- Сцены AVOS — раздел: bar.
-- См. main/data/scenes/_shared.lua для recipes (s.inspect, s.leave, ...).

local s = require "main.data.scenes._shared"

local function can_discuss_loop(gs)
    return gs.get_flag("loop2_revealed_to_npc") and not gs.get_flag("bar_discussion_done")
end

return {

    bar_hub = {
        bg = "bg_bar_maybe_night",
        label = "Бар Maybe",
        on_enter = {
            knot = "bar_loop_discuss",
            condition = can_discuss_loop,
        },
        hotspots = {
            s.inspect{
                id = "bar_counter",
                rect = { x = 300, y = 150, w = 500, h = 300 },
                label = "Стойка бара",
                icon = "",
                knot = "bar_counter_interact",
            },
            s.leave{
                id = "leave_bar",
                rect = { x = 0, y = 0, w = 150, h = 200 },
                knot = "leave_bar",
            },
        },
    },

}
