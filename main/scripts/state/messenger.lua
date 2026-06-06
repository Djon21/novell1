-- main/scripts/state/messenger.lua
-- Канал мессенджера (msg:*). Структурно идентичен SMS, но с префиксом
-- msg_ для авто-флагов и собственным базовым временем (07:05).

local H = require "main.scripts.state._helpers"

local M = {}

local notify_cb   = function() end
local set_flag_cb = function(_n, _v) end

function M.set_deps(deps)
    if deps.notify   then notify_cb   = deps.notify   end
    if deps.set_flag then set_flag_cb = deps.set_flag end
end

local _msg        = {}
local _msg_unread = {}
-- Runtime pin-теги поверх статичного CHAT_META в phone_messenger.gui_script.
-- Из ink ставятся через `# msg:tag:CHAT:TONE:LABEL` / `# msg:need_reply:CHAT`,
-- очищаются через `# msg:tag:CHAT:clear`. Авто-очистка в reply() для need_reply.
local _msg_tags   = {}
-- Активные prompts: { [chat_id] = { knot = "...", label = "..." } }
-- Ставятся из ink через `# msg:prompt:CHAT:KNOT[:LABEL]`. Это «открытая
-- инициатива»: чат можно писать (can_reply ← true игнорит _replied), а тап
-- по input'у диверитит в указанный knot. Авто-снимается при reply().
local _msg_prompts = {}
local next_seq, _get_seq, _absorb_seq = H.make_seq()
local default_time = H.make_default_time(7 * 60 + 5)

local function read_flag(chat_id)
    if not chat_id or chat_id == "" then return nil end
    return "msg_" .. tostring(chat_id) .. "_read"
end

local function normalize()
    local raw = type(_msg) == "table" and _msg or {}
    local normalized = {}
    local max_seq = 0

    for raw_chat_id, chat in pairs(raw) do
        if type(chat) == "table" and #chat > 0 then
            local chat_id = tostring(raw_chat_id)
            local out_chat = {}
            for _, m in ipairs(chat) do
                local entry = type(m) == "table" and m or { text = m }
                local seq = tonumber(entry.seq)
                if not seq or seq < 1 then seq = max_seq + 1 end
                if seq > max_seq then max_seq = seq end
                table.insert(out_chat, {
                    text      = tostring(entry.text or ""),
                    unread    = entry.unread == true,
                    direction = (entry.direction == "out") and "out" or "in",
                    time      = entry.time and tostring(entry.time) or default_time(seq),
                    seq       = seq,
                })
            end
            table.sort(out_chat, function(a, b)
                return (tonumber(a.seq) or 0) < (tonumber(b.seq) or 0)
            end)
            if #out_chat > 0 then normalized[chat_id] = out_chat end
        end
    end

    _msg = normalized
    _msg_unread = {}
    for chat_id, chat in pairs(_msg) do
        local unread = 0
        for _, m in ipairs(chat) do
            if m.unread then unread = unread + 1 end
        end
        _msg_unread[chat_id] = unread
    end
    _absorb_seq(max_seq)
end

function M.reset()
    _msg = {}
    _msg_unread = {}
    _msg_tags = {}
    _msg_prompts = {}
    next_seq, _get_seq, _absorb_seq = H.make_seq()
end

-- ---------------------------------------------------------------------------
-- Prompts (открытая инициатива: «можно написать в чат X через knot Y»)
-- ---------------------------------------------------------------------------
function M.set_prompt(chat_id, knot, label)
    if not chat_id or chat_id == "" then return false end
    local id = tostring(chat_id)
    if not knot or knot == "" or knot == "clear" or knot == "none" then
        if _msg_prompts[id] then
            _msg_prompts[id] = nil
            notify_cb()
            return true
        end
        return false
    end
    _msg_prompts[id] = {
        knot  = tostring(knot),
        label = label and tostring(label) or nil,
    }
    notify_cb()
    return true
end

function M.get_prompt(chat_id)
    if not chat_id or chat_id == "" then return nil, nil end
    local p = _msg_prompts[tostring(chat_id)]
    if not p then return nil, nil end
    return p.knot, p.label
end

function M.clear_prompt(chat_id)
    return M.set_prompt(chat_id, nil)
end

-- ---------------------------------------------------------------------------
-- Runtime tags (pin-теги в списке мессенджера)
-- ---------------------------------------------------------------------------
function M.set_tag(chat_id, tone, label)
    if not chat_id or chat_id == "" then return false end
    local id = tostring(chat_id)
    if not tone or tone == "" or tone == "clear" or tone == "none" then
        if _msg_tags[id] then
            _msg_tags[id] = nil
            notify_cb()
            return true
        end
        return false
    end
    _msg_tags[id] = {
        tone  = tostring(tone),
        label = label and tostring(label) or nil,
    }
    notify_cb()
    return true
end

function M.get_tag(chat_id)
    if not chat_id or chat_id == "" then return nil, nil end
    local t = _msg_tags[tostring(chat_id)]
    if not t then return nil, nil end
    return t.tone, t.label
end

-- opts (опционально):
--   unread = false → сообщение УЖЕ прочитано (для seed-истории).
--   time   = строка готового времени ("пн", "вчера"). Если nil — автогенерация.
function M.add(chat_id, text, opts)
    if not chat_id or chat_id == "" then return false end
    local seq = next_seq()
    local unread, time = true, nil
    if type(opts) == "table" then
        if opts.unread == false then unread = false end
        if opts.time then time = tostring(opts.time) end
    end
    _msg[chat_id] = _msg[chat_id] or {}
    table.insert(_msg[chat_id], {
        text      = tostring(text or ""),
        unread    = unread,
        direction = "in",
        time      = time or default_time(seq),
        seq       = seq,
    })
    if unread then
        _msg_unread[chat_id] = (_msg_unread[chat_id] or 0) + 1
    end
    notify_cb()
    return true
end

function M.reply(chat_id, text)
    if not chat_id or chat_id == "" then return false end
    local seq = next_seq()
    _msg[chat_id] = _msg[chat_id] or {}
    table.insert(_msg[chat_id], {
        text      = tostring(text or ""),
        unread    = false,
        direction = "out",
        time      = default_time(seq),
        seq       = seq,
    })
    set_flag_cb("msg_" .. tostring(chat_id) .. "_replied", true)
    local id = tostring(chat_id)
    if _msg_tags[id] and _msg_tags[id].tone == "need_reply" then
        _msg_tags[id] = nil
    end
    if _msg_prompts[id] then
        _msg_prompts[id] = nil
    end
    notify_cb()
    return true
end

-- Старое исходящее сообщение для seed-истории. Не ставит msg_<chat>_replied,
-- не снимает need_reply и не очищает active prompt.
function M.reply_old(chat_id, text, opts)
    if not chat_id or chat_id == "" then return false end
    local seq = next_seq()
    local time = nil
    if type(opts) == "table" and opts.time then
        time = tostring(opts.time)
    end
    _msg[chat_id] = _msg[chat_id] or {}
    table.insert(_msg[chat_id], {
        text      = tostring(text or ""),
        unread    = false,
        direction = "out",
        time      = time or default_time(seq),
        seq       = seq,
    })
    notify_cb()
    return true
end

function M.mark_read(chat_id)
    local chat = _msg[chat_id]
    if not chat then return end
    local changed = false
    for _, m in ipairs(chat) do
        if m.unread then
            m.unread = false
            changed = true
        end
    end
    if (_msg_unread[chat_id] or 0) > 0 then changed = true end
    _msg_unread[chat_id] = 0
    local rf = read_flag(chat_id)
    if rf then
        set_flag_cb(rf, true)
        changed = true
    end
    if changed then notify_cb() end
end

function M.mark_all_read()
    local changed = false
    for chat_id, chat in pairs(_msg) do
        for _, m in ipairs(chat) do
            if m.unread then
                m.unread = false
                changed = true
            end
        end
        if (_msg_unread[chat_id] or 0) > 0 then changed = true end
        _msg_unread[chat_id] = 0
        local rf = read_flag(chat_id)
        if rf then
            set_flag_cb(rf, true)
            changed = true
        end
    end
    if changed then notify_cb() end
end

function M.get(chat_id)
    return H.clone_value(_msg[chat_id] or {})
end

function M.get_chats()
    local ids = {}
    for id, chat in pairs(_msg) do
        if type(chat) == "table" and #chat > 0 then
            table.insert(ids, id)
        end
    end
    table.sort(ids, function(a, b)
        local last_a = _msg[a] and _msg[a][#_msg[a]] and tonumber(_msg[a][#_msg[a]].seq) or 0
        local last_b = _msg[b] and _msg[b][#_msg[b]] and tonumber(_msg[b][#_msg[b]].seq) or 0
        if last_a ~= last_b then return last_a > last_b end
        return tostring(a) < tostring(b)
    end)
    return ids
end

function M.get_unread_total()
    local total = 0
    for _, n in pairs(_msg_unread) do total = total + n end
    return total
end

function M.get_need_reply_count()
    local n = 0
    for _, tag in pairs(_msg_tags) do
        if tag.tone == "need_reply" then n = n + 1 end
    end
    return n
end

function M.get_unread(chat_id)
    return _msg_unread[chat_id] or 0
end

function M.serialize()
    return {
        msg = H.clone_value(_msg),
        msg_unread = H.clone_value(_msg_unread),
        msg_tags = H.clone_value(_msg_tags),
        msg_prompts = H.clone_value(_msg_prompts),
    }
end

function M.deserialize(data)
    data = data or {}
    _msg = type(data.msg) == "table" and data.msg or {}
    _msg_unread = type(data.msg_unread) == "table" and data.msg_unread or {}
    _msg_tags = type(data.msg_tags) == "table" and data.msg_tags or {}
    _msg_prompts = type(data.msg_prompts) == "table" and data.msg_prompts or {}
    normalize()
end

return M
