-- main/data/scenes/cafe.lua
-- Сцены AVOS — раздел: cafe. См. _shared.lua для recipes.

local s = require "main.data.scenes._shared"

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
            s.inspect{
                id = "cafe_window_table",
                rect = { x = 680, y = 170, w = 300, h = 270 },
                label = "Столик у окна",
                knot = "cafe_window_table",
                visible_when = function(gs)
                    return gs.get_flag("met_npc_sunday")
                end,
            },
            s.use{
                id = "cafe_bar",
                rect = { x = 360, y = 205, w = 380, h = 280 },
                label = "Стойка",
                icon = "coffee",
                knot = "cafe_bar_interact",
            },
            s.leave{
                id = "leave_cafe",
                rect = { x = 0, y = 0, w = 170, h = 220 },
                knot = "leave_cafe",
            },
        },
    },

}
