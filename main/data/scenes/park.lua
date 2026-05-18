-- main/data/scenes/park.lua
-- Сцены AVOS — раздел: park. См. _shared.lua для recipes.

local s = require "main.data.scenes._shared"

-- =====================================================================
-- ПАРК У РЕКИ — воскресная встреча, мини-хаб из 3 фонов
-- =====================================================================
-- park_hub                 — вход / первая точка, Messenger "Ты где?"
-- park_riverside_bench     — скамейка у воды; NPC может ждать ЗДЕСЬ
-- park_riverside_path      — прогулочная аллея; NPC может ждать ЗДЕСЬ
--
-- NPC-flow:
--   1) sunday_date_park_arrival ставит # msg:prompt:<npc>:park_message_where_are_you
--      с pin "НАПИСАТЬ" и # hud:hint:phone. Игрок открывает Messenger,
--      заходит в чат NPC и тапает input — prompt сам дивертит в
--      park_message_where_are_you. Обычный msg_thread_<npc> в этом flow
--      не участвует.
--   2) park_message_where_are_you отправляет сообщение, снимает prompt через
--      # msg:reply и выбирает локацию NPC: park_npc_at_bench ИЛИ
--      park_npc_at_path (детерминированно по iteration_number; iter 1 = bench).
--   3) NPC НЕ показывается в park_hub. Игрок видит nav-хотспоты
--      park_to_bench / park_to_path после park_where_message_sent.
--   4) При входе в sub-сцену с NPC, on_enter ink-knot показывает
--      scene_char (mila_idle_bench / mila_idle_path; Артём пока TODO)
--      и появляется greeting hotspot.
--   5) Click greeting -> park_npc_arrives (общий knot для любой локации).

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

-- Gate для nav-хотспотов из hub: после сообщения через msg:prompt игрок
-- может перейти в sub-сцену, где NPC ждёт. park_npc_greeted оставлен как
-- страховка для старых сейвов/ручных dev-jump сценариев.
local function nav_to_subscene_visible(gs)
    return (gs.get_flag("park_where_message_sent") or gs.get_flag("park_npc_greeted"))
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
            -- "Написать" хотспот убран: игрок пишет через Messenger.
            -- sunday_date_park_arrival ставит # msg:prompt на чат NPC;
            -- при тапе input prompt сам ведёт в park_message_where_are_you.
            -- park_npc_greeting в hub УБРАН. NPC после message_sent ждёт
            -- в sub-сцене (bench или path), greeting хотспот там же.
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
                visible_when = nav_to_subscene_visible,
            },
            s.nav_scene{
                id = "park_to_path",
                rect = { x = 175, y = 260, w = 130, h = 130 },
                label = "По аллее",
                icon = "up",
                scene = "park_riverside_path",
                visible_when = nav_to_subscene_visible,
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
        -- NPC ждёт здесь, если park_message_where_are_you выбрал bench.
        -- on_enter показывает scene_char один раз (до greeting). Отдельный
        -- park_npc_bench_shown нужен, иначе return_to_scene снова входит сюда
        -- до клика "Поздороваться" и on_enter зацикливается.
        on_enter = {
            knot = "park_bench_npc_show",
            condition = function(gs)
                return gs.get_flag("park_npc_at_bench")
                   and not gs.get_flag("park_npc_bench_shown")
                   and not gs.get_flag("park_npc_greeted")
            end,
        },
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
            -- Greeting hotspot для bench (NPC ждёт здесь).
            -- Альтернатива клику по scene_char (он тоже триггерит park_npc_arrives).
            s.story{
                id = "park_npc_greeting_bench",
                rect = { x = 700, y = 140, w = 130, h = 280 },
                label = "Поздороваться",
                knot = "park_npc_arrives",
                visible_when = function(gs)
                    return gs.get_flag("park_npc_at_bench")
                       and not gs.get_flag("park_npc_greeted")
                       and not gs.get_flag("met_npc_sunday")
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
        -- NPC ждёт здесь, если park_message_where_are_you выбрал path.
        on_enter = {
            knot = "park_path_npc_show",
            condition = function(gs)
                return gs.get_flag("park_npc_at_path")
                   and not gs.get_flag("park_npc_path_shown")
                   and not gs.get_flag("park_npc_greeted")
            end,
        },
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
            -- Greeting hotspot для path (NPC ждёт здесь).
            s.story{
                id = "park_npc_greeting_path",
                rect = { x = 720, y = 140, w = 130, h = 320 },
                label = "Поздороваться",
                knot = "park_npc_arrives",
                visible_when = function(gs)
                    return gs.get_flag("park_npc_at_path")
                       and not gs.get_flag("park_npc_greeted")
                       and not gs.get_flag("met_npc_sunday")
                end,
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
