-- save_manager.lua
-- Stores only run-state for the current playthrough.
-- Persistent loop/meta progression lives in meta_state.lua.

local M = {}

local SAVE_PATH = sys.get_save_file("novell1", "save.dat")

local _data = nil

local function defaults()
    return {
        mc_gender  = nil,
        chapter    = 1,
        ink_state  = nil,
        game_state = nil,
    }
end

local function ensure_loaded()
    if not _data then
        M.load()
    end
end

function M.load()
    local loaded = sys.load(SAVE_PATH)
    if loaded and next(loaded) ~= nil then
        _data = loaded
    else
        _data = defaults()
    end
    return _data
end

function M.save()
    ensure_loaded()
    sys.save(SAVE_PATH, _data)
end

function M.new_game()
    _data = defaults()
    M.save()
end

function M.clear_run()
    ensure_loaded()
    _data.mc_gender = nil
    _data.chapter = 1
    _data.ink_state = nil
    _data.game_state = nil
    M.save()
end

function M.has_save()
    ensure_loaded()
    -- Continue needs both halves of the run. On HTML5/Yandex an interrupted
    -- write can leave ink_state ahead of game_state; loading that produced
    -- dialogue over the menu background and could immediately reach END.
    return _data.ink_state ~= nil and _data.game_state ~= nil
end

function M.set_ink_state(state)
    ensure_loaded()
    _data.ink_state = state
    M.save()
end

function M.get_ink_state()
    ensure_loaded()
    return _data.ink_state
end

function M.set_game_state(state)
    ensure_loaded()
    _data.game_state = state
    M.save()
end

function M.get_game_state()
    ensure_loaded()
    return _data.game_state
end

function M.set_gender(gender)
    ensure_loaded()
    _data.mc_gender = gender
    M.save()
end

function M.get_gender()
    ensure_loaded()
    return _data.mc_gender
end

function M.get_mc_name()
    ensure_loaded()
    return _data.mc_gender == "female" and "Мила" or "Артём"
end

function M.get_npc_name()
    ensure_loaded()
    return _data.mc_gender == "female" and "Артём" or "Мила"
end

function M.set_chapter(n)
    ensure_loaded()
    _data.chapter = n
    M.save()
end

function M.get_chapter()
    ensure_loaded()
    return _data.chapter
end

return M
