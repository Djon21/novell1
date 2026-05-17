-- main/scripts/state/sms.lua
-- SMS-канал телефона. Выделен из game_state.lua.
--
-- API (все вызовы публичные):
--   M.set_deps({ notify = fn, set_flag = fn })  — обязательно вызвать ДО
--                                                  использования add/reply/mark.
--   M.reset()                — обнулить состояние (новый run / load).
--   M.add(contact_id, text)  — входящее сообщение от контакта (unread=true).
--   M.reply(contact_id, text) — исходящее от ГГ (флаг sms_<contact>_replied).
--   M.mark_read(contact_id)  — пометить чат прочитанным (флаг sms_<contact>_read).
--   M.mark_all_read()        — пометить все чаты.
--   M.get(contact_id)        — клонированный список сообщений чата.
--   M.get_contacts()         — список contact_id, отсортирован по последнему seq.
--   M.get_unread_total()     — суммарное кол-во непрочитанных (для бейджа).
--   M.get_unread(contact_id) — непрочитанные у одного контакта.
--   M.serialize()            — данные для save_manager.
--   M.deserialize(data)      — восстановить + normalize.

local H = require "main.scripts.state._helpers"

local M = {}

-- Зависимости: коллбэки, которые модуль зовёт. Подключаются game_state.lua
-- через set_deps() до первого использования. Без notify_cb обновления UI
-- не пройдут; без set_flag_cb не выставятся auto-флаги read/replied.
local notify_cb = function() end
local set_flag_cb = function(_name, _value) end

function M.set_deps(deps)
    if deps.notify   then notify_cb   = deps.notify   end
    if deps.set_flag then set_flag_cb = deps.set_flag end
end

-- Внутреннее состояние модуля.
local _sms        = {}    -- { [contact_id] = { msg_entry, ... } }
local _sms_unread = {}    -- { [contact_id] = N }
-- Runtime-теги поверх статичного phone_contacts.lua. Из ink ставятся через
-- `# sms:tag:CONTACT:TONE:LABEL`, очищаются через `# sms:tag:CONTACT:clear`.
-- TONE ∈ { "hot", "amber", "danger", "warn" }. LABEL — короткая строка.
local _sms_tags   = {}    -- { [contact_id] = { tone = "hot", label = "сигнал" } }
local next_seq, _get_seq, _absorb_seq = H.make_seq()
local default_time = H.make_default_time(7 * 60 + 12)  -- база 07:12

local function read_flag(contact_id)
    if not contact_id or contact_id == "" then return nil end
    return "sms_" .. tostring(contact_id) .. "_read"
end

local function get_contact_last_seq(contact_id)
    local chat = _sms[contact_id]
    if not chat or #chat == 0 then return 0 end
    local last = chat[#chat]
    return tonumber(last and last.seq) or 0
end

local function normalize()
    local raw_sms = type(_sms) == "table" and _sms or {}
    local normalized = {}
    local max_seq = 0

    for raw_contact_id, chat in pairs(raw_sms) do
        if type(chat) == "table" and #chat > 0 then
            local contact_id = tostring(raw_contact_id)
            local out_chat = {}
            for _, msg in ipairs(chat) do
                local entry = type(msg) == "table" and msg or { text = msg }
                local seq = tonumber(entry.seq)
                if not seq or seq < 1 then seq = max_seq + 1 end
                if seq > max_seq then max_seq = seq end
                table.insert(out_chat, {
                    text      = tostring(entry.text or ""),
                    unread    = entry.unread == true,
                    direction = (entry.direction == "out") and "out" or "in",
                    hot       = entry.hot == true,
                    time      = entry.time and tostring(entry.time) or default_time(seq),
                    seq       = seq,
                })
            end
            table.sort(out_chat, function(a, b)
                return (tonumber(a.seq) or 0) < (tonumber(b.seq) or 0)
            end)
            if #out_chat > 0 then
                normalized[contact_id] = out_chat
            end
        end
    end

    _sms = normalized
    _sms_unread = {}
    for contact_id, chat in pairs(_sms) do
        local unread = 0
        for _, msg in ipairs(chat) do
            if msg.unread then unread = unread + 1 end
        end
        _sms_unread[contact_id] = unread
    end
    _absorb_seq(max_seq)
end

function M.reset()
    _sms = {}
    _sms_unread = {}
    _sms_tags = {}
    next_seq, _get_seq, _absorb_seq = H.make_seq()
end

-- ---------------------------------------------------------------------------
-- Runtime tags (pin-теги в списке SMS)
-- ---------------------------------------------------------------------------
function M.set_tag(contact_id, tone, label)
    if not contact_id or contact_id == "" then return false end
    local id = tostring(contact_id)
    -- Очистка: tone="clear" / nil / "" / "none" → снять тег.
    if not tone or tone == "" or tone == "clear" or tone == "none" then
        if _sms_tags[id] then
            _sms_tags[id] = nil
            notify_cb()
            return true
        end
        return false
    end
    _sms_tags[id] = {
        tone  = tostring(tone),
        label = label and tostring(label) or nil,
    }
    notify_cb()
    return true
end

function M.get_tag(contact_id)
    if not contact_id or contact_id == "" then return nil, nil end
    local t = _sms_tags[tostring(contact_id)]
    if not t then return nil, nil end
    return t.tone, t.label
end

-- hot_or_opts: true → пометить сообщение как hot (визуальный red-tinted bubble +
-- акцент при unread). Можно передать таблицу { hot = true, ... } для расширения
-- в будущем. Сейчас используется только для in-сообщений (входящих).
function M.add(contact_id, text, hot_or_opts)
    if not contact_id or contact_id == "" then return false end
    local seq = next_seq()
    local hot = false
    if hot_or_opts == true then hot = true
    elseif type(hot_or_opts) == "table" and hot_or_opts.hot == true then hot = true end
    _sms[contact_id] = _sms[contact_id] or {}
    table.insert(_sms[contact_id], {
        text      = tostring(text or ""),
        unread    = true,
        direction = "in",
        hot       = hot,
        time      = default_time(seq),
        seq       = seq,
    })
    _sms_unread[contact_id] = (_sms_unread[contact_id] or 0) + 1
    notify_cb()
    return true
end

function M.reply(contact_id, text)
    if not contact_id or contact_id == "" then return false end
    local seq = next_seq()
    _sms[contact_id] = _sms[contact_id] or {}
    table.insert(_sms[contact_id], {
        text      = tostring(text or ""),
        unread    = false,
        direction = "out",
        time      = default_time(seq),
        seq       = seq,
    })
    set_flag_cb("sms_" .. tostring(contact_id) .. "_replied", true)
    notify_cb()
    return true
end

function M.mark_read(contact_id)
    local chat = _sms[contact_id]
    if not chat then return end
    local changed = false
    for _, msg in ipairs(chat) do
        if msg.unread then
            msg.unread = false
            changed = true
        end
    end
    if (_sms_unread[contact_id] or 0) > 0 then changed = true end
    _sms_unread[contact_id] = 0
    local rf = read_flag(contact_id)
    if rf then
        set_flag_cb(rf, true)
        changed = true
    end
    if changed then notify_cb() end
end

function M.mark_all_read()
    local changed = false
    for contact_id, chat in pairs(_sms) do
        for _, msg in ipairs(chat) do
            if msg.unread then
                msg.unread = false
                changed = true
            end
        end
        if (_sms_unread[contact_id] or 0) > 0 then changed = true end
        _sms_unread[contact_id] = 0
        local rf = read_flag(contact_id)
        if rf then
            set_flag_cb(rf, true)
            changed = true
        end
    end
    if changed then notify_cb() end
end

function M.get(contact_id)
    return H.clone_value(_sms[contact_id] or {})
end

function M.get_contacts()
    local ids = {}
    for id, chat in pairs(_sms) do
        if type(chat) == "table" and #chat > 0 then
            table.insert(ids, id)
        end
    end
    table.sort(ids, function(a, b)
        local seq_a = get_contact_last_seq(a)
        local seq_b = get_contact_last_seq(b)
        if seq_a ~= seq_b then return seq_a > seq_b end
        return tostring(a) < tostring(b)
    end)
    return ids
end

function M.get_unread_total()
    local total = 0
    for _, n in pairs(_sms_unread) do total = total + n end
    return total
end

function M.get_unread(contact_id)
    return _sms_unread[contact_id] or 0
end

function M.serialize()
    return {
        sms = H.clone_value(_sms),
        sms_unread = H.clone_value(_sms_unread),
        sms_tags = H.clone_value(_sms_tags),
    }
end

function M.deserialize(data)
    data = data or {}
    _sms = type(data.sms) == "table" and data.sms or {}
    _sms_unread = type(data.sms_unread) == "table" and data.sms_unread or {}
    _sms_tags = type(data.sms_tags) == "table" and data.sms_tags or {}
    normalize()
end

return M
