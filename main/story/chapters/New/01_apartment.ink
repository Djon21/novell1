// ================================================================
// AVOS_S — 01_apartment.ink
// Stage function:
// - baseline обычного дня
// - выбор героя
// - обучение exploration / кофе / телефон
// - первые слабые аномалии
// - ранний эмоциональный контакт с NPC
// ================================================================


// ================================================================
// СЦЕНА 1А: ПРОБУЖДЕНИЕ + ТЕРМИНАЛ
// ================================================================
=== wake_intro
# bg:bg_bedroom_01 # color:0.38,0.28,0.18 # speaker:none
Спальня. Рассвет проходит сквозь жалюзи, расчерчивая комнату ровными полосами.

Слишком ровными.
Будто кто-то заранее выставил свет.

На тумбочке — синяя таблетница, почти пустая.
Мелатонин закончился ещё вчера.
Рядом блокнот с обрывком формулы.
Почерк мой.
Момент записи — нет.

Перед кроватью — большой экран, скорее телевизор, чем монитор.
Чёрный. Спящий.
Слишком пустой.

{iteration_number == 1:
# speaker:mc
Не выспал{mc_gender == "female":ась|ся}.
Голова как будто догружает реальность кусками.
- else:
# speaker:mc
Снова это утро.
И снова ощущение, будто я вхожу в уже открытую сцену.
~ INSIGHT = INSIGHT + 1
}

# bg:bg_bedroom_02 # speaker:none
В тёмном экране — размытое отражение.
Силуэт есть.
Деталей нет.

Ты делаешь шаг ближе.

# bg:bg_bedroom_03 # sfx:terminal_wake # pulse:0.8,0,255,0 # speaker:none
Экран включается с тихим щелчком.

Чёрный терминал.
Зелёная строка: user@local:~$

Курсор мигает в левом верхнем углу.
Поверх стекла.
Поверх тебя.

Ждёт ввода.

~ early_terminal_glitch = true
~ anomaly_noticed = true

{iteration_number > 1:
~ repeated_phrase_noticed = true
# speaker:mc
Я уже видел{mc_gender == "female":а|} этот экран.
- else:
# speaker:mc
Сон ещё не отпустил.
}

# speaker:none
Кто я?

-> choose_character


// ================================================================
// СЦЕНА 1Б: ВЫБОР ПЕРСОНАЖА
// ================================================================
=== choose_character
# bg:bg_bedroom_03 # color:0.38,0.28,0.18 # speaker:none
Выбери персонажа

* [Артём]
    ~ mc_gender = "male"
    ~ mc_name   = "Артём"
    ~ npc_name  = "Мила"
    -> wake_after_choice

* [Мила]
    ~ mc_gender = "female"
    ~ mc_name   = "Мила"
    ~ npc_name  = "Артём"
    -> wake_after_choice


// ================================================================
// СЦЕНА 1В: ОСОЗНАНИЕ → УТРЕННИЙ КОНТУР
// ================================================================
=== wake_after_choice
# bg:bg_bedroom_03 # color:0.38,0.28,0.18 # speaker:mc
{mc_gender == "female":В отражении на экране — женское лицо.|В отражении на экране — мужское лицо.}

Курсор продолжает мигать.
Системе всё равно, кто смотрит в ответ.

В углу всплывает время: 06:57.

Будильник должен сработать через три минуты.
Но я уже просну{mc_gender == "female":лась|лся}.

{loop_awareness > 0:
И слово «уже» звучит слишком точно.
Словно это утро не началось, а повторилось.
~ INSIGHT = INSIGHT + 1
- else:
Можно списать это на недосып.
Пока ещё можно.
}

Холодный пол под ногами.

Сначала кофе.
Потом телефон.
Без него дверь не откроется.

Нужно собраться.
День сам себя не переживёт.

# quest:start:make_coffee
-> morning_npc_ping


// ================================================================
// РАННИЙ ЭМОЦИОНАЛЬНЫЙ КОНТАКТ С NPC
// Нужен для раннего TRUST и закрепления baseline.
// ================================================================
=== morning_npc_ping
# speaker:npc
Ты уже встал{mc_gender == "female":а|}?

# speaker:mc
Похоже на то.

# speaker:npc
Ты выглядишь так, будто вообще не спал{mc_gender == "female":а|}.

* [Отмахнуться]
    ~ player_was_honest = false
    ~ day_strategy = "ignore"
    # speaker:mc
    Всё нормально. Просто тяжёлое утро.
    -> morning_npc_ping_end

* [Сказать, что утро кажется странным]
    ~ player_was_honest = true
    ~ TRUST = TRUST + 1
    ~ day_strategy = "observe"
    # speaker:mc
    Есть странное ощущение, будто я уже был{mc_gender == "female":а|} здесь.
    -> morning_npc_ping_truth

=== morning_npc_ping_truth
# speaker:npc
Это называется переработка.

# speaker:npc
Сначала кофе. Потом existential crisis.

# speaker:mc
Справедливо.

=== morning_npc_ping_end
-> apartment_hub


// ================================================================
// ХАБ: ИНТЕРАКТИВНАЯ КВАРТИРА
// Основной exploration-узел. Перемещение и hotspot'ы обрабатываются
// в scenes.lua (scene "apartment_hub").
// ================================================================
=== apartment_hub
# bg:bg_apartment # color:0.3,0.3,0.3 # speaker:mc # explore:apartment_hub
Коридор. Тихо.

{not coffee_drunk:
Сначала кухня. Без кофе утро всё равно не начнётся.
- else:
Теперь телефон. Без него дверь не открыть.
}
-> DONE


// ================================================================
// КУХНЯ: ОБУЧЕНИЕ КОФЕ / ИНВЕНТАРЮ
// Логика:
// 1. Игрок приходит на кухню
// 2. Жмёт на кофемашину -> понимает, что нужна кружка
// 3. Ищет кружку в ящике
// 4. Использует кружку на кофемашине
// ================================================================

=== enter_kitchen
# speaker:mc
Кухня.

{not kitchen_intro_seen:
# speaker:mc
Вот он. Источник временной стабильности.
~ kitchen_intro_seen = true
- else:
# speaker:mc
Кофе как единственная рабочая архитектура этого утра.
}

# flag:kitchen_intro_seen=true
# return_to_scene
-> DONE


=== use_coffee_machine_no_cup
# speaker:none
Кофемашина тихо гудит в режиме ожидания.

# speaker:mc
Стоп.

# speaker:mc
Во что я это наливать собира{mc_gender == "female":лась|лся}?

# speaker:mc
Нужна кружка.

~ need_mug_for_coffee = true
# flag:need_mug_for_coffee=true
# return_to_scene
-> DONE


=== take_mug
# speaker:none
В ящике — одна чистая кружка.

{iteration_number > 1:
# speaker:mc
Опять одна и та же.
Словно других вариантов у утра не предусмотрено.
~ anomaly_noticed = true
~ INSIGHT = INSIGHT + 1
- else:
# speaker:mc
Подойдёт.
}

# speaker:mc
Забираю с собой.

~ mug_taken = true
# flag:has_mug=true
# return_to_scene
-> DONE


=== use_coffee_machine_with_cup
# speaker:none
Кружка встаёт под носик.

# speaker:none # sfx:coffee_brew
Машина оживает.
Тёмная струйка наполняет кружку.

# speaker:mc
Вот. Теперь правильно.

# speaker:mc
Горький, терпкий.
Голова начинает работать.

{anomaly_noticed:
# speaker:mc
И вместе с этим становится сложнее делать вид, что всё нормально.
~ anomaly_interpreted = true
~ INSIGHT = INSIGHT + 1
- else:
# speaker:mc
Теперь телефон. Без него дверь не открыть.
}

~ coffee_drunk = true
~ SYNC = SYNC + 1
~ morning_choice = "coffee"
~ need_phone = true

# flag:coffee_drunk=true
# flag:need_phone=true

# quest:done:make_coffee
# quest:start:find_phone
# return_to_scene
-> DONE


// ================================================================
// СПАЛЬНЯ: ТЕЛЕФОН (ПОЯВЛЯЕТСЯ ПОСЛЕ КОФЕ)
// Логика:
// 1. После кофе активируется поиск телефона
// 2. Игрок возвращается в спальню
// 3. Телефон "появляется" на тумбочке
// 4. Игрок берёт его
// 5. Открывает телефон (обучение интерфейсу)
// ================================================================

=== spot_phone_after_coffee
# speaker:none
На тумбочке лежит телефон.

# speaker:mc
...

# speaker:mc
Минуту назад тебя здесь не было.

* [Списать на усталость]
    ~ day_strategy = "ignore"
    # speaker:mc
    Или я просто не заметил{mc_gender == "female":а|}.
    -> spot_phone_after_coffee_end

* [Признать, что это странно]
    ~ anomaly_noticed = true
    ~ anomaly_interpreted = true
    ~ INSIGHT = INSIGHT + 1
    ~ day_strategy = "observe"
    # speaker:mc
    Нет.
    Тебя здесь не было.
    -> spot_phone_after_coffee_end

=== spot_phone_after_coffee_end
~ spot_phone_after_coffee_seen = true
# flag:spot_phone_after_coffee_seen=true
# return_to_scene
-> DONE


=== take_phone
# speaker:mc
Холодный.

{spot_phone_after_coffee_seen:
# speaker:mc
Как будто я наш{mc_gender == "female":ла|ёл} не вещь, а доказательство.
~ INSIGHT = INSIGHT + 1
- else:
# speaker:mc
Ладно. Нашёлся — уже хорошо.
}

~ phone_taken = true
# flag:has_phone=true
-> open_phone


=== open_phone
# speaker:none
Экран загорается от касания.

# speaker:none
Несколько уведомлений.
Среди них — три сообщения от Ани.

# speaker:mc
С утра пораньше. Конечно.

# speaker:none
Все три почти одинаковые.

# speaker:none
PATCH temporal_sync.module

# speaker:mc
Без "привет". Без контекста. Просто отлично.

{iteration_number > 1:
# speaker:mc
И всё же я почти уверен{mc_gender == "female":а|}, что уже читал{mc_gender == "female":а|} это.
~ INSIGHT = INSIGHT + 1
~ future_hint_seen = true
- else:
# speaker:mc
Либо дедлайн горит, либо мир сломан.
И оба варианта звучат правдоподобно.
}

~ phone_active = true
~ TRUST = TRUST + 1

# flag:phone_active=true
# sms:add:anya:"PATCH temporal_sync.module"
# sms:add:anya:"PATCH temporal_sync.module"
# sms:add:anya:"PATCH temporal_sync.module — ответь, когда увидишь."

# quest:done:find_phone
# quest:start:reply_anya
# quest:start:go_to_office
# return_to_scene
-> DONE


// ================================================================
// ДОПОЛНИТЕЛЬНЫЕ ОСМОТРЫ
// ================================================================
=== bedroom_monitor
# bg:bg_bedroom_03 # speaker:mc
Монитор мигает в режиме ожидания.

{iteration_number == 1:
На рабочем столе — десятки открытых окон, которые я вчера не закрыл{mc_gender == "female":а|}.
«Авось» уже там, в трее. Ждёт.
- else:
На рабочем столе всё почти так же.
Слишком почти.
Одно из окон будто сдвинуто ровно туда, где я его уже видел{mc_gender == "female":а|}.
~ anomaly_noticed = true
}

~ bedroom_monitor_seen = true
# flag:bedroom_monitor_seen=true
# return_to_scene
-> DONE


=== inspect_bathroom
# speaker:none
Ванная. Всё на своих местах.

# speaker:mc
Умыться, зубы, лицо поприличнее.

{iteration_number == 1:
# speaker:mc
Нормальные люди с этого начинают.
Я — с кофе.
- else:
# speaker:mc
Нормальные люди начинают утро не с проверки, повторялось ли оно уже.
~ INSIGHT = INSIGHT + 1
}

~ bathroom_seen = true
# flag:bathroom_intro_seen=true
# return_to_scene
-> DONE


// ================================================================
// ВЫХОД ИЗ КВАРТИРЫ
// ================================================================
=== leave_apartment
# bg:none # speaker:mc
{not phone_active:
Телефон в руке.
Экран тёмный, но присутствие ощущается почти сильнее, чем вес.
- else:
Телефон в кармане.
Сообщения уже внутри дня, как заноза.
}

{player_was_honest:
Слова {npc_name} всё ещё крутятся в голове.
Сначала кофе. Потом existential crisis.
- else:
Если это и странность, то пока моя личная.
}

Бесшумный лифт.
Выход на улицу.

~ can_leave_apt = true
# flag:left_apartment=true
-> street_transition


// ================================================================
// ПЕРЕХОД: УЛИЦА → КАРТА ГОРОДА
// ================================================================
=== street_transition
# bg:none # color:0.4,0.4,0.4 # speaker:none
Серый рассветный город.

# speaker:mc
За окном просыпается мегаполис.
Машины. Огни. Люди, которые ещё не знают, что день может застрять.

{loop_awareness > 0:
# speaker:mc
Или знают. Просто делают вид, что нет.
}

-> city_map_hub


// ================================================================
// ХАБ: КАРТА ГОРОДА (ОБУЧЕНИЕ НАВИГАЦИИ)
// ================================================================
=== city_map_hub
# bg:bg_city_map # color:0.1,0.1,0.15 # speaker:none
Карта района.
Маршруты проложены, но большинство ещё недоступно.
Пока только один путь горит зелёным.

* [Метро «Технопарк»]
    -> metro