// ================================================================
// AVOS_S — 01_apartment.ink
// Утренняя квартира: коридор, спальня, кухня.
//
// ФЛАГИ (синхронизированы с scenes.lua и quests.lua):
//   bedroom_morning_seen      — спальня: интро уже показывалось
//   kitchen_morning_seen      — кухня: интро уже показывалось
//   has_mug                   — кружка в инвентаре
//   coffee_drunk              — кофе выпит (разблокирует «Сварить»)
//   has_phone                 — телефон в инвентаре
//   phone_active              — экран включён
//   spot_phone_after_coffee_seen — вернулся в спальню за телефоном
//   left_apartment            — вышел из квартиры
//   first_anomaly_seen        — нашёл странную запись в блокноте
//   kitchen_intro_seen        — дошёл до кухни (шаг квеста make_coffee)
//
// КВЕСТЫ: make_coffee, find_phone, reply_mila, go_to_office
// ================================================================


// ================================================================
// СТАРТ
// ================================================================

=== apartment_start ===
# bg:bg_apartment_bedroom_morning # speaker:none
Воскресное утро. Комната тихая.
Сон отпускает не сразу.
{iteration_number > 1:
На секунду — странное чувство, что это утро уже пыталось начаться.
~ INSIGHT = INSIGHT + 1
~ anomaly_noticed = true
}
# explore:apartment_bedroom_morning
-> DONE


// ================================================================
// ИНТРО-КНОТЫ (on_enter для комнат, один раз)
// ================================================================

=== apartment_bedroom_intro ===
# bg:bg_apartment_bedroom_morning # speaker:none
Комната ещё держит сон: смятая постель, слабый свет через жалюзи.
Надо просто начать утро.
# set_flag:bedroom_morning_seen=true
# return_to_scene
-> DONE


=== enter_kitchen_morning_first ===
# bg:bg_apartment_kitchen_morning # speaker:none
На кухне тихо. За окном редкие машины и слишком спокойный двор.
Кофе бы не помешал.
# set_flag:kitchen_morning_seen=true
# set_flag:kitchen_intro_seen=true
# return_to_scene
-> DONE


// ================================================================
// СПАЛЬНЯ — кноты
// ================================================================

=== take_phone ===
# speaker:none
Телефон лежит экраном вниз. За утро ты почти успел про него забыть.
Экран вспыхивает: новое сообщение.
# sfx:phone_notify
# add_item:phone
~ has_phone = true
~ phone_taken = true
# set_flag:has_phone=true
# set_flag:phone_active=true
# set_flag:spot_phone_after_coffee_seen=true
# set_flag:phone_taken=true
# sms:add:mila:Есть планы на сегодня? Может, увидимся?
# quest:start:reply_mila
# return_to_scene
-> DONE


=== bedroom_desk_morning ===
# speaker:none
Рабочий стол. Ноутбук закрыт, рядом блокнот и зарядка от телефона.
Сегодня воскресенье. Работу можно не трогать.
# return_to_scene
-> DONE


=== look_bed_morning ===
# speaker:none
{iteration_number > 1:
Постель скомкана знакомым образом. Тем же, что и в прошлый раз.
Не успокаивает.
~ INSIGHT = INSIGHT + 1
- else:
Постель скомкана. Сон был неровным — или слишком длинным.
}
Ладно. Пора вставать.
# set_flag:got_out_of_bed=true
# return_to_scene
-> DONE


=== wash_up_morning ===
# speaker:none
Холодная вода быстро собирает лицо обратно.
В зеркале — обычное воскресное утро. Ничего героического.
# set_flag:washed_up=true
# return_to_scene
-> DONE


=== bathroom_not_now ===
# speaker:none
Ванная уже сделала своё.
# return_to_scene
-> DONE


// ================================================================
// КОРИДОР — кноты
// ================================================================

=== look_hall_mirror ===
# speaker:none
{iteration_number > 1:
Знакомое лицо. Слишком знакомое — будто уже видел его сегодня в зеркале.
~ INSIGHT = INSIGHT + 1
- else:
Зеркало в коридоре. Обычное отражение. Ничего странного.
}
# return_to_scene
-> DONE


=== leave_apartment ===
# speaker:none
Ключи, телефон, кофе внутри. Теперь можно выходить.
Дверь захлопывается за спиной.
# set_flag:left_apartment=true
-> metro


// ================================================================
// КУХНЯ — кноты
// ================================================================

=== use_coffee_machine_no_cup ===
# speaker:none
Кофемашина готова к работе, но нужна кружка.
Она должна быть где-то в шкафчике.
# return_to_scene
-> DONE


=== take_mug ===
# speaker:none
Кружка в шкафчике — та самая, с трещиной на ручке.
Каждый раз она стоит на одном месте.
# add_item:mug
~ has_mug = true
# set_flag:has_mug=true
# return_to_scene
-> DONE


=== use_coffee_machine_with_cup ===
# speaker:none
Кружка встаёт под носик. Несколько секунд — и кофе готов.
Запах правильный. Почти успокаивает.
# sfx:coffee_brew
# set_flag:coffee_drunk=true
# set_flag:morning_ritual_done=true
# return_to_scene
-> DONE


=== look_kitchen_window ===
# speaker:none
{iteration_number > 1:
Та же машина у подъезда. Серая, без номеров. Снова.
~ anomaly_noticed = true
~ INSIGHT = INSIGHT + 1
- else:
Окно выходит во двор. Пусто. Машина у подъезда — не твоя.
}
# return_to_scene
-> DONE


// ================================================================
// SMS — переписка с Милой
// ================================================================

=== sms_thread_mila ===
# speaker:none
Открываешь переписку. Мила написала утром:
«Есть планы на сегодня? Может, увидимся?»

* [«Давай. Напишу, как освобожусь.»]
    Тёплый ответ. Не обещаешь конкретику, но дверь открыта.
    # sms:reply:mila:Давай. Напишу, как освобожусь.
    ~ TRUST = TRUST + 1
    -> sms_mila_sent
* [«Сейчас занят. Потом.»]
    Коротко. Без объяснений.
    # sms:reply:mila:Сейчас занят. Потом напишу.
    -> sms_mila_sent
* [«Не знаю ещё. Посмотрим.»]
    Уклончиво. Ни да ни нет.
    # sms:reply:mila:Не знаю ещё. Посмотрим.
    -> sms_mila_sent

= sms_mila_sent
# speaker:none
Сообщение отправлено.
# quest:done:reply_mila
# return_to_scene
-> DONE
