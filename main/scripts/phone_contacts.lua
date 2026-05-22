-- phone_contacts.lua
-- Presentation metadata registry for phone channels.
--
-- Contract with Ink/game_state:
--   SMS uses contact_id from tags:
--       # sms:add:<contact_id>:text
--       # sms:reply:<contact_id>:text
--     Default Ink thread: sms_thread_<contact_id>.
--
--   Messenger uses chat_id from tags:
--       # msg:add:<chat_id>:text
--       # msg:reply:<chat_id>:text
--     Default Ink thread: msg_thread_<chat_id>.
--
-- This module is presentation metadata only. It does not mutate game_state
-- and does not start Ink by itself.

local M = {}

-- ---------------------------------------------------------------------------
-- SMS contacts
-- ---------------------------------------------------------------------------
M.contacts = {
    nm = {
        name       = "Н. М.",
        number     = "+7 (916) 314-15-92",
        tag        = nil,
        tone       = "hot",
        ink_thread = "sms_thread_nm",
    },
    unknown = {
        name       = "+7 (???) ???-??-??",
        number     = "номер скрыт · CLI restricted",
        tag        = "сигнал",
        tone       = "hot",
        readonly   = true,
        ink_thread = "sms_thread_unknown",
    },
    prod = {
        name       = "Отдел · Прод",
        number     = "короткий номер 4040",
        tag        = "офис",
        tone       = "amber",
        ink_thread = "sms_thread_prod",
    },
    mama = {
        name       = "Мама",
        number     = "+7 (903) 712-04-58",
        ink_thread = "sms_thread_mama",
    },
    mila = {
        name       = "Мила",
        number     = "+7 (925) 117-03-17",
        ink_thread = "sms_thread_mila",
    },
    artem = {
        name       = "Артём",
        number     = "+7 (925) 117-03-17",
        ink_thread = "sms_thread_artem",
    },
    bank = {
        name       = "Банк · СберID",
        number     = "900",
        readonly   = true,
        tag        = "банк",
        tone       = "amber",
        ink_thread = "sms_thread_bank",
    },
    delivery = {
        name       = "Доставка",
        number     = "+7 (495) 134-08-08",
        ink_thread = "sms_thread_delivery",
    },
    upravdom = {
        name       = "Управдом",
        number     = "+7 (499) 740-19-04",
        ink_thread = "sms_thread_upravdom",
    },
    taxi = {
        name       = "Такси · ЯКС",
        number     = "+7 (495) 999-99-99",
        ink_thread = "sms_thread_taxi",
    },
    metro = {
        name       = "Метро",
        number     = "короткий номер 3210",
        readonly   = true,
        tag        = "город",
        tone       = "amber",
        ink_thread = "sms_thread_metro",
    },
    market = {
        name       = "Маркет",
        number     = "короткий номер 7070",
        readonly   = true,
        tag        = "заказ",
        tone       = "default",
        ink_thread = "sms_thread_market",
    },
    clinic = {
        name       = "Клиника",
        number     = "+7 (495) 220-14-03",
        readonly   = true,
        tag        = "запись",
        tone       = "default",
        ink_thread = "sms_thread_clinic",
    },
    coffee = {
        name       = "Кофейня рядом",
        number     = "короткий номер 5050",
        readonly   = true,
        tag        = "акция",
        tone       = "default",
        ink_thread = "sms_thread_coffee",
    },
}

-- ---------------------------------------------------------------------------
-- Messenger chats
-- ---------------------------------------------------------------------------
M.msg_chats = {
    nm        = { name = "Н. М.", av = "НМ", tone = "hot",    status = "был(а) в сети 5 мин назад", ink_thread = "msg_thread_nm" },
    loop      = { name = "loop_bot", av = "LO", tone = "violet", status = "бот · работает в фоне", bot = true, ink_thread = "msg_thread_loop" },
    prod      = { name = "Отдел · Прод", av = "ПР", tone = "amber", status = "группа · 12 участников", group = true, ink_thread = "msg_thread_prod" },
    mila      = { name = "Мила", av = "МИ", tone = "green",  status = "в сети", ink_thread = "msg_thread_mila" },
    artem     = { name = "Артём", av = "АР", tone = "green",  status = "в сети", ink_thread = "msg_thread_artem" },
    metro     = { name = "Москва · Транспорт", av = "МТ", tone = "default", status = "канал", muted = true, channel = true, ink_thread = "msg_thread_metro" },
    mama      = { name = "Мама", av = "МА", tone = "violet", status = "была в сети недавно", ink_thread = "msg_thread_mama" },
    kgb       = { name = "КГБ-чат · соседи", av = "КН", tone = "dim", status = "группа", group = true, ink_thread = "msg_thread_kgb" },
    changelog = { name = "avos · changelog", av = "АВ", tone = "amber", status = "канал", channel = true, ink_thread = "msg_thread_changelog" },
}

local function title_from_id(id)
    local s = tostring(id or "")
    if s == "" then return "—" end
    s = s:gsub("_", " "):gsub("%-", " ")
    return (s:gsub("(%S+)", function(word)
        return word:sub(1, 1):upper() .. word:sub(2)
    end))
end

local function clone_table(src)
    local out = {}
    if type(src) == "table" then
        for k, v in pairs(src) do out[k] = v end
    end
    return out
end

local function clone_contact(src, contact_id)
    local out = clone_table(src)
    out.id = contact_id
    out.name = out.name or title_from_id(contact_id)
    out.number = out.number or tostring(contact_id or "—")
    if out.ink_thread == nil and contact_id and contact_id ~= "" then
        out.ink_thread = "sms_thread_" .. tostring(contact_id)
    end
    return out
end

local function clone_msg_chat(src, chat_id)
    local out = clone_table(src)
    out.id = chat_id
    out.name = out.name or title_from_id(chat_id)
    out.tone = out.tone or "default"
    out.status = out.status or "в сети"
    if out.ink_thread == nil and chat_id and chat_id ~= "" then
        out.ink_thread = "msg_thread_" .. tostring(chat_id)
    end
    return out
end

-- ---------------------------------------------------------------------------
-- SMS API (existing call sites)
-- ---------------------------------------------------------------------------
function M.get(contact_id)
    if not contact_id or contact_id == "" then
        return clone_contact(nil, "")
    end
    return clone_contact(M.contacts[tostring(contact_id)], tostring(contact_id))
end

function M.get_name(contact_id)
    return M.get(contact_id).name
end

function M.get_number(contact_id)
    return M.get(contact_id).number
end

function M.get_tag(contact_id)
    local c = M.get(contact_id)
    return c.tone, c.tag
end

function M.get_sms_ink_thread(contact_id)
    return M.get(contact_id).ink_thread
end

function M.is_readonly(contact_id)
    return M.get(contact_id).readonly == true
end

function M.register(contact_id, data)
    if not contact_id or contact_id == "" or type(data) ~= "table" then
        return false
    end
    M.contacts[tostring(contact_id)] = data
    return true
end

-- ---------------------------------------------------------------------------
-- Messenger API
-- ---------------------------------------------------------------------------
function M.get_msg(chat_id)
    if not chat_id or chat_id == "" then
        return clone_msg_chat(nil, "")
    end
    return clone_msg_chat(M.msg_chats[tostring(chat_id)], tostring(chat_id))
end

function M.get_msg_name(chat_id)
    return M.get_msg(chat_id).name
end

function M.get_msg_ink_thread(chat_id)
    return M.get_msg(chat_id).ink_thread
end

function M.is_msg_readonly(chat_id)
    local c = M.get_msg(chat_id)
    return c.readonly == true or c.channel == true or c.bot == true
end

function M.register_msg(chat_id, data)
    if not chat_id or chat_id == "" or type(data) ~= "table" then
        return false
    end
    M.msg_chats[tostring(chat_id)] = data
    return true
end

-- Backward-compatible one-arg form:
--   get_ink_thread(contact_id)       -> sms_thread_<contact_id>
-- New explicit form:
--   get_ink_thread("sms", id)
--   get_ink_thread("msg", chat_id)
function M.get_ink_thread(kind_or_id, maybe_id)
    if maybe_id ~= nil then
        local kind = tostring(kind_or_id or "sms")
        if kind == "msg" or kind == "messenger" then
            return M.get_msg_ink_thread(maybe_id)
        end
        return M.get_sms_ink_thread(maybe_id)
    end
    return M.get_sms_ink_thread(kind_or_id)
end

return M
