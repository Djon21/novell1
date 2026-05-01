// ================================================================
// AVOS_S — 02_sunday_date.ink
// Воскресенье: встреча с NPC после квартиры.
//
// Flow:
//   01_apartment.leave_apartment
//   -> # map:hub:sunday_date_map_fallback
//   -> cafe_hub / park_hub через карту телефона
//   -> on_enter: sunday_date_cafe_arrival / sunday_date_park_arrival
// ================================================================

=== sunday_date_map_fallback ===
# speaker:none
Карта остаётся открытой. Маршрут ещё не выбран.

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
# explore:park_hub
-> DONE


=== sunday_date_cafe_arrival ===
# bg:bg_office # speaker:none
Кафе встречает мягким шумом голосов и запахом выпечки.

{npc_name} уже здесь — у окна, с телефоном в руке. Увидев тебя, {npc_name} убирает экран и улыбается так, будто это утро ещё можно спасти.

# speaker:npc
{mc_gender == "female":
Ты пришла. Я не был уверен, что ты выберешь кафе.
- else:
Ты пришёл. Я не была уверена, что ты выберешь кафе.
}

# speaker:mc
Я тоже.

# speaker:none
Ответ получается честнее, чем планировалось. И от этого разговор становится чуть теплее.
# set_flag:date_route_chosen=true
# set_flag:met_npc_sunday=true
~ date_route_chosen = true
~ met_npc_sunday = true
~ TRUST = TRUST + 1
# quest:done:meet_npc
# map:allow:reset
# return_to_scene
-> DONE


=== sunday_date_park_arrival ===
# bg:bg_rooftop # speaker:none
Парк у реки светлый и почти пустой. Воскресенье здесь звучит тише, чем в квартире: шаги по дорожке, вода за деревьями, редкие голоса вдали.

{npc_name} ждёт у перил. Не машет сразу — сначала смотрит, будто проверяет, точно ли это ты.

# speaker:npc
{mc_gender == "female":
Ты всё-таки выбрала парк.
- else:
Ты всё-таки выбрал парк.
}

# speaker:mc
Сегодня хотелось воздуха.

# speaker:none
{npc_name} кивает. В этом кивке нет вопроса, но есть место для разговора.
# set_flag:date_route_chosen=true
# set_flag:met_npc_sunday=true
~ date_route_chosen = true
~ met_npc_sunday = true
~ TRUST = TRUST + 1
# quest:done:meet_npc
# map:allow:reset
# return_to_scene
-> DONE


=== cafe_bar_interact ===
# speaker:none
Стойка, меню, тихий звук кофемолки. Всё здесь делает вид, что день обычный.

{date_place_cafe:
# speaker:mc
Хорошо, что я выбрал кафе.
- else:
# speaker:mc
Не то место. Мы договаривались о парке.
}
# return_to_scene
-> DONE


=== park_bench_interact ===
# speaker:none
Скамейка смотрит на дорожку и реку. Здесь легко молчать, не делая вид, что это пауза.

{date_place_park:
# speaker:mc
Нормальное место. Можно просто идти рядом.
- else:
# speaker:mc
Не то место. Мы договаривались о кафе.
}
# return_to_scene
-> DONE


=== leave_cafe ===
# speaker:none
Выходить из кафе пока рано. Воскресный разговор только начался.
# return_to_scene
-> DONE


=== leave_park ===
# speaker:none
Уходить из парка пока рано. Воскресный разговор только начался.
# return_to_scene
-> DONE
