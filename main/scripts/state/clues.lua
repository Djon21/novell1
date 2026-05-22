-- main/scripts/state/clues.lua
-- Улики (clues): уникальные по id записи. Повторный add(id) с тем же id —
-- no-op (важно для ink-rewind циклов).

local H = require "main.scripts.state._helpers"

local M = {}

local notify_cb = function() end

function M.set_deps(deps)
    if deps.notify then notify_cb = deps.notify end
end

local _clues = {}
local next_seq, _get_seq, _absorb_seq = H.make_seq()
local default_time = H.make_default_time(7 * 60 + 50)

local function normalize()
    local raw = type(_clues) == "table" and _clues or {}
    local normalized = {}
    local seen = {}
    local max_seq = 0

    for _, clue in ipairs(raw) do
        local entry = type(clue) == "table" and clue or { label = tostring(clue) }
        local id = tostring(entry.id or "")
        if id ~= "" and not seen[id] then
            seen[id] = true
            local seq = tonumber(entry.seq)
            if not seq or seq < 1 then seq = max_seq + 1 end
            if seq > max_seq then max_seq = seq end
            table.insert(normalized, {
                id    = id,
                label = tostring(entry.label or ""),
                time  = entry.time and tostring(entry.time) or default_time(seq),
                seq   = seq,
            })
        end
    end

    table.sort(normalized, function(a, b)
        return (tonumber(a.seq) or 0) < (tonumber(b.seq) or 0)
    end)

    _clues = normalized
    _absorb_seq(max_seq)
end

function M.reset()
    _clues = {}
    next_seq, _get_seq, _absorb_seq = H.make_seq()
end

function M.add(id, label)
    id = tostring(id or "")
    if id == "" then return false end
    for _, existing in ipairs(_clues) do
        if existing.id == id then return false end
    end
    local seq = next_seq()
    table.insert(_clues, {
        id    = id,
        label = tostring(label or ""),
        time  = default_time(seq),
        seq   = seq,
    })
    notify_cb()
    return true
end

function M.has(id)
    id = tostring(id or "")
    if id == "" then return false end
    for _, existing in ipairs(_clues) do
        if existing.id == id then return true end
    end
    return false
end

-- Newest-first.
function M.get()
    local out = {}
    for i = #_clues, 1, -1 do
        table.insert(out, H.clone_value(_clues[i]))
    end
    return out
end

function M.serialize()
    return { clues = H.clone_value(_clues) }
end

function M.deserialize(data)
    data = data or {}
    _clues = type(data.clues) == "table" and data.clues or {}
    normalize()
end

return M
