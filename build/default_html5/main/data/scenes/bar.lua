-- main/data/scenes/bar.lua
-- Сцены AVOS — раздел: bar.
-- См. main/data/scenes/_shared.lua для recipes (s.inspect, s.leave, ...).

local s = require "main.data.scenes._shared"

return {

    -- Минимальный хаб бара: один фон, осмотр стойки, выход через карту.
    bar_hub = {
        bg = "bg_bar_maybe_night",
        label = "Бар Maybe",
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
