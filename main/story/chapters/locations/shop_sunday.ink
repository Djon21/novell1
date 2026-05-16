// ================================================================
// AVOS_S - locations/shop_sunday.ink
// Магазин 24/7 в воскресенье: улица у магазина, входная зона,
// бытовой отдел, pre-date / with-npc сцены и хотспот-реакции.
// ================================================================

=== sunday_shop_street_arrival ===
# bg:bg_shop_street_day # speaker:none
Магазин стоит внизу жилого дома, слишком яркий для обычного воскресного маршрута. Стекло отражает улицу, но внутри всё равно видно ровные полки, холодильники и красную линию над кассой.

{not met_npc_sunday:
    До встречи ещё есть время. Можно зайти за водой или чем-нибудь случайным — из тех мелочей, которые кажутся подготовкой, хотя просто помогают не идти с пустыми руками.

    # set_flag:sunday_shop_street_pre_date_seen=true
    ~ sunday_shop_street_pre_date_seen = true
- else:
    После прогулки магазин выглядит почти смешно: свет, витрина, кофе с собой, бумажный штендер у входа. Но в этом есть что-то честное — не место для красивого жеста, а место для нормального человеческого “давай зайдём”.

    # set_flag:sunday_shop_street_with_npc_seen=true
    ~ sunday_shop_street_with_npc_seen = true
}

# return_to_scene
-> DONE

=== sunday_shop_arrival ===
{not met_npc_sunday:
    -> sunday_shop_arrival_pre_date
- else:
    -> sunday_shop_arrival_with_npc
}

=== sunday_shop_arrival_pre_date ===
# bg:bg_shop_front_day # speaker:none
Внутри магазин оказывается почти пустым: белый свет, ровные полки, холодильники с напитками у дальней стены, касса у выхода.

До встречи ещё есть время. Можно взять что-то по дороге — или просто выйти и не превращать утро в список покупок.

# set_flag:sunday_shop_pre_date_visited=true
~ sunday_shop_pre_date_visited = true
# return_to_scene
-> DONE

=== sunday_shop_arrival_with_npc ===
# bg:bg_shop_front_day # speaker:none
Магазин 24/7 выглядит слишком ярким для воскресенья: белый свет, ровные полки, холодильники у дальней стены, касса у выхода.

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
# bg:bg_shop_front_day # speaker:none
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
# bg:bg_shop_street_day # speaker:none
{not met_npc_sunday:
Ты отходишь от витрины магазина. Стекло ещё держит отражение улицы, но телефон уже в руке — до встречи можно выбрать маршрут.
# map:allow:reset
# map:allow:poi_shop
{date_place_cafe:
    # map:allow:poi_cafe
- else:
    # map:allow:poi_park
}
# phone:map
- else:
Вы выходите от магазина обратно к улице. Свет за стеклом остаётся позади, а телефон уже в руке — пора решить, куда завершать день.
# map:allow:reset
# map:allow:poi_home
# phone:map
}
-> DONE


// ================================================================
// УЛИЦА У МАГАЗИНА
// ================================================================

=== shop_window_interact ===
# bg:bg_shop_street_day # speaker:none
Витрина работает как обещание: внутри светлее, чем снаружи, и всё разложено так, будто достаточно выбрать правильную полку — и день станет чуть понятнее.

Через стекло видны холодильники, стеллаж со снеками и касса. Дальше магазин уходит вглубь, но отсюда эта часть уже прячется за отражениями.
# return_to_scene
-> DONE

=== shop_sign_interact ===
# bg:bg_shop_street_day # speaker:none
Красная полоса над входом ничего не объясняет и не пытается понравиться. Просто сообщает: открыто, свет горит, можно зайти.

# speaker:mc
Иногда этого почти достаточно.
# return_to_scene
-> DONE


// ================================================================
// ВХОДНАЯ ЧАСТЬ / КАССА / НАПИТКИ / СНЕки
// ================================================================

=== shop_drinks_interact ===
# bg:bg_shop_front_day # speaker:none
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
# bg:bg_shop_front_day # speaker:none
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
# bg:bg_shop_front_day # speaker:none
Касса стоит у выхода, как граница между “взял с полки” и “это теперь часть дня”. Терминал, сканер, пустое место за стойкой — пока без продавца, но место для него уже очевидно.

Но сегодня даже такая мелочь почему-то кажется частью маршрута.
# return_to_scene
-> DONE


// ================================================================
// БЫТОВОЙ ОТДЕЛ
// ================================================================

=== shop_household_goods_interact ===
# bg:bg_shop_household_day # speaker:none
Бытовой отдел выглядит так, будто здесь продают не вещи, а обещание маленького контроля: пакеты, губки, лампочки, батарейки, рулоны бумаги, чистящие средства.

Всё разложено ровно. Даже слишком ровно для полки, к которой обычно подходят только когда дома внезапно заканчивается что-то очевидное.

{met_npc_sunday:
    # speaker:npc
    Вот это уже серьёзный уровень свидания. Отдел губок и пакетов.

    # speaker:mc
    Зато честно. Никто не притворяется, что жизнь состоит только из кофе и красивых видов.

    # speaker:npc
    Ладно. Это неожиданно сильный аргумент.
}

# return_to_scene
-> DONE

=== shop_cleaning_supplies_interact ===
# bg:bg_shop_household_day # speaker:none
На крючках висят перчатки, щётки и совки. Внизу стоят швабры, слишком прямые и терпеливые для предметов, которые обычно вспоминают в последнюю минуту.

# speaker:mc
Каждый раз кажется, что если купить правильную щётку, дома станет чуть больше порядка.

{met_npc_sunday:
    # speaker:npc
    Опасная мысль. Так люди и уходят отсюда с ведром, которое им не нужно.

    # speaker:mc
    Ведро хотя бы честнее большинства импульсивных покупок.
}

# return_to_scene
-> DONE

=== shop_paper_goods_interact ===
# bg:bg_shop_household_day # speaker:none
Полка с бумажными полотенцами и салфетками выглядит почти абсурдно спокойной. Белые рулоны, мягкие упаковки, одинаковые обещания “на всякий случай”.

{met_npc_sunday:
    # speaker:npc
    У этой полки очень взрослая энергетика.

    # speaker:mc
    Да. Тут даже импульсивная покупка звучит как хозяйственное решение.

    # speaker:npc
    Страшное место.
}

# return_to_scene
-> DONE
