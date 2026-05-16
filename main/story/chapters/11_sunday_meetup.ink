// ================================================================
// AVOS_S - 11_sunday_meetup.ink
// Воскресная встреча с NPC: прибытие в кафе/парк и основные диалоги.
//
// Hub-specific reactions:
//   - 41_hub_park.ink, 42_hub_cafe.ink
//   - 43_hub_shop.ink (after-meetup магазин)
//   - 44_hub_viewpoint.ink (after-meetup смотровая)
//   - 45_hub_bar.ink (бар maybe)
// Вечер и возврат домой - в 17_sunday_evening.ink.
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
# remove_item:water_bottle
# set_flag:date_small_kindness=true
~ date_small_kindness = true
}

* [Спросить, как {npc_name_dat} хотелось провести день]
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
Встреча не заканчивается на первом разговоре. Теперь это уже не просто договорённость, а настоящий воскресный день.

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
# phone:map
-> DONE

=== sunday_date_park_arrival ===
# bg:bg_park_riverside_entrance_morning # speaker:none
Парк у реки встречает светом и воздухом. Здесь уже день: солнце выше крыш, вода блестит между деревьями, дорожки живут своим спокойным движением.

{npc_name_gen} нигде не видно. Не у лавочки, не у перил, не на дорожке к воде.

# speaker:mc
Ладно. Значит, сначала — не паниковать. Потом — написать.

# speaker:none
Можно осмотреться и написать {npc_name_dat} в Messenger: уточнить, где вы разминулись.

# set_flag:park_arrived=true
~ park_arrived = true
# map:lock_all
# return_to_scene
-> DONE

=== park_message_where_are_you ===
# bg:bg_park_riverside_entrance_morning # speaker:none
Ты открываешь Messenger. Палец зависает над полем ввода чуть дольше, чем нужно для простого вопроса.

# speaker:mc
«Ты где?»

{mc_gender == "female":
# msg:reply:artem:Ты где?
# msg:add:artem:У воды, ближе к лавочкам. Уже иду к тебе.
- else:
# msg:reply:mila:Ты где?
# msg:add:mila:У воды, ближе к лавочкам. Уже иду к тебе.
}
# sfx:phone_notify

# speaker:none
Ответ приходит почти сразу. Не тревожно — просто теперь ожидание стало конкретным.

# set_flag:park_where_message_sent=true
~ park_where_message_sent = true
# hud:hint:phone:off
# scene_char:show:park:mila_idle
// Появляется на фоне как часть «Уже иду к тебе» — игрок видит её
// фигуру у воды и теперь может «Поздороваться» через хотспот.
# return_to_scene
-> DONE

=== park_npc_arrives ===
# bg:bg_park_riverside_entrance_morning # speaker:none
{npc_name} появляется со стороны дорожки к воде. Сначала ты замечаешь движение между людьми, потом знакомую улыбку — осторожную, будто её тоже надо подвести поближе.

# speaker:npc
{mc_gender == "female":
Нашёл. То есть нашёл тебя, а не смысл жизни. Хотя день уже странно удачный.
- else:
Нашла. То есть нашла тебя, а не смысл жизни. Хотя день уже странно удачный.
}

# speaker:mc
Я почти не успел{mc_gender == "female":а|} начать волноваться.

# speaker:npc
Почти — это мило.

# speaker:none
Вы стоите у входа рядом, но всё ещё на проходе. Теперь надо найти место для разговора: сесть у воды или уйти в тень аллеи.

# set_flag:park_npc_greeted=true
~ park_npc_greeted = true
# scene_char:show:park:mila_idle
// TODO: когда появится спрайт artem_park.png — добавить условный
//   show artem для случая mc_gender=="female"
# return_to_scene
-> DONE

=== park_offer_place ===
# speaker:none
Теперь место уже не абстрактный выбор на карте, а конкретная развилка: сесть у воды или уйти в тень аллеи. Лавочка приведена в порядок, дорожка проверена — можно предложить.

* [«Сядем у воды?»]
    # speaker:mc
    Сядем у воды? Там теперь нормально. И вроде тише.

    # speaker:npc
    Давай. Только без торжественного вида, будто мы сейчас подписываем договор о воскресенье.

    # speaker:none
    Вы двигаетесь к лавочке почти одновременно. Это маленькое совпадение почему-то запоминается.
    # set_flag:park_place_chosen=true
    # set_flag:park_talk_place_bench=true
    ~ park_place_chosen = true
    ~ park_talk_place_bench = true
    ~ TRUST = TRUST + 1
    # goto_scene:park_riverside_bench
    -> DONE

* [«Может, пройдёмся?»]
    # speaker:mc
    Может, пройдёмся? Так проще разговаривать, когда не надо всё время смотреть друг на друга.

    # speaker:npc
    Звучит как очень честная причина.

    # speaker:none
    Вы уходите в тень аллеи. Шаги сразу берут на себя часть неловкости.
    # set_flag:park_place_chosen=true
    # set_flag:park_talk_place_path=true
    ~ park_place_chosen = true
    ~ park_talk_place_path = true
    ~ SYNC = SYNC + 1
    # goto_scene:park_riverside_path
    -> DONE

=== park_bench_main_talk ===
# bg:bg_park_riverside_bench_morning # speaker:none
Вы садитесь на скамейку у воды. Не слишком близко, чтобы это требовало объяснений, но и не так далеко, чтобы можно было сделать вид, что между вами только случайная прогулка.

# speaker:npc
Хорошо здесь. Не так официально, как кафе, и не так страшно, как просто стоять напротив друг друга.

# speaker:mc
Значит, я выбрал{mc_gender == "female":а|} правильный уровень неловкости.

# speaker:npc
Почти идеальный. Сидеть у воды и хотеть пить — довольно глупый контраст, но после второго кофе я, кажется, именно там.

{sunday_shop_bought_drink_for_npc and not park_water_given:
    # speaker:mc
    Тогда у меня есть очень неромантичный, но полезный жест. Я взял{mc_gender == "female":а|} воду по дороге.

    # speaker:npc
    Ты правда подумал{mc_gender == "female":а|} об этом заранее?

    # speaker:mc
    Я бы назвал{mc_gender == "female":а|} это логистикой, но так хуже звучит.

    # speaker:none
    {npc_name} берёт бутылку. Пальцы на секунду касаются твоих, и вы оба делаете вид, что заметили только крышку.

    # remove_item:water_bottle
    # set_flag:park_water_given=true
    # set_flag:date_small_kindness=true
    ~ park_water_given = true
    ~ date_small_kindness = true
    ~ TRUST = TRUST + 1
- else:
    # speaker:mc
    Мне стоило догадаться купить воду. Вместо этого у меня есть только уверенность, что парк красивый.

    # speaker:npc
    Уверенность тоже почти жидкость. Ладно, переживу.

    # speaker:none
    Неловкость выходит лёгкой, почти домашней. Вы оба смотрите на воду так серьёзно, будто она сейчас подскажет достойный ответ.
}

# speaker:none
Вы смеётесь не громко. Река рядом делает паузу длиннее, чем она могла бы быть в другом месте.

* [Спросить, как {npc_name_dat} хотелось провести день]
    # speaker:mc
    А тебе как хотелось провести сегодня? Не куда “правильно”, а как правда хочется.

    # speaker:npc
    Вот так, наверное. Чтобы можно было не торопиться и не доказывать, что всё под контролем.

    # speaker:none
    {npc_name} отвечает не сразу. Сначала улыбается — маленько, благодарно, будто вопрос оказался важнее любого готового плана.
    ~ TRUST = TRUST + 1
    -> sunday_date_park_settle

* [Пошутить про прогулку как план]
    # speaker:mc
    Если что, прогулка вдоль реки официально считается планом. Просто без таблицы и дедлайна.

    # speaker:npc
    Редкий вид плана. Мне нравится.

    # speaker:none
    Воздуха становится больше не только вокруг, но и между словами.
    ~ SYNC = SYNC + 1
    -> sunday_date_park_settle

* [Признаться, что парк казался проще]
    # speaker:mc
    Я выбрал{mc_gender == "female":а|} парк, потому что он казался проще. Меньше шума, меньше ожиданий.

    # speaker:npc
    Понимаю. Только давай не превращать даже прогулку в оптимизацию.

    # speaker:none
    Сказано мягко, но точно. Ты киваешь и впервые за утро не спешишь защищать свой выбор.
    ~ INSIGHT = INSIGHT + 1
    -> sunday_date_park_settle

=== park_path_main_talk ===
# bg:bg_park_riverside_path_morning # speaker:none
Вы идёте по аллее в тени деревьев. Дорожка сама задаёт темп: достаточно медленно, чтобы говорить, и достаточно легко, чтобы молчание не становилось проверкой.

# speaker:npc
Так правда легче. Когда идёшь, не нужно всё время решать, кто на кого смотрит.

# speaker:mc
Я примерно на это и рассчитывал{mc_gender == "female":а|}.

# speaker:npc
Опасно. Ты начинаешь понимать мои слабые места. После второго кофе идти легче, но пить хочется сильнее.

{sunday_shop_bought_drink_for_npc and not park_water_given:
    # speaker:mc
    Тогда я сейчас рискну выглядеть предусмотрительно. Я взял{mc_gender == "female":а|} воду по дороге.

    # speaker:npc
    Это очень подозрительно заботливо.

    # speaker:mc
    Могу сделать вид, что это логистика.

    # speaker:npc
    Не надо. Забота звучит лучше.

    # speaker:none
    Бутылка переходит из руки в руку на ходу. Вы чуть сбиваетесь с шага и одновременно смеётесь.

    # remove_item:water_bottle
    # set_flag:park_water_given=true
    # set_flag:date_small_kindness=true
    ~ park_water_given = true
    ~ date_small_kindness = true
    ~ TRUST = TRUST + 1
- else:
    # speaker:mc
    Вот тут я проигрываю собственному плану. Воды нет, зато есть честное сожаление.

    # speaker:npc
    Честное сожаление принимается. Но в следующий раз — с крышечкой.

    # speaker:none
    Вы оба смеётесь, и неловкость не застревает. Просто становится ещё одной маленькой вещью, которую можно будет вспомнить позже.
}

# speaker:none
Шутка получается тише, чем могла бы быть. Может быть, поэтому она звучит честнее.

* [Спросить, что помогает {npc_name_dat} не торопиться]
    # speaker:mc
    Что тебе помогает не торопиться?

    # speaker:npc
    Когда рядом человек, который не пытается сразу всё решить.

    # speaker:none
    Ответ звучит легко. Ты не споришь и не отшучиваешься — просто подстраиваешь шаг.
    ~ TRUST = TRUST + 1
    -> sunday_date_park_settle

* [Подстроиться под общий темп]
    # speaker:mc
    Давай просто пойдём как идётся.

    # speaker:npc
    Вот это хороший план. Почти не план.

    # speaker:none
    Через несколько шагов общий темп находится сам. Внимательность оказывается не жестом, а скоростью.
    ~ SYNC = SYNC + 1
    -> sunday_date_park_settle

* [Признаться, что так меньше давления]
    # speaker:mc
    Мне так легче. Когда можно говорить не прямо в точку, а как будто между делом.

    # speaker:npc
    Это не слабость. Иногда между делом говорят самое важное.

    # speaker:none
    Фраза остаётся между вами на несколько шагов дольше обычной шутки.
    ~ INSIGHT = INSIGHT + 1
    -> sunday_date_park_settle

=== sunday_date_park_settle ===
# speaker:none
Разговор начинается с простого: погода, дорога, смешная неловкость у входа, кто сколько кофе уже успел выпить. Но рядом с {npc_name_ins} простые темы не кажутся пустыми.

# speaker:npc
Хорошо, что мы выбрались именно в парк.

# speaker:mc
Я тоже.

# speaker:none
Сказать больше пока не нужно. Достаточно быть рядом и не отступать от этой простоты слишком быстро.

# speaker:npc
У меня ещё есть немного времени. Можно не разбегаться сразу.

# speaker:mc
Тогда выберем, куда пойти дальше.

# speaker:none
Встреча не заканчивается на первом разговоре. Теперь это уже не просто договорённость, а настоящий воскресный день.

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
# phone:map
-> DONE
