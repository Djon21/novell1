// ================================================================
// AVOS_S - 41_hub_park.ink
// Парк у реки: хотспот-реакции (entrance/bench/river/path/bin/trash).
// Сюжетная встреча и диалоги - в 11_sunday_meetup.ink.
// ================================================================

=== park_entrance_view ===
# bg:bg_park_riverside_entrance_morning # speaker:none
{park_entrance_seen:
    Вход в парк уже понятен: дорожка, вода дальше справа, зелень, тёплый камень под солнцем.
- else:
    Отсюда парк кажется больше, чем на карте: справа вода и лавочки, впереди аллея, вокруг достаточно людей, чтобы не чувствовать себя одному, и достаточно пространства, чтобы не мешать друг другу.

    # set_flag:park_entrance_seen=true
    ~ park_entrance_seen = true
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
# bg:bg_park_riverside_bench_morning # speaker:none
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
# bg:bg_park_riverside_bench_morning # speaker:none
Река движется медленно и уверенно. На таком фоне разговоры обычно становятся тише — не слабее, просто честнее.

{park_npc_greeted and not met_npc_sunday:
    {npc_name} смотрит на воду чуть дольше, чем на тебя. Не избегает — просто даёт вам обоим пару секунд без необходимости сразу быть смелыми.
}

# return_to_scene
-> DONE

=== park_path_trees ===
# bg:bg_park_riverside_path_morning # speaker:none
{park_path_seen:
    Аллея остаётся хорошим вариантом: идти проще, чем сидеть напротив и делать вид, что это просто прогулка.
- else:
    Тень от деревьев ложится на дорожку пятнами. Здесь прохладнее, чем у воды, и меньше случайных взглядов. Если идти рядом, разговор может начаться сам.
    # set_flag:park_path_seen=true
    ~ park_path_seen = true
}

Рядом с {npc_name_ins} эта дорожка перестаёт быть маршрутом и становится способом не торопить разговор.

# return_to_scene
-> DONE

=== park_path_walk ===
# bg:bg_park_riverside_path_morning # speaker:none
{met_npc_sunday:
    Вы проходите дальше по аллее. Несколько минут можно не решать ничего: только идти, слушать шаги и редкие голоса где-то впереди.
    # return_to_scene
    -> DONE
}

-> park_path_main_talk

=== park_bin_prompt ===
# bg:bg_park_riverside_entrance_morning # speaker:none
Урна стоит у края дорожки — как будто специально для маленьких решений, которые никто не заметит, кроме тебя.

# speaker:mc
Урна рядом. Осталось не просто держать стаканчик в руке, а действительно выбросить его.

# hud:hint:bag
# return_to_scene
-> DONE

=== take_park_trash_cup ===
# bg:bg_park_riverside_bench_morning # speaker:none
Чужой пустой стаканчик стоит на краю лавочки. Ничего драматичного: просто след чужого дня, который мешает начать свой.

# speaker:mc
Ладно. Унесу к урне.

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
# map:allow:reset
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
