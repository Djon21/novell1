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

=== inv_apartment_kitchen_use_mug_on_coffee_setup ===
# speaker:mc
Ставлю кружку на столешницу рядом с чайником.

Щелчок кнопки. Вода начинает шуметь — сначала тихо, потом всё увереннее.
Пока чайник греется, я нахожу кофе и насыпаю его в кружку.

Обычный утренний порядок. Почти убедительный.

~ coffee_drunk = true
# set_flag:coffee_drunk=true
# quest:done:make_coffee
# hud:hint:bag:off
# return_to_scene
-> DONE

=== inv_apartment_kitchen_morning_use_mug_on_coffee_setup ===
# speaker:mc
Ставлю кружку на столешницу рядом с чайником.

Щелчок кнопки. Вода начинает шуметь — сначала тихо, потом всё увереннее.
Пока чайник греется, я нахожу кофе и насыпаю его в кружку.

Обычный утренний порядок. Почти убедительный.

~ coffee_drunk = true
# set_flag:coffee_drunk=true
# quest:done:make_coffee
# hud:hint:bag:off
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


// ----------------------------------------------------------------
// ПОНЕДЕЛЬНИК / ОФИС — playable task
// ----------------------------------------------------------------

=== inv_work_hub_use_card_on_office_turnstile ===
# speaker:mc
Прикладываю пропуск к считывателю.

Короткий писк. Турникет отпускает створку, и офис окончательно перестаёт быть просто зданием.

# speaker:none
Доступ разрешён.

# set_flag:monday_checked_in_office=true
# return_to_scene
-> DONE

=== inv_inspect_report_page ===
# speaker:mc
Один лист, несколько полей и слишком много пустых мест между строками.

Если смотреть быстро, похоже на нормальный кейс. Если читать внимательно — на просьбу не задавать лишних вопросов.
# return_to_scene
-> DONE

=== inv_read_report_page ===
# speaker:none
Кейс 017.

Входные данные: частичные.
Подтверждение: отсутствует.
Рекомендованный путь: стандартная обработка при истечении срока.

# speaker:mc
То есть лист уже почти знает, куда меня подтолкнут.
# return_to_scene
-> DONE

=== inv_inspect_folder ===
# speaker:mc
Обычная офисная папка. Чем аккуратнее она выглядит, тем легче забыть, что внутри может быть недостающая часть решения.
# return_to_scene
-> DONE

=== inv_combine_folder_with_report_page ===
# speaker:mc
Вкладываю распечатку в папку, выравниваю край листа и закрываю обложку.

Получается “пакет по кейсу”. Слишком солидное название для одного неполного набора данных.

# remove_item:folder
# remove_item:report_page
# add_item:case_file
# set_flag:monday_case_file_assembled=true
# hud:hint:bag
# return_to_scene
-> DONE

=== inv_inspect_case_file ===
# speaker:mc
Папка выглядит готовой. И в этом проблема: готовый вид легко принять за готовый ответ.
# return_to_scene
-> DONE

=== inv_read_case_file ===
# speaker:none
Кейс 017.

Собранный пакет содержит первичную распечатку и место для решения. Подтверждающего поля по-прежнему нет.

# speaker:mc
Форма появилась. Данные — нет.
# return_to_scene
-> DONE

=== inv_office_workspace_use_case_file_on_work_desk_submit ===
# speaker:mc
Кладу папку рядом с клавиатурой и прикрепляю её к рабочему кейсу.

Теперь система видит не просто красную строку, а собранный пакет. Этого достаточно, чтобы она начала следующий шаг.

# remove_item:case_file
# set_flag:monday_case_file_submitted=true
# hud:hint:bag:off
-> mon_office_npc_greeting

=== inv_office_workspace_give_case_file_on_npc ===
# speaker:mc
Передаю папку коллеге.

# speaker:npc
Есть. Тогда открываем кейс и смотрим, почему он так спешит стать “стандартным”.

# remove_item:case_file
# set_flag:monday_case_file_submitted=true
# hud:hint:bag:off
-> mon_office_npc_greeting

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
