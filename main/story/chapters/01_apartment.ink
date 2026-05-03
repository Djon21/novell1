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

Где-то рядом коротко вибрирует телефон.

{iteration_number > 1:
На секунду возникает ощущение, что эта тишина уже была.
Не похожая. Та же самая.
~ INSIGHT = INSIGHT + 1
~ anomaly_noticed = true
}

# speaker:mc
Телефон сначала. Потом уже кофе и всё остальное.
# quest:start:find_phone
# explore:apartment_bedroom_morning
-> DONE


// ================================================================
// ON_ENTER KNOTS
// ================================================================

=== apartment_bedroom_intro ===
# bg:bg_apartment_bedroom_morning # speaker:none
Комната собирается из привычных деталей: смятая постель, тумбочка у кровати, рабочий стол у окна, дверь в ванную справа.
Телефон лежит у тумбочки экраном вниз и снова коротко вибрирует.

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
Новое сообщение от {npc_name}:

{mc_gender == "female":
«Доброе утро. Ты сегодня свободна? Может, выберемся куда-нибудь?»
- else:
«Доброе утро. Ты сегодня свободен? Может, выберемся куда-нибудь?»
}

# speaker:mc
{npc_name}. Коллега — слишком сухое слово для человека, чьи сообщения я почему-то читаю быстрее остальных.

# speaker:none
Под уведомлением на секунду появляется ещё одна строка — будто от системного приложения без иконки:

«ДАННЫХ НЕДОСТАТОЧНО. СТАНДАРТНОЕ РЕШЕНИЕ ОЖИДАЕТСЯ.»

Строка исчезает раньше, чем ты успеваешь нажать.

# speaker:mc
Нет. Сегодня без стандартных решений.
# add_item:phone
~ phone_taken = true
~ phone_active = true
~ anomaly_noticed = true
# set_flag:phone_active=true
# set_flag:phone_taken=true
{mc_gender == "female":
    # sms:add:artem:Доброе утро. Ты сегодня свободна? Может, выберемся куда-нибудь?
- else:
    # sms:add:mila:Доброе утро. Ты сегодня свободен? Может, выберемся куда-нибудь?
}
# quest:done:find_phone
# quest:start:reply_npc
# quest:start:make_coffee
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


=== leave_apartment ===
# speaker:none
Кофе выпит. Телефон в кармане. Входная дверь ждёт, как простая точка перехода из дома в воскресенье.

Перед выходом всё оказывается удивительно телесным: ключи, обувь, куртка с крючка, короткая проверка карманов.

# speaker:mc
Телефон. Ключи. Всё.

{date_place_cafe:
Кафе. Спокойно. Нормально.
- else:
Парк у реки. Воздух точно не помешает.
}

# speaker:none
Ключ ложится в карман привычным весом. Замок щёлкает за спиной не драматично, а по-домашнему: день действительно начался.

На экране телефона уже открыта карта: осталось выбрать маршрут к месту встречи.

# add_item:key
# set_flag:ready_to_leave_sunday=true
# set_flag:left_apartment=true
~ can_leave_apt = true
# quest:done:make_coffee
# quest:start:meet_npc
# set_flag:map_opened_after_apartment=true
~ map_opened_after_apartment = true
# phone:map
-> DONE


// ================================================================
// КУХНЯ
// ================================================================

=== use_coffee_machine_no_cup ===
# speaker:none
На столешнице всё для кофе: чайник, банка, ложка, привычный утренний порядок.
Не хватает только кружки.

# speaker:mc
Кружка. Сначала кружка.
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
# speaker:none
Кружка оказывается на столешнице рядом с чайником.
Пакет с кофе шуршит слишком громко для такого тихого утра.

# sfx:coffee_brew

Запах кофе заполняет кухню. На пару секунд мир становится проще.

# speaker:mc
Вот. Уже лучше.
# set_flag:coffee_drunk=true
# set_flag:morning_ritual_done=true
~ coffee_drunk = true
~ can_leave_apt = true
# quest:done:make_coffee
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


// ================================================================
// SMS — ПЕРЕПИСКА
//
// Технические контакты:
// - mila  — когда ГГ Артём, NPC Мила.
// - artem — когда ГГ Мила, NPC Артём.
// Квест reply_npc засчитывает оба набора флагов через quests.lua.
// ================================================================

=== sms_thread_mila ===
# speaker:none
Открываешь переписку.

Мила написала утром:

«Доброе утро. Ты сегодня свободен? Может, выберемся куда-нибудь?»

# speaker:mc
Воскресенье. Значит, не офис. Нормальный день. Нормальная встреча.

* [«А тебе куда хочется?»]
    # speaker:none
    Ты почти пишешь первое, что приходит в голову: кафе. Тёплое, понятное, безопасное.
    Палец останавливается.

    # speaker:mc
    А тебе куда хочется?

    # sms:reply:mila:А тебе куда хочется?
    # sms:add:mila:Если честно — в парк у реки. Хочется воздуха.
    # sms:read:mila

    # speaker:npc
    Если честно — в парк у реки. Хочется воздуха.

    # speaker:mc
    Тогда в парк. Хорошо.

    # sms:reply:mila:Тогда в парк. Хорошо.
    # set_flag:date_agreed=true
    # set_flag:date_place_park=true
    # map:lock_to:poi_park
    ~ date_agreed = true
    ~ date_place_park = true
    ~ TRUST = TRUST + 1
    ~ INSIGHT = INSIGHT + 1
    -> sms_npc_place_sent

* [«Давай в кафе. Спокойно посидим.»]
    # speaker:none
    Ты выбираешь самый безопасный вариант: тепло, столик, кофе и разговор без лишней суеты.

    # sms:reply:mila:Давай в кафе. Спокойно посидим.
    # set_flag:date_agreed=true
    # set_flag:date_place_cafe=true
    # map:lock_to:poi_cafe
    ~ date_agreed = true
    ~ date_place_cafe = true
    ~ TRUST = TRUST + 1
    -> sms_npc_place_sent

* [«Давай в парк у реки. Хочется пройтись.»]
    # speaker:none
    В этом ответе больше воздуха, чем уверенности. Но, может, сейчас именно это и нужно.

    # sms:reply:mila:Давай в парк у реки. Хочется пройтись.
    # set_flag:date_agreed=true
    # set_flag:date_place_park=true
    # map:lock_to:poi_park
    ~ date_agreed = true
    ~ date_place_park = true
    ~ SYNC = SYNC + 1
    -> sms_npc_place_sent


=== sms_thread_artem ===
# speaker:none
Открываешь переписку.

Артём написал утром:

«Доброе утро. Ты сегодня свободна? Может, выберемся куда-нибудь?»

# speaker:mc
Воскресенье. Значит, не офис. Нормальный день. Нормальная встреча.

* [«А тебе куда хочется?»]
    # speaker:none
    Ты почти пишешь первое, что приходит в голову: кафе. Тёплое, понятное, безопасное.
    Палец останавливается.

    # speaker:mc
    А тебе куда хочется?

    # sms:reply:artem:А тебе куда хочется?
    # sms:add:artem:Если честно — в парк у реки. Хочется воздуха.
    # sms:read:artem

    # speaker:npc
    Если честно — в парк у реки. Хочется воздуха.

    # speaker:mc
    Тогда в парк. Хорошо.

    # sms:reply:artem:Тогда в парк. Хорошо.
    # set_flag:date_agreed=true
    # set_flag:date_place_park=true
    # map:lock_to:poi_park
    ~ date_agreed = true
    ~ date_place_park = true
    ~ TRUST = TRUST + 1
    ~ INSIGHT = INSIGHT + 1
    -> sms_npc_place_sent

* [«Давай в кафе. Спокойно посидим.»]
    # speaker:none
    Ты выбираешь самый безопасный вариант: тепло, столик, кофе и разговор без лишней суеты.

    # sms:reply:artem:Давай в кафе. Спокойно посидим.
    # set_flag:date_agreed=true
    # set_flag:date_place_cafe=true
    # map:lock_to:poi_cafe
    ~ date_agreed = true
    ~ date_place_cafe = true
    ~ TRUST = TRUST + 1
    -> sms_npc_place_sent

* [«Давай в парк у реки. Хочется пройтись.»]
    # speaker:none
    В этом ответе больше воздуха, чем уверенности. Но, может, сейчас именно это и нужно.

    # sms:reply:artem:Давай в парк у реки. Хочется пройтись.
    # set_flag:date_agreed=true
    # set_flag:date_place_park=true
    # map:lock_to:poi_park
    ~ date_agreed = true
    ~ date_place_park = true
    ~ SYNC = SYNC + 1
    -> sms_npc_place_sent


=== sms_npc_place_sent ===
# speaker:none
Сообщение отправлено.

Теперь у утра появляется форма: умыться, сделать кофе, выйти и открыть карту.
# quest:done:reply_npc
# quest:start:meet_npc
# return_to_scene
-> DONE


// ================================================================
// LEGACY-COMPAT KNOTS
// Оставлены, чтобы старые сцены из scenes.lua не падали при случайном входе.
// ================================================================

