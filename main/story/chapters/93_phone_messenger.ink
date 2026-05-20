// 93_phone_messenger.ink
// ============================================================================
// PHONE / MESSENGER THREADS
// ============================================================================
// Messenger-события и интерактивные msg_thread_<chat_id> живут здесь.
// Сценовые файлы вызывают phone_msg_* tunnel-блоки, а не держат # msg:* напрямую.
// msg_thread_* создаётся только если игрок реально должен отвечать/выбирать.
//
// Важно:
// - Messenger не смешиваем с SMS: sms_thread_* остаются в 92_phone_sms.ink.
// - chat_id должен совпадать с id, который используется в # msg:add/# msg:reply.
// - Если для chat_id нет msg_thread_<chat_id>, чат остаётся обычной inline-
//   перепиской внутри телефона без side-dialogue.
// ============================================================================

// -----------------------------------------------------------------------------
// PHONE MESSENGER EVENTS
// Сцены вызывают эти блоки через tunnel: -> phone_msg_* ->
// Здесь живут все msg:* теги, которые относятся к событиям телефона.
// -----------------------------------------------------------------------------

=== phone_msg_seed_sunday_morning ===
{mc_gender == "female":
    # msg:add_old:artem:пн:Есть планы на сегодня? Может, выберемся куда-нибудь после работы.
- else:
    # msg:add_old:mila:пн:Есть планы на сегодня? Может, выберемся куда-нибудь после работы.
}
# msg:add_old:friends:пт:Доброе утро, выжившие. Кто сегодня не отменяет планы в последний момент?
# msg:reply_old:friends:пт:Я могу отменить заранее, чтобы не рушить традицию.
# msg:add_old:work_team:пт:Планёрку в понедельник сдвинули на 10:40. Календарь говорит, что это забота.
# msg:add_old:work_team:вчера:По завтрашнему кейсу проверьте входящие перед автоответом.
# msg:add_old:prod_bot:вчера:Новый кейс создан. Часть полей ожидает подтверждения.
# msg:add_old:neighbor_chat:пн:У кого опять будильник играет с 07:00?
# msg:add_old:city_bot:вчера:Солнечно. Летний день без осадков, будто специально для прогулки.
->->

=== phone_msg_take_phone_sunday_morning ===
# msg:add:friends:Артём опять онлайн в 07:13. Подозрительно.
# msg:add:friends:Мила тоже. Вы там синхронизировались или что?
# msg:add:calendar_bot:Сегодня: встреча без названия. Место: не указано.
->->

=== phone_msg_sunday_invite_after_coffee ===
{mc_gender == "female":
    # msg:add:artem:Ты сегодня вообще живая?
    # msg:add:artem:Я уже второй кофе пью.
    # msg:add:artem:Выберемся куда-нибудь, пока день не стал совсем домашним?
    # msg:need_reply:artem
- else:
    # msg:add:mila:Ты сегодня вообще живой?
    # msg:add:mila:Я уже второй кофе пью.
    # msg:add:mila:Выберемся куда-нибудь, пока день не стал совсем домашним?
    # msg:need_reply:mila
}
->->

=== phone_msg_sunday_evening_home_thanks ===
{mc_gender == "female":
    # msg:add:artem:Спасибо за сегодня. Было хорошо.
    # msg:read:artem
- else:
    # msg:add:mila:Спасибо за сегодня. Было хорошо.
    # msg:read:mila
}
->->

=== phone_msg_sunday_evening_reply_warm ===
{mc_gender == "female":
    # msg:reply:artem:Спасибо, что продолжили день. Я рада, что мы встретились.
- else:
    # msg:reply:mila:Спасибо, что продолжили день. Я рад, что мы встретились.
}
->->

=== phone_msg_sunday_evening_reply_calm ===
{mc_gender == "female":
    # msg:reply:artem:Да. Хороший день получился.
- else:
    # msg:reply:mila:Да. Хороший день получился.
}
->->

=== phone_msg_park_arrival_prompt ===
{mc_gender == "female":
    # msg:prompt:artem:park_message_where_are_you:НАПИСАТЬ
- else:
    # msg:prompt:mila:park_message_where_are_you:НАПИСАТЬ
}
->->

=== phone_msg_park_where_reply_path ===
{mc_gender == "female":
    # msg:reply:artem:Ты где?
    # msg:add:artem:В аллее, в тени. Подходи — я тут.
- else:
    # msg:reply:mila:Ты где?
    # msg:add:mila:В аллее, в тени. Подходи — я тут.
}
# sfx:phone_notify
->->

=== phone_msg_park_where_reply_bench ===
{mc_gender == "female":
    # msg:reply:artem:Ты где?
    # msg:add:artem:У воды, ближе к лавочкам. Уже там, жду.
- else:
    # msg:reply:mila:Ты где?
    # msg:add:mila:У воды, ближе к лавочкам. Уже там, жду.
}
# sfx:phone_notify
->->

// -----------------------------------------------------------------------------
// PERSONAL THREADS
// -----------------------------------------------------------------------------

=== msg_thread_mila ===
# speaker:none
Открываешь Messenger.

Мила:
«Ты сегодня вообще живой?»
«Я уже второй кофе пью.»
«Выберемся куда-нибудь, пока день не стал совсем домашним?»

# speaker:mc
Вот теперь понятно: это приглашение. И почему-то от него становится чуть теплее.

* [«А тебе куда хочется?»]
    # speaker:none
    Ты почти пишешь первое, что приходит в голову: кафе. Тёплое, понятное, безопасное.
    Палец останавливается.

    # speaker:mc
    А тебе куда хочется?

    # msg:reply:mila:А тебе куда хочется?
    # msg:add:mila:Если честно — в парк у реки. Хочется воздуха.
    # msg:read:mila

    # speaker:npc
    Если честно — в парк у реки. Хочется воздуха.

    # speaker:mc
    Тогда в парк. Хорошо.

    # msg:reply:mila:Тогда в парк. Хорошо.
    # set_flag:date_agreed=true
    # set_flag:date_place_park=true
    ~ date_agreed = true
    ~ date_place_park = true
    ~ TRUST = TRUST + 1
    ~ INSIGHT = INSIGHT + 1
    -> msg_npc_place_sent

* [«Давай в кафе. Спокойно посидим.»]
    # speaker:none
    Ты выбираешь самый безопасный вариант: тепло, столик, кофе и разговор без лишней суеты.

    # msg:reply:mila:Давай в кафе. Спокойно посидим.
    # set_flag:date_agreed=true
    # set_flag:date_place_cafe=true
    ~ date_agreed = true
    ~ date_place_cafe = true
    ~ TRUST = TRUST + 1
    -> msg_npc_place_sent

* [«Давай в парк у реки. Хочется пройтись.»]
    # speaker:none
    В этом ответе больше воздуха, чем уверенности. Но, может, сейчас именно это и нужно.

    # msg:reply:mila:Давай в парк у реки. Хочется пройтись.
    # set_flag:date_agreed=true
    # set_flag:date_place_park=true
    ~ date_agreed = true
    ~ date_place_park = true
    ~ SYNC = SYNC + 1
    -> msg_npc_place_sent

* [Пока не отвечать]
    # msg:read:mila
    # return_to_scene
    -> DONE


=== msg_thread_artem ===
# speaker:none
Открываешь Messenger.

Артём:
«Ты сегодня вообще живая?»
«Я уже второй кофе пью.»
«Выберемся куда-нибудь, пока день не стал совсем домашним?»

# speaker:mc
Вот теперь понятно: это приглашение. И почему-то от него становится чуть теплее.

* [«А тебе куда хочется?»]
    # speaker:none
    Ты почти пишешь первое, что приходит в голову: кафе. Тёплое, понятное, безопасное.
    Палец останавливается.

    # speaker:mc
    А тебе куда хочется?

    # msg:reply:artem:А тебе куда хочется?
    # msg:add:artem:Если честно — в парк у реки. Хочется воздуха.
    # msg:read:artem

    # speaker:npc
    Если честно — в парк у реки. Хочется воздуха.

    # speaker:mc
    Тогда в парк. Хорошо.

    # msg:reply:artem:Тогда в парк. Хорошо.
    # set_flag:date_agreed=true
    # set_flag:date_place_park=true
    ~ date_agreed = true
    ~ date_place_park = true
    ~ TRUST = TRUST + 1
    ~ INSIGHT = INSIGHT + 1
    -> msg_npc_place_sent

* [«Давай в кафе. Спокойно посидим.»]
    # speaker:none
    Ты выбираешь самый безопасный вариант: тепло, столик, кофе и разговор без лишней суеты.

    # msg:reply:artem:Давай в кафе. Спокойно посидим.
    # set_flag:date_agreed=true
    # set_flag:date_place_cafe=true
    ~ date_agreed = true
    ~ date_place_cafe = true
    ~ TRUST = TRUST + 1
    -> msg_npc_place_sent

* [«Давай в парк у реки. Хочется пройтись.»]
    # speaker:none
    В этом ответе больше воздуха, чем уверенности. Но, может, сейчас именно это и нужно.

    # msg:reply:artem:Давай в парк у реки. Хочется пройтись.
    # set_flag:date_agreed=true
    # set_flag:date_place_park=true
    ~ date_agreed = true
    ~ date_place_park = true
    ~ SYNC = SYNC + 1
    -> msg_npc_place_sent

* [Пока не отвечать]
    # msg:read:artem
    # return_to_scene
    -> DONE


=== msg_npc_place_sent ===
# speaker:none
Сообщение отправлено.

Теперь у воскресенья есть адрес. Осталось одеться и выйти.

# quest:done:reply_npc
# quest:start:meet_npc
# map:lock_all
# hud:hint:phone:off
# return_to_scene
-> DONE

// -----------------------------------------------------------------------------
// WORK / SYSTEM THREADS
// -----------------------------------------------------------------------------

=== msg_thread_work_team ===
# speaker:none
Командный чат листается короткими служебными сообщениями.

ОТДЕЛ:
«Планёрка перенесена на 10:40.»

ОТДЕЛ:
«Пожалуйста, не отправляйте кейс без проверки входных данных.»

{iteration_number > 1:
Последняя фраза выглядит не как просьба, а как предупреждение.
}

* [«Ок, увидел.»]
    # msg:reply:work_team:Ок, увидел.
    # set_flag:messenger_work_team_ack=true
    # return_to_scene
    -> DONE

* [Не отвечать]
    # msg:read:work_team
    # return_to_scene
    -> DONE


=== msg_thread_prod_bot ===
# speaker:none
PROD-BOT:
«CASE-017 принят в очередь.»

PROD-BOT:
«Статус: данных недостаточно.»

PROD-BOT:
«Ожидание стандартного решения.»

# speaker:mc
Стандартное решение. Слова звучат слишком спокойно для того, что они означают.

* [Запросить недостающие поля]
    # msg:reply:prod_bot:Уточните, каких данных не хватает.
    # set_flag:messenger_prod_bot_questioned=true
    ~ INSIGHT = INSIGHT + 1
    # speaker:none
    Ответ уходит в никуда: бот не печатает, не спорит, не объясняет.
    # return_to_scene
    -> DONE

* [Закрыть чат]
    # msg:read:prod_bot
    # return_to_scene
    -> DONE


=== msg_thread_unknown ===
# speaker:none
Чат без имени. Аватар пустой.

НЕИЗВЕСТНЫЙ:
«Не соглашайся сразу.
Сначала спроси, чего не хватает.»

{iteration_number > 1:
Эта формулировка не новая. Новым кажется только то, что ты наконец читаешь её внимательно.
}

* [«Кто это?»]
    # msg:reply:unknown:Кто это?
    # set_flag:messenger_unknown_asked_who=true
    # speaker:none
    Индикатор отправки висит слишком долго. Потом исчезает, будто его и не было.
    # return_to_scene
    -> DONE

* [«Что именно нужно соединить?»]
    # msg:reply:unknown:Что именно нужно соединить?
    # set_flag:messenger_unknown_asked_synthesis=true
    ~ SYNC = SYNC + 1
    # speaker:none
    Ответа нет. Но сам вопрос почему-то кажется важнее ответа.
    # return_to_scene
    -> DONE

* [Закрыть чат]
    # msg:read:unknown
    # return_to_scene
    -> DONE
