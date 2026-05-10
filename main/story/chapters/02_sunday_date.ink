// ================================================================
// AVOS_S — 02_sunday_date.ink
// Воскресенье: первая встреча с NPC после квартиры.
//
// Canon:
// - первая петля;
// - обычный день, без осознания петли;
// - место встречи выбрал игрок в SMS;
// - NPC принимает выбор и приходит туда;
// - странности НЕ подсвечиваем: никаких deja vu, сбоев времени,
//   подозрений или мыслей "это уже было".
//
// Runtime links:
// - scenes.lua cafe_hub.on_enter -> sunday_date_cafe_arrival
// - scenes.lua park_hub.on_enter -> sunday_date_park_arrival
// - existing hotspots:
//     cafe_bar_interact, leave_cafe
//     park_bench_interact, leave_park
// ================================================================

=== sunday_date_map_fallback ===
# speaker:none
Карта открыта. Осталось выбрать маршрут.

{date_place_cafe:
    -> sunday_date_go_cafe
- else:
    -> sunday_date_go_park
}

=== sunday_date_go_cafe ===
# set_flag:date_route_chosen=true
~ date_route_chosen = true
# explore:cafe_hub
-> DONE

=== sunday_date_go_park ===
# set_flag:date_route_chosen=true
~ date_route_chosen = true
# explore:park_hub
-> DONE


// ================================================================
// КАФЕ
// ================================================================

=== sunday_date_cafe_arrival ===
# bg:bg_cafe_morning # speaker:none
Кафе оказывается ровно таким, каким хотелось его увидеть утром: тёплый свет из окна, тёмное дерево, тихий звон чашек за стойкой.

{npc_name} уже здесь — за столиком у окна. Не делает из встречи событие, просто поднимает взгляд и улыбается.

# speaker:npc
{mc_gender == "female":
Ты пришла.
- else:
Ты пришёл.
}

# speaker:mc
Я стараюсь держать слово.

# speaker:npc
Хорошо, что выбрали кафе. Тут спокойно.

# speaker:none
Вы садитесь друг напротив друга. Между вами — маленький столик, меню без спешки и воскресное утро, которое наконец-то перестаёт быть только списком дел.

# speaker:npc
Ну что, кофе сначала или сразу разговоры?

{sunday_shop_bought_drink_for_npc:
# speaker:mc
Я по дороге взял{mc_gender == "female":а|} тебе напиток. Не знал{mc_gender == "female":а|}, что захочется, но вдруг.

# speaker:npc
Ты правда зашёл{mc_gender == "female":ла|} в магазин до встречи, чтобы взять это мне?

# speaker:none
Жест маленький, почти неловкий. Но именно поэтому он работает.
~ TRUST = TRUST + 1
# set_flag:date_small_kindness=true
~ date_small_kindness = true
}

* [Спросить, как {npc_name} хотелось провести день]
    # speaker:mc
    А тебе как хотелось провести сегодня? Не в смысле “куда правильно”, а как правда хочется.

    # speaker:npc
    Спасибо, что спрашиваешь. Наверное, спокойно. Без расписания.

    # speaker:none
    Ты не предлагаешь решение за двоих — сначала даёшь человеку место в разговоре. От этого столик у окна становится не просто выбранной точкой, а началом общего дня.
    ~ TRUST = TRUST + 1
    -> sunday_date_cafe_settle

* [Пошутить, что воскресенье требует нормального завтрака]
    # speaker:mc
    Воскресенье требует нормального завтрака. Иначе оно не засчитывается.

    # speaker:npc
    Тогда придётся спасать воскресенье официально.

    # speaker:none
    {npc_name} улыбается шире. Напряжение, с которым закрывалась дверь квартиры, понемногу отпускает.
    ~ SYNC = SYNC + 1
    -> sunday_date_cafe_settle

* [Признаться, что кафе было самым безопасным вариантом]
    # speaker:mc
    Я выбрал кафе, потому что это был самый безопасный вариант. Тёплый свет, столик, всё понятно.

    # speaker:npc
    Безопасный — не обязательно плохой. Главное, чтобы ты правда хотел быть здесь, а не просто выбрал первый понятный маршрут.

    # speaker:none
    Ответ не ранит, но слегка сдвигает разговор. Ты замечаешь: логичный выбор и внимательный выбор — не всегда одно и то же.
    ~ INSIGHT = INSIGHT + 1
    -> sunday_date_cafe_settle

=== sunday_date_cafe_settle ===
# speaker:none
Разговор складывается из простых вещей: кто как спал, почему город утром кажется тише, что лучше — сладкое к кофе или просто второй кофе.

# speaker:npc
Хорошо, что мы списались.

# speaker:mc
Я тоже.

# speaker:none
Этого достаточно. Не для большого признания — для начала.

# speaker:npc
У меня ещё есть немного времени. Можно не разбегаться сразу.

# speaker:mc
Тогда выберем, куда пойти дальше.

# speaker:none
Встреча не заканчивается на первом разговоре. Теперь это уже не просто договорённость из SMS, а настоящий воскресный день.

# set_flag:date_route_chosen=true
# set_flag:met_npc_sunday=true
# set_flag:sunday_after_date_active=true
# quest:done:meet_npc
# quest:start:spend_sunday
# map:allow:reset
# map:allow:poi_shop
# map:allow:poi_view
~ date_route_chosen = true
~ met_npc_sunday = true
~ sunday_after_date_active = true
# return_to_scene
-> DONE

=== cafe_bar_interact ===
# bg:bg_cafe_morning # speaker:none
Стойка пахнет кофе и тёплой выпечкой. Бариста двигается быстро, но без суеты — как будто воскресенье здесь умеют не торопить.

{date_place_cafe:
    -> cafe_bar_interact_right_place
- else:
    -> cafe_bar_interact_wrong_place
}

=== cafe_bar_interact_right_place ===
# speaker:mc
Надо будет взять что-нибудь к столу. Не только же пытаться красиво разговаривать.
# return_to_scene
-> DONE

=== cafe_bar_interact_wrong_place ===
# speaker:mc
Кафе хорошее, но мы договорились не здесь.
# return_to_scene
-> DONE

=== cafe_window_table ===
# bg:bg_cafe_morning # speaker:none
Столик у окна держит ровно ту дистанцию, которая нужна для первого воскресного разговора: достаточно близко, чтобы слышать друг друга, и достаточно спокойно, чтобы не спешить.
# return_to_scene
-> DONE

=== leave_cafe ===
# bg:bg_cafe_morning # speaker:none
{met_npc_sunday:
Ты выходишь из кафе на улицу. Телефон уже в руке — можно выбрать, куда идти дальше.
# phone:map
- else:
Выходить из кафе пока рано. Воскресный разговор только начался.
# return_to_scene
}
-> DONE


// ================================================================
// ПАРК У РЕКИ
// ================================================================

=== sunday_date_park_arrival ===
# bg:bg_park_by_the_river_morning # speaker:none
Парк у реки встречает воздухом. Не тишиной — здесь есть шаги, вода, далёкие голоса, — но всё это не давит.

{npc_name} ждёт у дорожки ближе к реке. Замечает тебя не сразу, а потом улыбается — спокойно, без лишних вопросов.

# speaker:npc
{mc_gender == "female":
Ты выбрала парк. Хорошо.
- else:
Ты выбрал парк. Хорошо.
}

# speaker:mc
Сегодня хотелось воздуха.

# speaker:npc
Тогда идём у воды. Кафе никуда не денется.

# speaker:none
Вы идёте рядом. Первые несколько шагов не требуют слов — только подобрать общий темп.

{sunday_shop_bought_drink_for_npc:
# speaker:mc
Я, кстати, взял{mc_gender == "female":а|} тебе кое-что по дороге. В магазине у дома.

# speaker:npc
Вот это подготовка. Неожиданная, но приятная.

# speaker:none
Ты протягиваешь напиток не как подарок, а как простую заботу. В парке это выглядит особенно уместно.
~ TRUST = TRUST + 1
# set_flag:date_small_kindness=true
~ date_small_kindness = true
}

* [Подстроиться под общий темп]
    # speaker:mc
    Давай не будем спешить. Пойдём как идётся.

    # speaker:npc
    Вот это хороший план. Почти не план.

    # speaker:none
    Вы идёте рядом, и через несколько шагов общий темп находится сам. Внимательность оказывается не жестом, а скоростью.
    ~ TRUST = TRUST + 1
    -> sunday_date_park_settle

* [Пошутить, что прогулка засчитывается как план]
    # speaker:mc
    Если что, прогулка вдоль реки официально считается планом. Просто без таблицы и дедлайна.

    # speaker:npc
    Редкий вид плана. Мне нравится.

    # speaker:none
    Вы смеётесь коротко, почти одновременно. Воздуха становится больше не только вокруг, но и между словами.
    ~ SYNC = SYNC + 1
    -> sunday_date_park_settle

* [Сказать, что парк был менее шумным решением]
    # speaker:mc
    Я выбрал парк, потому что он казался менее шумным решением. Меньше людей, меньше ожиданий.

    # speaker:npc
    Понимаю. Только давай не превращать даже прогулку в оптимизацию.

    # speaker:none
    Сказано мягко, но точно. Ты ловишь себя на том, что снова объясняешь выбор как задачу, а не как желание.
    ~ INSIGHT = INSIGHT + 1
    -> sunday_date_park_settle

=== sunday_date_park_settle ===
# speaker:none
Разговор начинается с простого: погода, работа, планы на день, ничего обязательного. Но рядом с {npc_name} простые темы не кажутся пустыми.

# speaker:npc
Хорошо, что мы выбрались именно в парк.

# speaker:mc
Я тоже.

# speaker:none
Сказать больше пока не нужно. Достаточно идти рядом.

# speaker:npc
У меня ещё есть немного времени. Можно не разбегаться сразу.

# speaker:mc
Тогда выберем, куда пойти дальше.

# speaker:none
Встреча не заканчивается на первом разговоре. Теперь это уже не просто договорённость из SMS, а настоящий воскресный день.

# set_flag:date_route_chosen=true
# set_flag:met_npc_sunday=true
# set_flag:sunday_after_date_active=true
# quest:done:meet_npc
# quest:start:spend_sunday
# map:allow:reset
# map:allow:poi_shop
# map:allow:poi_view
~ date_route_chosen = true
~ met_npc_sunday = true
~ sunday_after_date_active = true
# return_to_scene
-> DONE

=== park_bench_interact ===
# bg:bg_park_by_the_river_morning # speaker:none
Скамейка смотрит на дорожку и реку. На ней удобно не решать ничего важного сразу.

{date_place_park:
    -> park_bench_interact_right_place
- else:
    -> park_bench_interact_wrong_place
}

=== park_bench_interact_right_place ===
# speaker:mc
Хорошее место. Можно просто посидеть и не объяснять, почему молчишь.
# return_to_scene
-> DONE

=== park_bench_interact_wrong_place ===
# speaker:mc
Парк хороший, но мы договорились о кафе.
# return_to_scene
-> DONE

=== park_river_view ===
# bg:bg_park_by_the_river_morning # speaker:none
Река движется медленно и уверенно. На таком фоне разговоры обычно становятся тише — не слабее, просто честнее.
# return_to_scene
-> DONE

=== leave_park ===
# bg:bg_park_by_the_river_morning # speaker:none
{met_npc_sunday:
Ты выходишь с набережной. Телефон уже в руке — можно выбрать, куда идти дальше.
# phone:map
- else:
Уходить из парка пока рано. Воскресный разговор только начался.
# return_to_scene
}
-> DONE

// ================================================================
// ПОСЛЕ ВСТРЕЧИ: ВТОРОЕ МЕСТО
// ================================================================

=== sunday_viewpoint_arrival ===
# bg:bg_observation_day # speaker:none
Смотровая оказывается не торжественной, а простой: город внизу, перила перед вами, ветер, который не требует разговаривать громче.

{npc_name} подходит ближе к краю, но не смотрит вниз слишком долго. Скорее на линию домов, на свет между стеклом и небом.

# speaker:npc
Мне нравятся такие места. Здесь проще понять, что день не обязан куда-то спешить.

* [Спросить, почему тебе нравятся такие места]
    # speaker:mc
    Почему тебе нравятся такие места?

    # speaker:npc
    Потому что отсюда всё большое становится не таким шумным. И свои мысли тоже.

    # speaker:none
    Ты не перебиваешь. Даёшь ответу остаться в воздухе, и от этого он звучит важнее.
    ~ TRUST = TRUST + 1
    -> sunday_viewpoint_settle

* [Пошутить про вид на город]
    # speaker:mc
    Вид, конечно, хороший. Почти как реклама нормальной жизни.

    # speaker:npc
    Почти. Только без слогана мелким шрифтом.

    # speaker:none
    Вы смеётесь не громко, но синхронно. Иногда этого достаточно, чтобы неловкость стала общей, а не чужой.
    ~ TRUST = TRUST + 1
    -> sunday_viewpoint_settle

* [Просто постоять рядом]
    # speaker:mc
    Давай просто постоим минуту.

    # speaker:npc
    Давай.

    # speaker:none
    Вы стоите рядом. Без попытки заполнить паузу. И пауза впервые за день не кажется пустой.
    ~ TRUST = TRUST + 1
    -> sunday_viewpoint_settle

=== sunday_viewpoint_settle ===
# speaker:none
Город снизу выглядит собранным и спокойным. Будто все маршруты в нём уже проложены, но сегодня можно не выбирать самый короткий.

# speaker:npc
Спасибо, что не закончилось сразу после первой встречи.

# speaker:mc
Мне тоже не хотелось сразу домой.

# speaker:none
Воскресенье становится длиннее не из-за количества дел, а из-за того, что в нём появляется место для другого человека.

# set_flag:sunday_second_stop_done=true
# set_flag:sunday_went_to_viewpoint=true
# map:allow:reset
# map:allow:poi_home
~ sunday_second_stop_done = true
~ sunday_went_to_viewpoint = true
# return_to_scene
-> DONE

=== leave_viewpoint ===
# bg:bg_observation_day # speaker:none
Телефон снова оказывается в руке. День уже не кажется коротким, но ему всё ещё нужен нормальный вечерний финал.
# phone:map
-> DONE


=== sunday_shop_arrival ===
{not met_npc_sunday:
    -> sunday_shop_arrival_pre_date
- else:
    -> sunday_shop_arrival_with_npc
}

=== sunday_shop_arrival_pre_date ===
# bg:bg_shop_day # speaker:none
Магазин у дома оказывается почти пустым: белый свет, ровные полки, холодильники с напитками у дальней стены.

До встречи ещё есть время. Можно взять что-то по дороге — или просто выйти и не превращать утро в список покупок.

# set_flag:sunday_shop_pre_date_visited=true
~ sunday_shop_pre_date_visited = true
# return_to_scene
-> DONE


=== sunday_shop_arrival_with_npc ===
# bg:bg_shop_day # speaker:none
Магазин 24/7 выглядит слишком ярким для воскресенья: белый свет, ровные полки, холодильники у дальней стены.

После первой встречи он кажется почти смешным выбором, но именно поэтому здесь легко быть обычными.

# set_flag:sunday_shop_with_npc_seen=true
~ sunday_shop_with_npc_seen = true

# speaker:npc
Знаешь, иногда такие места честнее красивых. Тут хотя бы понятно, зачем ты пришёл.

# speaker:mc
За водой, жвачкой и иллюзией контроля.

# speaker:npc
Нормальный набор.

* [Взять воду на двоих]
    # speaker:mc
    Возьму воды. На двоих.

    # speaker:npc
    Заботливо. Засчитано.

    # speaker:none
    Это мелочь. Но воскресенье как раз и держится на мелочах, которые кто-то заметил.
    ~ TRUST = TRUST + 1
    -> sunday_shop_settle

* [Взять что-нибудь сладкое]
    # speaker:mc
    Надо взять что-нибудь сладкое. Чтобы день официально не был взрослым.

    # speaker:npc
    Хорошая защита от взрослости.

    # speaker:none
    {npc_name} выбирает не сразу, будто это решение почему-то важно. Ты запоминаешь этот маленький момент.
    ~ TRUST = TRUST + 1
    -> sunday_shop_settle

* [Спросить, что обычно берёт {npc_name}]
    # speaker:mc
    А ты что обычно берёшь в таких местах?

    # speaker:npc
    Что-нибудь ненужное. Чтобы почувствовать, что день не весь по плану.

    # speaker:none
    Ответ звучит легко, но в нём есть маленькая правда. Ты её не комментируешь — просто слышишь.
    ~ TRUST = TRUST + 1
    -> sunday_shop_settle

=== sunday_shop_settle ===
# speaker:none
Вы выходите из магазина с пакетом, который почти ничего не весит. Вода, сладкое, случайная мелочь — всё это не меняет день, но делает его прожитым.

# speaker:npc
Теперь можно и домой. Уже не ощущается, что мы просто встретились и разбежались.

# speaker:mc
Да. Теперь похоже на воскресенье.

# set_flag:sunday_second_stop_done=true
# set_flag:sunday_went_to_shop=true
# map:allow:reset
# map:allow:poi_home
~ sunday_second_stop_done = true
~ sunday_went_to_shop = true
# return_to_scene
-> DONE

=== leave_shop ===
# bg:bg_shop_day # speaker:none
{not met_npc_sunday:
Автоматические двери выпускают тебя обратно в город. До встречи ещё можно выбрать маршрут.
# map:allow:reset
# map:allow:poi_shop
{date_place_cafe:
    # map:allow:poi_cafe
- else:
    # map:allow:poi_park
}
# phone:map
- else:
Автоматические двери выпускают вас обратно в город. Телефон уже в руке — пора решить, куда завершать день.
# phone:map
}
-> DONE


// ================================================================
// ВОЗВРАТ ДОМОЙ И ЗАВЕРШЕНИЕ ВОСКРЕСЕНЬЯ
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

Телефон вибрирует уже без тревоги — короткое сообщение от {npc_name}.

# sfx:phone_notify
{mc_gender == "female":
    # sms:add:artem:Спасибо за сегодня. Было хорошо.
    # sms:read:artem
- else:
    # sms:add:mila:Спасибо за сегодня. Было хорошо.
    # sms:read:mila
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
        # sms:reply:artem:Спасибо, что продолжили день. Я рада, что мы встретились.
    - else:
        # sms:reply:mila:Спасибо, что продолжили день. Я рад, что мы встретились.
    }

    # speaker:none
    Ответ уходит сразу. В нём нет ничего громкого, но есть точность.
    ~ TRUST = TRUST + 1
    -> sunday_evening_finish

* [Ответить спокойно]
    # speaker:mc
    Да. Хороший день получился.

    {mc_gender == "female":
        # sms:reply:artem:Да. Хороший день получился.
    - else:
        # sms:reply:mila:Да. Хороший день получился.
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


=== shop_drinks_interact ===
# bg:bg_shop_day # speaker:none
Холодильники гудят ровно и уверенно. Вода, сок, холодный чай — маленькие решения, которые не требуют объяснений.

* [Взять воду себе]
    # speaker:mc
    Вода — самый честный план на утро.
    # set_flag:sunday_shop_bought_water=true
    # set_flag:sunday_shop_done=true
    ~ sunday_shop_bought_water = true
    ~ sunday_shop_done = true
    # return_to_scene
    -> DONE

* [Взять напиток для {npc_name}]
    # speaker:mc
    Возьму ещё один. Не подарок. Просто вдруг пригодится.
    # set_flag:sunday_shop_bought_drink_for_npc=true
    # set_flag:sunday_shop_done=true
    ~ sunday_shop_bought_drink_for_npc = true
    ~ sunday_shop_done = true
    # return_to_scene
    -> DONE

* [Ничего не брать]
    # speaker:mc
    Нет. Я просто посмотрел{mc_gender == "female":а|}. Так тоже бывает.
    # return_to_scene
    -> DONE


=== shop_snacks_interact ===
# bg:bg_shop_day # speaker:none
Центральный стеллаж предлагает всё, что человек обычно покупает не потому, что нужно, а потому что день длиннее, чем казался утром.

* [Взять батончик]
    # speaker:mc
    Не завтрак, но хотя бы признание проблемы.
    # set_flag:sunday_shop_bought_snack=true
    # set_flag:sunday_shop_done=true
    ~ sunday_shop_bought_snack = true
    ~ sunday_shop_done = true
    # return_to_scene
    -> DONE

* [Взять жвачку]
    # speaker:mc
    Жвачка — странный способ сказать себе, что ты подготовился.
    # set_flag:sunday_shop_bought_snack=true
    # set_flag:sunday_shop_done=true
    ~ sunday_shop_bought_snack = true
    ~ sunday_shop_done = true
    # return_to_scene
    -> DONE

* [Оставить как есть]
    # speaker:mc
    Снеки переживут моё отсутствие.
    # return_to_scene
    -> DONE


=== shop_counter_interact ===
# bg:bg_shop_day # speaker:none
Полки, холодильники, касса, пластиковая корзина у входа. Всё здесь устроено так, чтобы человек быстро взял нужное и не думал слишком долго.

Но сегодня даже такая мелочь почему-то кажется частью дня.
# return_to_scene
-> DONE

=== view_railing_interact ===
# bg:bg_observation_day # speaker:none
Поручни прохладные. За ними город выглядит собранным, почти спокойным.

Можно было бы сказать что-то умное, но сейчас достаточно просто постоять и посмотреть вниз.
# return_to_scene
-> DONE



// ================================================================
// БАР MAYBE — минимальный хаб
// ================================================================

=== bar_counter_interact ===
# bg:bg_bar_maybe_night # speaker:none
Барная стойка тянется вдоль стены тёмной линией. За ней — бутылки, отражения и низкий свет, в котором легко сделать вид, что день ещё не закончился.

Пока здесь нечего решать. Можно просто запомнить место.
# return_to_scene
-> DONE

=== leave_bar ===
# bg:bg_bar_maybe_night # speaker:none
Ты выходишь из бара обратно в город. Ночной воздух кажется проще, чем свет внутри.
# phone:map
-> DONE

// ================================================================
// СОН И ПЕРЕХОД К ПОНЕДЕЛЬНИКУ
// ================================================================

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
