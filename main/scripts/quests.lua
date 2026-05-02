-- quests.lua
-- Каталог квестов игры. Данные, не код.
--
-- Воскресный flow:
--   find_phone -> reply_npc -> make_coffee -> meet_npc -> spend_sunday
--
-- go_to_office остаётся в каталоге, но НЕ стартует в воскресенье.
-- Его запускает понедельничный маршрут / рабочий день.

local M = {}

M.phone_order = {
    "find_phone",
    "reply_npc",
    "make_coffee",
    "meet_npc",
    "spend_sunday",
    "go_to_office",
}

local ORDER_INDEX = {}
for i, id in ipairs(M.phone_order) do
    ORDER_INDEX[id] = i
end

M.quests = {
    find_phone = {
        name = "Найти телефон",
        description = "Телефон вибрирует рядом с кроватью. Нужно взять его и проверить сообщение.",
        steps = {
            { text = "Подобрать телефон", done_when = "phone_taken" },
            { text = "Включить экран",    done_when = "phone_active" },
        },
    },

    reply_npc = {
        name = "Ответить коллеге",
        description = "Утром пришло личное сообщение. Нужно открыть переписку и выбрать место встречи.",
        steps = {
            {
                text = "Прочитать сообщение",
                done_when_any = { "sms_mila_read", "sms_artem_read" },
            },
            {
                text = "Выбрать место встречи",
                done_when_any = { "date_place_cafe", "date_place_park" },
            },
            {
                text = "Ответить",
                done_when_any = { "sms_mila_replied", "sms_artem_replied" },
            },
        },
    },

    make_coffee = {
        name = "Собраться перед встречей",
        description = "Перед выходом нужно прийти в себя: умыться, дойти до кухни, найти кружку и сделать кофе.",
        steps = {
            { text = "Умыться",         done_when = "washed_up" },
            { text = "Дойти до кухни",  done_when = "kitchen_morning_seen" },
            { text = "Найти кружку",    done_when = "mug_taken" },
            { text = "Сделать кофе",    done_when = "coffee_drunk" },
        },
    },

    meet_npc = {
        name = "Встретиться с коллегой",
        description = "Вы договорились увидеться сегодня. Осталось собраться, выйти из квартиры и добраться до выбранного места.",
        steps = {
            { text = "Договориться о встрече", done_when = "date_agreed" },
            {
                text = "Выбрать место",
                done_when_any = { "date_place_cafe", "date_place_park" },
            },
            { text = "Собраться",             done_when = "coffee_drunk" },
            { text = "Выйти из квартиры",     done_when = "left_apartment" },
            { text = "Открыть карту",         done_when = "map_opened_after_apartment" },
            { text = "Прийти на встречу",     done_when = "met_npc_sunday" },
        },
    },

    spend_sunday = {
        name = "Продолжить воскресенье",
        description = "После первой встречи день ещё не закончился. Можно провести немного времени вместе, вернуться домой и лечь спать.",
        steps = {
            { text = "Встретиться с коллегой", done_when = "met_npc_sunday" },
            { text = "Решить, куда пойти дальше", done_when = "sunday_after_date_active" },
            { text = "Провести ещё немного времени", done_when = "sunday_second_stop_done" },
            { text = "Вернуться домой", done_when = "sunday_evening_started" },
            { text = "Лечь спать", done_when = "sunday_finished" },
        },
    },


    go_to_office = {
        name = "Добраться до офиса",
        description = "Понедельник — рабочий день. Сначала до метро, потом две станции, и я на месте.",
        steps = {
            { text = "Выйти из дома",     done_when = "monday_left_home" },
            { text = "Доехать до метро",  done_when = "reached_metro" },
            { text = "Добраться до офиса", done_when = "reached_office" },
        },
    },
}

function M.get(id)
    return M.quests[id]
end

function M.get_order(id)
    return ORDER_INDEX[id] or math.huge
end

local function is_step_done(step, gs)
    if not step or not gs then return false end

    if step.done_when and gs.get_flag(step.done_when) then
        return true
    end

    if step.done_when_any then
        for _, flag in ipairs(step.done_when_any) do
            if flag and gs.get_flag(flag) then
                return true
            end
        end
    end

    return false
end

-- Считает выполненные/все шаги квеста по текущим флагам.
-- Возвращает done_count, total_count, steps_table (с .checked = true/false).
function M.progress(id, gs)
    local q = M.quests[id]
    if not q then return 0, 0, {} end

    local done = 0
    local steps = {}
    for i, step in ipairs(q.steps or {}) do
        local checked = is_step_done(step, gs)
        steps[i] = { text = step.text, checked = checked }
        if checked then done = done + 1 end
    end

    return done, #(q.steps or {}), steps
end

return M
