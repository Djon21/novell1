-- main/scripts/state/notes.lua
-- Заметки игрока (короткие записи). {title, body, time, seq}.

local H = require "main.scripts.state._helpers"

local M = {}

local notify_cb = function() end

function M.set_deps(deps)
    if deps.notify then notify_cb = deps.notify end
end

local _notes = {}
local next_seq, _get_seq, _absorb_seq = H.make_seq()
local default_time = H.make_default_time(7 * 60 + 20)

local function normalize()
    local raw = type(_notes) == "table" and _notes or {}
    local normalized = {}
    local max_seq = 0

    for _, note in ipairs(raw) do
        local entry = type(note) == "table" and note or { body = note }
        local seq = tonumber(entry.seq)
        if not seq or seq < 1 then seq = max_seq + 1 end
        if seq > max_seq then max_seq = seq end
        table.insert(normalized, {
            title = tostring(entry.title or ""),
            body  = tostring(entry.body or ""),
            time  = entry.time and tostring(entry.time) or default_time(seq),
            seq   = seq,
        })
    end

    table.sort(normalized, function(a, b)
        return (tonumber(a.seq) or 0) < (tonumber(b.seq) or 0)
    end)

    _notes = normalized
    _absorb_seq(max_seq)
end

function M.reset()
    _notes = {}
    next_seq, _get_seq, _absorb_seq = H.make_seq()
end

function M.add(title, body)
    local seq = next_seq()
    table.insert(_notes, {
        title = tostring(title or ""),
        body  = tostring(body or ""),
        time  = default_time(seq),
        seq   = seq,
    })
    notify_cb()
end

function M.get()
    return H.clone_value(_notes)
end

function M.serialize()
    return { notes = H.clone_value(_notes) }
end

function M.deserialize(data)
    data = data or {}
    _notes = type(data.notes) == "table" and data.notes or {}
    normalize()
end

return M
