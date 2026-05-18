// ================================================================
// AVOS_S - locations/shop_sunday.ink
// Магазин 24/7 в воскресенье: улица у магазина, входная зона,
// бытовой отдел, pre-date / with-npc сцены и хотспот-реакции.
// ================================================================

=== sunday_shop_street_arrival ===
# speaker:none
Магазин стоит внизу жилого дома: красная полоса над входом, бумажный штендер у двери, холодный свет за стеклом. Витрина отражает улицу так чётко, будто внутри и снаружи идут два разных воскресенья.

{not met_npc_sunday:
    До встречи ещё есть время. Можно зайти за чем-нибудь небольшим: не обязательный ритуал, не большой жест, а способ прийти не совсем с пустыми руками.

    # set_flag:sunday_shop_street_pre_date_seen=true
    ~ sunday_shop_street_pre_date_seen = true
- else:
    После прогулки магазин выглядит почти смешно: слишком яркий, слишком обычный, с рекламой кофе на двери и корзинками у входа. Но именно поэтому здесь легко не играть в красивый момент, а просто быть рядом.

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
# speaker:none
Внутри магазин почти пустой: холодильники гудят у дальней стены, возле кассы мигает терминал, на стеллаже кто-то оставил шоколадку не в том ряду.

До встречи ещё есть время. Можно взять один маленький подарок — напиток, сладкое или что-нибудь совсем неочевидное из бытового отдела. А можно выйти обратно: не каждое намерение обязано становиться покупкой.

# set_flag:sunday_shop_pre_date_visited=true
~ sunday_shop_pre_date_visited = true
# return_to_scene
-> DONE

=== sunday_shop_arrival_with_npc ===
# speaker:none
Магазин 24/7 встречает белым светом, гулом холодильников и корзинками у входа. После прогулки это место выглядит не романтично, зато очень убедительно: здесь не нужно придумывать повод стоять рядом.

# set_flag:sunday_shop_with_npc_seen=true
~ sunday_shop_with_npc_seen = true

# speaker:npc
Знаешь, у таких мест есть плюс. Тут сразу понятно, что делать руками.

# speaker:mc
Открыть холодильник, взять что-нибудь, сделать вид, что это был план.

# speaker:npc
Вот. Почти взрослая стратегия.

* [Взять воду на двоих]
    # speaker:mc
    Возьму воды. На двоих.

    # speaker:npc
    Заботливо. Засчитано.

    # speaker:none
    Холод пластика быстро переходит в ладонь. Две бутылки выглядят смешно серьёзно — как будто заботу правда можно просто снять с полки. Одна бутылка оказывается в сумке: достаточно лёгкая, чтобы забыть о ней, и достаточно полезная, чтобы потом вспомнить.
    # set_flag:sunday_shop_bought_drink_for_npc=true
    # set_flag:sunday_shop_done=true
    # add_item:water_bottle
    ~ sunday_shop_bought_drink_for_npc = true
    ~ sunday_shop_done = true
    ~ TRUST = TRUST + 1
    -> sunday_shop_settle

* [Взять что-нибудь сладкое]
    # speaker:mc
    Надо взять что-нибудь сладкое. Чтобы день официально не был взрослым.

    # speaker:npc
    Хорошая защита от взрослости.

    # speaker:none
    {npc_name} выбирает не сразу: батончик, мармелад, снова батончик. Решение маленькое, но пауза получается настоящей.
    # set_flag:sunday_shop_bought_snack=true
    # set_flag:sunday_shop_done=true
    ~ sunday_shop_bought_snack = true
    ~ sunday_shop_done = true
    ~ TRUST = TRUST + 1
    -> sunday_shop_settle

* [Спросить, что обычно берёт {npc_name}]
    # speaker:mc
    А ты что обычно берёшь в таких местах?

    # speaker:npc
    Что-нибудь ненужное. Чтобы почувствовать, что день не весь по плану.

    # speaker:none
    В итоге в пакете оказывается маленькая упаковка мармелада и чек, который выглядит серьёзнее покупки. Ответ звучит легко, но в нём есть маленькая правда. Ты её не комментируешь — просто слышишь.
    # set_flag:sunday_shop_done=true
    ~ sunday_shop_done = true
    ~ TRUST = TRUST + 1
    -> sunday_shop_settle

=== sunday_shop_settle ===
# speaker:none
Касса отвечает коротким писком, пакет шуршит у запястья, дверь выпускает вас обратно к улице.

{sunday_shop_bought_drink_for_npc:
    В пакете — вода. Ничего праздничного, зато очень похоже на заботу, если не произносить это слово вслух.
- else:
    {sunday_shop_bought_snack:
        В пакете — сладкое, выбранное почти случайно. Такие покупки редко нужны, но хорошо доказывают, что день был не только маршрутом.
    - else:
        В пакете — случайная мелочь, чек и немного неловкой радости от того, что вы выбрали её вместе.
    }
}

# speaker:npc
Теперь можно и домой. Уже не ощущается, что мы просто встретились и разбежались.

# speaker:mc
Да. Теперь похоже на воскресенье.

# set_flag:sunday_second_stop_done=true
# set_flag:sunday_went_to_shop=true
# set_flag:sunday_shop_done=true
# map:allow:reset
# map:lock_to:poi_home
~ sunday_second_stop_done = true
~ sunday_went_to_shop = true
~ sunday_shop_done = true
# phone:map
-> DONE

=== leave_shop ===
# speaker:none
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
    {sunday_second_stop_done:
Вы выходите от магазина обратно к улице. Свет за стеклом остаётся позади, а телефон уже в руке — пора домой.
# map:allow:reset
# map:lock_to:poi_home
# phone:map
    - else:
Вы задерживаетесь у выхода. Автоматическая дверь послушно ждёт, но уходить сейчас странно: вы пришли сюда вместе и ещё даже ничего не выбрали.

# speaker:npc
Сбегаешь?

# speaker:mc
Нет. Разведка местности.

# speaker:npc
Тогда разведка докладывает: холодильники всё ещё там.

# speaker:none
Похоже, сначала нужно всё-таки выбрать что-нибудь у полок.
# return_to_scene
    }
}
-> DONE


// ================================================================
// УЛИЦА У МАГАЗИНА
// ================================================================

=== shop_window_interact ===
# speaker:none
Витрина собирает внутри маленькую выставку нормальности: вода ровными рядами, шоколадки у кассы, корзинки одна в другой, ценники под одинаковым углом.

В отражении поверх этого остаётся улица — деревья, окно второго этажа, ваше почти незаметное движение у стекла.
# return_to_scene
-> DONE

=== shop_sign_interact ===
# speaker:none
Вывеска светится без настроения: 24/7, красная полоса, белые буквы, обещание быть открытой даже тогда, когда человеку лучше бы уже спать.

# speaker:mc
Удобная форма бессмертия.
# return_to_scene
-> DONE


// ================================================================
// ВХОДНАЯ ЧАСТЬ / КАССА / НАПИТКИ / СНЕки
// ================================================================

// ============================================================
// ВАЖНО про воду для NPC:
// ============================================================
// Этот хотспот доступен ТОЛЬКО до встречи (visible_when: not sunday_shop_done).
// Опция «Взять напиток для NPC» здесь — PRE-DATE жест, единственный
// путь, который реально отыгрывается потом в парке/кафе как «у меня
// для тебя вода» (см. park_bench_main_talk / park_path_main_talk
// в park_sunday.ink — там проверяется sunday_shop_bought_drink_for_npc).
//
// Не путать с «Взять воду на двоих» в sunday_shop_arrival_with_npc —
// это AFTER-DATE покупка, она ставит тот же флаг, но к моменту
// where this triggers свидание уже закончилось, в парк/кафе вода
// "опоздала". Воду из after-date использовать можно только для flavor
// в shop_settle и описаний дороги домой.
//
// `sunday_shop_bought_water` (выбор «Взять воду себе») — orphan флаг,
// нигде не читается. Заготовка под iter 2+ или дополнительный
// flavor в парке.
// ============================================================
=== shop_drinks_interact ===
{met_npc_sunday:
    -> shop_drinks_with_npc
- else:
    -> shop_drinks_pre_date
}

=== shop_drinks_pre_date ===
# speaker:none
Холодильники гудят ровно, будто у них воскресенье никогда не сбивается. За стеклом — вода, холодный чай, газировка, кофе в банке и энергетик с таким дизайном, будто он обещает не бодрость, а сюжетный поворот.

{sunday_gift_bought:
    # speaker:mc
    Один подарок уже есть. Докупать второй — это уже не забота, а тревожная закупка.
    # return_to_scene
    -> DONE
}

* [Взять воду]
    # speaker:mc
    Вода — самый безопасный вариант. Почти не подарок. Зато честно.

    # speaker:none
    Бутылка холодит ладонь и сразу делает подготовку чуть менее абстрактной.
    # add_item:water_bottle
    # set_flag:sunday_gift_bought=true
    # set_flag:sunday_gift_water_bottle=true
    ~ sunday_gift_bought = true
    ~ sunday_gift_water_bottle = true
    # return_to_scene
    -> DONE

* [Взять холодный чай]
    # speaker:mc
    Холодный чай звучит так, будто я хотя бы попытал{mc_gender == "female":ась|ся} угадать настроение.
    # add_item:gift_iced_tea
    # set_flag:sunday_gift_bought=true
    # set_flag:sunday_gift_iced_tea=true
    ~ sunday_gift_bought = true
    ~ sunday_gift_iced_tea = true
    # return_to_scene
    -> DONE

* [Взять ягодную газировку]
    # speaker:mc
    Слишком яркая. Может, это и хорошо.
    # add_item:gift_berry_soda
    # set_flag:sunday_gift_bought=true
    # set_flag:sunday_gift_berry_soda=true
    ~ sunday_gift_bought = true
    ~ sunday_gift_berry_soda = true
    # return_to_scene
    -> DONE

* [Взять кофе в банке]
    # speaker:mc
    Кофе — подарок человеку, которому я пока не знаю, что сказать.
    # add_item:gift_coffee_can
    # set_flag:sunday_gift_bought=true
    # set_flag:sunday_gift_coffee_can=true
    ~ sunday_gift_bought = true
    ~ sunday_gift_coffee_can = true
    # return_to_scene
    -> DONE

* [Взять энергетик]
    # speaker:mc
    Это либо забота, либо угроза провести вместе ещё восемь часов.
    # add_item:gift_energy_drink
    # set_flag:sunday_gift_bought=true
    # set_flag:sunday_gift_energy_drink=true
    ~ sunday_gift_bought = true
    ~ sunday_gift_energy_drink = true
    # return_to_scene
    -> DONE

+ [Ничего не брать]
    # speaker:mc
    Нет. Я просто посмотрел{mc_gender == "female":а|}. Так тоже бывает.
    # return_to_scene
    -> DONE

=== shop_drinks_with_npc ===
# speaker:none
Холодильники гудят ровно, будто у них воскресенье никогда не сбивается. После прогулки холодные бутылки выглядят не как подарок, а как очень понятная бытовая идея.

* [Взять воду на двоих]
    # speaker:mc
    Возьму воды. На двоих.

    # speaker:npc
    Заботливо. Засчитано.

    # speaker:none
    Холод пластика быстро переходит в ладонь. Две бутылки выглядят смешно серьёзно — как будто заботу правда можно просто снять с полки.
    # set_flag:sunday_shop_bought_drink_for_npc=true
    # set_flag:sunday_shop_done=true
    # add_item:water_bottle
    ~ sunday_shop_bought_drink_for_npc = true
    ~ sunday_shop_done = true
    ~ TRUST = TRUST + 1
    -> sunday_shop_settle

* [Взять холодный чай]
    # speaker:mc
    Может, чай? Он хотя бы делает вид, что это не просто сахар и вода.

    # speaker:npc
    Уважаю напитки с биографией.
    # set_flag:sunday_shop_bought_drink_for_npc=true
    # set_flag:sunday_shop_done=true
    ~ sunday_shop_done = true
    -> sunday_shop_settle

+ [Не брать напитки]
    # speaker:mc
    Нет, холодильники сегодня слишком уверенные.
    # return_to_scene
    -> DONE

=== shop_snacks_interact ===
{met_npc_sunday:
    -> shop_snacks_with_npc
- else:
    -> shop_snacks_pre_date
}

=== shop_snacks_pre_date ===
# speaker:none
Центральный стеллаж выглядит убедительнее, чем должен: крекеры, чипсы, орешки, вафли и шоколадки. Всё слишком яркое и слишком готовое стать “ну ладно, возьму”.

{sunday_gift_bought:
    # speaker:mc
    Подарок уже выбран. Переигрывать его у стеллажа со снеками — плохой жанр тревоги.
    # return_to_scene
    -> DONE
}

* [Взять солёные крекеры]
    # speaker:mc
    Крекеры. Не романтично, зато можно разделить без церемонии.
    # add_item:gift_crackers
    # set_flag:sunday_gift_bought=true
    # set_flag:sunday_gift_crackers=true
    ~ sunday_gift_bought = true
    ~ sunday_gift_crackers = true
    # return_to_scene
    -> DONE

* [Взять маленькие чипсы]
    # speaker:mc
    Чипсы — это уже смелее. И громче.
    # add_item:gift_chips
    # set_flag:sunday_gift_bought=true
    # set_flag:sunday_gift_chips=true
    ~ sunday_gift_bought = true
    ~ sunday_gift_chips = true
    # return_to_scene
    -> DONE

* [Взять орешки]
    # speaker:mc
    Орешки выглядят почти взросло. Значит, подозрительно.
    # add_item:gift_nuts
    # set_flag:sunday_gift_bought=true
    # set_flag:sunday_gift_nuts=true
    ~ sunday_gift_bought = true
    ~ sunday_gift_nuts = true
    # return_to_scene
    -> DONE

* [Взять тёмный шоколад]
    # speaker:mc
    Тёмный шоколад. Нормальный выбор. Может, даже слишком нормальный.
    # add_item:gift_dark_chocolate
    # set_flag:sunday_gift_bought=true
    # set_flag:sunday_gift_dark_chocolate=true
    ~ sunday_gift_bought = true
    ~ sunday_gift_dark_chocolate = true
    # return_to_scene
    -> DONE

* [Взять молочный шоколад]
    # speaker:mc
    Молочный шоколад — это честная попытка быть приятным{mc_gender == "female":ой|ым}.
    # add_item:gift_milk_chocolate
    # set_flag:sunday_gift_bought=true
    # set_flag:sunday_gift_milk_chocolate=true
    ~ sunday_gift_bought = true
    ~ sunday_gift_milk_chocolate = true
    # return_to_scene
    -> DONE

* [Взять вафельный батончик]
    # speaker:mc
    Вафля — компактная форма оптимизма.
    # add_item:gift_waffle_bar
    # set_flag:sunday_gift_bought=true
    # set_flag:sunday_gift_waffle_bar=true
    ~ sunday_gift_bought = true
    ~ sunday_gift_waffle_bar = true
    # return_to_scene
    -> DONE

+ [Оставить как есть]
    # speaker:mc
    Снеки переживут моё отсутствие.
    # return_to_scene
    -> DONE

=== shop_snacks_with_npc ===
# speaker:none
Центральный стеллаж выглядит убедительнее, чем должен: батончики, жвачка, мармелад, маленькие пачки печенья. Всё слишком яркое и слишком готовое стать “ну ладно, возьму”.

* [Взять что-нибудь сладкое]
    # speaker:mc
    Надо взять что-нибудь сладкое. Чтобы день официально не был взрослым.

    # speaker:npc
    Хорошая защита от взрослости.

    # speaker:none
    {npc_name} выбирает не сразу: батончик, мармелад, снова батончик. Решение маленькое, но пауза получается настоящей.
    # set_flag:sunday_shop_bought_snack=true
    # set_flag:sunday_shop_done=true
    ~ sunday_shop_bought_snack = true
    ~ sunday_shop_done = true
    ~ TRUST = TRUST + 1
    -> sunday_shop_settle

* [Спросить, что обычно берёт {npc_name}]
    # speaker:mc
    А ты что обычно берёшь в таких местах?

    # speaker:npc
    Что-нибудь ненужное. Чтобы почувствовать, что день не весь по плану.

    # speaker:none
    В итоге в пакете оказывается маленькая упаковка мармелада и чек, который выглядит серьёзнее покупки. Ответ звучит легко, но в нём есть маленькая правда. Ты её не комментируешь — просто слышишь.
    # set_flag:sunday_shop_done=true
    ~ sunday_shop_done = true
    ~ TRUST = TRUST + 1
    -> sunday_shop_settle

+ [Оставить как есть]
    # speaker:mc
    Сладкое подождёт другого импульса.
    # return_to_scene
    -> DONE

=== shop_counter_interact ===
# speaker:none
{sunday_shop_done:
    Касса уже сделала своё: короткий писк терминала, тонкий чек, пакет, который почти ничего не весит.

    {met_npc_sunday:
        # speaker:npc
        Удивительно, как быстро покупка становится доказательством, что мы правда куда-то зашли.

        # speaker:mc
        Чек как документальное подтверждение воскресенья.
    - else:
        # speaker:mc
        Главное — не потерять чек раньше, чем смысл покупки.
    }
- else:
    Касса стоит у выхода: терминал, сканер, маленькая зона ожидания. {not met_npc_sunday:
        Если брать подарок, сначала надо выбрать один — и только один. Касса не спасает от нерешительности.
    - else:
        Пока здесь нечего делать — сначала надо выбрать что-то с полки.
    }
}
# return_to_scene
-> DONE


// ================================================================
// БЫТОВОЙ ОТДЕЛ — заготовка под повторные визиты и iter 2+
// ================================================================
// В iter 1 это flavor-комната: 3 хотспота, у каждого описание +
// 2 строки с NPC. Никаких pickup'ов / выборов / флагов. Игрок проходит
// мимо и идёт обратно к кассе.
//
// Сцена существует потому что:
//   1) Магазин — рекуррентная локация. В Mon/Tue петлях ГГ будет
//      возвращаться (например за зубной щёткой / батарейками / лампочкой),
//      бытовой отдел станет источником конкретных items.
//   2) В iter 2+ household отыграет тревожно — намёк уже зашит в
//      shop_household_goods_interact: «ценник наклеен ниже остальных...
//      глаз почему-то возвращается к нему снова». Добавить
//      {iteration_number > 1: ...} ветку с реальной аномалией.
//   3) Геометрия 3-хотспотного отдела позволяет позже легко добавить
//      хозтовары как inventory-targets (например купить салфетки чтобы
//      использовать на пятне в офисе).
//
// При правках iter 1: НЕ удалять scene shop_household — иначе придётся
// перенастраивать переходы to_shop_household / to_shop_front и
// PROJECT_INVENTORY потеряет существующий scene_id.

=== shop_household_goods_interact ===
# speaker:none
Бытовой отдел встречает вещами, о которых вспоминают не вовремя: пакеты, губки, лампочки, батарейки, рулоны бумаги, чистящие средства.

{iteration_number > 1:
    На нижней полке один ценник наклеен чуть ниже остальных. Тот же самый: тот же угол, тот же шрифт, тот же кусочек скотча.

    # speaker:mc
    Почему я знаю, что он именно этот.
    ~ INSIGHT = INSIGHT + 1
    ~ anomaly_noticed = true
- else:
    На нижней полке один ценник наклеен чуть ниже остальных. Ничего странного — просто глаз почему-то возвращается к нему снова.
}

{not met_npc_sunday:
    {sunday_gift_bought:
        # speaker:mc
        Подарок уже есть. Второй предмет превратит подготовку в странный набор для выживания.
    - else:
        # speaker:mc
        Вот он. Самый странный кандидат в подарки.

        * [Взять фонарик-брелок]
            # speaker:none
            На маленьком блистере висит фонарик-брелок: пластиковый корпус, металлическое кольцо, кнопка, которая обещает крошечный круг света.

            # speaker:mc
            Это не красиво. Зато понятно. Способ не потеряться — тоже подарок.
            # add_item:gift_keychain_flashlight
            # set_flag:sunday_gift_bought=true
            # set_flag:sunday_gift_keychain_flashlight=true
            ~ sunday_gift_bought = true
            ~ sunday_gift_keychain_flashlight = true
            # return_to_scene
            -> DONE

        * [Оставить фонарик]
            # speaker:mc
            Нет. Не сейчас. Если я беру странный подарок, пусть это будет осознанно, а не потому что он первым попался на полке.
            # return_to_scene
            -> DONE
    }
}

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
# speaker:none
На крючках висят перчатки, щётки и совки. Внизу стоят швабры — слишком прямые, слишком терпеливые, будто они давно приняли человеческий хаос как условие работы.

{iteration_number > 1:
    # speaker:mc
    Каждый раз кажется, что если купить правильную щётку, дома станет чуть больше порядка.

    # speaker:none
    «Каждый раз». Слово звучит привычнее, чем должно.
    ~ INSIGHT = INSIGHT + 1
    ~ anomaly_noticed = true
- else:
    # speaker:mc
    Каждый раз кажется, что если купить правильную щётку, дома станет чуть больше порядка.
}

{not met_npc_sunday:
    {sunday_gift_bought:
        # speaker:mc
        Веник смотрит укоризненно, но поезд уже ушёл: подарок выбран.
    - else:
        * [Взять маленький веник]
            # speaker:mc
            Если это сработает, значит у нас с {npc_name_ins} очень специфическое будущее.
            # add_item:gift_small_broom
            # set_flag:sunday_gift_bought=true
            # set_flag:sunday_gift_small_broom=true
            ~ sunday_gift_bought = true
            ~ sunday_gift_small_broom = true
            # return_to_scene
            -> DONE

        * [Оставить веник]
            # speaker:mc
            Нет. Даже для меня это пока слишком смелый бытовой жест.
            # return_to_scene
            -> DONE
    }
}

{met_npc_sunday:
    # speaker:npc
    Опасная мысль. Так люди и уходят отсюда с ведром, которое им не нужно.

    # speaker:mc
    Ведро хотя бы честнее большинства импульсивных покупок.
}

# return_to_scene
-> DONE

=== shop_paper_goods_interact ===
# speaker:none
Полка с бумажными полотенцами и салфетками выглядит почти абсурдно спокойной: белые рулоны, мягкие упаковки, одинаковые обещания “на всякий случай”.

{iteration_number > 1:
    Одна упаковка развёрнута лицом не в ту сторону. Та же самая.

    # speaker:mc
    Я её не трогал. И в прошлый раз не трогал. Но она снова повёрнута именно так.
    ~ INSIGHT = INSIGHT + 1
    ~ anomaly_noticed = true
- else:
    Одна упаковка развёрнута лицом не в ту сторону. Среди такой ровной выкладки это выглядит почти как личное решение.
}

{not met_npc_sunday:
    {sunday_gift_bought:
        # speaker:mc
        Салфетки остаются на полке. Сегодня у меня уже есть один странный ответ.
    - else:
        * [Взять влажные салфетки]
            # speaker:mc
            Практично. Слишком практично. Но вдруг это и есть мой стиль.
            # add_item:gift_wet_wipes
            # set_flag:sunday_gift_bought=true
            # set_flag:sunday_gift_wet_wipes=true
            ~ sunday_gift_bought = true
            ~ sunday_gift_wet_wipes = true
            # return_to_scene
            -> DONE

        * [Взять бумажные салфетки]
            # speaker:mc
            На случай крошек, неловкости и слишком оптимистичных планов.
            # add_item:gift_paper_napkins
            # set_flag:sunday_gift_bought=true
            # set_flag:sunday_gift_paper_napkins=true
            ~ sunday_gift_bought = true
            ~ sunday_gift_paper_napkins = true
            # return_to_scene
            -> DONE

        * [Оставить салфетки]
            # speaker:mc
            Не надо превращать заботу в закупку на всякий случай. Посмотрю ещё.
            # return_to_scene
            -> DONE
    }
}

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
