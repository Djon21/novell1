-- phone_contacts.lua
-- Display metadata for SMS contacts.
--
-- Contract with Ink/game_state:
--   - contact_id is the same id used in Ink tags:
--       # sms:add:<contact_id>:text
--       # sms:reply:<contact_id>:text
--   - By default, the related Ink thread knot is "sms_thread_<contact_id>".
--   - Override `ink_thread` per contact when a thread uses a custom knot name.
--
-- phone_sms.gui_script uses this module only for presentation metadata.
-- It does not mutate game_state and does not start Ink by itself.

local M = {}

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

local function title_from_id(contact_id)
    local s = tostring(contact_id or "")
    if s == "" then return "—" end
    s = s:gsub("_", " "):gsub("%-", " ")
    return (s:gsub("(%S+)", function(word)
        return word:sub(1, 1):upper() .. word:sub(2)
    end))
end

local function clone_contact(src, contact_id)
    local out = {}
    if type(src) == "table" then
        for k, v in pairs(src) do out[k] = v end
    end
    out.id = contact_id
    out.name = out.name or title_from_id(contact_id)
    out.number = out.number or tostring(contact_id or "—")
    if out.ink_thread == nil and contact_id and contact_id ~= "" then
        out.ink_thread = "sms_thread_" .. tostring(contact_id)
    end
    return out
end

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

function M.get_ink_thread(contact_id)
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

return M
