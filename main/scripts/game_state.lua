-- game_state.lua
-- Единый источник правды для point-and-click слоя.
-- Хранит flags, inventory, quests, current_scene. Подписчики получают
-- _notify() при любом изменении — так quests.lua будет реактивно
-- пересчитывать шаги квестов (Спринт 4).
--
-- Сериализация — snapshot для save_manager.set_game_state(state).

local M = {}

M.MAX_INVENTORY_SLOTS = 12

-- Приватное состояние
local _flags       = {}    -- { [name] = value } — bool/number/string
local _inventory   = {}    -- список item_id в порядке получения
local _quests      = {}    -- { [quest_id] = "active"|"done"|"failed" }
local _current_scene = nil -- id сцены или nil если в ink-режиме
local _listeners   = {}    -- callback'и на изменения

-- Телефон (Спринт 4):
--   _sms[contact_id]      = { {text=, unread=true/false, time=, seq=}, ... } — порядок прихода
--   _sms_unread[contact_id] = N непрочитанных (для бейджа)
--   _notes                = { {title=, body=, time=}, ... } — порядок создания
--   _mails                = { {from=, subject=, body=, unread=, time=, seq=}, ... }
--   _call_log             = { {who=, missed=, kind="in"/"out"/"missed", time=, seq=}, ... }
--   _clues                = { {id=, label=, time=, seq=}, ... } — уникальные по id
local _sms         = {}
local _sms_unread  = {}
local _notes       = {}
local _mails       = {}
local _mails_unread = 0
local _call_log    = {}
local _call_missed = 0
local _clues       = {}

-- Messenger (отдельный от SMS канал):
--   _msg[chat_id]       = { {text, unread, direction="in"/"out", time, seq}, ... }
--   _msg_unread[chat_id] = N непрочитанных
-- Управляется ink-тегами # msg:add:, # msg:reply:, # msg:read:
-- Авто-флаги: msg_<chat>_read, msg_<chat>_replied
local _msg         = {}
local _msg_unread  = {}

-- Map POI lock (для phone_map):
--   _map_allowed_pois = { [poi_id] = true } — set разрешённых POI
--   Если пуст → все POI разрешены (default behaviour), кроме режима lock_all.
--   Управляется ink-тегами:
--     # map:allow:poi_cafe       — добавить POI в allowed
--     # map:allow:reset          — очистить (вернуть «все разрешены»)
--     # map:lock_to:poi_cafe     — clear + добавить (только этот разрешён)
--     # map:lock_all             — заблокировать все POI
local _map_allowed_pois = {}
local _map_all_pois_locked = false

-- Camera feed (вьюха «камера» в телефоне). Один активный канал.
--   _camera = { status = "offline"|"online"|"error", message, meta }
-- Terminal log (вьюха «терминал»). Хронологический список, отображается
-- последние TERMINAL_MAX_LINES — сверху старые, снизу свежие.
--   _terminal_lines = { {level = "ok"|"warn"|"err"|"info"|"prompt"|"plain", text}, ... }
local TERMINAL_MAX_LINES = 4
local DEFAULT_CAMERA = {
    status  = "offline",
    message = "NO SIGNAL",
    meta    = "CAM-01 · offline",
}
local DEFAULT_TERMINAL_LINES = {
    { level = "prompt", text = "loop --init" },
    { level = "ok",     text = "monday-worker spawned" },
    { level = "warn",   text = "cycle drift detected · +14ms" },
    { level = "err",    text = "reality.check() returned FALSE" },
}

local _camera = {
    status  = DEFAULT_CAMERA.status,
    message = DEFAULT_CAMERA.message,
    meta    = DEFAULT_CAMERA.meta,
}
local _terminal_lines = {}

local QUEST_STATUS_PRIORITY = {
    active = 1,
    failed = 2,
    done = 3,
}

local SMS_TIME_BASE_MINUTES  = 7 * 60 + 12
local NOTE_TIME_BASE_MINUTES = 7 * 60 + 20
local MAIL_TIME_BASE_MINUTES = 7 * 60 + 30
local CALL_TIME_BASE_MINUTES = 7 * 60 + 40
local CLUE_TIME_BASE_MINUTES = 7 * 60 + 50
local MSG_TIME_BASE_MINUTES  = 7 * 60 + 5

local _sms_seq  = 0
local _note_seq = 0
local _mail_seq = 0
local _call_seq = 0
local _clue_seq = 0
local _msg_seq  = 0

local function clone_value(value)
    if type(value) ~= "table" then
        return value
    end
    local out = {}
    for k, v in pairs(value) do
        out[k] = clone_value(v)
    end
    return out
end

local function clone_array(src)
    local out = {}
    if type(src) ~= "table" then
        return out
    end
    for i = 1, #src do
        out[i] = src[i]
    end
    return out
end

local function sanitize_inventory(src)
    local out = {}
    local seen = {}
    if type(src) ~= "table" then
        return out
    end
    for _, id in ipairs(src) do
        if id ~= nil and id ~= "" and not seen[id] then
            if #out >= M.MAX_INVENTORY_SLOTS then
                print("[game_state] inventory overflow on deserialize, dropping:", tostring(id))
            else
                table.insert(out, id)
                seen[id] = true
            end
        end
    end
    return out
end

local function sms_read_flag(contact_id)
    if not contact_id or contact_id == "" then return nil end
    return "sms_" .. tostring(contact_id) .. "_read"
end

local function msg_read_flag(chat_id)
    if not chat_id or chat_id == "" then return nil end
    return "msg_" .. tostring(chat_id) .. "_read"
end

local function format_clock(total_minutes)
    total_minutes = math.max(0, math.floor(tonumber(total_minutes) or 0))
    local hours = math.floor(total_minutes / 60) % 24
    local minutes = total_minutes % 60
    return string.format("%02d:%02d", hours, minutes)
end

local function next_sms_seq()
    _sms_seq = _sms_seq + 1
    return _sms_seq
end

local function next_note_seq()
    _note_seq = _note_seq + 1
    return _note_seq
end

local function default_sms_time(seq)
    return format_clock(SMS_TIME_BASE_MINUTES + math.max(0, (tonumber(seq) or 1) - 1))
end

local function default_note_time(seq)
    return format_clock(NOTE_TIME_BASE_MINUTES + math.max(0, (tonumber(seq) or 1) - 1))
end

local function default_mail_time(seq)
    return format_clock(MAIL_TIME_BASE_MINUTES + math.max(0, (tonumber(seq) or 1) - 1))
end

local function default_call_time(seq)
    return format_clock(CALL_TIME_BASE_MINUTES + math.max(0, (tonumber(seq) or 1) - 1))
end

local function default_clue_time(seq)
    return format_clock(CLUE_TIME_BASE_MINUTES + math.max(0, (tonumber(seq) or 1) - 1))
end

local function next_mail_seq()
    _mail_seq = _mail_seq + 1
    return _mail_seq
end

local function next_call_seq()
    _call_seq = _call_seq + 1
    return _call_seq
end

local function next_clue_seq()
    _clue_seq = _clue_seq + 1
    return _clue_seq
end

local function next_msg_seq()
    _msg_seq = _msg_seq + 1
    return _msg_seq
end

local function default_msg_time(seq)
    return format_clock(MSG_TIME_BASE_MINUTES + math.max(0, (tonumber(seq) or 1) - 1))
end

local function get_contact_last_seq(contact_id)
    local chat = _sms[contact_id]
    if not chat or #chat == 0 then
        return 0
    end
    local last = chat[#chat]
    return tonumber(last and last.seq) or 0
end

local function normalize_sms_state()
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
                if not seq or seq < 1 then
                    seq = max_seq + 1
                end
                if seq > max_seq then
                    max_seq = seq
                end
                table.insert(out_chat, {
                    text      = tostring(entry.text or ""),
                    unread    = entry.unread == true,
                    direction = (entry.direction == "out") and "out" or "in",
                    time      = entry.time and tostring(entry.time) or default_sms_time(seq),
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
            if msg.unread then
                unread = unread + 1
            end
        end
        _sms_unread[contact_id] = unread
    end
    _sms_seq = max_seq
end

local function normalize_notes_state()
    local raw_notes = type(_notes) == "table" and _notes or {}
    local normalized = {}
    local max_seq = 0

    for _, note in ipairs(raw_notes) do
        local entry = type(note) == "table" and note or { body = note }
        local seq = tonumber(entry.seq)
        if not seq or seq < 1 then
            seq = max_seq + 1
        end
        if seq > max_seq then
            max_seq = seq
        end
        table.insert(normalized, {
            title = tostring(entry.title or ""),
            body = tostring(entry.body or ""),
            time = entry.time and tostring(entry.time) or default_note_time(seq),
            seq = seq,
        })
    end

    table.sort(normalized, function(a, b)
        return (tonumber(a.seq) or 0) < (tonumber(b.seq) or 0)
    end)

    _notes = normalized
    _note_seq = max_seq
end

local function normalize_mails_state()
    local raw = type(_mails) == "table" and _mails or {}
    local normalized = {}
    local max_seq = 0
    local unread = 0

    for _, mail in ipairs(raw) do
        local entry = type(mail) == "table" and mail or { subject = tostring(mail) }
        local seq = tonumber(entry.seq)
        if not seq or seq < 1 then
            seq = max_seq + 1
        end
        if seq > max_seq then
            max_seq = seq
        end
        local is_unread = entry.unread == true
        if is_unread then
            unread = unread + 1
        end
        table.insert(normalized, {
            from    = tostring(entry.from or ""),
            subject = tostring(entry.subject or ""),
            body    = tostring(entry.body or ""),
            unread  = is_unread,
            time    = entry.time and tostring(entry.time) or default_mail_time(seq),
            seq     = seq,
        })
    end

    table.sort(normalized, function(a, b)
        return (tonumber(a.seq) or 0) < (tonumber(b.seq) or 0)
    end)

    _mails = normalized
    _mails_unread = unread
    _mail_seq = max_seq
end

local CALL_KINDS = { ["in"] = true, out = true, missed = true }

local function normalize_call_log_state()
    local raw = type(_call_log) == "table" and _call_log or {}
    local normalized = {}
    local max_seq = 0
    local missed = 0

    for _, call in ipairs(raw) do
        local entry = type(call) == "table" and call or { who = tostring(call) }
        local seq = tonumber(entry.seq)
        if not seq or seq < 1 then
            seq = max_seq + 1
        end
        if seq > max_seq then
            max_seq = seq
        end
        local kind = entry.kind
        if not CALL_KINDS[kind] then
            kind = entry.missed and "missed" or "in"
        end
        local is_missed = (kind == "missed")
        if is_missed then
            missed = missed + 1
        end
        table.insert(normalized, {
            who    = tostring(entry.who or ""),
            kind   = kind,
            missed = is_missed,
            time   = entry.time and tostring(entry.time) or default_call_time(seq),
            seq    = seq,
        })
    end

    table.sort(normalized, function(a, b)
        return (tonumber(a.seq) or 0) < (tonumber(b.seq) or 0)
    end)

    _call_log = normalized
    _call_missed = missed
    _call_seq = max_seq
end

local CAMERA_STATUSES = { offline = true, online = true, error = true }

local function normalize_camera_state()
    local raw = type(_camera) == "table" and _camera or {}
    local status = raw.status
    if not CAMERA_STATUSES[status] then
        status = DEFAULT_CAMERA.status
    end
    _camera = {
        status  = status,
        message = tostring(raw.message or DEFAULT_CAMERA.message),
        meta    = tostring(raw.meta    or DEFAULT_CAMERA.meta),
    }
end

local TERMINAL_LEVELS = {
    ok = true, warn = true, err = true, info = true, prompt = true, plain = true,
}

local function normalize_terminal_state()
    local raw = type(_terminal_lines) == "table" and _terminal_lines or {}
    local normalized = {}
    for _, line in ipairs(raw) do
        local entry = type(line) == "table" and line or { text = tostring(line) }
        local level = entry.level
        if not TERMINAL_LEVELS[level] then
            level = "plain"
        end
        table.insert(normalized, {
            level = level,
            text  = tostring(entry.text or ""),
        })
    end
    while #normalized > TERMINAL_MAX_LINES do
        table.remove(normalized, 1)
    end
    _terminal_lines = normalized
end

local function seed_default_terminal()
    _terminal_lines = {}
    for _, entry in ipairs(DEFAULT_TERMINAL_LINES) do
        table.insert(_terminal_lines, { level = entry.level, text = entry.text })
    end
end

seed_default_terminal()

local function normalize_clues_state()
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
            if not seq or seq < 1 then
                seq = max_seq + 1
            end
            if seq > max_seq then
                max_seq = seq
            end
            table.insert(normalized, {
                id    = id,
                label = tostring(entry.label or ""),
                time  = entry.time and tostring(entry.time) or default_clue_time(seq),
                seq   = seq,
            })
        end
    end

    table.sort(normalized, function(a, b)
        return (tonumber(a.seq) or 0) < (tonumber(b.seq) or 0)
    end)

    _clues = normalized
    _clue_seq = max_seq
end

function M.reset()
    _flags = {}
    _inventory = {}
    _quests = {}
    _sms = {}
    _sms_unread = {}
    _msg = {}
    _msg_unread = {}
    _msg_seq = 0
    _notes = {}
    _mails = {}
    _mails_unread = 0
    _call_log = {}
    _call_missed = 0
    _clues = {}
    _map_allowed_pois = {}
    _map_all_pois_locked = false
    _camera = {
        status  = DEFAULT_CAMERA.status,
        message = DEFAULT_CAMERA.message,
        meta    = DEFAULT_CAMERA.meta,
    }
    seed_default_terminal()
    _current_scene = nil
    _sms_seq = 0
    _note_seq = 0
    _mail_seq = 0
    _call_seq = 0
    _clue_seq = 0
    M._notify()
end

-- flags ------------------------------------------------------------------
function M.get_flag(name) return _flags[name] end

function M.set_flag(name, value)
    if _flags[name] == value then return end
    _flags[name] = value
    M._notify()
end

-- inventory --------------------------------------------------------------
function M.has_item(id)
    for _, v in ipairs(_inventory) do
        if v == id then return true end
    end
    return false
end

function M.add_item(id)
    if not id or id == "" then
        return false
    end
    if M.has_item(id) then
        return false
    end
    if #_inventory >= M.MAX_INVENTORY_SLOTS then
        print("[game_state] inventory is full, cannot add:", tostring(id))
        return false
    end
    table.insert(_inventory, id)
    M._notify()
    return true
end

function M.remove_item(id)
    for i, v in ipairs(_inventory) do
        if v == id then
            table.remove(_inventory, i)
            M._notify()
            return true
        end
    end
    return false
end

-- Возвращает копию массива, чтобы UI не мутировал state напрямую.
function M.get_inventory() return clone_array(_inventory) end

-- quests -----------------------------------------------------------------
function M.get_quest(id) return _quests[id] end

function M.set_quest(id, status)
    if _quests[id] == status then return end
    _quests[id] = status
    M._notify()
end

-- current scene ----------------------------------------------------------
function M.get_scene() return _current_scene end

function M.set_scene(id)
    _current_scene = id
    M._notify()
end

-- SMS (телефон) ----------------------------------------------------------
-- Добавить входящее сообщение от контакта. Помечаем unread=true, чтобы
-- на иконке SMS в телефоне показался бейдж.
function M.add_sms(contact_id, text)
    if not contact_id or contact_id == "" then
        return false
    end
    local seq = next_sms_seq()
    _sms[contact_id] = _sms[contact_id] or {}
    table.insert(_sms[contact_id], {
        text      = tostring(text or ""),
        unread    = true,
        direction = "in",
        time      = default_sms_time(seq),
        seq       = seq,
    })
    _sms_unread[contact_id] = (_sms_unread[contact_id] or 0) + 1
    M._notify()
    return true
end

-- Исходящее сообщение от ГГ (# sms:reply:contact:text).
-- Автоматически ставит флаг sms_<contact_id>_replied = true.
function M.reply_sms(contact_id, text)
    if not contact_id or contact_id == "" then
        return false
    end
    local seq = next_sms_seq()
    _sms[contact_id] = _sms[contact_id] or {}
    table.insert(_sms[contact_id], {
        text      = tostring(text or ""),
        unread    = false,
        direction = "out",
        time      = default_sms_time(seq),
        seq       = seq,
    })
    -- автоматический флаг "ответил"
    local replied_flag = "sms_" .. tostring(contact_id) .. "_replied"
    if _flags[replied_flag] ~= true then
        _flags[replied_flag] = true
    end
    M._notify()
    return true
end

-- Пометить чат как прочитанный (вызывается при открытии переписки).
function M.mark_sms_read(contact_id)
    local chat = _sms[contact_id]
    if not chat then return end
    local changed = false
    for _, msg in ipairs(chat) do
        if msg.unread then
            msg.unread = false
            changed = true
        end
    end
    if (_sms_unread[contact_id] or 0) > 0 then
        changed = true
    end
    _sms_unread[contact_id] = 0
    local read_flag = sms_read_flag(contact_id)
    if read_flag and _flags[read_flag] ~= true then
        _flags[read_flag] = true
        changed = true
    end
    if changed then
        M._notify()
    end
end

function M.mark_all_sms_read()
    local changed = false
    for contact_id, chat in pairs(_sms) do
        for _, msg in ipairs(chat) do
            if msg.unread then
                msg.unread = false
                changed = true
            end
        end
        if (_sms_unread[contact_id] or 0) > 0 then
            changed = true
        end
        _sms_unread[contact_id] = 0
        local read_flag = sms_read_flag(contact_id)
        if read_flag and _flags[read_flag] ~= true then
            _flags[read_flag] = true
            changed = true
        end
    end
    if changed then
        M._notify()
    end
end

function M.get_sms(contact_id)
    return clone_value(_sms[contact_id] or {})
end

function M.get_sms_contacts()
    local ids = {}
    for id, chat in pairs(_sms) do
        if type(chat) == "table" and #chat > 0 then
            table.insert(ids, id)
        end
    end
    table.sort(ids, function(a, b)
        local seq_a = get_contact_last_seq(a)
        local seq_b = get_contact_last_seq(b)
        if seq_a ~= seq_b then
            return seq_a > seq_b
        end
        return tostring(a) < tostring(b)
    end)
    return ids
end

function M.get_sms_unread_total()
    local total = 0
    for _, n in pairs(_sms_unread) do total = total + n end
    return total
end

function M.get_sms_unread(contact_id) return _sms_unread[contact_id] or 0 end

-- Messenger -------------------------------------------------------------
-- Параллельный SMS канал. ink-теги:
--   # msg:add:<chat_id>:<text>     — входящее сообщение
--   # msg:reply:<chat_id>:<text>   — исходящее ГГ (auto-flag msg_<chat>_replied)
--   # msg:read:<chat_id>           — пометить чат прочитанным вручную
-- Авто-флаг msg_<chat>_read ставится при mark_msg_read
-- (открытие конкретного чата или явный тег # msg:read:<chat_id>).

function M.add_msg(chat_id, text)
    if not chat_id or chat_id == "" then return false end
    local seq = next_msg_seq()
    _msg[chat_id] = _msg[chat_id] or {}
    table.insert(_msg[chat_id], {
        text      = tostring(text or ""),
        unread    = true,
        direction = "in",
        time      = default_msg_time(seq),
        seq       = seq,
    })
    _msg_unread[chat_id] = (_msg_unread[chat_id] or 0) + 1
    M._notify()
    return true
end

function M.reply_msg(chat_id, text)
    if not chat_id or chat_id == "" then return false end
    local seq = next_msg_seq()
    _msg[chat_id] = _msg[chat_id] or {}
    table.insert(_msg[chat_id], {
        text      = tostring(text or ""),
        unread    = false,
        direction = "out",
        time      = default_msg_time(seq),
        seq       = seq,
    })
    local replied_flag = "msg_" .. tostring(chat_id) .. "_replied"
    if _flags[replied_flag] ~= true then
        _flags[replied_flag] = true
    end
    M._notify()
    return true
end

function M.mark_msg_read(chat_id)
    local chat = _msg[chat_id]
    if not chat then return end
    local changed = false
    for _, msg in ipairs(chat) do
        if msg.unread then
            msg.unread = false
            changed = true
        end
    end
    if (_msg_unread[chat_id] or 0) > 0 then
        changed = true
    end
    _msg_unread[chat_id] = 0
    local read_flag = msg_read_flag(chat_id)
    if read_flag and _flags[read_flag] ~= true then
        _flags[read_flag] = true
        changed = true
    end
    if changed then M._notify() end
end

function M.mark_all_msg_read()
    local changed = false
    for chat_id, chat in pairs(_msg) do
        for _, msg in ipairs(chat) do
            if msg.unread then
                msg.unread = false
                changed = true
            end
        end
        if (_msg_unread[chat_id] or 0) > 0 then changed = true end
        _msg_unread[chat_id] = 0
        local read_flag = msg_read_flag(chat_id)
        if read_flag and _flags[read_flag] ~= true then
            _flags[read_flag] = true
            changed = true
        end
    end
    if changed then M._notify() end
end

function M.get_msg(chat_id)
    return clone_value(_msg[chat_id] or {})
end

function M.get_msg_chats()
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

function M.get_msg_unread_total()
    local total = 0
    for _, n in pairs(_msg_unread) do total = total + n end
    return total
end

function M.get_msg_unread(chat_id) return _msg_unread[chat_id] or 0 end

-- Notes (заметки) --------------------------------------------------------
function M.add_note(title, body)
    local seq = next_note_seq()
    table.insert(_notes, {
        title = tostring(title or ""),
        body = tostring(body or ""),
        time = default_note_time(seq),
        seq = seq,
    })
    M._notify()
end

function M.get_notes()
    return clone_value(_notes)
end

-- Phone view getters (step23) --------------------------------------------
-- Возвращают списки в формате, ожидаемом phone_v2.gui_script.
-- Все сторы (sms, notes, mails, call_log, clues) пополняются через ink-теги
-- (см. docs/guides/HOW_TO_WRITE_INK.md) и сохраняются в save_manager.

-- Сообщения для SMS-вьюхи: { {from, time, body, unread}, ... }
-- Берём последние сообщения по каждому контакту и сортируем чаты по
-- актуальности последнего сообщения.
function M.get_messages()
    local out = {}
    for _, id in ipairs(M.get_sms_contacts()) do
        local chat = _sms[id]
        if chat and #chat > 0 then
            local last = chat[#chat]
            local unread_n = _sms_unread[id] or 0
            table.insert(out, {
                from      = id,
                time      = last.time or "",
                body      = last.text or "",
                direction = last.direction or "in",
                unread    = unread_n > 0,
            })
        end
    end
    return out
end

-- Mail (телефон, приложение «почта») ------------------------------------
-- Добавить новое письмо. unread=true, чтобы попало в бейдж.
function M.add_mail(from, subject, body)
    local seq = next_mail_seq()
    table.insert(_mails, {
        from    = tostring(from or ""),
        subject = tostring(subject or ""),
        body    = tostring(body or ""),
        unread  = true,
        time    = default_mail_time(seq),
        seq     = seq,
    })
    _mails_unread = _mails_unread + 1
    M._notify()
    return true
end

-- Пометить одно письмо прочитанным. index — позиция в get_mails() (1 = свежее).
function M.mark_mail_read(index)
    local list = _mails
    if #list == 0 then return end
    local i = tonumber(index)
    local target
    if i and i >= 1 and i <= #list then
        -- get_mails() отдаёт newest-first, поэтому переводим внешний индекс
        -- в внутренний (chronological) через #list - i + 1.
        target = list[#list - i + 1]
    end
    if not target or not target.unread then return end
    target.unread = false
    _mails_unread = math.max(0, _mails_unread - 1)
    M._notify()
end

function M.mark_all_mail_read()
    if _mails_unread == 0 then return end
    for _, mail in ipairs(_mails) do
        mail.unread = false
    end
    _mails_unread = 0
    M._notify()
end

-- Почта: { {from, subject, unread, time}, ... }. Свежие — первыми.
function M.get_mails()
    local out = {}
    for i = #_mails, 1, -1 do
        table.insert(out, clone_value(_mails[i]))
    end
    return out
end

function M.get_mail_unread_total()
    return _mails_unread
end

-- Call log (телефон, журнал звонков) -------------------------------------
-- kind: "in" (входящий), "out" (исходящий), "missed" (пропущенный).
function M.add_call(who, kind)
    local k = kind
    if not CALL_KINDS[k] then k = "in" end
    local seq = next_call_seq()
    local is_missed = (k == "missed")
    table.insert(_call_log, {
        who    = tostring(who or ""),
        kind   = k,
        missed = is_missed,
        time   = default_call_time(seq),
        seq    = seq,
    })
    if is_missed then
        _call_missed = _call_missed + 1
    end
    M._notify()
    return true
end

-- «Отсмотреть» журнал: сбросить счётчик пропущенных (записи остаются).
function M.mark_all_calls_seen()
    if _call_missed == 0 then return end
    for _, call in ipairs(_call_log) do
        call.missed = false
    end
    _call_missed = 0
    M._notify()
end

-- Журнал звонков: { {who, kind, missed, time}, ... }. Свежие — первыми.
function M.get_call_log()
    local out = {}
    for i = #_call_log, 1, -1 do
        table.insert(out, clone_value(_call_log[i]))
    end
    return out
end

function M.get_call_missed_total()
    return _call_missed
end

-- Clues (телефон, улики) -------------------------------------------------
-- Повторный add_clue с тем же id — no-op. Подходит для записей в ink,
-- которые могут сработать после rewind/замкнутого цикла.
function M.add_clue(id, label)
    id = tostring(id or "")
    if id == "" then return false end
    for _, existing in ipairs(_clues) do
        if existing.id == id then
            return false
        end
    end
    local seq = next_clue_seq()
    table.insert(_clues, {
        id    = id,
        label = tostring(label or ""),
        time  = default_clue_time(seq),
        seq   = seq,
    })
    M._notify()
    return true
end

function M.has_clue(id)
    id = tostring(id or "")
    if id == "" then return false end
    for _, existing in ipairs(_clues) do
        if existing.id == id then return true end
    end
    return false
end

-- Улики: { {id, label, time}, ... }. Свежие — первыми.
function M.get_clues()
    local out = {}
    for i = #_clues, 1, -1 do
        table.insert(out, clone_value(_clues[i]))
    end
    return out
end

-- Camera feed ------------------------------------------------------------
-- Одна активная вьюха; любые значения опциональны — перезаписываются
-- только переданные поля, остальное сохраняется.
function M.set_camera_feed(opts)
    if type(opts) ~= "table" then return end
    local changed = false
    if opts.status ~= nil and CAMERA_STATUSES[opts.status] and _camera.status ~= opts.status then
        _camera.status = opts.status
        changed = true
    end
    if opts.message ~= nil then
        local msg_txt = tostring(opts.message)
        if _camera.message ~= msg_txt then
            _camera.message = msg_txt
            changed = true
        end
    end
    if opts.meta ~= nil then
        local meta_txt = tostring(opts.meta)
        if _camera.meta ~= meta_txt then
            _camera.meta = meta_txt
            changed = true
        end
    end
    if changed then M._notify() end
end

function M.reset_camera_feed()
    _camera = {
        status  = DEFAULT_CAMERA.status,
        message = DEFAULT_CAMERA.message,
        meta    = DEFAULT_CAMERA.meta,
    }
    M._notify()
end

function M.get_camera_feed()
    return {
        status  = _camera.status,
        message = _camera.message,
        meta    = _camera.meta,
    }
end

-- Terminal log -----------------------------------------------------------
-- Новая строка уходит в конец. Храним не больше TERMINAL_MAX_LINES.
function M.add_terminal_line(level, text)
    if not TERMINAL_LEVELS[level] then level = "plain" end
    table.insert(_terminal_lines, { level = level, text = tostring(text or "") })
    while #_terminal_lines > TERMINAL_MAX_LINES do
        table.remove(_terminal_lines, 1)
    end
    M._notify()
end

function M.clear_terminal()
    if #_terminal_lines == 0 then return end
    _terminal_lines = {}
    M._notify()
end

function M.reset_terminal_to_defaults()
    seed_default_terminal()
    M._notify()
end

-- ─── Map POI lock ───────────────────────────────────────────────────────

function M.map_allow(poi_id)
    if not poi_id or poi_id == "" then return end
    _map_all_pois_locked = false
    _map_allowed_pois[poi_id] = true
    M._notify()
end

function M.map_allow_reset()
    if not next(_map_allowed_pois) and not _map_all_pois_locked then return end
    _map_allowed_pois = {}
    _map_all_pois_locked = false
    M._notify()
end

function M.map_lock_to(poi_id)
    _map_allowed_pois = {}
    _map_all_pois_locked = false
    if poi_id and poi_id ~= "" then
        _map_allowed_pois[poi_id] = true
    end
    M._notify()
end

function M.map_lock_all()
    _map_allowed_pois = {}
    _map_all_pois_locked = true
    M._notify()
end

function M.map_is_poi_allowed(poi_id)
    if _map_all_pois_locked then return false end
    -- Empty allow-set → все POI разрешены (default behaviour).
    if not next(_map_allowed_pois) then return true end
    return _map_allowed_pois[poi_id] == true
end

function M.get_map_allowed_pois()
    return clone_value(_map_allowed_pois)
end

function M.is_map_all_pois_locked()
    return _map_all_pois_locked == true
end

-- Возвращает до TERMINAL_MAX_LINES записей в хронологическом порядке
-- (старые — первыми). В phone_v2.gui_script верхний слот = первая запись.
function M.get_terminal_lines()
    local out = {}
    for i = 1, #_terminal_lines do
        out[i] = { level = _terminal_lines[i].level, text = _terminal_lines[i].text }
    end
    return out
end

-- Квесты для phone-вьюхи: { {title, status, progress}, ... }.
-- Берём из _quests ({ [id] = "active"|"done"|"failed" }). progress пока пустой.
function M.get_quests()
    local quests_catalog = require "main.scripts.quests"
    local out = {}
    local ids = {}
    for id, _ in pairs(_quests) do table.insert(ids, id) end
    table.sort(ids, function(a, b)
        local status_a = _quests[a]
        local status_b = _quests[b]
        local priority_a = QUEST_STATUS_PRIORITY[status_a] or 99
        local priority_b = QUEST_STATUS_PRIORITY[status_b] or 99
        if priority_a ~= priority_b then
            return priority_a < priority_b
        end

        local order_a = quests_catalog.get_order and quests_catalog.get_order(a) or math.huge
        local order_b = quests_catalog.get_order and quests_catalog.get_order(b) or math.huge
        if order_a ~= order_b then
            return order_a < order_b
        end

        return tostring(a) < tostring(b)
    end)
    for _, id in ipairs(ids) do
        local q = quests_catalog.get(id)
        local title = q and q.name or id
        local desc = q and q.description or ""
        local progress = ""
        if q then
            local done, total, _ = quests_catalog.progress(id, M)
            progress = string.format("%d/%d", done, total)
        end
        table.insert(out, {
            id       = id,
            title    = title,
            status   = _quests[id],
            progress = progress,
            desc     = desc,
        })
    end
    return out
end

-- Суммарный счётчик непрочитанных для бейджа телефона.
function M.get_phone_unread_total()
    local total = M.get_sms_unread_total()
    if M.get_msg_unread_total then
        total = total + (M.get_msg_unread_total() or 0)
    end
    for _, m in ipairs(M.get_mails()) do
        if m.unread then total = total + 1 end
    end
    for _, c in ipairs(M.get_call_log()) do
        if c.missed then total = total + 1 end
    end
    return total
end

-- Реактивные подписки ----------------------------------------------------
function M.subscribe(cb)
    table.insert(_listeners, cb)
end

function M._notify()
    for _, cb in ipairs(_listeners) do
        pcall(cb)
    end
end

-- Сериализация -----------------------------------------------------------
function M.serialize()
    return {
        flags          = _flags,
        inventory      = clone_array(_inventory),
        quests         = _quests,
        sms            = clone_value(_sms),
        sms_unread     = clone_value(_sms_unread),
        msg            = clone_value(_msg),
        msg_unread     = clone_value(_msg_unread),
        notes          = clone_value(_notes),
        mails          = clone_value(_mails),
        call_log       = clone_value(_call_log),
        clues          = clone_value(_clues),
        camera         = clone_value(_camera),
        terminal_lines = clone_value(_terminal_lines),
        map_allowed_pois = clone_value(_map_allowed_pois),
        map_all_pois_locked = _map_all_pois_locked == true,
        current_scene  = _current_scene,
    }
end

function M.deserialize(data)
    if not data then
        M.reset()
        return
    end
    _flags          = data.flags      or {}
    _inventory      = sanitize_inventory(data.inventory)
    _quests         = data.quests     or {}
    _sms            = data.sms        or {}
    _sms_unread     = data.sms_unread or {}
    _msg            = data.msg        or {}
    _msg_unread     = data.msg_unread or {}
    _notes          = data.notes      or {}
    _mails          = data.mails      or {}
    _mails_unread   = 0
    _call_log       = data.call_log   or {}
    _call_missed    = 0
    _clues          = data.clues      or {}
    _camera         = data.camera     or nil
    _terminal_lines = data.terminal_lines or nil
    _map_allowed_pois = data.map_allowed_pois or {}
    _map_all_pois_locked = data.map_all_pois_locked == true
    _current_scene  = data.current_scene
    normalize_sms_state()
    -- Восстанавливаем _msg_seq и _msg_unread по содержимому _msg.
    do
        local max_seq = 0
        local rebuilt_unread = {}
        for chat_id, chat in pairs(_msg) do
            if type(chat) == "table" then
                local unread = 0
                for _, m in ipairs(chat) do
                    local s = tonumber(m and m.seq) or 0
                    if s > max_seq then max_seq = s end
                    if m and m.unread then unread = unread + 1 end
                end
                rebuilt_unread[chat_id] = unread
            end
        end
        _msg_seq = max_seq
        _msg_unread = rebuilt_unread
    end
    normalize_notes_state()
    normalize_mails_state()
    normalize_call_log_state()
    normalize_clues_state()
    normalize_camera_state()
    if _terminal_lines == nil then
        seed_default_terminal()
    else
        normalize_terminal_state()
    end
    M._notify()
end

return M
