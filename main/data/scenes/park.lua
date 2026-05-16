-- main/data/scenes/park.lua
-- Сцены AVOS — раздел: park. См. _shared.lua для recipes.

local s = require "main.data.scenes._shared"

-- =====================================================================
-- ПАРК У РЕКИ — воскресная встреча, мини-хаб из 3 фонов
-- =====================================================================
-- park_hub остаётся entrypoint с карты.
-- Внутри парка:
--   park_hub                 — вход / первая точка, Messenger "Ты где?"
--   park_riverside_bench     — скамейка у воды
--   park_riverside_path      — прогулочная аллея

-- visible_when-выражения часто повторяются — выносим в helpers.
local function not_chosen_or_met(gs)
    return not (gs.get_flag("park_place_chosen") and not gs.get_flag("met_npc_sunday"))
end

local function can_offer_place(gs)
    return gs.get_flag("park_npc_greeted")
       and gs.get_flag("park_bench_cleared")
       and gs.get_flag("park_path_seen")
       and not gs.get_flag("park_place_chosen")
       and not gs.get_flag("met_npc_sunday")
end

return {

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
            s.inspect{
                id = "park_entrance_view",
                rect = { x = 775, y = 300, w = 130, h = 130 },
                label = "Осмотреться",
                knot = "park_entrance_view",
                visible_when = function(gs)
                    return not gs.get_flag("park_place_chosen")
                       and not gs.get_flag("met_npc_sunday")
                end,
            },
            s.item_target{
                id = "park_bin",
                rect = { x = 320, y = 85, w = 120, h = 120 },
                label = "Урна",
                icon = "delete",
                knot = "park_bin_prompt",
                visible_when = function(gs)
                    return gs.has_item("park_trash_cup")
                       and not gs.get_flag("park_bench_cleared")
                end,
            },
            s.story{
                id = "park_message_where",
                rect = { x = 1050, y = 470, w = 130, h = 130 },
                label = "Написать",
                icon = "phone",
                knot = "park_message_where_are_you",
                visible_when = function(gs)
                    return not gs.get_flag("park_where_message_sent")
                       and not gs.get_flag("park_npc_greeted")
                       and not gs.get_flag("met_npc_sunday")
                end,
            },
            s.story{
                id = "park_npc_greeting",
                rect = { x = 490, y = 85, w = 130, h = 130 },
                label = "Поздороваться",
                knot = "park_npc_arrives",
                visible_when = function(gs)
                    return gs.get_flag("park_where_message_sent")
                       and not gs.get_flag("park_npc_greeted")
                       and not gs.get_flag("met_npc_sunday")
                end,
            },
            s.story{
                id = "park_offer_place",
                rect = { x = 805, y = 85, w = 120, h = 120 },
                label = "Предложить",
                knot = "park_offer_place",
                visible_when = can_offer_place,
            },
            s.nav_scene{
                id = "park_to_bench",
                rect = { x = 500, y = 205, w = 130, h = 130 },
                label = "К скамейке",
                icon = "up",
                scene = "park_riverside_bench",
                visible_when = function(gs)
                    return gs.get_flag("park_npc_greeted")
                       and not gs.get_flag("park_place_chosen")
                       and not gs.get_flag("met_npc_sunday")
                end,
            },
            s.nav_scene{
                id = "park_to_path",
                rect = { x = 175, y = 260, w = 130, h = 130 },
                label = "По аллее",
                icon = "up",
                scene = "park_riverside_path",
                visible_when = function(gs)
                    return gs.get_flag("park_npc_greeted")
                       and not gs.get_flag("park_place_chosen")
                       and not gs.get_flag("met_npc_sunday")
                end,
            },
            s.leave{
                id = "leave_park",
                rect = { x = 0, y = 0, w = 170, h = 220 },
                label = "Уйти",
                knot = "leave_park",
                visible_when = not_chosen_or_met,
            },
        },
    },

    park_riverside_bench = {
        bg = "bg_park_riverside_bench_morning",
        label = "Парк у реки — скамейка",
        hotspots = {
            s.inspect{
                id = "park_bench",
                rect = { x = 420, y = 140, w = 120, h = 120 },
                label = "Скамейка",
                knot = "park_bench_interact",
            },
            s.pickup{
                id = "park_trash_cup",
                rect = { x = 270, y = 175, w = 70, h = 90 },
                label = "Стаканчик",
                knot = "take_park_trash_cup",
                visible_when = function(gs)
                    return gs.get_flag("park_npc_greeted")
                       and gs.get_flag("park_bench_trash_seen")
                       and not gs.has_item("park_trash_cup")
                       and not gs.get_flag("park_bench_cleared")
                end,
            },
            s.inspect{
                id = "park_river_view",
                rect = { x = 940, y = 275, w = 120, h = 120 },
                label = "Река",
                knot = "park_river_view",
            },
            s.story{
                id = "park_offer_place_bench",
                rect = { x = 240, y = 165, w = 120, h = 120 },
                label = "Предложить",
                knot = "park_offer_place",
                visible_when = can_offer_place,
            },
            s.nav_scene{
                id = "bench_to_path",
                rect = { x = 265, y = 365, w = 120, h = 120 },
                label = "Пройтись",
                icon = "up",
                scene = "park_riverside_path",
                visible_when = not_chosen_or_met,
            },
            s.nav_scene{
                id = "bench_to_entrance",
                rect = { x = 0, y = 0, w = 170, h = 220 },
                label = "К входу",
                icon = "left",
                scene = "park_hub",
                visible_when = not_chosen_or_met,
            },
        },
    },

    park_riverside_path = {
        bg = "bg_park_riverside_path_morning",
        label = "Парк у реки — аллея",
        hotspots = {
            s.use{
                id = "park_path_walk",
                rect = { x = 520, y = 165, w = 300, h = 330 },
                label = "Пройтись",
                knot = "park_path_walk",
                visible_when = function(gs)
                    return gs.get_flag("park_talk_place_path") or gs.get_flag("met_npc_sunday")
                end,
            },
            s.inspect{
                id = "park_path_trees",
                rect = { x = 270, y = 295, w = 130, h = 130 },
                label = "Тень деревьев",
                knot = "park_path_trees",
                visible_when = not_chosen_or_met,
            },
            s.story{
                id = "park_offer_place_path",
                rect = { x = 720, y = 225, w = 120, h = 120 },
                label = "Предложить",
                knot = "park_offer_place",
                visible_when = can_offer_place,
            },
            s.nav_scene{
                id = "path_to_bench",
                rect = { x = 550, y = 340, w = 130, h = 130 },
                label = "К скамейке",
                icon = "right",
                scene = "park_riverside_bench",
                visible_when = not_chosen_or_met,
            },
            s.nav_scene{
                id = "path_to_entrance",
                rect = { x = 575, y = 55, w = 130, h = 130 },
                label = "К входу",
                icon = "down",
                scene = "park_hub",
                visible_when = not_chosen_or_met,
            },
        },
    },

}
