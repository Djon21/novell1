-- main/scripts/state/mail.lua
-- Канал почты. Список писем с {from, subject, body, unread, time, seq}.
-- get_mails() отдаёт newest-first, mark_mail_read(index) принимает индекс
-- из этого newest-first списка.

local H = require "main.scripts.state._helpers"

local M = {}

local notify_cb = function() end

function M.set_deps(deps)
    if deps.notify then notify_cb = deps.notify end
end

local _mails        = {}
local _mails_unread = 0
local next_seq, _get_seq, _absorb_seq = H.make_seq()
local default_time = H.make_default_time(7 * 60 + 30)

local function normalize()
    local raw = type(_mails) == "table" and _mails or {}
    local normalized = {}
    local max_seq = 0
    local unread = 0

    for _, mail in ipairs(raw) do
        local entry = type(mail) == "table" and mail or { subject = tostring(mail) }
        local seq = tonumber(entry.seq)
        if not seq or seq < 1 then seq = max_seq + 1 end
        if seq > max_seq then max_seq = seq end
        local is_unread = entry.unread == true
        if is_unread then unread = unread + 1 end
        table.insert(normalized, {
            from    = tostring(entry.from or ""),
            subject = tostring(entry.subject or ""),
            body    = tostring(entry.body or ""),
            unread  = is_unread,
            time    = entry.time and tostring(entry.time) or default_time(seq),
            seq     = seq,
        })
    end

    table.sort(normalized, function(a, b)
        return (tonumber(a.seq) or 0) < (tonumber(b.seq) or 0)
    end)

    _mails = normalized
    _mails_unread = unread
    _absorb_seq(max_seq)
end

function M.reset()
    _mails = {}
    _mails_unread = 0
    next_seq, _get_seq, _absorb_seq = H.make_seq()
end

function M.add(from, subject, body)
    local seq = next_seq()
    table.insert(_mails, {
        from    = tostring(from or ""),
        subject = tostring(subject or ""),
        body    = tostring(body or ""),
        unread  = true,
        time    = default_time(seq),
        seq     = seq,
    })
    _mails_unread = _mails_unread + 1
    notify_cb()
    return true
end

-- index из newest-first списка (как возвращает get_mails).
function M.mark_read(index)
    if #_mails == 0 then return end
    local i = tonumber(index)
    local target
    if i and i >= 1 and i <= #_mails then
        target = _mails[#_mails - i + 1]
    end
    if not target or not target.unread then return end
    target.unread = false
    _mails_unread = math.max(0, _mails_unread - 1)
    notify_cb()
end

function M.mark_all_read()
    if _mails_unread == 0 then return end
    for _, mail in ipairs(_mails) do
        mail.unread = false
    end
    _mails_unread = 0
    notify_cb()
end

function M.get_mails()
    local out = {}
    for i = #_mails, 1, -1 do
        table.insert(out, H.clone_value(_mails[i]))
    end
    return out
end

function M.get_unread_total()
    return _mails_unread
end

function M.serialize()
    return {
        mails = H.clone_value(_mails),
        mails_unread = _mails_unread,
    }
end

function M.deserialize(data)
    data = data or {}
    _mails = type(data.mails) == "table" and data.mails or {}
    _mails_unread = tonumber(data.mails_unread) or 0
    normalize()
end

return M
