-- scenes.lua
-- Source of truth для point-and-click сцен. Тонкий фасад: реальные
-- определения сцен живут в main/data/scenes/<location>.lua, разбитые
-- по локациям. Этот файл их собирает и экспортирует через M.scenes / M.get.
--
-- Структура main/data/scenes/:
--   _shared.lua             — STYLE_* + bg-функции для дня/ночи
--   apartment.lua           — apartment_hub / _bedroom / _bathroom / _kitchen (воскресная база)
--   apartment_monday.lua    — monday morning-flow в квартире
--   apartment_tuesday.lua   — tuesday consequences-flow в квартире
--   office_monday.lua       — work_hub / office_workspace / office_meeting_room (понедельник)
--   office_tuesday.lua      — stub, пока без собственных хотспотов
--   park.lua                — park_hub / park_riverside_bench / park_riverside_path
--   cafe.lua                — cafe_hub
--   shop.lua                — shop_hub
--   bar.lua                 — bar_hub
--   viewpoint.lua           — view_hub
--   archive.lua             — archive_hub
--
-- Coordinates:
--   rect = { x, y, w, h } uses GUI space 1280x720, origin at bottom-left.
--
-- Supported action.type:
--   "goto_scene"  -- switch to another scene_id
--   "ink_knot"    -- leave exploration and jump to an Ink knot
--   "set_flag"    -- set a game_state flag
--   "add_item"    -- add an inventory item
--
-- Hotspot visibility:
--   visible_when(gs) -> false  hides hotspot completely
--   condition(gs)    -> false  keeps hotspot visible but locked/dimmed
--
-- Keep Ink contracts in sync:
--   every action = { type = "ink_knot", knot = "..." } must exist as
--   === ... === in an included .ink file, unless the scene is a locked future POI.

local M = { scenes = {} }

local function merge(table_or_module)
    for id, scene in pairs(table_or_module) do
        M.scenes[id] = scene
    end
end

merge(require "main.data.scenes.apartment")
merge(require "main.data.scenes.apartment_monday")
merge(require "main.data.scenes.apartment_tuesday")
merge(require "main.data.scenes.office_monday")
merge(require "main.data.scenes.office_tuesday")
merge(require "main.data.scenes.park")
merge(require "main.data.scenes.cafe")
merge(require "main.data.scenes.shop")
merge(require "main.data.scenes.bar")
merge(require "main.data.scenes.viewpoint")
merge(require "main.data.scenes.archive")

-- ---------------------------------------------------------------------------
-- Backwards-compatible aliases
-- ---------------------------------------------------------------------------
-- Указывают на канонические scene-таблицы, не дублируют данные. Держим пока
-- старые saves и старые Ink scene_id ещё могут встретиться.
M.scenes.apartment_hall_morning      = M.scenes.apartment_hub
M.scenes.apartment_bedroom_morning   = M.scenes.apartment_bedroom
M.scenes.apartment_kitchen_morning   = M.scenes.apartment_kitchen
M.scenes.sunday_apartment_bedroom_night = M.scenes.apartment_bedroom

-- Backwards-compatible aliases for office naming.
M.scenes.office_lobby   = M.scenes.work_hub
M.scenes.work_hub_day   = M.scenes.work_hub
M.scenes.work_hub_night = M.scenes.work_hub

function M.get(id) return M.scenes[id] end

return M
