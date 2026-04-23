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
--   _sms[contact_id]      = { {text=, unread=true/false}, ... } — порядок прихода
--   _sms_unread[contact_id] = N непрочитанных (для бейджа)
--   _notes                = { {title=, body=, time=}, ... } — порядок создания
local _sms         = {}
local _sms_unread  = {}
local _notes       = {}

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

function M.reset()
    _flags = {}
    _inventory = {}
    _quests = {}
    _sms = {}
    _sms_unread = {}
    _notes = {}
    _current_scene = nil
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

-- Внимание: возвращает прямую ссылку — не мутировать снаружи.
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
    _sms[contact_id] = _sms[contact_id] or {}
    table.insert(_sms[contact_id], { text = text, unread = true })
    _sms_unread[contact_id] = (_sms_unread[contact_id] or 0) + 1
    M._notify()
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

function M.get_sms(contact_id) return _sms[contact_id] or {} end

function M.get_sms_contacts()
    local ids = {}
    for id, _ in pairs(_sms) do table.insert(ids, id) end
    table.sort(ids)
    return ids
end

function M.get_sms_unread_total()
    local total = 0
    for _, n in pairs(_sms_unread) do total = total + n end
    return total
end

function M.get_sms_unread(contact_id) return _sms_unread[contact_id] or 0 end

-- Notes (заметки) --------------------------------------------------------
function M.add_note(title, body)
    table.insert(_notes, { title = title, body = body })
    M._notify()
end

function M.get_notes() return _notes end

-- Phone view getters (step23) --------------------------------------------
-- Возвращают списки в формате, ожидаемом phone_v2.gui_script.
-- Пока что основаны на существующих SMS/notes + пустые стабы для
-- quests/mail/calls/clues, которые будут заполняться ink-тегами позже.

-- Сообщения для SMS-вьюхи: { {from, time, body, unread}, ... }
-- Берём последние сообщения по каждому контакту (по одной карточке на
-- контакт), сортируем по порядку добавления контакта.
function M.get_messages()
    local out = {}
    local ids = {}
    for id, _ in pairs(_sms) do table.insert(ids, id) end
    table.sort(ids)
    for _, id in ipairs(ids) do
        local chat = _sms[id]
        if chat and #chat > 0 then
            local last = chat[#chat]
            local unread_n = _sms_unread[id] or 0
            table.insert(out, {
                from   = id,
                time   = last.time or "",
                body   = last.text or "",
                unread = unread_n > 0,
            })
        end
    end
    return out
end

-- Почта: { {from, subject, unread}, ... }. Пока нет хранилища — пустой список.
-- TODO: добавить _mails + add_mail/mark_mail_read когда появятся ink-теги.
function M.get_mails()
    return {}
end

-- Журнал звонков: { {who, time, missed}, ... }. Пустой стаб.
-- TODO: добавить _call_log + add_call.
function M.get_call_log()
    return {}
end

-- Улики: { {id, label}, ... }. Пустой стаб.
-- TODO: завести _clues + add_clue (можно шарить с notes).
function M.get_clues()
    return {}
end

-- Квесты для phone-вьюхи: { {title, status, progress}, ... }.
-- Берём из _quests ({ [id] = "active"|"done"|"failed" }). progress пока пустой.
function M.get_quests()
    local quests_catalog = require "main.scripts.quests"
    local out = {}
    local ids = {}
    for id, _ in pairs(_quests) do table.insert(ids, id) end
    table.sort(ids)
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
        flags         = _flags,
        inventory     = clone_array(_inventory),
        quests        = _quests,
        sms           = _sms,
        sms_unread    = _sms_unread,
        notes         = _notes,
        current_scene = _current_scene,
    }
end

function M.deserialize(data)
    if not data then
        M.reset()
        return
    end
    _flags         = data.flags      or {}
    _inventory     = sanitize_inventory(data.inventory)
    _quests        = data.quests     or {}
    _sms           = data.sms        or {}
    _sms_unread    = data.sms_unread or {}
    _notes         = data.notes      or {}
    _current_scene = data.current_scene
    M._notify()
end

return M
