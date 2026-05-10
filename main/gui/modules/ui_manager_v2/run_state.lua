local gs = require "main.scripts.game_state"
local log = require "main.scripts.log"
local sm = require "main.scripts.save_manager"
local scene_controller = require "main.scripts.scene_controller"

local M = {}

local function reset_scene_controller()
    if scene_controller.reset then
        scene_controller.reset()
    else
        scene_controller.deserialize({ scene_stack = {} })
    end
end

function M.persist(suppress_run_save)
    if suppress_run_save then return end
    if not gs.serialize or not scene_controller.serialize then return end

    sm.set_game_state({
        gs = gs.serialize(),
        scene_controller = scene_controller.serialize(),
    })
end

function M.restore(set_suppressed, opts)
    opts = opts or {}
    local saved = sm.get_game_state()
    local scene_to_enter = nil

    set_suppressed(true)

    if saved and saved.gs then
        gs.deserialize(saved.gs)
        scene_controller.deserialize(saved.scene_controller)
        if saved.scene_controller and saved.scene_controller.active and saved.scene_controller.scene_id then
            scene_to_enter = saved.scene_controller.scene_id
        elseif saved.gs.current_scene then
            scene_to_enter = saved.gs.current_scene
        end
    elseif saved then
        gs.deserialize(saved)
        reset_scene_controller()
        if saved.current_scene then
            scene_to_enter = saved.current_scene
        end
    else
        gs.reset()
        reset_scene_controller()
    end

    set_suppressed(false)
    if scene_to_enter and not opts.defer_scene_enter then
        scene_controller.enter(scene_to_enter)
    end

    return {
        has_game_state = saved ~= nil,
        scene_to_enter = scene_to_enter,
    }
end

function M.load_main_story_bytes()
    local ok, bytes = pcall(sys.load_resource, "/main/story/chapter_01.json")
    if not ok or not bytes then
        log.error("ui_manager", "chapter_01.json not found")
        return nil
    end
    return bytes
end

function M.reset_runtime(set_suppressed)
    set_suppressed(true)
    gs.reset()
    reset_scene_controller()
    set_suppressed(false)
end

return M
