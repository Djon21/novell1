// 93_phone_messenger.ink
// ============================================================================
// PHONE / MESSENGER THREADS
// ============================================================================
// Все msg_thread_<chat_id> живут здесь.
// Сюжетные файлы добавляют сообщения через # msg:add:<chat_id>:text.
// Ответы игрока пишутся через # msg:reply:<chat_id>:text.
//
// Важно:
// - Messenger не смешиваем с SMS: sms_thread_* остаются в 92_phone_sms.ink.
// - chat_id должен совпадать с id, который используется в # msg:add/# msg:reply.
// - Если для chat_id нет msg_thread_<chat_id>, чат остаётся обычной inline-
//   перепиской внутри телефона без side-dialogue.
// ============================================================================

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
