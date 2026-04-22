// ================================================================
// ТЕЛЕФОН: ПРИЛОЖЕНИЯ (запускаются из hotspot'ов сцены phone_home)
// ================================================================
// Каждый knot — короткий ink-монолог с # return_to_scene в конце, чтобы
// после просмотра игрок вернулся на сцену phone_home (её scene_controller
// запомнил в _last_scene_id при клике по hotspot'у приложения).
// phone_close — особый: # phone:close выведет игрока из phone_home
// обратно в сцену, откуда телефон был открыт (см. _phone_return_scene).

=== phone_sms
# bg:bg_phone # speaker:none
Сообщения. Одна активная ветка — от Ани.
# speaker:mc
Три строки. Все — про «PATCH temporal_sync.module».
+ [Открыть диалог с Аней]
    # flag:sms_anya_read=true
    -> anya_chat
+ [Назад]
    # goto_scene:phone_home
    -> DONE

=== anya_chat
# bg:bg_phone # speaker:none
[09:12] Аня: Привет. Проснул{mc_gender == "female":ась|ся}?
[09:13] Аня: Пришёл странный патч. Посмотри.
[09:14] PATCH temporal_sync.module
[09:14] Аня: Ты ведь чувствуешь, что с этим файлом что-то не так?
# speaker:mc
Три одинаковых строки. И один вопрос в конце. Ответить пока нечем — надо сначала увидеть модуль вживую.
# flag:sms_anya_replied=true
# quest:done:reply_anya
+ [Закрыть диалог]
    # goto_scene:phone_home
    -> DONE

=== phone_tasks
# bg:bg_phone # speaker:none
Задачи на сегодня.
# speaker:mc
— Ответить Ане.
— Добраться до офиса: квартира → метро → «Технопарк».
— PATCH temporal_sync.module. Без описания. Как обычно.
+ [Назад]
    # goto_scene:phone_home
    -> DONE

=== phone_notes
# bg:bg_phone # speaker:none
Заметки.
# speaker:mc
Пусто. Не веду. Если записывать всё, что в голову лезет в последние дни, — быстро закончится память и терпение.
+ [Назад]
    # goto_scene:phone_home
    -> DONE

=== phone_contacts
# bg:bg_phone # speaker:none
Контакты.
# speaker:mc
Аня — коллега. Сидит через два стола.
{npc_name} — тоже в команде. Номер есть, но звонить не принято.
«Авось / System» — служебный контакт. Пишет только патчи.
+ [Назад]
    # goto_scene:phone_home
    -> DONE

=== phone_close
# phone:close
-> DONE

=== phone_stub_soon ===
# bg:bg_phone # speaker:none
Эта часть приложения пока недоступна.
# speaker:mc
Скоро. Но не сегодня.
+ [Назад]
    # goto_scene:phone_home
    -> DONE
