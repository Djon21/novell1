// ================================================================
// AVOS_S - 10a_sunday.ink / Воскресенье: квартира (спальня, ванная, телефон, коридор, кухня, вечер, сон)
// ================================================================

// ================================================================
// СПАЛЬНЯ
// ================================================================

=== look_bed_morning ===
# speaker:none
{iteration_number > 1:
Постель смята точно так же, как в прошлый раз.
Та же складка на простыне. Тот же край одеяла на полу.

# speaker:mc
Нет. Я просто не выспался.
~ INSIGHT = INSIGHT + 1
- else:
Постель смята. Сон был тяжёлым, с короткими провалами вместо нормального отдыха.
}

# speaker:mc
Хватит лежать.
# set_flag:got_out_of_bed=true
# return_to_scene
-> DONE

=== bedroom_desk_morning ===
# speaker:none
На рабочем столе закрытый ноутбук, блокнот и кабель от телефона.
Блокнот лежит чуть под углом, будто его открывали ночью и потом поспешно закрыли.

{not first_anomaly_seen:
Последняя страница чуть выпирает из-под обложки.

# speaker:mc
Я этого не помню.

# speaker:none
Внутри — одна строка твоим почерком:

«Проверить перед отправкой.»

Ни даты. Ни подписи. Только нажим ручки — слишком сильный для заметки на ходу.
# set_flag:first_anomaly_seen=true
~ first_anomaly_seen = true
~ anomaly_noticed = true
~ INSIGHT = INSIGHT + 1
# note:add:Запись в блокноте:Проверить перед отправкой.
- else:
Блокнот закрыт. Строка внутри никуда не делась, хотя лучше бы исчезла.
}
# return_to_scene
-> DONE

=== look_bedroom_window ===
# speaker:none
За окном город выглядит так, будто воскресенье у него началось раньше твоего: редкие машины, свет в стекле, кто-то с собакой у подъезда.

{iteration_number > 1:
Картинка слишком знакомая. Не похожая — именно та же.
Ты моргаешь, и ощущение проходит.
~ INSIGHT = INSIGHT + 1
- else:
Утро держится ровно: свет, двор, редкие машины. И очень хочется не искать в этом ничего лишнего.
}
# set_flag:sunday_bedroom_window_seen=true
~ sunday_bedroom_window_seen = true
# return_to_scene
-> DONE

// ================================================================
// ВАННАЯ
// ================================================================

=== enter_bathroom_morning_first ===
# bg:bg_apartment_bathroom_day # speaker:none
Ванная встречает прохладной плиткой, зеркалом и тем самым мятным запахом, который обещает бодрость, но пока только обещает.

На раковине — щётка, паста и стакан. Просто утро, которое просит выполнить базовые операции.

# speaker:mc
Ладно. Сначала щётка и паста, потом уже всё остальное.

# set_flag:bathroom_morning_seen=true
# return_to_scene
-> DONE

=== look_bathroom_mirror ===
{sunday_evening_started:
    # speaker:none
    В ванной горит только ровный искусственный свет. Зеркало больше не пытается сделать утро бодрым — просто возвращает лицо после прогулки, разговора и дороги домой.

    # speaker:mc
    Утром я смотрел{mc_gender == "female":а|} сюда как на старт дня. Сейчас — как на точку после него.

    # return_to_scene
    -> DONE
}

# speaker:none
Зеркало показывает человека, который уже взял телефон, но ещё не совсем проснулся.

{iteration_number > 1:
На секунду кажется, что выражение лица уже было отрепетировано.
Потом вода в трубах щёлкает, и мысль распадается.
~ INSIGHT = INSIGHT + 1
- else:
Воскресное лицо: немного сна, немного работы, немного желания не торопиться.
}
# return_to_scene
-> DONE

=== take_toothbrush ===
# speaker:none
Зубная щётка стоит в стакане у раковины.

# speaker:mc
Взял{mc_gender == "female":а|} щётку.
{toothpaste_taken:
    Теперь надо открыть инвентарь и соединить щётку с пастой.
- else:
    Теперь нужна паста. Потом соединю их в инвентаре.
}

# add_item:toothbrush
# set_flag:toothbrush_taken=true
~ toothbrush_taken = true
# hud:hint:bag
# return_to_scene
-> DONE

=== take_toothpaste ===
# speaker:none
Тюбик пасты смят посередине и стоит так, будто его тоже подняли слишком рано.

# speaker:mc
Пасту взял{mc_gender == "female":а|}.
{toothbrush_taken:
    Теперь надо открыть инвентарь и соединить пасту со щёткой.
- else:
    Осталась щётка. Потом соединю их в инвентаре.
}

# add_item:toothpaste
# set_flag:toothpaste_taken=true
~ toothpaste_taken = true
# hud:hint:bag
# return_to_scene
-> DONE

=== bathroom_sink_prompt ===
# speaker:mc
{toothbrush_pasted_ready:
    Щётка уже готова. Надо использовать её на раковине.
- else:
    {toothbrush_taken and toothpaste_taken:
        Щётка и паста уже в инвентаре. Надо соединить их, а потом использовать щётку на раковине.
    - else:
        {toothbrush_taken:
            Щётка уже есть. Нужна паста, потом соединить их в инвентаре.
        - else:
            {toothpaste_taken:
                Паста уже есть. Нужна щётка, потом соединить их в инвентаре.
            - else:
                Вода есть. Осталось взять щётку и пасту, соединить их в инвентаре и использовать на раковине.
            }
        }
    }
}

# hud:hint:bag
# return_to_scene
-> DONE

=== bathroom_exit_locked ===
# speaker:mc
Нет. Я уже в ванной, щётка и паста передо мной.
Сначала надо соединить их в инвентаре и почистить зубы у раковины.

# hud:hint:bag
# return_to_scene
-> DONE

// TODO iter 2+: повторный клик на раковину/щётку ПОСЛЕ `washed_up`.
// Сейчас все ванные хотспоты скрыты через visible_when после умывания,
// так что knot недостижим. Когда iter 2+ откроет цикл «вернуться в петлю
// и снова попробовать утренний ритуал», нужно добавить либо хотспот
// `bathroom_sink_again` (visible_when = washed_up), либо routing через
// существующий bathroom_sink_prompt с веткой по washed_up.
=== bathroom_not_now ===
# speaker:mc
Умылся. Второй раз бодрее не станет.
# return_to_scene
-> DONE

=== take_phone ===
# speaker:none
{iteration_number > 1:
Телефон лежит экраном вниз у тумбочки.

Ровно там же.

Когда пальцы касаются корпуса, экран вспыхивает слишком знакомо: воскресенье, утро, старые ленты, те же чаты, те же сервисные уведомления.

# sfx:phone_notify

# speaker:mc
Отлично. Он не просто дату потерял. Он откатился.

# speaker:none
Это всё ещё можно объяснить. Плохая синхронизация. Сбой истории. Кэш. Что угодно, лишь бы не произносить вслух самое неприятное объяснение.
- else:
Телефон лежит экраном вниз у тумбочки.
Не на зарядке. Не совсем там, где ты его оставлял.

Когда пальцы касаются корпуса, экран вспыхивает сам.

# sfx:phone_notify
# speaker:none
Старые ленты как были, так и есть — банк, дом, чаты, прод. Поверх них — пара свежих сообщений, которые пришли пока ты спал{mc_gender == "female":а|}.

# speaker:mc
Телефон всегда знает, что день начался, даже если я ещё нет.
}

# add_item:phone
~ phone_taken = true
~ phone_active = true
# set_flag:phone_active=true
# set_flag:phone_taken=true

// Сегодняшние свежие SMS-беспокойства поверх истории живут в 92_phone_sms.ink.
-> phone_sms_take_phone_sunday_morning ->

// Свежие в Messenger (пара штук, не лавина) живут в 93_phone_messenger.ink.
-> phone_msg_take_phone_sunday_morning ->

# quest:start:make_coffee
# map:lock_all
# phone:app:sms
# return_to_scene
-> DONE

// ================================================================
// КОРИДОР
// ================================================================

=== look_hall_mirror ===
{sunday_evening_started:
    # speaker:none
    Ночной коридор в зеркале выглядит глубже, чем утром: тёмная дверь за спиной, тонкая полоска света из кухни, плечи чуть ниже после длинного дня.

    # speaker:mc
    Я дома. И это сейчас важнее, чем выглядеть собранно.

    # return_to_scene
    -> DONE
}

# speaker:none
Зеркало в коридоре показывает ровно то, что должно: лицо, плечи, входную дверь за спиной.

{iteration_number > 1:
На секунду кажется, что отражение моргнуло раньше тебя.
Нет. Свет от окна. Усталость.
~ INSIGHT = INSIGHT + 1
- else:
Ничего странного. Отражение человека, который слишком много работает.
}
# return_to_scene
-> DONE

=== sunday_get_dressed ===
# speaker:none
Куртка с вешалки, обувь у двери. Никакого торжественного выхода — просто бытовая последовательность, без которой человек не попадает в город.

# speaker:mc
Так. Теперь я хотя бы похож{mc_gender == "female":а|} на человека, который собирается выйти.

# set_flag:sunday_dressed=true
~ sunday_dressed = true
# return_to_scene
-> DONE

=== leave_apartment_prompt ===
{iteration_number == 2 and not loop2_work_check_done:
    {not sunday_dressed:
        # speaker:mc
        Если сегодня среда, то сначала надо хотя бы выйти как на работу.

        # speaker:none
        Телефон может показывать что угодно, но город проверяется не с кровати. Куртка и обувь у двери.

        # return_to_scene
        -> DONE
    - else:
        -> loop2_fake_wednesday_leave_for_work
    }
}
{not date_agreed:
    {sunday_messenger_invite_sent:
        # speaker:mc
        Телефон уже вибрировал. Сначала надо ответить в Messenger — иначе выходить всё ещё некуда.

        # speaker:none
        Дверь никуда не делась. Просто теперь между мной и улицей лежит неотвеченный вопрос.

        # hud:hint:phone
        # return_to_scene
        -> DONE
    - else:
        # speaker:mc
        Я только проснул{mc_gender == "female":ась|ся}. Выходить пока некуда.

        # speaker:none
        Воскресенье ещё не требует двери. Сначала кухня, кофе — и тогда уже станет понятно, зовёт ли день наружу.

        # return_to_scene
        -> DONE
    }
- else:
    {not sunday_dressed:
        # speaker:mc
        Встреча уже есть. Осталось выглядеть так, будто я действительно собира{mc_gender == "female":лась|лся} выйти.

        # speaker:none
        Куртка и обувь у двери. Без них выход будет выглядеть как эксперимент, а не прогулка.

        # return_to_scene
        -> DONE
    - else:
        -> leave_apartment
    }
}

=== leave_apartment ===
# speaker:none
Куртка и обувь наконец делают намерение выйти похожим на действие.

{coffee_drunk:
Кофе уже работает где-то под рёбрами.
- else:
    {breakfast_done:
    Я даже успел{mc_gender == "female":а|} что-то съесть. Почти взрослая победа.
    - else:
        {water_drunk:
        Хотя бы воды выпил{mc_gender == "female":а|}. Уже не худший старт.
        - else:
        Желудок напоминает, что встреча — не завтрак. Но сейчас уже поздно спорить с утром.
        }
    }
}

# speaker:mc
Телефон в кармане. Этого достаточно.

{date_place_cafe:
Кафе. Спокойно. Тепло.
- else:
Парк у реки. Воздух точно не помешает.
}

# speaker:none
Замок щёлкает за спиной не драматично, а по-домашнему: день действительно начался.

На экране телефона открывается карта. Можно сразу ехать на встречу — или сделать маленький крюк через магазин у дома.

# set_flag:sunday_ready_to_leave=true
# set_flag:left_apartment=true
~ sunday_ready_to_leave = true
~ can_leave_apt = true
# quest:done:make_coffee
# quest:start:meet_npc
# speaker:none
Система делает паузу. На экране появится короткая реклама, потом всё продолжится с того же места.

# adv:fullscreen
# set_flag:map_opened_after_apartment=true
~ map_opened_after_apartment = true
# map:allow:reset
# map:allow:poi_shop
{date_place_cafe:
    # map:allow:poi_cafe
- else:
    # map:allow:poi_park
}
# phone:map
-> DONE

// Триггерится из 91_inventory_actions.ink ->
// inv_apartment_kitchen_use_mug_on_coffee_setup (после варки кофе).
// Идемпотентно через sunday_messenger_invite_sent — повторные стрелки
// просто фолбэчат на «телефон уже вибрировал, ответ в Messenger».
=== sunday_send_messenger_invite ===
{not sunday_messenger_invite_sent:
    # speaker:none
    Телефон на столешнице коротко вибрирует — не как утренний шум, а как сообщение, которое ждало, пока ты наконец сделаешь кофе.

    # sfx:phone_notify
    # set_flag:sunday_morning_routine_seen=true
    # set_flag:sunday_messenger_invite_sent=true
    ~ sunday_morning_routine_seen = true
    ~ sunday_messenger_invite_sent = true
    -> phone_msg_sunday_invite_after_coffee ->
# quest:start:reply_npc
# quest:start:loop2_date
# hud:hint:phone
- else:
    # speaker:none
    Телефон лежит рядом. Новое сообщение уже ждёт в Messenger.
}
# return_to_scene
-> DONE

// ================================================================
// КУХНЯ
// ================================================================

=== use_coffee_setup_no_mug ===
# speaker:mc
{mug_taken:
    Кружка у меня. Надо не просто смотреть на чайник, а использовать её здесь.
- else:
    Чайник на месте. Кофе тоже.

    Не хватает только кружки.
}

# return_to_scene
-> DONE

=== take_mug ===
# speaker:none
На столе стоит белая кружка с тонкой трещиной на ручке.
Домашняя. Та, которую легко узнать на ощупь.

{iteration_number > 1:
Она снова стоит на том же месте.
Даже ручка повернута под тем же углом.
~ INSIGHT = INSIGHT + 1
}

# speaker:mc
Подойдёт. Теперь к чайнику.
# add_item:mug
~ mug_taken = true
# set_flag:mug_taken=true
# hud:hint:bag
# return_to_scene
-> DONE


=== look_kitchen_window ===
{sunday_evening_started:
    # speaker:none
    За кухонным окном двор уже не светлый, а точечный: окна напротив, лампа у подъезда, редкие фары за деревьями. Утреннее солнце ушло так буднично, будто его здесь и не было.

    {sunday_kitchen_window_seen:
        Днём за этим стеклом всё казалось проще: машины, тени, люди с пакетами. Ночью те же контуры выглядят как черновик.
    - else:
        Серой машины у подъезда не разобрать. Может, она там. Может, нет. В темноте двор легче прощает неточности.
    }

    # return_to_scene
    -> DONE
}

# speaker:none
{sunday_kitchen_window_seen:
    Лето держится во дворе уверенно: солнце на стекле машин, тени от деревьев, кто-то медленно несёт пакет из магазина.

    # return_to_scene
    -> DONE
- else:
    Окно выходит во двор. Солнце уже поднялось достаточно высоко, чтобы кухня казалась теплее, чем есть на самом деле.

    {iteration_number > 1:
    У подъезда снова стоит серая машина без номеров.
    Ты не знаешь, почему слово «снова» приходит первым.
    ~ anomaly_noticed = true
    ~ INSIGHT = INSIGHT + 1
    - else:
    У подъезда стоит серая машина без номеров. Наверное, соседская. Или временно припарковали.
    }

    ~ sunday_kitchen_window_seen = true
    # set_flag:sunday_kitchen_window_seen=true
    # return_to_scene
    -> DONE
}

=== take_kitchen_apple ===
# speaker:none
В миске на столе лежат зелёные яблоки. Одно холодит ладонь чуть сильнее остальных.

# speaker:mc
Завтрак уровня "я старал{mc_gender == "female":ась|ся}".

# set_flag:breakfast_done=true
~ breakfast_done = true
# return_to_scene
-> DONE

=== look_kitchen_fridge ===
# speaker:none
В холодильнике йогурт, сыр и контейнер, который лучше не открывать без отдельного морального разрешения.

* [Взять йогурт]
    # speaker:mc
    Йогурт — это почти завтрак. Если не читать состав.
    # set_flag:breakfast_done=true
    # set_flag:fridge_checked=true
    ~ breakfast_done = true
    ~ fridge_checked = true
    # return_to_scene
    -> DONE

* [Просто закрыть]
    # speaker:mc
    Нет. Холодильник сегодня остаётся загадкой.
    # set_flag:fridge_checked=true
    ~ fridge_checked = true
    # return_to_scene
    -> DONE


// ================================================================
// ITER 2: ложная среда -> проверка офиса -> воскресный invite
// ================================================================

=== loop2_fake_wednesday_leave_for_work ===
# speaker:none
Куртка, обувь, телефон в кармане. Всё складывается в рабочий маршрут слишком легко — как будто тело ещё не получило обновление календаря.

# speaker:mc
Телефон может глючить. Офис — нет.

# speaker:none
Дверь закрывается за спиной. На этот раз выход не похож на прогулку и не похож на свидание. Это проверка: если сегодня среда, город должен вести себя как среда.

# set_flag:left_apartment=true
# map:lock_all
-> loop2_fake_wednesday_work_check

=== loop2_fake_wednesday_work_check ===
# bg:bg_office_lobby_day # speaker:none
Бизнес-центр встречает стеклом, охраной и слишком чистым холлом.

Но турникеты темны.

Не сломаны. Просто выключены. На стойке охраны стоит табличка с воскресным расписанием, и она выглядит не как ошибка интерфейса, а как вещь, которая вообще не обязана оправдываться.

# speaker:mc
Нет. Ну нет.

# speaker:none
Можно спорить с датой на экране. Можно спорить со старыми сообщениями. С пустым офисом спорить труднее.

У рабочих лифтов нет привычного гула. На этаже за стеклом нет людей, нет разговоров, нет запаха кофе из автомата. Среда, в которую ты пытал{mc_gender == "female":ась|ся} попасть, не открывается.

Телефон вибрирует.

# sfx:phone_notify

Сообщение от {npc_name_gen} появляется ровно там, где уже появлялось однажды.

~ loop2_work_check_done = true
~ loop2_invite_after_office_sent = true
~ anomaly_noticed = true
~ INSIGHT = INSIGHT + 1
# set_flag:loop2_work_check_done=true
# set_flag:loop2_invite_after_office_sent=true
{mc_gender == "female":
    # msg:add:artem:Эй, ты там?
    # msg:add:artem:Я так и не получил ответа.
    # msg:add:artem:Всё в порядке?
    # msg:need_reply:artem
    # msg:prompt:artem:msg_thread_artem:ОТВЕТИТЬ
- else:
    # msg:add:mila:Эй, ты там?
    # msg:add:mila:Я так и не получила ответа.
    # msg:add:mila:Всё в порядке?
    # msg:need_reply:mila
    # msg:prompt:mila:msg_thread_mila:ОТВЕТИТЬ
}
# quest:start:reply_npc
# hud:hint:phone
-> loop2_return_home_after_office

=== loop2_return_home_after_office ===
# speaker:none
Обратная дорога занимает меньше времени, чем путь сюда. Может, потому что теперь не нужно никуда торопиться. Может, потому что тело уже знает маршрут.

Двор встречает тем же светом, что и утром. Серая машина всё ещё стоит у подъезда — или это другая серая машина. Разница сейчас не имеет значения.

Замок щёлкает. Квартира принимает обратно без вопросов: тот же коридор, то же зеркало, та же тишина, которая не спрашивает, зачем ты уходил{mc_gender == "female":а|}.

# bg:bg_apartment_hall_day
# set_flag:loop2_returned_home=true
-> loop2_accept_sunday

=== loop2_accept_sunday ===
# speaker:none
В коридоре тихо.

Обувь у порога, куртка на вешалке, ключи звякнули о полку — и теперь не двигаются. Только что ты вернулся из города, который не признал среду, и это был не сбой телефона и не глюк календаря.

Это была проверка. И она провалилась так чисто, что отрицать маршрут дальше — просто тратить время, которого у тебя, возможно, вообще нет.

# speaker:mc
Офис закрыт. Среда не случилась.

# speaker:none
Слова падают в коридор как простой факт: без паники, без отрицания, без попытки найти третье объяснение между «глюком» и «петлёй».

# speaker:mc
Значит, воскресенье. Снова.

# speaker:none
Пауза держится ровно столько, сколько нужно, чтобы слово перестало быть диагнозом и стало просто названием дня.

# speaker:mc
Раз мир решил повторить воскресенье — я хотя бы могу прожить его иначе. Не как день, который я уже проходил{mc_gender == "female":а|}, а как день, в котором я уже был{mc_gender == "female":а|}.

~ anomaly_interpreted = true
~ INSIGHT = INSIGHT + 1
# set_flag:anomaly_interpreted=true
# quest:done:check_the_loop

# speaker:none
Телефон коротко вибрирует — напоминание о сообщении, которое пришло, пока ты проверял{mc_gender == "female":а|} пустую реальность.

# sfx:phone_notify

# speaker:mc
{mc_gender == "female":Он - else:Она} всё ещё ждёт ответа.

# speaker:none
{sunday_shop_pre_date_visited:
Ты вспоминаешь, что в прошлый раз — или в тот раз, который был «первым» — забежал{mc_gender == "female":а|} в магазин перед встречей.
}

Рука сама тянется к экрану. Не потому что нужно ответить. А потому что в этом дне, который повторяется, есть хотя бы одна вещь, которую не хочется прожить иначе: встреча.

# set_flag:date_agreed=true
# set_flag:sunday_messenger_invite_sent=true
~ date_agreed = true
~ sunday_messenger_invite_sent = true

# quest:start:reply_npc
# hud:hint:phone
# goto_scene:apartment_hub
-> DONE

// ================================================================
// ВОСКРЕСЕНЬЕ: ВЫБОР МАРШРУТА (из квартиры)
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
# map:lock_all
# explore:park_hub
-> DONE


// ================================================================
// КАФЕ
// ================================================================

// ================================================================
// ВОСКРЕСЕНЬЕ: ВЕЧЕР И СОН
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
# bg:bg_apartment_hall_night # speaker:none
Коридор встречает тем же спокойствием, с которого началось утро. Только теперь оно ощущается иначе: не как список дел, а как место, куда можно вернуться.

{not loop2_revealed_to_npc:
    Дверь закрывается за спиной мягко, почти буднично. Обувь остаётся у порога, ключи ложатся на полку, и квартира на несколько секунд становится тише любого места, где вы сегодня были.
- else:
    Дверь закрывается, и вместе с ней — день, который ты прожил{mc_gender == "female":а|} дважды. Ключи на полку, обувь к порогу, и только в коридоре доходит: ты не один знаешь об этом.
}

Итоги ещё не хочется раскладывать по полкам. Пусть день сначала просто побудет в квартире: в тишине, в свете из кухни, в привычном звуке ключей на полке.

Телефон вибрирует уже без тревоги — короткое сообщение от {npc_name_gen}.

# sfx:phone_notify
{loop2_revealed_to_npc:
    -> phone_msg_sunday_evening_home_loop_revealed ->
- else:
    -> phone_msg_sunday_evening_home_thanks ->
}

{loop2_revealed_to_npc:
    # speaker:npc
    Я всё думаю о том, что ты сказал{mc_gender == "female":а|}. Не знаю, правильно ли я сделал{mc_gender == "female":а|}, что поверил{mc_gender == "female":а|}. Но перестать уже не могу.

    # speaker:mc
    Я тоже не могу.

    # speaker:none
    Сообщение остаётся на экране. Между строк — не неловкость, а странная близость: вы оба теперь носите одно и то же знание.

    * [Ответить тепло — подтвердить связь]
        # speaker:mc
        Спасибо, что ты есть. Завтра напишу, как только пойму, что происходит.

        -> phone_msg_sunday_evening_reply_warm ->

        # speaker:none
        Ответ уходит. Ты чувствуешь не облегчение, а тишину после честности.
        ~ TRUST = TRUST + 2
        -> sunday_evening_finish

    * [Ответить спокойно — без драмы]
        # speaker:mc
        Завтра разберёмся. Я напишу.

        -> phone_msg_sunday_evening_reply_calm ->

        # speaker:none
        Коротко. Без паники. Именно так, как нужно, когда мир сошёл с ума, но вы ещё нет.
        ~ SYNC = SYNC + 1
        -> sunday_evening_finish

    * [Не отвечать — переварить]
        # speaker:none
        Ты закрываешь телефон. Не потому что нечего сказать — а потому что слов на этот раз правда мало. Пусть день сначала уляжется в тишине.
        ~ INSIGHT = INSIGHT + 1
        -> sunday_evening_finish
- else:
    # speaker:npc
    Спасибо за сегодня. Было хорошо.

    # speaker:mc
    Мне тоже.

    # speaker:none
    Сообщение остаётся на экране чуть дольше, чем нужно. Воскресенье не требует немедленного отчёта — только ответа, если на него сейчас хватает сил.

    * [Ответить тепло]
        # speaker:mc
        Спасибо, что продолжили день. Я рад{mc_gender == "female":а|}, что мы встретились.

        -> phone_msg_sunday_evening_reply_warm ->

        # speaker:none
        Ответ уходит сразу. В нём нет ничего громкого, но есть точность.
        ~ TRUST = TRUST + 1
        -> sunday_evening_finish

    * [Ответить спокойно]
        # speaker:mc
        Да. Хороший день получился.

        -> phone_msg_sunday_evening_reply_calm ->

        # speaker:none
        Простые слова подходят лучше длинных. Воскресенье не требует отчёта, чтобы быть настоящим.
        ~ SYNC = SYNC + 1
        -> sunday_evening_finish

    * [Не отвечать сразу]
        # speaker:none
        Ты оставляешь сообщение открытым. Не из холодности — просто хочется ещё немного побыть внутри этого дня, не превращая его в переписку.
        ~ INSIGHT = INSIGHT + 1
        -> sunday_evening_finish
}

=== sunday_evening_finish ===
# speaker:none
{loop2_revealed_to_npc:
    Вечер собирает квартиру вокруг тебя тихо, будто давая пространство для мыслей. Коридор, кухня, свет из окна — всё на своих местах.

    Завтра понедельник. И впервые за долгое время ты знаешь, что кто-то будет ждать от тебя вестей не просто из вежливости.

    # speaker:mc
    Я дома. {npc_name} знает. Завтра напишу.

    # speaker:none
    Фраза звучит не как обязательство, а как опора.
- else:
    Вечер постепенно собирает квартиру вокруг тебя: коридор, кухня, свет из окна, телефон на ладони.

    Завтра понедельник. Рабочий день, офис, обычные маршруты.

    Но сегодня пока ещё воскресенье, и ему не обязательно отчитываться прямо в коридоре.

    # speaker:mc
    Я дома. Можно выдохнуть, пройти на кухню, заглянуть в спальню — вечер больше никуда не торопит.
}

# set_flag:sunday_evening_started=true
~ sunday_evening_started = true
# goto_scene:apartment_hub
-> DONE

=== sunday_sleep_in_bed ===
# bg:bg_apartment_bedroom_night # speaker:none
Спальня выглядит почти так же, как утром, только свет стал мягче и ниже.

{loop2_revealed_to_npc:
    Кровать помнит не только утро, но и тот миг, когда ты понял{mc_gender == "female":а|}: день уже был. И решил{mc_gender == "female":а|} сказать об этом.
- else:
    Кровать всё ещё помнит смятое одеяло, тяжёлый сон и то воскресное утро, которое начиналось с вибрации телефона.
}

{date_place_park:
    Ты вспоминаешь парк уже без необходимости куда-то идти: не карту, не точку на экране, а то, как {npc_name} появил{npc_gender == "female":ся|ась} в дне не сразу, а после сообщения.
- else:
    Ты вспоминаешь кафе уже без шума: не стойку, не меню, а момент, когда разговор перестал держаться на заказе и начал держаться на вас двоих.
}

{loop2_revealed_to_npc:
    А потом — бар. Красноватый свет, деревянная стойка, {npc_name} напротив. И разговор, в котором ты перестал{mc_gender == "female":а|} быть единственным человеком, знающим правду.

    {npc_gender == "female": Она поверила|Он поверил}. Не сразу, не до конца, но достаточно, чтобы завтра ждать сообщения.
- else:
    {sunday_went_to_shop:
        Потом вспоминается магазин после встречи — обычный свет, обычные полки, обычная покупка. Воскресенье почему-то выбрало именно такие детали, чтобы казаться настоящим.
    - else:
        Потом вспоминается смотровая — город, перила, лавочка. Высота не дала ответов, но помогла не превращать паузы в проблему.
    }
}

{sunday_gift_bought:
    {sunday_gift_right:
        Фонарик-брелок ненадолго вспыхивает в памяти. Маленький круг света днём почти ничего не освещал, но ты всё равно помнишь именно его.
    - else:
        Подарок был не тем самым, но {npc_name} принял{npc_gender == "female":а его| его} так деликатно, что неловкость не осталась на коже.
    }
- else:
    Пустые руки тоже вспоминаются. Не как ошибка — скорее как напоминание, что иногда прийти самому важнее, чем принести правильную вещь.
}

{loop2_revealed_to_npc:
    # speaker:mc
    Завтра — понедельник. В прошлый раз я пошёл{mc_gender == "female":а|} на работу, и там... что-то пошло не так.

    # speaker:none
    Ты не додумываешь эту мысль. Но впервые за день у тебя есть не только память о том, что было, но и шанс сделать иначе.

    # speaker:mc
    Завтра я узнаю, повторяется ли день. Или петля замкнулась, и понедельник наконец настал по-настоящему.

    # speaker:none
    Телефон ложится на тумбочку экраном вниз. {npc_name} обещал{mc_gender == "female":а|} написать завтра. И ты обещал{mc_gender == "female":а|}.

    На этот раз ты не один.
- else:
    # speaker:mc
    Вот теперь день правда закончился.

    # speaker:none
    Телефон ложится на тумбочку экраном вниз.

    На этот раз он молчит.

    Ты закрываешь глаза — не потому что всё понятно, а потому что воскресенье наконец-то стало целым днём: утро, встреча, второй маршрут, возвращение.

    Понедельник придёт сам.
}

# set_flag:sunday_finished=true
# set_flag:monday_started=true
# quest:done:spend_sunday
# map:allow:reset
~ sunday_finished = true
~ monday_started = true
# splash:day:monday
-> monday_morning_start
