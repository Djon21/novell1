// ================================================================
// AVOS_S — 01_apartment.ink
// Apartment onboarding scene, synced with current 1920x1080 apartment backgrounds.
//
// ВАЖНО:
// - Имена knot'ов сохранены под scenes.lua.
// - До choose_character нет speaker:mc / speaker:npc.
// - Описания мира идут через speaker:none.
// - Внутренний голос/действия ГГ идут через speaker:mc.
// - Визуальных аномалий нет: странность только через информацию.
// - SMS больше не привязан жёстко к Миле: male -> mila, female -> artem.
// - Воскресное приглашение перенесено из SMS в Messenger.
//
// Совместимые квесты: find_phone, make_coffee, reply_npc, meet_npc. go_to_office стартует позже, в понедельник.
// Совместимые предметы: mug, phone, toothbrush, toothpaste, toothbrush_pasted.
// ================================================================


// ================================================================
// СТАРТ / ВЫБОР ПЕРСОНАЖА
// ================================================================

=== choose_character ===
# bg:bg_apartment_bedroom_morning # speaker:none
Кто я?

* [Артём]
    ~ mc_gender = "male"
    ~ mc_name = "Артём"
    ~ npc_name = "Мила"
    -> apartment_start

* [Мила]
    ~ mc_gender = "female"
    ~ mc_name = "Мила"
    ~ npc_name = "Артём"
    -> apartment_start


=== apartment_start ===
# bg:bg_apartment_bedroom_morning # speaker:none
Воскресное утро.

Спальня тихая и светлая. Слева ещё держит тепло смятая кровать, справа у окна молчит рабочий стол.
За стеклом город уже давно начал день без тебя.

# sfx:phone_notify
Где-то рядом коротко вибрирует телефон.

{iteration_number > 1:
На секунду возникает ощущение, что эта тишина уже была.
Не похожая. Та же самая.
~ INSIGHT = INSIGHT + 1
~ anomaly_noticed = true
}

# speaker:mc
Сначала до меня доходит вибрация телефона. Потом свет из окна. Потом всё остальное.
# quest:start:find_phone
# explore:apartment_bedroom
-> DONE


// ================================================================
// ON_ENTER KNOTS
// ================================================================

=== apartment_bedroom_intro ===
# bg:bg_apartment_bedroom_morning # speaker:none
Комната собирается из привычных деталей: смятая постель, тумбочка у кровати, рабочий стол у окна, дверь в ванную справа.
Телефон лежит у тумбочки экраном вниз. Экран на мгновение подсвечивается и снова гаснет.

# speaker:mc
Кто пишет в воскресенье с утра?

# speaker:none
Ответ напрашивается сам, но лучше сначала посмотреть.
# set_flag:bedroom_morning_seen=true
# return_to_scene
-> DONE


=== enter_kitchen_morning_first ===
# bg:bg_apartment_kitchen_morning # speaker:none
Кухня встречает сухим щелчком холодильника и светлым окном во двор.
На столешнице — чайник, раковина, плита и всё утреннее, что не требует объяснений.

# speaker:mc
Кофе. Без героизма.
# set_flag:kitchen_morning_seen=true
# set_flag:kitchen_intro_seen=true
# return_to_scene
-> DONE


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
# bg:bg_apartment_bedroom_morning # speaker:none
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


=== enter_bathroom_morning_first ===
# bg:bg_apartment_bathroom_morning # speaker:none
Ванная встречает прохладной плиткой, зеркалом и тем самым мятным запахом, который обещает бодрость, но пока только обещает.

На раковине — щётка, паста и стакан. Просто утро, которое просит выполнить базовые операции.

# speaker:mc
Ладно. Сначала щётка и паста, потом уже всё остальное.

# set_flag:bathroom_morning_seen=true
# return_to_scene
-> DONE


=== look_bathroom_mirror ===
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


=== bathroom_not_now ===
# speaker:mc
Умылся. Второй раз бодрее не станет.
# return_to_scene
-> DONE


=== take_phone ===
# speaker:none
Телефон лежит экраном вниз у тумбочки.
Не на зарядке. Не совсем там, где ты его оставлял.

Когда пальцы касаются корпуса, экран вспыхивает сам.

# sfx:phone_notify
# speaker:none
Экран забит уведомлениями: банк, дом, доставка, городские сервисы, работа — утренний шум, который успевает жить раньше тебя.

# speaker:mc
Телефон всегда знает, что день начался, даже если ты ещё нет.

# speaker:none
Ничего, что требует ответа прямо сейчас. Просто жизнь, которая накопилась за ночь и теперь делает вид, что она срочная.

# add_item:phone
~ phone_taken = true
~ phone_active = true
# set_flag:phone_active=true
# set_flag:phone_taken=true
# sms:add:mama:Не забудь позавтракать. И не сиди весь день дома.
# sms:add:bank:Карта *4821: списание 349 ₽. Кофе и выпечка. 08:41.
# sms:add:prod:Напоминание: в понедельник до 11:00 подтвердите статус по кейсу 017.
# sms:add:delivery:Курьер не смог дозвониться. Заказ вернётся в ресторан через 10 минут.
# sms:add:upravdom:Сегодня с 10:00 до 14:00 возможны перебои с горячей водой.
# msg:add:friends:Доброе утро, выжившие. Кто сегодня не отменяет планы в последний момент?
# msg:add:friends:Я могу отменить заранее, чтобы не рушить традицию.
# msg:add:friends:Артём опять онлайн в 07:13. Подозрительно.
# msg:add:friends:Мила тоже. Вы там синхронизировались или что?
# msg:add:work_team:Понедельничная планёрка перенесена на 10:40. Да, в воскресенье. Нет, я тоже не рад.
# msg:add:work_team:По кейсу 017 завтра не забудьте сверить входящие.
# msg:add:work_team:Автостатус опять проставился раньше времени.
# msg:add:prod_bot:CASE-017 создан.
# msg:add:prod_bot:Часть полей ожидает подтверждения.
# msg:add:prod_bot:Черновик решения сохранён.
# msg:add:calendar_bot:Сегодня: встреча без названия. Место: не указано.
# msg:add:calendar_bot:Напоминание удалено пользователем. Пользователь: вы. Время удаления: 08:41.
# msg:add:delivery:Курьер назначен. Заказ: «что-то к чаю». Комментарий курьера: хорошее название.
# msg:add:neighbor_chat:У кого опять будильник играет с 07:00?
# msg:add:neighbor_chat:Если это «мягкий джаз для продуктивности», он уже продуктивно бесит весь подъезд.
# msg:add:city_bot:Солнечно. Летний день без осадков, будто специально для прогулки.
# msg:add:city_bot:Маршруты работают штатно. Задержек нет.
# msg:add:meme_chat:Утро начинается не с кофе, а с принятия плохих интерфейсных решений.
# msg:add:meme_chat:Удалено: изображение недоступно.
# msg:add:unknown:Не торопись.
# msg:add:unknown:Сначала прочитай.
# quest:done:find_phone
# quest:start:make_coffee
# map:lock_to:poi_home
# phone:app:sms
# return_to_scene
-> DONE


// ================================================================
// КОРИДОР
// ================================================================

=== look_hall_mirror ===
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



=== sunday_send_messenger_invite ===
{not sunday_messenger_invite_sent:
    # speaker:none
    Телефон на столешнице коротко вибрирует — не как утренний шум, а как сообщение, которое ждало, пока ты наконец сделаешь кофе.

    # sfx:phone_notify
    # set_flag:sunday_morning_routine_seen=true
    # set_flag:sunday_messenger_invite_sent=true
    ~ sunday_morning_routine_seen = true
    ~ sunday_messenger_invite_sent = true
    {mc_gender == "female":
        # msg:add:artem:Ты сегодня вообще живая?
        # msg:add:artem:Я уже второй кофе пью.
        # msg:add:artem:Выберемся куда-нибудь, пока день не стал совсем домашним?
    - else:
        # msg:add:mila:Ты сегодня вообще живой?
        # msg:add:mila:Я уже второй кофе пью.
        # msg:add:mila:Выберемся куда-нибудь, пока день не стал совсем домашним?
    }
    # quest:start:reply_npc
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



=== use_coffee_machine_with_cup ===
# speaker:mc
Кружка у меня. Надо не просто смотреть на чайник, а использовать её здесь.

# return_to_scene
-> DONE


=== look_kitchen_window ===
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
# bg:bg_apartment_kitchen_morning # speaker:none
В миске на столе лежат зелёные яблоки. Одно холодит ладонь чуть сильнее остальных.

# speaker:mc
Завтрак уровня “я старал{mc_gender == "female":ась|ся}”.

# set_flag:breakfast_done=true
~ breakfast_done = true
# return_to_scene
-> DONE



=== look_kitchen_fridge ===
# bg:bg_apartment_kitchen_morning # speaker:none
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


=== drink_water_kitchen ===
# bg:bg_apartment_kitchen_morning # speaker:none
Вода из-под фильтра прохладная и честная. Не кофе, не ритуал, просто способ напомнить телу, что оно существует.

# set_flag:water_drunk=true
~ water_drunk = true
# return_to_scene
-> DONE

