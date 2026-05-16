// ================================================================
// AVOS_S - 17_sunday_evening.ink
// Вечер воскресенья: возврат домой, переписка, сон, переход к понедельнику.
// ================================================================

=== sunday_home_after_date_router ===
{sunday_after_date_active and not sunday_second_stop_done:
    -> sunday_home_too_early
- else:
    -> sunday_evening_home
}

=== sunday_home_too_early ===
# speaker:none
Домой пока рано. День только начал становиться настоящим воскресеньем.

# speaker:mc
Нет. Сначала ещё куда-нибудь. Не хочется обрывать всё сразу.

# phone:map
-> DONE

=== sunday_evening_home ===
# bg:bg_apartment_bedroom_night # speaker:none
Квартира встречает тем же спокойствием, с которого началось утро. Только теперь оно ощущается иначе: не как список дел, а как место, куда можно вернуться.

Телефон вибрирует уже без тревоги — короткое сообщение от {npc_name_gen}.

# sfx:phone_notify
{mc_gender == "female":
    # msg:add:artem:Спасибо за сегодня. Было хорошо.
    # msg:read:artem
- else:
    # msg:add:mila:Спасибо за сегодня. Было хорошо.
    # msg:read:mila
}

# speaker:npc
Спасибо за сегодня. Было хорошо.

# speaker:mc
Мне тоже.

# speaker:none
Сообщение остаётся на экране чуть дольше, чем нужно. День наконец-то складывается в цельную форму: утро, встреча, прогулка, возвращение.

* [Ответить тепло]
    # speaker:mc
    Спасибо, что продолжили день. Я рад{mc_gender == "female":а|}, что мы встретились.

    {mc_gender == "female":
        # msg:reply:artem:Спасибо, что продолжили день. Я рада, что мы встретились.
    - else:
        # msg:reply:mila:Спасибо, что продолжили день. Я рад, что мы встретились.
    }

    # speaker:none
    Ответ уходит сразу. В нём нет ничего громкого, но есть точность.
    ~ TRUST = TRUST + 1
    -> sunday_evening_finish

* [Ответить спокойно]
    # speaker:mc
    Да. Хороший день получился.

    {mc_gender == "female":
        # msg:reply:artem:Да. Хороший день получился.
    - else:
        # msg:reply:mila:Да. Хороший день получился.
    }

    # speaker:none
    Простые слова подходят лучше длинных. Воскресенье не требует отчёта.
    ~ SYNC = SYNC + 1
    -> sunday_evening_finish

* [Не отвечать сразу]
    # speaker:none
    Ты оставляешь сообщение открытым. Не из холодности — просто хочется ещё немного побыть внутри этого дня, не превращая его в переписку.
    ~ INSIGHT = INSIGHT + 1
    -> sunday_evening_finish

=== sunday_evening_finish ===
# speaker:none
Вечер постепенно собирает квартиру вокруг тебя: коридор, кухня, свет из окна, телефон на ладони.

Завтра понедельник. Рабочий день, офис, обычные маршруты.

Но сегодня пока ещё воскресенье.

# speaker:mc
Пора в спальню. Иначе понедельник начнётся раньше, чем я успею лечь.

# set_flag:sunday_evening_started=true
~ sunday_evening_started = true
# goto_scene:apartment_bedroom
-> DONE

=== sunday_sleep_in_bed ===
# bg:bg_apartment_bedroom_night # speaker:none
Спальня выглядит почти так же, как утром, только свет стал мягче и ниже.

Кровать всё ещё помнит смятое одеяло, тяжёлый сон и то воскресное утро, которое начиналось с вибрации телефона.

# speaker:mc
Вот теперь день правда закончился.

# speaker:none
Телефон ложится на тумбочку экраном вниз.

На этот раз он молчит.

Ты закрываешь глаза — не потому что всё понятно, а потому что воскресенье наконец-то стало целым днём: утро, встреча, прогулка, возвращение.

Понедельник придёт сам.

# set_flag:sunday_finished=true
# set_flag:monday_started=true
# quest:done:spend_sunday
# map:allow:reset
~ sunday_finished = true
~ monday_started = true
-> monday_morning_start
