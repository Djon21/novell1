// ================================================================
// AVOS_S - 43_hub_shop.ink
// Магазин 24/7: воскресные сцены прибытия (pre-date / with-npc),
// settle и хотспот-реакции на полки/стойку.
// Подключается как POI poi_shop. Sunday-narrative бросается отсюда
// через флаг met_npc_sunday / sunday_after_date_active.
// ================================================================

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

* [Взять напиток для {npc_name_gen}]
    # speaker:mc
    Возьму ещё один. Не подарок. Просто вдруг пригодится.
    # set_flag:sunday_shop_bought_drink_for_npc=true
    # set_flag:sunday_shop_done=true
    # add_item:water_bottle
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
