-- quests.lua
-- Каталог phone quests текущей итерации. Данные, не код.
--
-- ВАЖНО:
-- Это НЕ persistent loop journal.
-- Эти квесты живут в game_state и сбрасываются при старте новой итерации.
-- Они нужны для текущих целей игрока внутри run-state:
-- найти телефон, ответить NPC, собраться, добраться до офиса и т.п.
--
-- Долгосрочные выводы о петле, ложных концовках и гипотезах игрока
-- должны жить в meta_state или отдельном persistent journal module.
--
-- Воскресный flow:
--   find_phone -> make_coffee -> reply_npc -> meet_npc -> spend_sunday
--
-- Приглашение на встречу приходит в Messenger после бытового утреннего блока.
--
-- go_to_office остаётся в каталоге, но НЕ стартует в воскресенье.
-- Его запускает monday_morning_start; воскресенье его не стартует.

local M = {}

M.phone_order = {
    "make_coffee",
    "check_the_loop",
    "reply_npc",
    "meet_npc",
    "reveal_the_loop",
    "spend_sunday",
    "go_to_office",
    "work_monday_case",
    "follow_monday_trace",
    "break_the_loop",
}

M.phone_order_iter1 = {
    "make_coffee",
    "reply_npc",
    "meet_npc",
    "spend_sunday",
    "go_to_office",
    "work_monday_case",
    "follow_monday_trace",
}

M.phone_order_iter2 = {
    "check_the_loop",
    "loop2_date",
    "reveal_the_loop",
    "break_the_loop",
}

local ORDER_INDEX = {}
for i, id in ipairs(M.phone_order) do
    ORDER_INDEX[id] = i
end

M.quests = {
    reply_npc = {
        name = "Договориться о встрече",
        description = "После утренних дел пришло личное сообщение. Нужно открыть Messenger и договориться о встрече.",
        steps = {
            {
                text = "Прочитать сообщение",
                done_when_any = { "msg_mila_read", "msg_artem_read" },
            },
            {
                text = "Выбрать место и ответить",
                done_when_any = { "date_place_cafe", "date_place_park" },
            },
        },
    },

    make_coffee = {
        name = "Утренние дела",
        description = "Умыться и сделать кофе, чтобы нормально войти в день. После этого станет понятнее, что делать дальше.",
        steps = {
            { text = "Умыться",      done_when = "washed_up" },
            { text = "Сделать кофе", done_when = "coffee_drunk" },
        },
    },

    meet_npc = {
        name = "Встретиться",
        description = "Вы договорились увидеться сегодня. Осталось собраться, выйти из квартиры и добраться до выбранного места.",
        steps = {
            { text = "Собраться и выйти",    done_when = "sunday_ready_to_leave" },
            { text = "Купить подарок",        done_when = "sunday_gift_bought" },
            { text = "Встретиться и поговорить", done_when = "met_npc_sunday" },
        },
    },

    spend_sunday = {
        name = "Продолжить воскресенье",
        description = "После первой встречи день ещё не закончился. Можно провести немного времени вместе, вернуться домой и лечь спать.",
        steps = {
            { text = "Решить, куда пойти дальше", done_when = "sunday_after_date_active" },
            { text = "Провести ещё немного времени", done_when = "sunday_second_stop_done" },
            { text = "Вернуться домой", done_when = "sunday_evening_started" },
            { text = "Лечь спать", done_when = "sunday_finished" },
        },
    },


    go_to_office = {
        name = "Добраться до офиса",
        description = "Понедельник — рабочий день. Офис ближе воскресных маршрутов: собраться и дойти до бизнес-центра.",
        steps = {
            { text = "Добраться до офиса",      done_when = "reached_office" },
        },
    },

    work_monday_case = {
        name = "Закрыть рабочий кейс",
        description = "На рабочем этаже нужно пройти турникет, собрать материалы по кейсу, подготовить папку и передать её в систему.",
        steps = {
            { text = "Пройти турникет",          done_when = "monday_checked_in_office" },
            { text = "Проверить почту и взять распечатку", done_when = "monday_mail_read" },
            { text = "Найти папку",              done_when = "monday_folder_taken" },
            { text = "Собрать папку по кейсу",   done_when = "monday_case_file_assembled" },
            { text = "Передать кейс в работу",   done_when = "monday_case_file_submitted" },
            { text = "Увидеть стандартное решение", done_when = "mon_office_error_seen" },
        },
    },

    follow_monday_trace = {
        name = "Проверить последствия",
        description = "Вторник показывает, что вчерашнее стандартное решение не исчезло. Нужно увидеть след, разобраться с кейсом и дойти до разговора на крыше.",
        steps = {
            { text = "Проверить телефон",          done_when = "tuesday_phone_checked" },
            { text = "Выйти из дома",              done_when = "tuesday_left_home" },
            { text = "Увидеть последствие кейса",  done_when = "tuesday_consequence_seen" },
            { text = "Разобрать след",             done_when = "tuesday_investigation_done" },
            { text = "Подняться на крышу",         done_when = "tuesday_rooftop_reached" },
        },
    },

    -- iteration 2+ квесты
    -- Запускаются только при второй и последующих итерациях.

    check_the_loop = {
        name = "Проверить день",
        description = "Сегодня не понедельник, а странная среда. Нужно собраться, проверить офис и понять, что происходит.",
        steps = {
            { text = "Умыться и сделать кофе",     done_when = "coffee_drunk" },
            { text = "Ответить на сообщение",      done_when = "loop2_first_invite_rejected" },
            { text = "Проверить офис",             done_when = "loop2_work_check_done" },
            { text = "Вернуться домой",            done_when = "loop2_returned_home" },
            { text = "Принять реальность",         done_when = "anomaly_interpreted" },
        },
    },

    loop2_date = {
        name = "Ещё один день",
        description = "Реальность принята. NPC написал снова — пора ответить, собраться и пойти на встречу.",
        steps = {
            { text = "Ответить на приглашение", done_when = "date_agreed" },
            { text = "Собраться на встречу",    done_when = "sunday_ready_to_leave" },
            { text = "Провести время вместе",   done_when = "met_npc_sunday" },
        },
    },

    reveal_the_loop = {
        name = "Довериться",
        description = "Во второй раз всё иначе. Можно рассказать спутнику о петле времени. Это рискованно, но может всё изменить.",
        steps = {
            { text = "Рассказать о петле",           done_when = "loop2_revealed_to_npc" },
            { text = "Обсудить в баре",              done_when = "bar_discussion_done" },
            { text = "Договориться о понедельнике",  done_when = "loop2_office_mentioned" },
            { text = "Проснуться с планом",          done_when = "loop2_monday_aware" },
        },
    },

    break_the_loop = {
        name = "Разорвать петлю",
        description = "Крыша — место истины. Пора собрать всё, что стало известно за три дня, и решить, как разорвать этот круг.",
        steps = {
            { text = "Осознать корень петли",  done_when = "tuesday_investigation_done" },
            { text = "Подняться на крышу",     done_when = "tuesday_rooftop_reached" },
            { text = "Выбрать исход",           done_when = "current_iteration_end" },
        },
    },
}

function M.get(id)
    return M.quests[id]
end

function M.get_order(id)
    return ORDER_INDEX[id] or math.huge
end

-- Возвращает правильный phone_order для текущей итерации.
-- iter_number = tonumber из meta_state.get("iteration_number") или 1.
function M.get_order_for_iteration(iter_number)
    return (tonumber(iter_number) or 1) >= 2 and M.phone_order_iter2 or M.phone_order_iter1
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
