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
//
// Совместимые квесты: find_phone, reply_npc, make_coffee, meet_npc. go_to_office стартует позже, в понедельник.
// Совместимые предметы: mug, phone.
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
За стеклом — обычный город, которому всё равно, проснулся ты или нет.

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

«Не соглашайся автоматически.»

Ни даты. Ни подписи. Только нажим ручки, слишком сильный для обычной заметки.
# set_flag:first_anomaly_seen=true
~ first_anomaly_seen = true
~ anomaly_noticed = true
~ INSIGHT = INSIGHT + 1
# note:add:Запись в блокноте:Не соглашайся автоматически.
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
Нормальное утро. Даже слишком нормальное, если прислушиваться к себе.
}
# set_flag:sunday_bedroom_window_seen=true
~ sunday_bedroom_window_seen = true
# return_to_scene
-> DONE


=== wash_up_morning ===
# speaker:none
Холодная вода быстро собирает лицо обратно.
За стеклом ванной — обычное воскресное утро: мокрые волосы, усталые глаза, никакой мистики.

# speaker:mc
Всё нормально. Просто надо проснуться.
# set_flag:washed_up=true
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
Экран забит уведомлениями: банк, дом, доставка, городские сервисы, работа — обычный утренний шум, который успевает жить раньше тебя.

# speaker:mc
Телефон всегда знает, что день начался, даже если ты ещё нет.

# speaker:none
Между сервисными строками висит личное сообщение от {npc_name}. Его почему-то хочется открыть первым.

{mc_gender == "female":
«Ты сегодня вообще проснулась? Я уже второй кофе пью.»
- else:
«Ты сегодня вообще проснулся? Я уже второй кофе пью.»
}

# speaker:mc
{npc_name}. Коллега — слишком сухое слово для человека, чьи сообщения я читаю быстрее остальных.
# add_item:phone
~ phone_taken = true
~ phone_active = true
# set_flag:phone_active=true
# set_flag:phone_taken=true
# sms:add:mama:Не забудь позавтракать. И ключи проверь, пожалуйста.
# sms:add:bank:Карта *4821: списание 349 ₽. Кофе и выпечка. 08:41.
# sms:add:prod:Напоминание: в понедельник до 11:00 подтвердите статус по кейсу 017.
{mc_gender == "female":
    # sms:add:artem:Ты сегодня вообще проснулась? Я уже второй кофе пью.
- else:
    # sms:add:mila:Ты сегодня вообще проснулся? Я уже второй кофе пью.
}

// Стартовый шум Messenger: виден сразу после получения телефона.
// Не открываем Messenger автоматически — игрок сам находит там бытовые, рабочие
// и слегка тревожные следы.
{mc_gender == "female":
    # msg:add:artem:Ты живая?
    # msg:add:artem:Я уже второй кофе пью. Это не хвастовство, это крик о помощи.
    # msg:add:artem:Если выбираешь место — только не то, где музыка громче людей.
- else:
    # msg:add:mila:Ты живой?
    # msg:add:mila:Я уже второй кофе пью. Это не хвастовство, это крик о помощи.
    # msg:add:mila:Если выбираешь место — только не то, где музыка громче людей.
}
# msg:add:friends:Доброе утро, выжившие. Кто сегодня не отменяет планы в последний момент?
# msg:add:friends:Я могу отменить заранее, чтобы не рушить традицию.
# msg:add:friends:Артём опять онлайн в 07:13. Подозрительно.
# msg:add:friends:Мила тоже. Вы там синхронизировались или что?
# msg:add:work_team:Понедельничная планёрка перенесена на 10:40. Да, в воскресенье. Нет, я тоже не рад.
# msg:add:work_team:По кейсу 017 не отправляйте решение без проверки входных данных.
# msg:add:work_team:Если система пишет «достаточно», это не всегда значит достаточно.
# msg:add:prod_bot:CASE-017 создан.
# msg:add:prod_bot:Пакет данных: неполный.
# msg:add:prod_bot:Режим ожидания: стандартное решение.
# msg:add:prod_bot:Совет дня: автоматизация не заменяет сомнение.
# msg:add:calendar_bot:Сегодня: встреча без названия. Место: уточняется.
# msg:add:calendar_bot:Напоминание удалено пользователем. Пользователь: вы. Время удаления: 08:41.
# msg:add:delivery:Курьер назначен. Заказ: «что-то к чаю». Комментарий курьера: хорошее название.
# msg:add:delivery:Если вы не оформляли заказ, сделайте вид, что это забота вселенной.
# msg:add:neighbor_chat:У кого опять будильник играет с 07:00?
# msg:add:neighbor_chat:Если это «мягкий джаз для продуктивности», он уже продуктивно бесит весь подъезд.
# msg:add:neighbor_chat:Кстати, у кого-то у двери лежат ключи. Не мои.
# msg:add:city_bot:Погода нормальная. Город делает вид, что ничего не происходит.
# msg:add:city_bot:Маршруты работают штатно. Слово «штатно» сегодня используется слишком часто.
# msg:add:meme_chat:Утро начинается не с кофе, а с принятия плохих интерфейсных решений.
# msg:add:meme_chat:Кто-нибудь видел мем «данных недостаточно, но я уже решил»?
# msg:add:meme_chat:Удалено: изображение недоступно.
# msg:add:unknown:Не отвечай автоматически.
# msg:add:unknown:Сначала спроси, чего не хватает.
# msg:add:unknown:Если сообщение кажется лишним — оно, скорее всего, главное.
# quest:done:find_phone
# quest:start:reply_npc
# map:lock_to:poi_home
# hud:hint:phone
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
Ничего странного. Обычное отражение обычного человека, который слишком много работает.
}
# return_to_scene
-> DONE


=== take_sunday_keys ===
# speaker:none
Ключи лежат на полке под зеркалом — там, где их оставляют люди, которые хотя бы пытаются не терять важное.

# speaker:mc
Ключи. Без них воскресенье быстро закончится у двери.

# add_item:key
# set_flag:sunday_keys_taken=true
~ sunday_keys_taken = true
# return_to_scene
-> DONE


=== sunday_get_dressed ===
# speaker:none
Куртка с вешалки, обувь у двери. Никакого торжественного выхода — просто бытовая последовательность, без которой человек не попадает в город.

# speaker:mc
Так. Теперь я хотя бы похож{mc_gender == "female":а|} на человека, который собирается выйти.

# set_flag:sunday_dressed=true
# set_flag:sunday_ready_to_leave=true
~ sunday_dressed = true
~ sunday_ready_to_leave = true
# return_to_scene
-> DONE


=== leave_apartment ===
# speaker:none
Телефон в кармане. Ключи на месте. Куртка и обувь наконец делают намерение выйти похожим на действие.

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
Телефон. Ключи. Всё.

{date_place_cafe:
Кафе. Спокойно. Нормально.
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
Обычная. Домашняя. Та, которую легко узнать на ощупь.

{iteration_number > 1:
Она снова стоит на том же месте.
Даже ручка повернута под тем же углом.
~ INSIGHT = INSIGHT + 1
}

# speaker:mc
Подойдёт.
# add_item:mug
~ mug_taken = true
# set_flag:mug_taken=true
# return_to_scene
-> DONE


=== use_coffee_machine_with_cup ===
# speaker:mc
Кружка у меня. Надо не просто смотреть на чайник, а использовать её здесь.

# return_to_scene
-> DONE


=== look_kitchen_window ===
# speaker:none
Окно выходит во двор. Машины, подъезд, редкие прохожие. Всё спокойно.

{iteration_number > 1:
У подъезда снова стоит серая машина без номеров.
Ты не знаешь, почему слово «снова» приходит первым.
~ anomaly_noticed = true
~ INSIGHT = INSIGHT + 1
- else:
У подъезда стоит серая машина без номеров. Наверное, соседская. Или временно припарковали.
}
# return_to_scene
-> DONE

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

