-- main/data/scenes/viewpoint.lua
-- Сцены AVOS — раздел: viewpoint. См. _shared.lua для recipes.
--
-- Смотровая — второй стоп после основной воскресной встречи, аналог магазина:
--   view_hub      — основная площадка у перил (bg_observation_railing_day)
--   view_corner   — тихий угол площадки       (bg_observation_corner_day)
--
-- view_hub остаётся entrypoint с карты телефона (poi_view -> view_hub).
-- Выход из локации есть только в view_hub: из бокового угла игрок сначала
-- возвращается к перилам, чтобы не выпадать на карту из второстепенной зоны.

local s = require "main.data.scenes._shared"

local function viewpoint_active(gs)
    return gs.get_flag("sunday_after_date_active")
       and not gs.get_flag("sunday_second_stop_done")
end

return {

    view_hub = {
        bg = "bg_observation_railing_day",
        label = "Смотровая",
        npc = "npc",
        on_enter = {
            knot = "sunday_viewpoint_arrival",
            condition = function(gs)
                return viewpoint_active(gs)
                   and not gs.get_flag("sunday_viewpoint_seen")
            end,
        },
        hotspots = {
            s.inspect{
                id = "view_railing",
                rect = { x = 465, y = 170, w = 130, h = 130 },
                label = "Поручни",
                knot = "view_railing_interact",
            },
            s.inspect{
                id = "view_city",
                rect = { x = 640, y = 380, w = 130, h = 130 },
                label = "Город",
                knot = "view_city_interact",
            },
            s.use{
                id = "view_binoculars",
                rect = { x = 885, y = 180, w = 130, h = 130 },
                label = "Бинокль",
                icon = "left_click",
                knot = "view_binoculars_interact",
            },
            s.nav_scene{
                id = "view_to_corner",
                rect = { x = 1130, y = 0, w = 150, h = 210 },
                label = "К лавочке",
                icon = "right",
                scene = "view_corner",
            },
            s.leave{
                id = "leave_view",
                rect = { x = 0, y = 0, w = 150, h = 210 },
                label = "Уйти",
                icon = "down",
                knot = "leave_viewpoint",
            },
        },
    },

    view_corner = {
        bg = "bg_observation_corner_day",
        label = "Смотровая — лавочка",
        npc = "npc",
        hotspots = {
            s.story{
                id = "view_corner_sit",
                rect = { x = 1010, y = 165, w = 130, h = 130 },
                label = "Сесть рядом",
                knot = "view_corner_main_talk",
                visible_when = function(gs)
                    return viewpoint_active(gs)
                end,
            },
            s.inspect{
                id = "view_corner_bench",
                rect = { x = 860, y = 235, w = 130, h = 130 },
                label = "Скамейка",
                knot = "view_corner_bench_interact",
            },
            s.inspect{
                id = "view_corner_glass",
                rect = { x = 355, y = 230, w = 130, h = 130 },
                label = "Стекло",
                knot = "view_corner_glass_interact",
            },
            s.inspect{
                id = "view_corner_planter",
                rect = { x = 1055, y = 395, w = 130, h = 130 },
                label = "Зелень",
                knot = "view_corner_planter_interact",
            },
            s.nav_scene{
                id = "corner_to_view",
                rect = { x = 0, y = 0, w = 150, h = 210 },
                label = "К перилам",
                icon = "left",
                scene = "view_hub",
            },
        },
    },

}
