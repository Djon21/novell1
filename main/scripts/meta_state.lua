local M = {}

local SAVE_PATH = sys.get_save_file("novell1", "meta_state.dat")

local DEFAULT = {
    iteration_number     = 1,
    completed_iterations = 0,
    loop_awareness       = 0,
    -- Ложные концовки, найденные в текущей итерации (сбрасываются при переходе
    -- на следующую). Ключ = id концовки, значение = true.
    false_endings_seen   = {},
    false_endings_count  = 0,
    -- Выбор персонажа сохраняется между итерациями.
    -- Сбрасывается только при reset_all() (кнопка "СБРОСИТЬ ИТЕРАЦИЮ").
    mc_gender            = nil,
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

-- Вызывается при нахождении ложной концовки.
-- Возвращает true, если эта концовка была найдена впервые.
-- loop_awareness растёт только при первом открытии каждой ложной концовки.
function M.record_false_ending(id)
    ensure_loaded()
    if not state.false_endings_seen then state.false_endings_seen = {} end
    if not state.false_endings_count then state.false_endings_count = 0 end

    if state.false_endings_seen[id] then
        return false  -- уже видели, awareness не меняем
    end

    state.false_endings_seen[id] = true
    state.false_endings_count = (state.false_endings_count or 0) + 1
    state.loop_awareness = (tonumber(state.loop_awareness) or 0) + 1
    M.save()
    return true  -- новая концовка
end

-- Истинная концовка доступна, когда найдены обе ложных.
function M.is_true_ending_unlocked()
    ensure_loaded()
    return (state.false_endings_count or 0) >= 2
end

function M.get_false_endings_count()
    ensure_loaded()
    return state.false_endings_count or 0
end

-- Вызывается при прохождении истинной концовки.
-- Сдвигает итерацию вперёд и сбрасывает счётчики ложных концовок для следующей главы.
-- loop_awareness НЕ меняется здесь — он уже был накоплен через record_false_ending.
function M.complete_iteration()
    ensure_loaded()

    state.completed_iterations = (tonumber(state.completed_iterations) or 0) + 1
    state.iteration_number     = (tonumber(state.iteration_number) or 1) + 1
    state.false_endings_seen   = {}
    state.false_endings_count  = 0

    M.save()
    return M.snapshot()
end

function M.reset_all()
    state = clone_defaults()
    M.save()
    return M.snapshot()
end

return M
