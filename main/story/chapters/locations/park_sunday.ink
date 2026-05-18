// ================================================================
// AVOS_S - locations/park_sunday.ink
// Парк у реки в воскресенье. Содержит: arc встречи с NPC (прибытие,
// поиск через messenger, главный диалог у воды или в аллее) +
// хотспот-реакции на entrance/bench/river/path/bin/trash для этого дня.
//
// Iteration 2+: добавлять новые knot'ы с условием iteration_number >= 2,
// не плодить параллельные файлы.
// ================================================================

=== park_entrance_view ===
# speaker:none
{park_entrance_seen:
    Вход в парк уже понятен: дорожка, вода дальше справа, зелень, тёплый камень под солнцем.
- else:
    Отсюда парк кажется больше, чем на карте: справа вода и лавочки, впереди аллея, вокруг достаточно людей, чтобы не чувствовать себя одному, и достаточно пространства, чтобы не мешать друг другу.

    # set_flag:park_entrance_seen=true
    ~ park_entrance_seen = true
}

{iteration_number > 1:
    # speaker:none
    Человек с собакой проходит мимо. Та же собака, тот же поводок, тот же темп. В третий раз ровно тот же шаг.
    ~ INSIGHT = INSIGHT + 1
    ~ anomaly_noticed = true
}

{not park_where_message_sent:
    Можно написать {npc_name_dat} и уточнить, где вы разминулись.
- else:
    {park_npc_greeted:
        Теперь это уже не место ожидания, а точка, откуда вы начали день вдвоём.
    - else:
        {mc_gender == "female":
            {npc_name} написал, что идёт к тебе. Теперь ожидание стало коротким и конкретным: осталось просто поздороваться.
        - else:
            {npc_name} написала, что идёт к тебе. Теперь ожидание стало коротким и конкретным: осталось просто поздороваться.
        }
    }
}

# return_to_scene
-> DONE

=== park_bench_interact ===
# speaker:none
{met_npc_sunday:
    Скамейка у воды теперь запомнилась не видом, а паузой, в которой вы оба не стали ничего портить лишними словами.
    # return_to_scene
    -> DONE
}


{not park_bench_cleared:
    {park_bench_trash_seen:
        На лавочке всё ещё стоит чужой стаканчик. Место хорошее, но садиться рядом с мусором почему-то совсем не хочется.
    - else:
        Лавочка хорошая: рядом вода, чуть тени, достаточно места для двоих.

        И почти сразу находится мелкая проблема — на краю стоит чужой пустой стаканчик. Никакой катастрофы, просто не то соседство для разговора, который хочется начать нормально.
        # set_flag:park_bench_trash_seen=true
        ~ park_bench_trash_seen = true
    }

    # speaker:mc
    Надо убрать стаканчик в урну у входа. Тогда уже можно будет предлагать сесть.

    # return_to_scene
    -> DONE
}

{park_talk_place_bench:
    -> park_bench_main_talk
- else:
    # speaker:mc
    Теперь здесь нормально. Осталось решить: сесть у воды или всё-таки пройтись.
    # return_to_scene
    -> DONE
}

=== park_river_view ===
# speaker:none
Река движется медленно и уверенно. На таком фоне разговоры обычно становятся тише — не слабее, просто честнее.

{iteration_number > 1:
    # speaker:none
    Течение в той же самой точке делает ту же самую дугу. Как будто это не вода, а кадр.

    # speaker:mc
    Реки так не повторяются.
    ~ INSIGHT = INSIGHT + 1
    ~ anomaly_noticed = true
}

{park_npc_greeted and not met_npc_sunday:
    {npc_name} смотрит на воду чуть дольше, чем на тебя. Не избегает — просто даёт вам обоим пару секунд без необходимости сразу быть смелыми.
}

# return_to_scene
-> DONE

=== park_path_trees ===
# speaker:none
{park_path_seen:
    Аллея остаётся хорошим вариантом: идти проще, чем сидеть напротив и делать вид, что это просто прогулка.
- else:
    Тень от деревьев ложится на дорожку пятнами. Здесь прохладнее, чем у воды, и меньше случайных взглядов. Если идти рядом, разговор может начаться сам.
    # set_flag:park_path_seen=true
    ~ park_path_seen = true
}

{iteration_number > 1:
    # speaker:none
    Пятна тени ложатся ровно туда же, куда легли в прошлый раз. Даже самое крайнее пятно у бортика — на том же шве плитки.
    ~ INSIGHT = INSIGHT + 1
    ~ anomaly_noticed = true
}

Рядом с {npc_name_ins} эта дорожка перестаёт быть маршрутом и становится способом не торопить разговор.

# return_to_scene
-> DONE

=== park_path_walk ===
# speaker:none
{met_npc_sunday:
    Вы проходите дальше по аллее. Несколько минут можно не решать ничего: только идти, слушать шаги и редкие голоса где-то впереди.
    # return_to_scene
    -> DONE
}

-> park_path_main_talk

=== park_bin_prompt ===
# speaker:none
{iteration_number > 1:
    Урна стоит у края дорожки. Ты её уже выбирал. В неё уже летел такой же стаканчик с тем же глухим звуком.

    # speaker:mc
    Тогда давай. Снова.
    ~ INSIGHT = INSIGHT + 1
    ~ anomaly_noticed = true
- else:
    Урна стоит у края дорожки — как будто специально для маленьких решений, которые никто не заметит, кроме тебя.

    # speaker:mc
    Урна рядом. Осталось не просто держать стаканчик в руке, а действительно выбросить его.
}

# hud:hint:bag
# return_to_scene
-> DONE

=== take_park_trash_cup ===
# speaker:none
{iteration_number > 1:
    Чужой пустой стаканчик стоит на краю лавочки. Тот же самый. С теми же отпечатками пальцев — твоими.

    # speaker:mc
    След того же дня. Я уже его уносил.
    ~ INSIGHT = INSIGHT + 1
    ~ anomaly_noticed = true
- else:
    Чужой пустой стаканчик стоит на краю лавочки. Ничего драматичного: просто след чужого дня, который мешает начать свой.

    # speaker:mc
    Ладно. Унесу к урне.
}

# add_item:park_trash_cup
# set_flag:park_trash_cup_taken=true
~ park_trash_cup_taken = true
# hud:hint:bag
# return_to_scene
-> DONE

=== leave_park ===
# speaker:none
{met_npc_sunday:
Ты выходишь с набережной. Телефон уже в руке — можно выбрать, куда идти дальше.
# map:lock_all
# map:allow:poi_shop
# map:allow:poi_view
# phone:map
- else:
    {park_place_chosen:
Уходить сейчас будет странно. Место уже выбрано — осталось не сбежать из разговора раньше, чем он начался.
    - else:
        {park_npc_greeted:
Уходить сейчас будет странно. Вы только нашли друг друга и ещё даже не выбрали, где нормально поговорить.
        - else:
        {park_where_message_sent:
Уходить из парка пока рано. {npc_name} уже идёт к тебе.
        - else:
Уходить из парка пока рано. Сначала стоит хотя бы написать {npc_name_dat}, где вы разминулись.
        }
        }
    }
# return_to_scene
}
-> DONE

// ================================================================
// ПОСЛЕ ВСТРЕЧИ: ВТОРОЕ МЕСТО
// ================================================================

=== sunday_date_park_arrival ===
# speaker:none
Парк у реки встречает светом и воздухом. Здесь уже день: солнце выше крыш, вода блестит между деревьями, дорожки живут своим спокойным движением.

{npc_name_gen} нигде не видно. Не у лавочки, не у перил, не на дорожке к воде.

# speaker:mc
Ладно. Значит, сначала — не паниковать. Потом — написать.

# speaker:none
В Messenger мигает чат — можно открыть и написать {npc_name_dat}, где вы разминулись.

# set_flag:park_arrived=true
~ park_arrived = true
# map:lock_all
// # msg:prompt — генерик-механизм: pin "НАПИСАТЬ" на чате, тап input'а
// диверитит в указанный knot независимо от _replied-флага. Pin авто-снимется
// при первом # msg:reply:CHAT:... внутри knot'а.
{mc_gender == "female":
    # msg:prompt:artem:park_message_where_are_you:НАПИСАТЬ
- else:
    # msg:prompt:mila:park_message_where_are_you:НАПИСАТЬ
}
# hud:hint:phone
# return_to_scene
-> DONE

=== park_message_where_are_you ===
# speaker:none
Ты открываешь Messenger. Палец зависает над полем ввода чуть дольше, чем нужно для простого вопроса.

# speaker:mc
«Ты где?»

// NPC может ждать у скамейки ИЛИ в аллее. Выбор детерминированный по
// iteration_number: нечётные (включая 1) → скамейка, чётные → аллея.
// Эффект: iter 1 = "у воды" (классический сценарий онбординга),
// iter 2 = "в аллее" (тонкая аномалия повторения).
// Спрайт NPC появляется НЕ здесь, а в on_enter соответствующей sub-сцены
// (park_bench_npc_show / park_path_npc_show).
{iteration_number % 2 == 0:
    // EVEN iter (iter 2, 4, ...) — at path
    {mc_gender == "female":
    # msg:reply:artem:Ты где?
    # msg:add:artem:В аллее, в тени. Подходи — я тут.
    - else:
    # msg:reply:mila:Ты где?
    # msg:add:mila:В аллее, в тени. Подходи — я тут.
    }
    # set_flag:park_npc_at_path=true
- else:
    // ODD iter (iter 1, 3, ...) — at bench
    {mc_gender == "female":
    # msg:reply:artem:Ты где?
    # msg:add:artem:У воды, ближе к лавочкам. Уже там, жду.
    - else:
    # msg:reply:mila:Ты где?
    # msg:add:mila:У воды, ближе к лавочкам. Уже там, жду.
    }
    # set_flag:park_npc_at_bench=true
}
# sfx:phone_notify

# speaker:none
Ответ приходит почти сразу. Не тревожно — просто теперь ожидание стало конкретным: нужно подойти.

# set_flag:park_where_message_sent=true
~ park_where_message_sent = true
# hud:hint:phone:off
# return_to_scene
-> DONE

// On_enter knot для park_riverside_bench когда NPC ждёт у скамейки.
// Гейтится в park.lua: park_npc_at_bench AND NOT park_npc_bench_shown
// AND NOT park_npc_greeted. Флаг shown обязателен: иначе return_to_scene
// снова войдёт в sub-сцену до клика "Поздороваться" и on_enter зациклится.
=== park_bench_npc_show ===
# speaker:none
{mc_gender == "male":
    {npc_name} стоит у лавочки, спиной к воде. Замечает тебя сразу, поднимает руку.
    # scene_char:show:park:mila_idle_bench
- else:
    {npc_name} стоит у лавочки, спиной к воде. Замечает тебя сразу, поднимает руку.
    // TODO: artem_park.png — добавить # scene_char:show:park:artem_idle_bench
}
# set_flag:park_npc_bench_shown=true
# return_to_scene
-> DONE

// On_enter knot для park_riverside_path когда NPC ждёт в аллее.
// См. park_bench_npc_show: shown-флаг нужен чтобы on_enter не зацикливался.
=== park_path_npc_show ===
# speaker:none
{mc_gender == "male":
    {npc_name} в нескольких шагах впереди, у дерева. Поворачивается на твои шаги.
    # scene_char:show:park:mila_idle_path
- else:
    {npc_name} в нескольких шагах впереди, у дерева. Поворачивается на твои шаги.
    // TODO: artem_park.png — добавить # scene_char:show:park:artem_idle_path
}
# set_flag:park_npc_path_shown=true
# return_to_scene
-> DONE

=== park_npc_arrives ===
{npc_name} появляется со стороны дорожки к воде. Сначала ты замечаешь движение между людьми, потом знакомую улыбку — осторожную, будто её тоже надо подвести поближе.

# speaker:npc
{npc_gender == "female":
Нашла. То есть нашла тебя, а не смысл жизни. Хотя день уже странно удачный.
- else:
Нашёл. То есть нашёл тебя, а не смысл жизни. Хотя день уже странно удачный.
}

# speaker:mc
Я почти не успел{mc_gender == "female":а|} начать волноваться.

# speaker:npc
Почти — это мило.

{sunday_gift_bought and not sunday_gift_given:
    -> sunday_gift_react
}
-> park_npc_arrives_after_gift

// sunday_gift_auto_park вынесен в locations/sunday_gift_reactions.ink
// (общая логика реакции на подарок — теперь шарится с cafe-вариантом).
// Сюда переадресует sunday_gift_react → sunday_gift_react_park →
// park_npc_arrives_after_gift (см. shared file).

=== park_npc_arrives_after_gift ===
# speaker:none
Вы стоите рядом, но разговор всё ещё не нашёл себе места. Теперь нужно решить: сесть у воды или уйти в тень аллеи.

# speaker:mc
Сначала пройдёмся: посмотрю и лавочку у воды, и аллею. Потом уже решим, где сесть.

# set_flag:park_npc_greeted=true
~ park_npc_greeted = true
// scene_char уже показан в park_bench_npc_show / park_path_npc_show
// (on_enter sub-сцены). Здесь не дублируем — show идемпотентен
// и оставаться видимым после greeting NPC должен в той же sub-сцене.
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
# speaker:none
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
# speaker:none
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
Разговор начинается с простого: погода, дорога, смешная неловкость первых минут, кто сколько кофе уже успел выпить. Но рядом с {npc_name_ins} простые темы не кажутся пустыми.

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
# map:lock_all
# map:allow:poi_shop
# map:allow:poi_view
~ date_route_chosen = true
~ met_npc_sunday = true
~ sunday_after_date_active = true
# phone:map
-> DONE
