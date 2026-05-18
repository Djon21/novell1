// ================================================================
// AVOS_S - locations/sunday_gift_reactions.ink
//
// Общая обработка реакции NPC на подарок из магазина для воскресенья.
// Раньше эти диалоги дублировались в park_sunday.ink и cafe_sunday.ink:
// одна и та же каскадная проверка предмета, одинаковые # remove_item:
// и один и тот же sunday_gift_given. Здесь это всё вынесено.
//
// Каркас:
//   sunday_gift_react        — entry. Определяет какой именно подарок
//                              в инвентаре, ставит sunday_current_gift,
//                              удаляет item, ставит общие флаги, а потом
//                              диверитит в venue-knot (park или cafe).
//   sunday_gift_react_park   — park-вариант текстов реакции.
//   sunday_gift_react_cafe   — cafe-вариант текстов реакции.
//
// Каждый venue-knot — это switch по sunday_current_gift с локационно
// специфичным NPC-репликами. После реакции диверитит в нужную точку
// продолжения сцены (park_npc_arrives_after_gift / sunday_date_cafe_arrival_after_gift).
// ================================================================

// ----------------------------------------------------------------
// ENTRY: вызывается через `-> sunday_gift_react` из park / cafe сцен.
// Гейтится на стороне вызывающего через {sunday_gift_bought and not sunday_gift_given}.
// ----------------------------------------------------------------
=== sunday_gift_react ===
// 1) Определяем какой именно gift-предмет в инвентаре. Это каскад
//    if-else'ов; первый сматчившийся флаг назначает sunday_current_gift
//    и удаляется из инвентаря. Порядок = приоритет (keychain первый —
//    «правильный» подарок с бонусами TRUST/SYNC).
{sunday_gift_keychain_flashlight:
    ~ sunday_current_gift = "keychain_flashlight"
    # remove_item:gift_keychain_flashlight
- else:
    {sunday_gift_small_broom:
        ~ sunday_current_gift = "small_broom"
        # remove_item:gift_small_broom
    - else:
        {sunday_gift_dark_chocolate:
            ~ sunday_current_gift = "dark_chocolate"
            # remove_item:gift_dark_chocolate
        - else:
            {sunday_gift_water_bottle:
                ~ sunday_current_gift = "water_bottle"
                # remove_item:water_bottle
            - else:
                {sunday_gift_energy_drink:
                    ~ sunday_current_gift = "energy_drink"
                    # remove_item:gift_energy_drink
                - else:
                    {sunday_gift_iced_tea:
                        ~ sunday_current_gift = "iced_tea"
                        # remove_item:gift_iced_tea
                    - else:
                        {sunday_gift_berry_soda:
                            ~ sunday_current_gift = "berry_soda"
                            # remove_item:gift_berry_soda
                        - else:
                            {sunday_gift_coffee_can:
                                ~ sunday_current_gift = "coffee_can"
                                # remove_item:gift_coffee_can
                            - else:
                                {sunday_gift_crackers:
                                    ~ sunday_current_gift = "crackers"
                                    # remove_item:gift_crackers
                                - else:
                                    {sunday_gift_chips:
                                        ~ sunday_current_gift = "chips"
                                        # remove_item:gift_chips
                                    - else:
                                        {sunday_gift_nuts:
                                            ~ sunday_current_gift = "nuts"
                                            # remove_item:gift_nuts
                                        - else:
                                            {sunday_gift_milk_chocolate:
                                                ~ sunday_current_gift = "milk_chocolate"
                                                # remove_item:gift_milk_chocolate
                                            - else:
                                                {sunday_gift_waffle_bar:
                                                    ~ sunday_current_gift = "waffle_bar"
                                                    # remove_item:gift_waffle_bar
                                                - else:
                                                    {sunday_gift_wet_wipes:
                                                        ~ sunday_current_gift = "wet_wipes"
                                                        # remove_item:gift_wet_wipes
                                                    - else:
                                                        {sunday_gift_paper_napkins:
                                                            ~ sunday_current_gift = "paper_napkins"
                                                            # remove_item:gift_paper_napkins
                                                        - else:
                                                            ~ sunday_current_gift = "unknown"
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// 2) Бонус «правильного подарка» — keychain даёт TRUST+SYNC и sunday_gift_right.
//    Это общая логика, не зависит от venue.
{sunday_current_gift == "keychain_flashlight":
    # set_flag:sunday_gift_right=true
    ~ sunday_gift_right = true
    ~ TRUST = TRUST + 1
    ~ SYNC = SYNC + 1
}

// 3) Помечаем что подарок отдан (общий флаг, проверяется в venue-сценах,
//    чтобы повторно не запускать sunday_gift_react).
# set_flag:sunday_gift_given=true
~ sunday_gift_given = true

// 4) Диверт в venue-специфичный текст реакции. Venue определяется флагом
//    места свидания (выставляется в Sunday-morning messenger choice).
{date_place_park:
    -> sunday_gift_react_park
- else:
    -> sunday_gift_react_cafe
}


// ----------------------------------------------------------------
// PARK-вариант реакции. NPC реплики специфичны для дневного парка.
// ----------------------------------------------------------------
=== sunday_gift_react_park ===
# speaker:none
Перед тем как выбрать место, ты вспоминаешь про пакет из магазина. Момент получается не торжественный — скорее такой, который легко пропустить, если слишком долго думать.

{sunday_current_gift == "keychain_flashlight":
    # speaker:mc
    Я тут взял{mc_gender == "female":а|} тебе кое-что. Не совсем подарок. Скорее... предмет с функцией.

    # speaker:npc
    Это... фонарик?

    # speaker:mc
    Фонарик-брелок.

    # speaker:npc
    Очень неожиданная категория заботы.

    # speaker:none
    {npc_name} нажимает кнопку. На ладони появляется маленький круг света, почти незаметный при дневном солнце, но почему-то упрямый.

    # speaker:npc
    Обычно люди приносят шоколад или кофе. А ты принёс{mc_gender == "female":ла|} способ не потеряться.
- else:
    {sunday_current_gift == "small_broom":
        # speaker:mc
        Я взял{mc_gender == "female":а|} тебе подарок. Сразу предупреждаю: он проиграл спор с нормальностью.

        # speaker:npc
        ...Это веник?

        # speaker:mc
        Маленький.

        # speaker:npc
        Спасибо. Это самый тревожно-хозяйственный подарок, который мне когда-либо дарили.

        # speaker:none
        Пауза длится ровно столько, чтобы стало страшно, а потом {npc_name} всё-таки смеётся.

        # speaker:npc
        Но я ценю смелость. И возможность однажды драматично подмести границы между нами.
    - else:
        {sunday_current_gift == "dark_chocolate":
            # speaker:mc
            Я взял{mc_gender == "female":а|} шоколад. Это звучало безопасно.

            # speaker:npc
            Безопасно — не плохо. Я обычно беру потемнее, так что ты почти попал{mc_gender == "female":а|}.
        - else:
            {sunday_current_gift == "water_bottle":
                # speaker:mc
                Я взял{mc_gender == "female":а|} воду. Не подарок. Просто вдруг пригодится.

                # speaker:npc
                Практично. Ты ухаживаешь так, будто мы собираемся в небольшой поход.
            - else:
                {sunday_current_gift == "energy_drink":
                    # speaker:mc
                    Я взял{mc_gender == "female":а|} энергетик.

                    # speaker:npc
                    Ого. Это на случай, если свидание перейдёт в ночную смену?
                - else:
                    {sunday_current_gift == "iced_tea":
                        # speaker:mc
                        Я взял{mc_gender == "female":а|} холодный чай. Вдруг захочется.

                        # speaker:npc
                        Спасибо. Очень дипломатичный напиток.
                    - else:
                        {sunday_current_gift == "berry_soda":
                            # speaker:mc
                            Я взял{mc_gender == "female":а|} газировку. Она выглядела веселее меня.

                            # speaker:npc
                            Тогда у неё сегодня ответственная роль.
                        - else:
                            {sunday_current_gift == "coffee_can":
                                # speaker:mc
                                Я взял{mc_gender == "female":а|} кофе в банке.

                                # speaker:npc
                                Спасибо. Бодрость в алюминии — романтика нашего времени.
                            - else:
                                {sunday_current_gift == "crackers":
                                    # speaker:mc
                                    Я взял{mc_gender == "female":а|} крекеры.

                                    # speaker:npc
                                    Хрустящий аргумент в пользу прогулки. Принято.
                                - else:
                                    {sunday_current_gift == "chips":
                                        # speaker:mc
                                        Я взял{mc_gender == "female":а|} чипсы.

                                        # speaker:npc
                                        Смело. Это подарок, который сразу выдаёт своё присутствие.
                                    - else:
                                        {sunday_current_gift == "nuts":
                                            # speaker:mc
                                            Я взял{mc_gender == "female":а|} орешки.

                                            # speaker:npc
                                            Почти взрослый выбор. Даже подозрительно.
                                        - else:
                                            {sunday_current_gift == "milk_chocolate":
                                                # speaker:mc
                                                Я взял{mc_gender == "female":а|} шоколад.

                                                # speaker:npc
                                                Милый вариант. Немного сладкий даже до открытия.
                                            - else:
                                                {sunday_current_gift == "waffle_bar":
                                                    # speaker:mc
                                                    Я взял{mc_gender == "female":а|} вафельный батончик.

                                                    # speaker:npc
                                                    Хорошо. У свидания теперь есть аварийный запас сахара.
                                                - else:
                                                    {sunday_current_gift == "wet_wipes":
                                                        # speaker:mc
                                                        Я взял{mc_gender == "female":а|} влажные салфетки. Да, звучит странно.

                                                        # speaker:npc
                                                        Зато честно. Очень бытовая форма заботы.
                                                    - else:
                                                        {sunday_current_gift == "paper_napkins":
                                                            # speaker:mc
                                                            Я взял{mc_gender == "female":а|} салфетки. На всякий случай.

                                                            # speaker:npc
                                                            Уважаю людей, которые приходят на встречу с планом против крошек.
                                                        - else:
                                                            # speaker:mc
                                                            Я взял{mc_gender == "female":а|} что-то из магазина. И только сейчас понимаю, что сам{mc_gender == "female":а|} не до конца уверен{mc_gender == "female":а|}, что именно.

                                                            # speaker:npc
                                                            Тогда будем считать это подарком с элементом расследования.
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

-> park_npc_arrives_after_gift


// ----------------------------------------------------------------
// CAFE-вариант реакции. NPC реплики специфичны для кафе.
// ----------------------------------------------------------------
=== sunday_gift_react_cafe ===
# speaker:none
Пауза у края зала напоминает про пакет из магазина. Здесь, среди шума кофемолки и чужих чашек, маленький подарок кажется одновременно уместным и очень заметным.

{sunday_current_gift == "keychain_flashlight":
    # speaker:mc
    Я по дороге взял{mc_gender == "female":а|} тебе кое-что. Не совсем подарок. Скорее... предмет с функцией.

    # speaker:npc
    Это фонарик?

    # speaker:mc
    Фонарик-брелок.

    # speaker:npc
    Неожиданно. Обычно люди приносят шоколад, кофе или цветы. А ты принёс{mc_gender == "female":ла|} способ не потеряться.

    # speaker:none
    {npc_name} нажимает кнопку. В дневном кафе свет почти не виден, но маленькая точка всё равно появляется на ладони.

    # speaker:npc
    Странный подарок. Хороший странный.
- else:
    {sunday_current_gift == "small_broom":
        # speaker:mc
        Я принёс{mc_gender == "female":ла|} подарок. Он немного проиграл нормальности.

        # speaker:npc
        Это веник?

        # speaker:mc
        Маленький.

        # speaker:npc
        Спасибо. Я редко получаю предметы, которые сразу предлагают навести порядок в отношениях.

        # speaker:none
        {npc_name} смотрит на веник ещё секунду и всё-таки улыбается.
    - else:
        {sunday_current_gift == "dark_chocolate":
            # speaker:mc
            Я взял{mc_gender == "female":а|} шоколад. Безопасный вариант.

            # speaker:npc
            Безопасный — не значит плохой. Я обычно беру потемнее, так что ты почти попал{mc_gender == "female":а|}.
        - else:
            {sunday_current_gift == "water_bottle":
                # speaker:mc
                Я взял{mc_gender == "female":а|} воду. Не знал{mc_gender == "female":а|}, что захочется, но вдруг.

                # speaker:npc
                Практично. Ты ухаживаешь так, будто мы собираемся в небольшой поход.
            - else:
                {sunday_current_gift == "energy_drink":
                    # speaker:mc
                    Я взял{mc_gender == "female":а|} энергетик.

                    # speaker:npc
                    Ого. Это если кафе окажется слишком спокойным?
                - else:
                    {sunday_current_gift == "iced_tea":
                        # speaker:mc
                        Я взял{mc_gender == "female":а|} холодный чай.

                        # speaker:npc
                        Спасибо. Очень мирный подарок.
                    - else:
                        {sunday_current_gift == "berry_soda":
                            # speaker:mc
                            Я взял{mc_gender == "female":а|} газировку. Она выглядела так, будто умеет спасать паузы.

                            # speaker:npc
                            Отлично. У нас как раз пара пауз без страховки.
                        - else:
                            {sunday_current_gift == "coffee_can":
                                # speaker:mc
                                Я взял{mc_gender == "female":а|} кофе в банке. Что странно, учитывая, где мы сейчас стоим.

                                # speaker:npc
                                Зато последовательность намерений впечатляет.
                            - else:
                                {sunday_current_gift == "crackers":
                                    # speaker:mc
                                    Я взял{mc_gender == "female":а|} крекеры.

                                    # speaker:npc
                                    Спасибо. Теперь у свидания есть хрустящий план Б.
                                - else:
                                    {sunday_current_gift == "chips":
                                        # speaker:mc
                                        Я взял{mc_gender == "female":а|} чипсы.

                                        # speaker:npc
                                        Сильный ход. Кафе ещё не готово к такому уровню хруста.
                                    - else:
                                        {sunday_current_gift == "nuts":
                                            # speaker:mc
                                            Я взял{mc_gender == "female":а|} орешки.

                                            # speaker:npc
                                            Почти взрослый подарок. Даже подозрительно.
                                        - else:
                                            {sunday_current_gift == "milk_chocolate":
                                                # speaker:mc
                                                Я взял{mc_gender == "female":а|} молочный шоколад.

                                                # speaker:npc
                                                Спасибо. Очень мягкий выбор. Даже упаковка старается быть доброй.
                                            - else:
                                                {sunday_current_gift == "waffle_bar":
                                                    # speaker:mc
                                                    Я взял{mc_gender == "female":а|} вафельный батончик.

                                                    # speaker:npc
                                                    Хорошо. У нас теперь есть аварийная сладость, если разговор станет слишком взрослым.
                                                - else:
                                                    {sunday_current_gift == "wet_wipes":
                                                        # speaker:mc
                                                        Я взял{mc_gender == "female":а|} влажные салфетки. Да, я понимаю, как это звучит.

                                                        # speaker:npc
                                                        Как человек, который готов к бытовому хаосу. Это не худшее качество.
                                                    - else:
                                                        {sunday_current_gift == "paper_napkins":
                                                            # speaker:mc
                                                            Я взял{mc_gender == "female":а|} салфетки. На всякий случай.

                                                            # speaker:npc
                                                            Спасибо. Очень взрослая форма тревоги.
                                                        - else:
                                                            # speaker:mc
                                                            Я взял{mc_gender == "female":а|} что-то из магазина. И только сейчас понимаю, что сам{mc_gender == "female":а|} не до конца уверен{mc_gender == "female":а|}, что именно.

                                                            # speaker:npc
                                                            Тогда это концептуальный подарок. Кафе такое выдержит.
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// Cafe-эксклюзивный флаг: малая забота как «момент свидания».
// (В парковом варианте такого нет — это намеренно: разные локации
// дают разные сюжетные оттенки.)
# set_flag:date_small_kindness=true
~ date_small_kindness = true

-> sunday_date_cafe_arrival_after_gift
