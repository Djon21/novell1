-- main/data/scenes/viewpoint.lua
-- Сцены AVOS — раздел: viewpoint. См. _shared.lua для recipes.
--
-- Смотровая — мини-хаб из двух фонов:
--   view_hub      — основная площадка у перил (bg_observation_railing_day)
--   view_corner   — другой угол площадки  (bg_observation_corner_day)
--
-- view_hub остаётся entrypoint с карты телефона (poi_view → view_hub).
-- Хотспот-rect'ы в view_corner — placeholder под фактическое изображение,
-- подгоняй через F1.

local s = require "main.data.scenes._shared"

return {

    view_hub = {
        bg = "bg_observation_railing_day",
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
            s.nav_scene{
                id = "view_to_corner",
                rect = { x = 1080, y = 200, w = 130, h = 320 },
                label = "В угол",
                icon = "right",
                scene = "view_corner",
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

    view_corner = {
        bg = "bg_observation_corner_day",
        label = "Смотровая — угол",
        hotspots = {
            -- Заготовка под хотспот «осмотреть угол» — содержание добавится
            -- когда заполнится narrative. Сейчас scene = просто фон + nav.
            s.nav_scene{
                id = "corner_to_view",
                rect = { x = 0, y = 200, w = 130, h = 320 },
                label = "К перилам",
                icon = "left",
                scene = "view_hub",
            },
            s.leave{
                id = "leave_view_corner",
                rect = { x = 0, y = 0, w = 150, h = 200 },
                label = "Уйти",
                icon = "",
                knot = "leave_viewpoint",
            },
        },
    },

}
