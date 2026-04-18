-- quests.lua
-- Каталог квестов игры. Данные, не код.
--
-- Поля:
--   name        — название квеста (показывается в списке телефона)
--   description — краткое описание (показывается при раскрытии карточки)
--   steps       — массив шагов. Каждый шаг: { text, done_when = flag_name }
--                 Шаг считается выполненным, если gs.get_flag(done_when) истинен.
--                 Если done_when отсутствует — шаг никогда не помечается сам,
--                 меняется вручную через gs.set_flag(...) из ink.
--   auto_done   — имя флага. Если истинен — весь квест помечается done.
--                 (альтернатива прохождению всех шагов; удобно для кейсов,
--                 где квест завершается не последним шагом, а внешним триггером).
--
-- Статусы живут в gs._quests[id]: "active" | "done" | "failed".
-- Старт квеста: ink-тег  # quest:start:<id>  → gs.set_quest(id, "active")
-- Завершение:   ink-тег  # quest:done:<id>   → gs.set_quest(id, "done")

local M = {}

M.quests = {
    reply_anya = {
        name = "Ответить Ане",
        description = "Аня прислала странные сообщения с ссылкой на " ..
                      "PATCH temporal_sync.module. Надо разобраться, " ..
                      "что она имела в виду, и ответить.",
        steps = {
            { text = "Прочитать сообщения от Ани", done_when = "sms_anya_read" },
            { text = "Ответить Ане",               done_when = "sms_anya_replied" },
        },
    },

    go_to_office = {
        name = "Добраться до офиса",
        description = "Обычный рабочий день. Сначала до метро, " ..
                      "потом две станции, и я на месте.",
        steps = {
            { text = "Выйти из квартиры",    done_when = "left_apartment" },
            { text = "Доехать до метро",     done_when = "reached_metro"   },
            { text = "Добраться до офиса",   done_when = "reached_office"  },
        },
    },
}

function M.get(id) return M.quests[id] end

-- Считает выполненные/все шаги квеста по текущим флагам.
-- Возвращает done_count, total_count, steps_table (с .checked = true/false).
function M.progress(id, gs)
    local q = M.quests[id]
    if not q then return 0, 0, {} end
    local done = 0
    local steps = {}
    for i, step in ipairs(q.steps or {}) do
        local checked = step.done_when and gs.get_flag(step.done_when) or false
        steps[i] = { text = step.text, checked = checked }
        if checked then done = done + 1 end
    end
    return done, #(q.steps or {}), steps
end

return M
