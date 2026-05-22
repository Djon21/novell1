-- main/scripts/state/calls.lua
-- Журнал звонков телефона. {who, kind="in"|"out"|"missed", missed, time, seq}.
-- mark_all_seen сбрасывает счётчик missed (записи остаются).

local H = require "main.scripts.state._helpers"

local M = {}

local notify_cb = function() end

function M.set_deps(deps)
    if deps.notify then notify_cb = deps.notify end
end

local CALL_KINDS = { ["in"] = true, out = true, missed = true }

local _call_log    = {}
local _call_missed = 0
local next_seq, _get_seq, _absorb_seq = H.make_seq()
local default_time = H.make_default_time(7 * 60 + 40)

local function normalize()
    local raw = type(_call_log) == "table" and _call_log or {}
    local normalized = {}
    local max_seq = 0
    local missed = 0

    for _, call in ipairs(raw) do
        local entry = type(call) == "table" and call or { who = tostring(call) }
        local seq = tonumber(entry.seq)
        if not seq or seq < 1 then seq = max_seq + 1 end
        if seq > max_seq then max_seq = seq end
        local kind = entry.kind
        if not CALL_KINDS[kind] then
            kind = entry.missed and "missed" or "in"
        end
        local is_missed = (kind == "missed")
        if is_missed then missed = missed + 1 end
        table.insert(normalized, {
            who    = tostring(entry.who or ""),
            kind   = kind,
            missed = is_missed,
            time   = entry.time and tostring(entry.time) or default_time(seq),
            seq    = seq,
        })
    end

    table.sort(normalized, function(a, b)
        return (tonumber(a.seq) or 0) < (tonumber(b.seq) or 0)
    end)

    _call_log = normalized
    _call_missed = missed
    _absorb_seq(max_seq)
end

function M.reset()
    _call_log = {}
    _call_missed = 0
    next_seq, _get_seq, _absorb_seq = H.make_seq()
end

function M.add(who, kind)
    local k = kind
    if not CALL_KINDS[k] then k = "in" end
    local seq = next_seq()
    local is_missed = (k == "missed")
    table.insert(_call_log, {
        who    = tostring(who or ""),
        kind   = k,
        missed = is_missed,
        time   = default_time(seq),
        seq    = seq,
    })
    if is_missed then _call_missed = _call_missed + 1 end
    notify_cb()
    return true
end

function M.mark_all_seen()
    if _call_missed == 0 then return end
    for _, call in ipairs(_call_log) do
        call.missed = false
    end
    _call_missed = 0
    notify_cb()
end

function M.get_log()
    local out = {}
    for i = #_call_log, 1, -1 do
        table.insert(out, H.clone_value(_call_log[i]))
    end
    return out
end

function M.get_missed_total()
    return _call_missed
end

function M.serialize()
    return {
        call_log = H.clone_value(_call_log),
        call_missed = _call_missed,
    }
end

function M.deserialize(data)
    data = data or {}
    _call_log = type(data.call_log) == "table" and data.call_log or {}
    _call_missed = tonumber(data.call_missed) or 0
    normalize()
end

return M
