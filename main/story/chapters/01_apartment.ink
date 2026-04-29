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
// КВЕСТЫ: make_coffee, find_phone, reply_anya, go_to_office
// ================================================================


// ================================================================
// СТАРТ
// ================================================================

=== apartment_start ===
# bg:bg_apartment_hall_morning # speaker:none
Воскресное утро. Квартира тихая, почти слишком тихая.
{iteration_number > 1:
На секунду — странное чувство, что это утро уже пыталось начаться.
~ INSIGHT = INSIGHT + 1
~ anomaly_noticed = true
}
# quest:start:make_coffee
# quest:start:go_to_office
# explore:apartment_hub
-> DONE


// ================================================================
// ИНТРО-КНОТЫ (on_enter для комнат, один раз)
// ================================================================

=== apartment_bedroom_intro ===
# bg:bg_apartment_bedroom_morning # speaker:none
Комната ещё держит сон: смятая постель, слабый свет через жалюзи.
На тумбочке что-то лежит экраном вниз.
# set_flag:bedroom_morning_seen=true
# quest:start:find_phone
# return_to_scene
-> DONE


=== enter_kitchen_morning_first ===
# bg:bg_apartment_kitchen_morning # speaker:none
На кухне пахнет утром — или просто кофе, которого ещё нет.
Кофемашина на столешнице. Нужна кружка.
# set_flag:kitchen_morning_seen=true
# set_flag:kitchen_intro_seen=true
# return_to_scene
-> DONE


// ================================================================
// СПАЛЬНЯ — кноты
// ================================================================

=== take_phone ===
# speaker:none
Телефон лежит экраном вниз. Поднимаешь — экран вспыхивает.
Есть сообщения. Одно от Ани — пришло ночью.
# sfx:phone_notify
# add_item:phone
~ has_phone = true
# set_flag:has_phone=true
# set_flag:phone_active=true
# set_flag:spot_phone_after_coffee_seen=true
# sms:add:anya:Ты видел PATCH к temporal_sync.module? Очень важно. Ответь.
# quest:done:find_phone
# quest:start:reply_anya
# return_to_scene
-> DONE


=== bedroom_desk_morning ===
# speaker:none
Рабочий стол. Ноутбук в спящем режиме, стопка распечаток и открытый блокнот.
{not first_anomaly_seen:
В блокноте — строчка твоим почерком, которую ты не помнишь:

"Не соглашайся сразу."

Это не первая такая запись, но всегда кажется, что видишь впервые.
# note:add:Странная запись:Не соглашайся сразу. Свой почерк.
~ first_anomaly_seen = true
# set_flag:first_anomaly_seen=true
- else:
Та запись на месте. Смотришь на неё и снова ничего не понимаешь.
}
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
# return_to_scene
-> DONE


=== bathroom_not_now ===
# speaker:none
{coffee_drunk and has_phone:
Сначала выйти. Ванная подождёт.
- else:
Ванная. Сначала нужно разобраться с кофе и телефоном.
}
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
# quest:done:make_coffee
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
