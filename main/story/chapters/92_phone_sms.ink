// 92_phone_sms.ink
// ============================================================================
// PHONE / SMS THREADS
// ============================================================================
// В текущей версии все SMS-чаты — read-only.
//
// ВАЖНО: для read-only SMS нельзя создавать `=== sms_thread_<contact> ===`.
// Само наличие thread-knot'а является сигналом UI, что input/SEND может открыть
// интерактивный Ink-ответ, из-за чего кнопка SEND может мигать/становиться
// активной даже если внутри thread стоит no-op.
//
// Старые и новые SMS добавляются через phone_sms_* event-knot'ы ниже.
// Сюжетные файлы должны вызывать их tunnel'ом (`-> phone_sms_* ->`),
// а не держать `# sms:*` / `# bank:*` напрямую.
//
// Если в будущем появится SMS, на которое игрок действительно должен ответить,
// тогда для этого контакта можно заново добавить `sms_thread_<contact>` и
// управлять ожиданием ответа через `sms:need_reply` / `sms:reply`.
// ============================================================================


// -----------------------------------------------------------------------------
// PHONE SMS EVENTS
// Сцены вызывают эти блоки через tunnel: -> phone_sms_* ->
// Здесь живут все sms:* и bank:* теги. Read-only SMS не получают sms_thread_*.
// -----------------------------------------------------------------------------

=== phone_sms_seed_sunday_morning ===
# sms:add_old:bank:чт:Карта *4821: списание 1 180 ₽. Такси. Баланс 284 360 ₽.
# sms:add_old:bank:пт:Карта *4821: списание 7 430 ₽. Маркет у дома. Баланс 276 930 ₽.
# sms:add_old:bank:сб:Карта *4821: списание 740 ₽. Кофейня «петля». Баланс 276 190 ₽.
# sms:add_old:bank:сб:Карта *4821: списание 3 890 ₽. Ресторан. Баланс 272 300 ₽.
# sms:add_old:bank:сб:Карта *4821: списание 71 ₽. Метро. Баланс 272 229 ₽.
# bank:set:272229
# sms:add_old:delivery:ср:Самокат: заказ №51988 доставлен. Пакет оставлен у консьержа.
# sms:add_old:delivery:пт:Ozon: заказ №18406 готов к выдаче до 21:00. Постамат у метро.
# sms:add_old:delivery:пт:Заказ №74021 оставлен у двери. Курьер завершил доставку.
# sms:add_old:upravdom:пн:Плановая проверка пожарной сигнализации 23 апр. Возможны короткие звуковые сигналы.
# sms:add_old:upravdom:ср:Лифт №1 временно работает с задержками. Сервисная служба вызвана.
# sms:add_old:upravdom:чт:Отключение горячей воды 24–26 апр. Ремонт стояка в подъезде №2.
# sms:add_old:taxi:вт:Поездка завершена. 980 ₽. Дом — офис. Спасибо, что выбрали ЯКС.
# sms:add_old:taxi:чт:Поездка завершена. 1 180 ₽. Оцените водителя в приложении.
# sms:add_old:taxi:сб:Поездка завершена. 760 ₽. Кофейня «петля» — дом.
# sms:add_old:mama:пн:Ты куртку забрал{mc_gender == "female":а|}? По вечерам уже обманчиво тепло.
# sms:reply_old:mama:пн:Забрал{mc_gender == "female":а|}. Всё нормально.
# sms:add_old:mama:ср:Я не контролирую, я просто проверяю, что ты жив{mc_gender == "female":а|}. Это разные вещи.
# sms:reply_old:mama:ср:Жив{mc_gender == "female":а|}. Завал на работе, потом наберу.
# sms:add_old:mama:сб:Если будешь в магазине, возьми что-нибудь нормальное домой. Не только кофе.
# sms:reply_old:mama:сб:Хорошо, мам. Возьму.
# sms:add_old:mama:сб:У тебя в понедельник обычный день? Или опять какой-нибудь аврал?
# sms:reply_old:mama:сб:Пока обычный. Сам{mc_gender == "female":а|} удивляюсь.
# sms:add_old:mama:сб:Тогда за выходные выспись. И не спорь с телефоном перед сном.
# sms:add_old:prod:сб:Прод упал. Тех. долг догнал. Подними, пожалуйста.
->->

=== phone_sms_take_phone_sunday_morning ===
// Сегодняшние свежие беспокойства поверх истории.
// mama — обычная утренняя забота.
// prod — пятничный кейс догнал в воскресенье.
// unknown — атмосферный hook, hot+tag.
# sms:add:mama:Доброе утро. Позавтракай, пожалуйста. И не превращай воскресенье в ещё один рабочий день.
# sms:add:prod:Напоминание: в понедельник до 11:00 подтвердите статус по кейсу 017.
# sms:add_hot:unknown:Не торопись.
# sms:add_hot:unknown:Сначала прочитай.
# sms:tag:unknown:hot:сигнал
# sms:tag:prod:amber:офис
->->

=== phone_sms_tuesday_case_followup ===
// SMS от NPC — эмоционально нагруженное, помечаем как hot.
// Pin-тег "amber:важное" на чат: это рабочее последствие, не "сигнал".
// Условия намеренно разложены в бинарные блоки, без вложенного switch внутри gender-ветки:
// так меньше риск случайно смешать ink-синтаксис `{condition: ... - else: ...}` и `{ - condition: ... }`.
{mc_gender == "female":
    {office_clarification_requested:
        # sms:add_hot:artem:Ты видела рабочий чат? Твой запрос по кейсу всплыл. Нам лучше поговорить до вечера.
    - else:
        {office_auto_solution_blocked:
            # sms:add_hot:artem:Ты видела рабочий чат? Заблокированный кейс всплыл. Нам лучше поговорить до вечера.
        - else:
            # sms:add_hot:artem:Ты видела рабочий чат? Вчерашний кейс всплыл. Нам лучше поговорить до вечера.
        }
    }
    # sms:tag:artem:amber:важное
    # sms:read:artem
- else:
    {office_clarification_requested:
        # sms:add_hot:mila:Ты видел рабочий чат? Твой запрос по кейсу всплыл. Нам лучше поговорить до вечера.
    - else:
        {office_auto_solution_blocked:
            # sms:add_hot:mila:Ты видел рабочий чат? Заблокированный кейс всплыл. Нам лучше поговорить до вечера.
        - else:
            # sms:add_hot:mila:Ты видел рабочий чат? Вчерашний кейс всплыл. Нам лучше поговорить до вечера.
        }
    }
    # sms:tag:mila:amber:важное
    # sms:read:mila
}
->->

=== phone_bank_charge_shop_95 ===
# bank:charge:95:Магазин 24/7
# sfx:phone_notify
->->

=== phone_bank_charge_shop_120 ===
# bank:charge:120:Магазин 24/7
# sfx:phone_notify
->->

=== phone_bank_charge_shop_140 ===
# bank:charge:140:Магазин 24/7
# sfx:phone_notify
->->

=== phone_bank_charge_shop_160 ===
# bank:charge:160:Магазин 24/7
# sfx:phone_notify
->->

=== phone_bank_charge_shop_170 ===
# bank:charge:170:Магазин 24/7
# sfx:phone_notify
->->

=== phone_bank_charge_shop_180 ===
# bank:charge:180:Магазин 24/7
# sfx:phone_notify
->->

=== phone_bank_charge_shop_190 ===
# bank:charge:190:Магазин 24/7
# sfx:phone_notify
->->

=== phone_bank_charge_shop_210 ===
# bank:charge:210:Магазин 24/7
# sfx:phone_notify
->->

=== phone_bank_charge_shop_220 ===
# bank:charge:220:Магазин 24/7
# sfx:phone_notify
->->

=== phone_bank_charge_shop_230 ===
# bank:charge:230:Магазин 24/7
# sfx:phone_notify
->->

=== phone_bank_charge_shop_240 ===
# bank:charge:240:Магазин 24/7
# sfx:phone_notify
->->

=== phone_bank_charge_shop_320 ===
# bank:charge:320:Магазин 24/7
# sfx:phone_notify
->->

=== phone_bank_charge_shop_350 ===
# bank:charge:350:Магазин 24/7
# sfx:phone_notify
->->

=== phone_bank_charge_shop_360 ===
# bank:charge:360:Магазин 24/7
# sfx:phone_notify
->->

=== phone_bank_charge_shop_380 ===
# bank:charge:380:Магазин 24/7
# sfx:phone_notify
->->

=== phone_bank_charge_shop_420 ===
# bank:charge:420:Магазин 24/7
# sfx:phone_notify
->->

=== phone_bank_charge_shop_490 ===
# bank:charge:490:Магазин 24/7
# sfx:phone_notify
->->

=== phone_bank_charge_cafe_two_coffee ===
# bank:charge:980:Кофейня «петля»
# sfx:phone_notify
->->

=== phone_bank_charge_cafe_coffee_sweet ===
# bank:charge:1420:Кофейня «петля»
# sfx:phone_notify
->->

=== phone_bank_charge_cafe_tea_small ===
# bank:charge:1160:Кофейня «петля»
# sfx:phone_notify
->->

// -----------------------------------------------------------------------------
// SAFE RETURN
// Оставлен как совместимый fallback для старых сейвов/старых runtime-вызовов,
// если где-то ещё попытаются прыгнуть в sms_service_done напрямую.
// -----------------------------------------------------------------------------

=== sms_service_done ===
# return_to_scene
-> DONE
