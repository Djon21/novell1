local M = {}

local SAVE_PATH = sys.get_save_file("novell1", "meta_state.dat")

local DEFAULT = {
    iteration_number = 1,
    completed_iterations = 0,
    loop_awareness = 0,
}

local state = nil

local function clone_defaults()
    local copy = {}
    for k, v in pairs(DEFAULT) do
        copy[k] = v
    end
    return copy
end

local function ensure_loaded()
    if not state then
        M.init()
    end
end

function M.init()
    local loaded = sys.load(SAVE_PATH)
    state = clone_defaults()

    if type(loaded) == "table" then
        for k, v in pairs(loaded) do
            state[k] = v
        end
    end

    return state
end

function M.save()
    ensure_loaded()
    sys.save(SAVE_PATH, state)
end

function M.get(key, default_value)
    ensure_loaded()
    local value = state[key]
    if value == nil then
        return default_value
    end
    return value
end

function M.set(key, value)
    ensure_loaded()
    state[key] = value
    M.save()
    return value
end

function M.inc(key, delta)
    ensure_loaded()
    state[key] = (tonumber(state[key]) or 0) + (delta or 1)
    M.save()
    return state[key]
end

function M.snapshot()
    ensure_loaded()
    local copy = {}
    for k, v in pairs(state) do
        copy[k] = v
    end
    return copy
end

function M.get_iteration_label()
    ensure_loaded()
    return string.format("%03d", tonumber(state.iteration_number) or 1)
end

function M.complete_iteration(loop_awareness_delta)
    ensure_loaded()

    state.completed_iterations = (tonumber(state.completed_iterations) or 0) + 1
    state.iteration_number = (tonumber(state.iteration_number) or 1) + 1
    state.loop_awareness = math.max(0, (tonumber(state.loop_awareness) or 0) + (loop_awareness_delta or 1))

    M.save()
    return M.snapshot()
end

function M.reset_all()
    state = clone_defaults()
    M.save()
    return M.snapshot()
end

return M
