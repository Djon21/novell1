-- main/data/scenes/cafe.lua
-- Сцены AVOS — раздел: cafe. См. _shared.lua для recipes.
--
-- Кафе — мини-хаб из трёх фонов:
--   cafe_hub      — основной зал (стойка, столик у окна, выход)
--                   bg_cafe_morning  [исторически morning-lit]
--   cafe_corner   — уголок зала    bg_cafe_corner_day
--   cafe_backroom — задняя комната bg_cafe_backroom_day
--
-- cafe_hub — entrypoint с карты (poi_cafe → cafe_hub). Sub-сцены
-- доступны через nav-хотспоты из hub.
--
-- Хотспот-rect'ы в новых sub-сценах — placeholder под F1-тюнинг.

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
            s.nav_scene{
                id = "cafe_to_corner",
                rect = { x = 1080, y = 200, w = 130, h = 320 },
                label = "В уголок",
                icon = "right",
                scene = "cafe_corner",
            },
            s.nav_scene{
                id = "cafe_to_backroom",
                rect = { x = 200, y = 380, w = 130, h = 180 },
                label = "Задняя",
                icon = "up",
                scene = "cafe_backroom",
            },
            s.leave{
                id = "leave_cafe",
                rect = { x = 0, y = 0, w = 170, h = 220 },
                knot = "leave_cafe",
            },
        },
    },

    cafe_corner = {
        bg = "bg_cafe_corner_day",
        label = "Кафе — уголок",
        hotspots = {
            -- Заготовка под хотспот-osмотр угла. Добавится когда заполнится narrative.
            s.nav_scene{
                id = "corner_to_cafe",
                rect = { x = 0, y = 200, w = 130, h = 320 },
                label = "В зал",
                icon = "left",
                scene = "cafe_hub",
            },
            s.leave{
                id = "leave_cafe_corner",
                rect = { x = 0, y = 0, w = 170, h = 220 },
                knot = "leave_cafe",
            },
        },
    },

    cafe_backroom = {
        bg = "bg_cafe_backroom_day",
        label = "Кафе — задняя",
        hotspots = {
            -- Заготовка под хотспот-osмотр задней комнаты.
            s.nav_scene{
                id = "backroom_to_cafe",
                rect = { x = 0, y = 200, w = 130, h = 320 },
                label = "В зал",
                icon = "left",
                scene = "cafe_hub",
            },
            s.leave{
                id = "leave_cafe_backroom",
                rect = { x = 0, y = 0, w = 170, h = 220 },
                knot = "leave_cafe",
            },
        },
    },

}
