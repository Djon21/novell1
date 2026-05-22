-- main/scripts/state/_helpers.lua
-- Общие утилиты для state-модулей: clone, format_clock, default_time-генератор.
-- Вынесено чтобы каждый канал (sms / msg / mail / calls / clues / notes)
-- не дублировал одни и те же функции у себя.

local M = {}

function M.clone_value(value)
    if type(value) ~= "table" then return value end
    local out = {}
    for k, v in pairs(value) do
        out[k] = M.clone_value(v)
    end
    return out
end

function M.clone_array(src)
    local out = {}
    if type(src) ~= "table" then return out end
    for i = 1, #src do
        out[i] = src[i]
    end
    return out
end

-- Формат "HH:MM" из абсолютного количества минут от начала суток.
function M.format_clock(total_minutes)
    total_minutes = math.max(0, math.floor(tonumber(total_minutes) or 0))
    local hours = math.floor(total_minutes / 60) % 24
    local minutes = total_minutes % 60
    return string.format("%02d:%02d", hours, minutes)
end

-- Возвращает функцию, генерирующую время для seq с базой base_minutes.
-- Используется в каналах: каждое следующее сообщение/звонок/письмо +1 минуту.
function M.make_default_time(base_minutes)
    return function(seq)
        return M.format_clock(base_minutes + math.max(0, (tonumber(seq) or 1) - 1))
    end
end

-- Создаёт счётчик seq. Возвращает 3 функции: next, get, set.
function M.make_seq()
    local n = 0
    return function() n = n + 1; return n end,
           function() return n end,
           function(v) n = math.max(n, tonumber(v) or 0) end
end

return M
