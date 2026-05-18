-- game_state.lua
-- Единый источник правды для point-and-click слоя.
-- Хранит flags, inventory, quests, current_scene + terminal/map_pois.
-- Канальные домены (sms, messenger, mail, calls, clues, notes) вынесены
-- в main/scripts/state/<channel>.lua — этот файл их подключает и
-- ре-экспортирует как M.add_sms / M.get_messages / etc. для обратной
-- совместимости со всем кодом, который ходит за gs.add_sms(...).
--
-- Подписчики получают M._notify() при любом изменении.
-- Сериализация — snapshot для save_manager.set_game_state(state).

local log = require "main.scripts.log"

-- Channel state-модули. У каждого свои _state, normalize, serialize.
-- Зависимости (notify_cb, set_flag_cb) пробрасываем ниже после M._notify.
local sms_state       = require "main.scripts.state.sms"
local messenger_state = require "main.scripts.state.messenger"
local mail_state      = require "main.scripts.state.mail"
local calls_state     = require "main.scripts.state.calls"
local clues_state     = require "main.scripts.state.clues"
local notes_state     = require "main.scripts.state.notes"
local H               = require "main.scripts.state._helpers"

local M = {}

M.MAX_INVENTORY_SLOTS = 12

-- Приватное состояние, оставшееся в game_state (нечанальные домены)
local _flags       = {}
local _inventory   = {}
local _quests      = {}
local _current_scene = nil
local _listeners   = {}

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

local TERMINAL_MAX_LINES = 4
local DEFAULT_TERMINAL_LINES = {
    { level = "ok",     text = "[OK] AVOS-CLI ready"     },
    { level = "info",   text = "$ help"                  },
    { level = "info",   text = "1. logs · 2. cam · 3. ?" },
    { level = "prompt", text = "_"                       },
}
local _terminal_lines = {}

local QUEST_STATUS_PRIORITY = {
    active = 1,
    failed = 2,
    done = 3,
}

-- ---------------------------------------------------------------------------
-- Helpers (только общие, channel-specific уехали в state/_helpers.lua)
-- ---------------------------------------------------------------------------

local function sanitize_inventory(src)
    local out = {}
    local seen = {}
    if type(src) ~= "table" then return out end
    for _, id in ipairs(src) do
        if id ~= nil and id ~= "" and not seen[id] then
            if #out >= M.MAX_INVENTORY_SLOTS then
                log.warn("game_state", "inventory overflow on deserialize, dropping:", tostring(id))
            else
                table.insert(out, id)
                seen[id] = true
            end
        end
    end
    return out
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
        if not TERMINAL_LEVELS[level] then level = "plain" end
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

-- ---------------------------------------------------------------------------
-- Реактивные подписки + notify (нужен ДО channel set_deps)
-- ---------------------------------------------------------------------------

function M.subscribe(cb)
    table.insert(_listeners, cb)
end

function M._notify()
    for _, cb in ipairs(_listeners) do
        pcall(cb)
    end
end

-- ---------------------------------------------------------------------------
-- Flags (нужны до channel set_deps, т.к. sms/msg ставят auto-флаги read/replied)
-- ---------------------------------------------------------------------------

function M.get_flag(name) return _flags[name] end

function M.set_flag(name, value)
    if _flags[name] == value then return end
    _flags[name] = value
    M._notify()
end

-- Внутренний setter для channel-модулей (не нотифицирует — channel сам
-- вызовет notify_cb после set_flag). Иначе будет двойной notify.
local function set_flag_internal(name, value)
    if _flags[name] == value then return end
    _flags[name] = value
end

-- Подключаем зависимости в channel-модули.
sms_state.set_deps      ({ notify = M._notify, set_flag = set_flag_internal })
messenger_state.set_deps({ notify = M._notify, set_flag = set_flag_internal })
mail_state.set_deps     ({ notify = M._notify })
calls_state.set_deps    ({ notify = M._notify })
clues_state.set_deps    ({ notify = M._notify })
notes_state.set_deps    ({ notify = M._notify })

-- ---------------------------------------------------------------------------
-- Reset (полный сброс всего state)
-- ---------------------------------------------------------------------------

function M.reset()
    _flags = {}
    _inventory = {}
    _quests = {}
    sms_state.reset()
    messenger_state.reset()
    mail_state.reset()
    calls_state.reset()
    clues_state.reset()
    notes_state.reset()
    _map_allowed_pois = {}
    _map_all_pois_locked = false
    seed_default_terminal()
    _current_scene = nil
    M._notify()
end

-- ---------------------------------------------------------------------------
-- Inventory
-- ---------------------------------------------------------------------------

function M.has_item(id)
    for _, v in ipairs(_inventory) do
        if v == id then return true end
    end
    return false
end

function M.add_item(id)
    if not id or id == "" then return false end
    if M.has_item(id) then return false end
    if #_inventory >= M.MAX_INVENTORY_SLOTS then
        log.warn("game_state", "inventory is full, cannot add:", tostring(id))
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

function M.get_inventory() return H.clone_array(_inventory) end

-- ---------------------------------------------------------------------------
-- Quests
-- ---------------------------------------------------------------------------

function M.get_quest(id) return _quests[id] end

function M.set_quest(id, status)
    if _quests[id] == status then return end
    _quests[id] = status
    M._notify()
end

-- ---------------------------------------------------------------------------
-- Current scene
-- ---------------------------------------------------------------------------

function M.get_scene() return _current_scene end

function M.set_scene(id)
    _current_scene = id
    M._notify()
end

-- ---------------------------------------------------------------------------
-- SMS — делегаты в state/sms.lua
-- ---------------------------------------------------------------------------
M.add_sms              = sms_state.add
M.reply_sms            = sms_state.reply
M.mark_sms_read        = sms_state.mark_read
M.mark_all_sms_read    = sms_state.mark_all_read
M.get_sms              = sms_state.get
M.get_sms_contacts     = sms_state.get_contacts
M.get_sms_unread_total = sms_state.get_unread_total
M.get_sms_unread       = sms_state.get_unread
M.set_sms_tag          = sms_state.set_tag
M.get_sms_tag          = sms_state.get_tag

-- ---------------------------------------------------------------------------
-- Messenger — делегаты в state/messenger.lua
-- ---------------------------------------------------------------------------
M.add_msg              = messenger_state.add
M.reply_msg            = messenger_state.reply
M.mark_msg_read        = messenger_state.mark_read
M.mark_all_msg_read    = messenger_state.mark_all_read
M.get_msg              = messenger_state.get
M.get_msg_chats        = messenger_state.get_chats
M.get_msg_unread_total = messenger_state.get_unread_total
M.get_msg_unread       = messenger_state.get_unread
M.set_msg_tag          = messenger_state.set_tag
M.get_msg_tag          = messenger_state.get_tag
M.set_msg_prompt       = messenger_state.set_prompt
M.get_msg_prompt       = messenger_state.get_prompt
M.clear_msg_prompt     = messenger_state.clear_prompt

-- ---------------------------------------------------------------------------
-- Notes
-- ---------------------------------------------------------------------------
M.add_note             = notes_state.add
M.get_notes            = notes_state.get

-- ---------------------------------------------------------------------------
-- Mail
-- ---------------------------------------------------------------------------
M.add_mail               = mail_state.add
M.mark_mail_read         = mail_state.mark_read
M.mark_all_mail_read     = mail_state.mark_all_read
M.get_mails              = mail_state.get_mails
M.get_mail_unread_total  = mail_state.get_unread_total

-- ---------------------------------------------------------------------------
-- Calls
-- ---------------------------------------------------------------------------
M.add_call               = calls_state.add
M.mark_all_calls_seen    = calls_state.mark_all_seen
M.get_call_log           = calls_state.get_log
M.get_call_missed_total  = calls_state.get_missed_total

-- ---------------------------------------------------------------------------
-- Clues
-- ---------------------------------------------------------------------------
M.add_clue               = clues_state.add
M.has_clue               = clues_state.has
M.get_clues              = clues_state.get

-- ---------------------------------------------------------------------------
-- SMS-сводка для phone_v2.gui_script (форматирует sms_state в нужный вид).
-- Возвращает { {from, time, body, direction, unread}, ... }, отсортировано
-- по актуальности последнего сообщения.
-- ---------------------------------------------------------------------------
function M.get_messages()
    local out = {}
    for _, id in ipairs(M.get_sms_contacts()) do
        local chat = M.get_sms(id)
        if chat and #chat > 0 then
            local last = chat[#chat]
            local unread_n = M.get_sms_unread(id) or 0
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

-- ---------------------------------------------------------------------------
-- Terminal log
-- ---------------------------------------------------------------------------

function M.add_terminal_line(level, text)
    if not TERMINAL_LEVELS[level] then level = "plain" end
    table.insert(_terminal_lines, { level = level, text = tostring(text or "") })
    while #_terminal_lines > TERMINAL_MAX_LINES do
        table.remove(_terminal_lines, 1)
    end
    M._notify()
end

function M.clear_terminal()
    _terminal_lines = {}
    M._notify()
end

function M.reset_terminal_to_defaults()
    seed_default_terminal()
    M._notify()
end

function M.get_terminal_lines()
    local out = {}
    for i = 1, #_terminal_lines do
        out[i] = { level = _terminal_lines[i].level, text = _terminal_lines[i].text }
    end
    return out
end

-- ---------------------------------------------------------------------------
-- Map POI lock
-- ---------------------------------------------------------------------------

function M.map_allow(poi_id)
    if not poi_id or poi_id == "" then return end
    _map_allowed_pois[poi_id] = true
    _map_all_pois_locked = false
    M._notify()
end

function M.map_allow_reset()
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
    -- Если allowed-set пуст, считаем что все POI разрешены (default behaviour).
    if next(_map_allowed_pois) == nil then return true end
    return _map_allowed_pois[poi_id] == true
end

function M.get_map_allowed_pois()
    local out = {}
    for id, _ in pairs(_map_allowed_pois) do out[id] = true end
    return out
end

function M.is_map_all_pois_locked()
    return _map_all_pois_locked == true
end

-- ---------------------------------------------------------------------------
-- Quests + phone-вьюха
-- ---------------------------------------------------------------------------

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
        if priority_a ~= priority_b then return priority_a < priority_b end

        local order_a = quests_catalog.get_order and quests_catalog.get_order(a) or math.huge
        local order_b = quests_catalog.get_order and quests_catalog.get_order(b) or math.huge
        if order_a ~= order_b then return order_a < order_b end

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

-- ---------------------------------------------------------------------------
-- Сериализация — собираем snapshot из всех каналов + локальных доменов
-- ---------------------------------------------------------------------------

function M.serialize()
    local snap = {
        flags          = _flags,
        inventory      = H.clone_array(_inventory),
        quests         = _quests,
        terminal_lines = H.clone_value(_terminal_lines),
        map_allowed_pois = H.clone_value(_map_allowed_pois),
        map_all_pois_locked = _map_all_pois_locked == true,
        current_scene  = _current_scene,
    }
    -- Channel snapshots — каждый возвращает таблицу со своими ключами,
    -- которые мы мерджим в общий snapshot.
    for _, ch in ipairs({ sms_state, messenger_state, mail_state, calls_state, clues_state, notes_state }) do
        for k, v in pairs(ch.serialize() or {}) do
            snap[k] = v
        end
    end
    return snap
end

function M.deserialize(data)
    if not data then
        M.reset()
        return
    end
    _flags          = data.flags      or {}
    _inventory      = sanitize_inventory(data.inventory)
    _quests         = data.quests     or {}
    _terminal_lines = data.terminal_lines or nil
    _map_allowed_pois = data.map_allowed_pois or {}
    _map_all_pois_locked = data.map_all_pois_locked == true
    _current_scene  = data.current_scene
    -- Делегируем каждому channel-модулю восстановление + normalize.
    sms_state.deserialize(data)
    messenger_state.deserialize(data)
    mail_state.deserialize(data)
    calls_state.deserialize(data)
    clues_state.deserialize(data)
    notes_state.deserialize(data)
    if _terminal_lines == nil then
        seed_default_terminal()
    else
        normalize_terminal_state()
    end
    M._notify()
end

return M
