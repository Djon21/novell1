// ================================================================
// AVOS_S - 10_apartment.ink
// Квартира: общее ядро (выбор персонажа, точка входа, on-enter knots).
// День-специфичный контент вынесен в отдельные файлы:
//   10_reset.ink     — сброс петли (loop1_to_iter2_reset)
//   10a_sunday.ink   — воскресенье
//   10b_monday.ink   — понедельник
//   10c_tuesday.ink  — вторник
// ================================================================

// ================================================================
// ВЫБОР ПЕРСОНАЖА
// ================================================================

=== choose_character ===
# bg:bg_apartment_bedroom_day # speaker:none
Кто я?

* [Артём]
    ~ mc_gender = "male"
    ~ npc_gender = "female"
    ~ mc_name = "Артём"
    ~ npc_name = "Мила"
    ~ mc_name_gen = "Артёма"
    ~ npc_name_gen = "Милы"
    ~ mc_name_dat = "Артёму"
    ~ npc_name_dat = "Миле"
    ~ mc_name_acc = "Артёма"
    ~ npc_name_acc = "Милу"
    ~ mc_name_ins = "Артёмом"
    ~ npc_name_ins = "Милой"
    ~ mc_name_prep = "Артёме"
    ~ npc_name_prep = "Миле"
    -> sunday_start_splash

* [Мила]
    ~ mc_gender = "female"
    ~ npc_gender = "male"
    ~ mc_name = "Мила"
    ~ npc_name = "Артём"
    ~ mc_name_gen = "Милы"
    ~ npc_name_gen = "Артёма"
    ~ mc_name_dat = "Миле"
    ~ npc_name_dat = "Артёму"
    ~ mc_name_acc = "Милу"
    ~ npc_name_acc = "Артёма"
    ~ mc_name_ins = "Милой"
    ~ npc_name_ins = "Артёмом"
    ~ mc_name_prep = "Миле"
    ~ npc_name_prep = "Артёме"
    -> sunday_start_splash

// Splash «ВОСКРЕСЕНЬЕ» сразу после выбора персонажа. Отдельный knot —
// чтобы не дублировать тег в обоих * [персонаж] ветках.
=== sunday_start_splash ===
# splash:day:sunday
-> apartment_start

// ================================================================
// ТОЧКА ВХОДА В КВАРТИРУ
// ================================================================

=== apartment_start ===
# map:lock_all
# bg:bg_apartment_bedroom_day # speaker:none
{iteration_number > 2:
Телефон дрожит на тумбочке. Я не проверяю число. Я знаю, что там — воскресенье.

# sfx:phone_notify
{iteration_number > 3:
«Опять воскресенье. Я уже был{mc_gender == "female":а|} здесь. Сколько можно?»
- else:
«Опять воскресенье. Я уже был{mc_gender == "female":а|} здесь. Дважды.»
}

~ anomaly_noticed = true
~ INSIGHT = INSIGHT + 1
}
{iteration_number == 2:
{not loop2_fake_wednesday_started:
Телефон дрожит так, будто всю ночь копил сообщения.

Среда.

Слово всплывает раньше, чем ты открываешь глаза.

# sfx:phone_notify
Экран вспыхивает снова. На нём — воскресенье.

# speaker:mc
Нет. Просто телефон заглючил.

# speaker:none
Самое удобное объяснение появляется сразу: синхронизация, дата, сбой после вчерашнего. Телефоны ломаются. Люди тоже.

~ loop2_fake_wednesday_started = true
~ anomaly_noticed = true
~ INSIGHT = INSIGHT + 1
# set_flag:loop2_fake_wednesday_started=true
# quest:start:check_the_loop
}
}
{iteration_number <= 1:
Воскресное утро.

Спальня тихая и светлая. Слева ещё держит тепло смятая кровать, справа у окна молчит рабочий стол.
За стеклом город уже давно начал день без тебя.

# sfx:phone_notify
Где-то рядом коротко вибрирует телефон.

# speaker:mc
Сначала до меня доходит вибрация телефона. Потом свет из окна. Потом всё остальное.
}
~ phone_history_seeded = true
# set_flag:phone_history_seeded=true

-> phone_sms_seed_sunday_morning ->
-> phone_msg_seed_sunday_morning ->

# explore:apartment_bedroom
-> DONE


// ================================================================
// ON_ENTER KNOTS
// ================================================================

=== apartment_bedroom_intro ===
// apartment_start уже описал спальню и упомянул вибрацию телефона.
// Здесь только pivot: ГГ соображает что делать дальше, и игроку
// подсвечивается направление действия (телефон на тумбочке).
# speaker:mc
Кто пишет в воскресенье с утра?

# speaker:none
Ответ напрашивается сам, но лучше сначала посмотреть.
# set_flag:bedroom_morning_seen=true
# return_to_scene
-> DONE

=== enter_kitchen_morning_first ===
# bg:bg_apartment_kitchen_day # speaker:none
Кухня встречает сухим щелчком холодильника и светлым окном во двор.
На столешнице — чайник, раковина, плита и всё утреннее, что не требует объяснений.

# speaker:mc
Кофе. Без героизма.
# set_flag:kitchen_morning_seen=true
# set_flag:kitchen_intro_seen=true
# return_to_scene
-> DONE
