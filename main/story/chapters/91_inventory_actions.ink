// Inventory action knots.
// Naming contract:
//   inv_<scene_id>_<verb>_<item_id>  -- highest priority
//   inv_<verb>_<item_id>             -- global item action
//   inv_<verb>_fallback              -- verb-wide fallback
//   inv_fallback                     -- last-resort fallback

=== inv_inspect_phone ===
# speaker:mc
Телефон тёплый, будто я уже держал его в руках минуту назад.

{loop_awareness > 0:
    Он кажется знакомым сильнее, чем должен. Не как место, куда нужно перейти. Как подсказка, которую нужно прочитать.
}

# return_to_scene
-> DONE

=== inv_read_note ===
# speaker:none
На смятом листке всего одна строка:
"не выходи до звонка"

{iteration_number > 1:
    На второй раз почерк уже не пугает. Пугает то, что я начинаю ждать эту фразу заранее.
    ~ INSIGHT = INSIGHT + 1
}

# return_to_scene
-> DONE

=== inv_inspect_note ===
# speaker:mc
Моя бумага. Мой почерк. Но ощущение, что писал это не я сегодняшний.
# return_to_scene
-> DONE

=== inv_use_fallback ===
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

=== inv_read_fallback ===
# speaker:mc
{inventory_item_name != "":
    На {inventory_item_name} нечего читать. По крайней мере, пока.
- else:
    Читать здесь пока нечего.
}
# return_to_scene
-> DONE

=== inv_inspect_fallback ===
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

=== inv_fallback ===
# speaker:mc
Сейчас я просто убираю предмет обратно.
# return_to_scene
-> DONE

// ── USE-ON-TARGET fallbacks ──────────────────────────────────────────
// Игрок выбрал предмет в инвентаре (USE) и кликнул по hotspot. Цепочка:
//   inv_<scene>_use_<item>_on_<hotspot>
//   inv_use_<item>_on_<hotspot>
//   inv_use_<item>_on_fallback
//   inv_use_on_<hotspot>
// → если ни один не определён, попадаем в inv_use_fallback (выше).
//
// Для нового кейса напиши свой knot по любому из этих имён.

=== inv_use_on_fallback ===
# speaker:mc
{inventory_item_name != "":
    {inventory_item_name} здесь не пригодится.
- else:
    Не пригодится.
}
# return_to_scene
-> DONE


// ── COMBINE fallback ─────────────────────────────────────────────────
// Игрок выбрал предмет A в инвентаре и нажал COMBINE, потом кликнул B.
// Цепочка (item_id'ы сортируются лексикографически — пишем один knot):
//   inv_combine_<low>_with_<high>     // например, inv_combine_lighter_with_matchbox
//   inv_combine_fallback              // эта функция
//   inv_fallback
//
// inventory_item_id    = первый item (тот, что был выделен при клике COMBINE)
// inventory_target_id  = второй item (на который кликнули)
// inventory_target_kind = "item"

=== inv_combine_fallback ===
# speaker:mc
{inventory_item_name != "":
    {inventory_target_id != "":
        {inventory_item_name} и {inventory_target_id} не получится соединить.
    - else:
        Нечего соединять.
    }
- else:
    Не сейчас.
}
# return_to_scene
-> DONE


// ── GIVE fallbacks ───────────────────────────────────────────────────
// Игрок выбрал предмет с verb=give. Если в текущей сцене есть NPC
// (scenes.lua: npc = "..."), цепочка:
//   inv_<scene>_give_<item>_on_<npc>
//   inv_give_<item>_on_<npc>
//   inv_give_<item>_on_fallback
//   inv_give_on_<npc>
// Если NPC в сцене нет — сразу inv_give_<item> или inv_give_fallback.

=== inv_give_fallback ===
# speaker:mc
{inventory_target_id != "":
    {inventory_item_name != "":
        Хочется передать {inventory_item_name}, но сейчас момент не тот.
    - else:
        Сейчас не время для подарков.
    }
- else:
    Никого рядом нет — некому передавать.
}
# return_to_scene
-> DONE
