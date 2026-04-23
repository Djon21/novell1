// Inventory action knots.
// Naming contract:
//   inv_<scene_id>_<verb>_<item_id>  -- highest priority
//   inv_<verb>_<item_id>             -- global item action
//   inv_<verb>_fallback              -- verb-wide fallback
//   inv_fallback                     -- last-resort fallback

=== inv_inspect_phone
# speaker:mc
Телефон тёплый, будто я уже держал его в руках минуту назад.
{loop_awareness > 0:
    Он кажется знакомым сильнее, чем должен. Не как вещь. Как подсказка.
}
# return_to_scene
-> DONE

=== inv_read_note
# speaker:none
На смятом листке всего одна строка:
"не выходи до звонка"
{iteration_number > 1:
    На второй раз почерк уже не пугает. Пугает то, что я начинаю ждать эту фразу заранее.
}
# return_to_scene
-> DONE

=== inv_inspect_note
# speaker:mc
Моя бумага. Мой почерк. Но ощущение, что писал это не я сегодняшний.
# return_to_scene
-> DONE

=== inv_use_fallback
# speaker:mc
{inventory_item_name != "":
    Сжимаю {inventory_item_name} в руке. Сейчас это ничего не изменит.
- else:
    Сейчас это ничего не изменит.
}
{loop_awareness > 0:
    Но я уже ловил себя на этой мысли. И именно это раздражает сильнее всего.
}
# return_to_scene
-> DONE

=== inv_read_fallback
# speaker:mc
{inventory_item_name != "":
    На {inventory_item_name} нечего читать. По крайней мере, пока.
- else:
    Читать здесь пока нечего.
}
# return_to_scene
-> DONE

=== inv_inspect_fallback
# speaker:mc
{inventory_item_name != "":
    Осматриваю {inventory_item_name}. Детали на месте. Ответов по-прежнему нет.
- else:
    Осматриваю предмет. Ответов от этого не прибавляется.
}
{loop_awareness > 1:
    И всё же предмет кажется слишком правильным, будто уже пережил этот день вместе со мной.
}
# return_to_scene
-> DONE

=== inv_fallback
# speaker:mc
Сейчас я просто убираю предмет обратно.
# return_to_scene
-> DONE
