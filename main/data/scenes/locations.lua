-- main/data/scenes/locations.lua
-- Сцены AVOS — раздел: locations.
-- См. main/data/scenes/_shared.lua для STYLE_* и helper'ов.

local s = require "main.data.scenes._shared"
local STYLE_NAV         = s.STYLE_NAV
local STYLE_INSPECT     = s.STYLE_INSPECT
local STYLE_PICKUP      = s.STYLE_PICKUP
local STYLE_USE         = s.STYLE_USE
local STYLE_ITEM_TARGET = s.STYLE_ITEM_TARGET
local STYLE_STORY       = s.STYLE_STORY


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
            {
                id = "cafe_window_table",
                rect = { x = 680, y = 170, w = 300, h = 270 },
                label = "Столик у окна",
                icon = "left_click",
                hotspot_style = STYLE_INSPECT,
                action = { type = "ink_knot", knot = "cafe_window_table" },
                visible_when = function(gs)
                    return gs.get_flag("met_npc_sunday")
                end,
            },
            {
                id = "cafe_bar",
                rect = { x = 360, y = 205, w = 380, h = 280 },
                label = "Стойка",
                icon = "coffee",
                hotspot_style = STYLE_USE,
                action = { type = "ink_knot", knot = "cafe_bar_interact" },
            },
            {
                id = "leave_cafe",
                rect = { x = 0, y = 0, w = 170, h = 220 },
                label = "Выйти",
                icon = "arrow_back",
                hotspot_style = STYLE_NAV,
                action = { type = "ink_knot", knot = "leave_cafe" },
            },
        },
    },

    -- =====================================================================
    -- ПАРК У РЕКИ — воскресная встреча, мини-хаб из 3 фонов
    -- =====================================================================
    -- park_hub остаётся entrypoint с карты.
    -- Внутри парка:
    --   park_hub                 — вход / первая точка, Messenger “Ты где?”
    --   park_riverside_bench     — скамейка у воды
    --   park_riverside_path      — прогулочная аллея

    park_hub = {
        bg = "bg_park_riverside_entrance_morning",
        label = "Парк у реки",
        on_enter = {
            knot = "sunday_date_park_arrival",
            condition = function(gs)
                return gs.get_flag("date_place_park") and not gs.get_flag("park_arrived")
            end,
        },

        hotspots = {
            {
                id = "park_entrance_view",
                rect = { x = 775, y = 300, w = 130, h = 130 },
                label = "Осмотреться",
                icon = "left_click",
                hotspot_style = STYLE_INSPECT,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "ink_knot", knot = "park_entrance_view" },
                visible_when = function(gs)
                    return not gs.get_flag("park_place_chosen")
                       and not gs.get_flag("met_npc_sunday")
                end,
            },
            {
                id = "park_bin",
                rect = { x = 320, y = 85, w = 120, h = 120 },
                label = "Урна",
                icon = "delete",
                hotspot_style = STYLE_ITEM_TARGET,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "ink_knot", knot = "park_bin_prompt" },
                visible_when = function(gs)
                    return gs.has_item("park_trash_cup")
                       and not gs.get_flag("park_bench_cleared")
                end,
            },
            {
                id = "park_message_where",
                rect = { x = 1050, y = 470, w = 130, h = 130 },
                label = "Написать",
                icon = "phone",
                hotspot_style = STYLE_STORY,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "ink_knot", knot = "park_message_where_are_you" },
                visible_when = function(gs)
                    return not gs.get_flag("park_where_message_sent")
                       and not gs.get_flag("park_npc_greeted")
                       and not gs.get_flag("met_npc_sunday")
                end,
            },
            {
                id = "park_npc_greeting",
                rect = { x = 490, y = 85, w = 130, h = 130 },
                label = "Поздороваться",
                icon = "left_click",
                hotspot_style = STYLE_STORY,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "ink_knot", knot = "park_npc_arrives" },
                visible_when = function(gs)
                    return gs.get_flag("park_where_message_sent")
                       and not gs.get_flag("park_npc_greeted")
                       and not gs.get_flag("met_npc_sunday")
                end,
            },
            {
                id = "park_offer_place",
                rect = { x = 805, y = 85, w = 120, h = 120 },
                label = "Предложить",
                icon = "left_click",
                hotspot_style = STYLE_STORY,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "ink_knot", knot = "park_offer_place" },
                visible_when = function(gs)
                    return gs.get_flag("park_npc_greeted")
                       and gs.get_flag("park_bench_cleared")
                       and gs.get_flag("park_path_seen")
                       and not gs.get_flag("park_place_chosen")
                       and not gs.get_flag("met_npc_sunday")
                end,
            },
            {
                id = "park_to_bench",
                rect = { x = 500, y = 205, w = 130, h = 130 },
                label = "К скамейке",
                icon = "arrow_up",
                hotspot_style = STYLE_NAV,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "goto_scene", scene = "park_riverside_bench" },
                visible_when = function(gs)
                    return gs.get_flag("park_npc_greeted")
                       and not gs.get_flag("park_place_chosen")
                       and not gs.get_flag("met_npc_sunday")
                end,
            },
            {
                id = "park_to_path",
                rect = { x = 175, y = 260, w = 130, h = 130 },
                label = "По аллее",
                icon = "arrow_up",
                hotspot_style = STYLE_NAV,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "goto_scene", scene = "park_riverside_path" },
                visible_when = function(gs)
                    return gs.get_flag("park_npc_greeted")
                       and not gs.get_flag("park_place_chosen")
                       and not gs.get_flag("met_npc_sunday")
                end,
            },
            {
                id = "leave_park",
                rect = { x = 0, y = 0, w = 170, h = 220 },
                label = "Уйти",
                icon = "arrow_back",
                hotspot_style = STYLE_NAV,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "ink_knot", knot = "leave_park" },
                visible_when = function(gs)
                    return not (gs.get_flag("park_place_chosen") and not gs.get_flag("met_npc_sunday"))
                end,
            },
        },
    },

    park_riverside_bench = {
        bg = "bg_park_riverside_bench_morning",
        label = "Парк у реки — скамейка",
        hotspots = {
            {
                id = "park_bench",
                rect = { x = 420, y = 140, w = 120, h = 120 },
                label = "Скамейка",
                icon = "left_click",
                hotspot_style = STYLE_INSPECT,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "ink_knot", knot = "park_bench_interact" },
            },
            {
                id = "park_trash_cup",
                rect = { x = 270, y = 175, w = 70, h = 90 },
                label = "Стаканчик",
                icon = "left_click",
                hotspot_style = STYLE_PICKUP,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "ink_knot", knot = "take_park_trash_cup" },
                visible_when = function(gs)
                    return gs.get_flag("park_npc_greeted")
                       and gs.get_flag("park_bench_trash_seen")
                       and not gs.has_item("park_trash_cup")
                       and not gs.get_flag("park_bench_cleared")
                end,
            },
            {
                id = "park_river_view",
                rect = { x = 940, y = 275, w = 120, h = 120 },
                label = "Река",
                icon = "left_click",
                hotspot_style = STYLE_INSPECT,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "ink_knot", knot = "park_river_view" },
            },
            {
                id = "park_offer_place_bench",
                rect = { x = 240, y = 165, w = 120, h = 120 },
                label = "Предложить",
                icon = "left_click",
                hotspot_style = STYLE_STORY,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "ink_knot", knot = "park_offer_place" },
                visible_when = function(gs)
                    return gs.get_flag("park_npc_greeted")
                       and gs.get_flag("park_bench_cleared")
                       and gs.get_flag("park_path_seen")
                       and not gs.get_flag("park_place_chosen")
                       and not gs.get_flag("met_npc_sunday")
                end,
            },
            {
                id = "bench_to_path",
                rect = { x = 265, y = 365, w = 120, h = 120 },
                label = "Пройтись",
                icon = "arrow_up",
                hotspot_style = STYLE_NAV,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "goto_scene", scene = "park_riverside_path" },
                visible_when = function(gs)
                    return not (gs.get_flag("park_place_chosen") and not gs.get_flag("met_npc_sunday"))
                end,
            },
            {
                id = "bench_to_entrance",
                rect = { x = 0, y = 0, w = 170, h = 220 },
                label = "К входу",
                icon = "arrow_back",
                hotspot_style = STYLE_NAV,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "goto_scene", scene = "park_hub" },
                visible_when = function(gs)
                    return not (gs.get_flag("park_place_chosen") and not gs.get_flag("met_npc_sunday"))
                end,
            },
        },
    },

    park_riverside_path = {
        bg = "bg_park_riverside_path_morning",
        label = "Парк у реки — аллея",
        hotspots = {
            {
                id = "park_path_walk",
                rect = { x = 520, y = 165, w = 300, h = 330 },
                label = "Пройтись",
                icon = "left_click",
                hotspot_style = STYLE_USE,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "ink_knot", knot = "park_path_walk" },
                visible_when = function(gs)
                    return gs.get_flag("park_talk_place_path") or gs.get_flag("met_npc_sunday")
                end,
            },
            {
                id = "park_path_trees",
                rect = { x = 270, y = 295, w = 130, h = 130 },
                label = "Тень деревьев",
                icon = "left_click",
                hotspot_style = STYLE_INSPECT,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "ink_knot", knot = "park_path_trees" },
                visible_when = function(gs)
                    return not (gs.get_flag("park_place_chosen") and not gs.get_flag("met_npc_sunday"))
                end,
            },
            {
                id = "park_offer_place_path",
                rect = { x = 720, y = 225, w = 120, h = 120 },
                label = "Предложить",
                icon = "left_click",
                hotspot_style = STYLE_STORY,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "ink_knot", knot = "park_offer_place" },
                visible_when = function(gs)
                    return gs.get_flag("park_npc_greeted")
                       and gs.get_flag("park_bench_cleared")
                       and gs.get_flag("park_path_seen")
                       and not gs.get_flag("park_place_chosen")
                       and not gs.get_flag("met_npc_sunday")
                end,
            },
            {
                id = "path_to_bench",
                rect = { x = 550, y = 340, w = 130, h = 130 },
                label = "К скамейке",
                icon = "arrow_forward",
                hotspot_style = STYLE_NAV,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "goto_scene", scene = "park_riverside_bench" },
                visible_when = function(gs)
                    return not (gs.get_flag("park_place_chosen") and not gs.get_flag("met_npc_sunday"))
                end,
            },
            {
                id = "path_to_entrance",
                rect = { x = 575, y = 55, w = 130, h = 130 },
                label = "К входу",
                icon = "arrow_down",
                hotspot_style = STYLE_NAV,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "goto_scene", scene = "park_hub" },
                visible_when = function(gs)
                    return not (gs.get_flag("park_place_chosen") and not gs.get_flag("met_npc_sunday"))
                end,
            },
        },
    },

    shop_hub = {
        bg = "bg_shop_day",
        label = "Магазин 24/7",
        on_enter = {
            knot = "sunday_shop_arrival",
            condition = function(gs)
                return (not gs.get_flag("met_npc_sunday") and not gs.get_flag("sunday_shop_pre_date_visited"))
                    or (gs.get_flag("sunday_after_date_active") and not gs.get_flag("sunday_second_stop_done") and not gs.get_flag("sunday_shop_with_npc_seen"))
            end,
        },
        hotspots = {
            {
                id = "shop_drinks",
                rect = { x = 930, y = 365, w = 135, h = 135 },
                label = "Напитки",
                icon = "left_click",
                hotspot_style = STYLE_PICKUP,
                action = { type = "ink_knot", knot = "shop_drinks_interact" },
                visible_when = function(gs)
                    return not gs.get_flag("sunday_shop_done")
                end,
            },
            {
                id = "shop_snacks",
                rect = { x = 705, y = 245, w = 135, h = 135 },
                label = "Снеки",
                icon = "left_click",
                hotspot_style = STYLE_PICKUP,
                action = { type = "ink_knot", knot = "shop_snacks_interact" },
                visible_when = function(gs)
                    return not gs.get_flag("sunday_shop_done")
                end,
            },
            {
                id = "shop_counter",
                rect = { x = 160, y = 405, w = 135, h = 135 },
                label = "Прилавок",
                icon = "left_click",
                hotspot_style = STYLE_INSPECT,
                action = { type = "ink_knot", knot = "shop_counter_interact" },
            },
            {
                id = "leave_shop",
                rect = { x = 505, y = 320, w = 115, h = 210 },
                label = "Выйти",
                icon = "arrow_up",
                hotspot_style = STYLE_NAV,
                action = { type = "ink_knot", knot = "leave_shop" },
            },
        },
    },

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
            {
                id = "view_railing",
                rect = { x = 200, y = 200, w = 800, h = 150 },
                label = "Поручни",
                icon = "",
                hotspot_style = STYLE_INSPECT,
                action = { type = "ink_knot", knot = "view_railing_interact" },
            },
            {
                id = "leave_view",
                rect = { x = 0, y = 0, w = 150, h = 200 },
                label = "Уйти",
                icon = "",
                hotspot_style = STYLE_NAV,
                action = { type = "ink_knot", knot = "leave_viewpoint" },
            },
        },
    },

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
