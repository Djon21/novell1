-- dialogue_backlog.lua
-- Общий буфер реплик и сделанных выборов за сессию.
--
-- Зачем модуль, а не self.dialogue_backlog + msg.post:
--   В Defold msg.post имеет жёсткий лимит таблицы (sys.max_message_data_size,
--   по умолчанию 2KB). Бэклог из 80 записей кириллицы туда не влезает.
--   Вместо пересылки таблицы через шину сообщений храним её прямо в Lua-модуле.
--   При [script] shared_state = 1 все скрипты получают один и тот же модуль —
--   ui_manager_v2 пишет, dialogue_v2 читает.
--
-- API:
--   M.add(entry)   — добавить запись { kind, speaker, text, fallback_speaker? }
--   M.clear()     — очистить (новая сессия / continue)
--   M.get_all()   — получить массив записей (read-only по соглашению)
--   M.size()      — кол-во записей

local M = {}

local LIMIT = 80

local entries  = {}
local last_key = nil

local function normalize_speaker(speaker, fallback)
    speaker = tostring(speaker or "")
    if speaker == "" or speaker == "nil" then
        return fallback or "НАРРАТОР"
    end
    return string.upper(speaker)
end

function M.add(entry)
    if not entry or not entry.text or tostring(entry.text) == "" then
        return
    end

    local kind    = entry.kind or "dialogue"
    local speaker = normalize_speaker(entry.speaker, entry.fallback_speaker)
    local text    = tostring(entry.text or "")
    local key     = kind .. "|" .. speaker .. "|" .. text

    if last_key == key then
        return
    end

    entries[#entries + 1] = {
        kind    = kind,
        speaker = speaker,
        text    = text,
    }
    last_key = key

    while #entries > LIMIT do
        table.remove(entries, 1)
    end
end

function M.clear()
    entries  = {}
    last_key = nil
end

function M.get_all()
    return entries
end

function M.size()
    return #entries
end

return M
