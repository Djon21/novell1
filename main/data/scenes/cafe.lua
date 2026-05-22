-- main/data/scenes/cafe.lua
-- Сцены AVOS — раздел: cafe. См. _shared.lua для recipes.
--
-- Кафе — хаб из трёх фонов:
--   cafe_hub      — основной зал (стойка, общий вход, переходы)
--                   bg_cafe_day  [исторически morning-lit]
--   cafe_corner   — уютный уголок / диванная зона для основного разговора
--                   bg_cafe_corner_day
--   cafe_backroom — тихая задняя зона: зеркало, объявления, вешалка, полки
--                   bg_cafe_backroom_day
--
-- cafe_hub — entrypoint с карты (poi_cafe -> cafe_hub). Sub-сцены
-- доступны через nav-хотспоты из hub.
--
-- Хотспот-rect'ы в новых sub-сценах первично размечены под сгенерированные
-- фоны; после импорта в проект их лучше пройти F1 editor'ом.

local s = require "main.data.scenes._shared"

local function cafe_active(gs)
    return gs.get_flag("date_place_cafe") and not gs.get_flag("met_npc_sunday")
end

local function cafe_order_done(gs)
    return gs.get_flag("cafe_order_done") or gs.get_flag("met_npc_sunday")
end

return {

    cafe_hub = {
        bg = "bg_cafe_day",
        label = "Кафе",
        npc = "npc",       -- для inventory verb=give: inv_give_<item>_on_npc

        on_enter = {
            knot = "sunday_date_cafe_arrival",
            condition = function(gs)
                return cafe_active(gs) and not gs.get_flag("cafe_arrived")
            end,
        },
        hotspots = {
            s.use{
                id = "cafe_bar",
                rect = { x = 835, y = 290, w = 130, h = 130 },
                label = "Заказ",
                icon = "coffee",
                knot = "cafe_bar_interact",
                visible_when = function(gs)
                    return not gs.get_flag("met_npc_sunday") and not gs.get_flag("cafe_order_done")
                end,
            },
            s.inspect{
                id = "cafe_window_table",
                rect = { x = 365, y = 330, w = 130, h = 130 },
                label = "Столик у окна",
                knot = "cafe_window_table",
            },
            s.inspect{
                id = "cafe_hall_light",
                rect = { x = 520, y = 110, w = 130, h = 130 },
                label = "Зал",
                knot = "cafe_hall_light_interact",
            },
            s.nav_scene{
                id = "cafe_to_corner",
                rect = { x = 1130, y = 0, w = 150, h = 210 },
                label = "В уголок",
                icon = "right",
                scene = "cafe_corner",
                condition = function(gs)
                    return cafe_order_done(gs)
                end,
            },
            s.nav_scene{
                id = "cafe_to_backroom",
                rect = { x = 0, y = 0, w = 150, h = 210 },
                label = "К проходу",
                icon = "left",
                scene = "cafe_backroom",
            },
            s.leave{
                id = "leave_cafe",
                rect = { x = 940, y = 450, w = 130, h = 130 },
                label = "Уйти",
				icon = "up",
                knot = "leave_cafe",
            },
        },
    },

    cafe_corner = {
        bg = "bg_cafe_corner_day",
        label = "Кафе — уголок",
        npc = "npc",
        hotspots = {
            s.story{
                id = "cafe_corner_talk",
                rect = { x = 490, y = 405, w = 130, h = 130 },
                label = "Разговор",
                knot = "cafe_corner_main_talk",
                visible_when = function(gs)
                    return gs.get_flag("cafe_order_done") and not gs.get_flag("met_npc_sunday")
                end,
            },
            s.inspect{
                id = "cafe_corner_table",
                rect = { x = 620, y = 200, w = 130, h = 130 },
                label = "Столик",
                knot = "cafe_corner_table_interact",
            },
            s.inspect{
                id = "cafe_corner_window",
                rect = { x = 115, y = 320, w = 130, h = 130 },
                label = "Окно",
                knot = "cafe_corner_window_interact",
            },
            s.inspect{
                id = "cafe_corner_shelf",
                rect = { x = 825, y = 450, w = 130, h = 130 },
                label = "Полка",
                knot = "cafe_corner_shelf_interact",
            },
            s.nav_scene{
                id = "corner_to_cafe",
                rect = { x = 1130, y = 0, w = 150, h = 210 },
                label = "В зал",
                icon = "right",
                scene = "cafe_hub",
            },
        },
    },

    cafe_backroom = {
        bg = "bg_cafe_backroom_day",
        label = "Кафе — проход",
        hotspots = {
            s.inspect{
                id = "cafe_backroom_mirror",
                rect = { x = 820, y = 420, w = 130, h = 130 },
                label = "Зеркало",
                knot = "cafe_backroom_mirror_interact",
            },
            s.inspect{
                id = "cafe_backroom_board",
                rect = { x = 1020, y = 375, w = 130, h = 130 },
                label = "Объявления",
                knot = "cafe_backroom_board_interact",
            },
            s.inspect{
                id = "cafe_backroom_coatrack",
                rect = { x = 585, y = 330, w = 130, h = 130 },
                label = "Вешалка",
                knot = "cafe_backroom_coatrack_interact",
            },
            s.inspect{
                id = "cafe_backroom_books",
                rect = { x = 210, y = 300, w = 130, h = 130 },
                label = "Книги",
                knot = "cafe_backroom_books_interact",
            },
            s.nav_scene{
                id = "backroom_to_cafe",
                rect = { x = 0, y = 0, w = 150, h = 210 },
                label = "В зал",
                icon = "left",
                scene = "cafe_hub",
            },
        },
    },

}
