// ================================================================
// AVOS_S — 04_rooftop.ink
// ================================================================


// ================================================================
// ВХОД НА КРЫШУ
// ================================================================
=== rooftop_entry
# bg:bg_rooftop # color:0.08,0.08,0.12 # speaker:none
Крыша встречает ветром.

Город внизу — как схема:
огни,
потоки,
движение без пауз.

# speaker:npc
Люблю это место.

# speaker:npc
Сверху всё выглядит проще.

# speaker:mc
Потому что деталей не видно.

-> rooftop_conversation


// ================================================================
// РАЗГОВОР С NPC (TRUST)
// ================================================================
=== rooftop_conversation

# speaker:npc
Ты сегодня странно себя вёл{mc_gender == "female":а|}.

* [Отшутиться]
    ~ TRUST = TRUST - 1
    ~ player_was_honest = false
    # speaker:mc
    Это мой стандартный режим.
    -> rooftop_after_talk

* [Сказать правду]
    ~ TRUST = TRUST + 1
    ~ player_was_honest = true
    # speaker:mc
    День был странный.
    -> rooftop_truth

* {INSIGHT >= 2} [Попробовать объяснить]
    ~ TRUST = TRUST + 1
    ~ player_was_honest = true
    # speaker:mc
    Это не просто усталость.
    -> rooftop_deep


=== rooftop_truth
# speaker:npc
Ну, ты хотя бы это признаёшь.

# speaker:npc
Большинство делают вид, что всё нормально.

{TRUST >= 1:
    ~ npc_opened_up = true
    # speaker:npc
    Я тоже иногда делаю вид. Так проще не пугаться.
}

-> rooftop_after_talk


=== rooftop_deep
# speaker:mc
{loop_awareness > 0 or iteration_number > 1:
Как будто этот день уже был.
- else:
Как будто день заранее знает, где я ошибусь.
}

# speaker:mc
И что-то пытается не объяснить, а подтолкнуть.

{INSIGHT >= 3:
    ~ INSIGHT = INSIGHT + 1
    # speaker:mc
    И я начинаю понимать, где именно он ломается.
}

{TRUST >= 1:
    ~ npc_opened_up = true
    # speaker:npc
    Тогда не отмахивайся. Если страшно — скажи, что страшно.
}

-> rooftop_after_talk


// ================================================================
// ВНУТРЕННЕЕ СОСТОЯНИЕ
// ================================================================
=== rooftop_after_talk

# speaker:mc
{used_fallback:
Я сегодня сделал{mc_gender == "female":а|} всё быстрее.
Но не уверен{mc_gender == "female":а|}, что правильно.
- else:
Я сегодня не стал{mc_gender == "female":а|} притворяться, что всё понятно.
}

{understood_uncertainty:
# speaker:mc
Проблема не в данных.
Проблема в том, как мы делаем вид, что их достаточно.
}

{npc_opened_up && player_was_honest && TRUST >= 2:
    ~ confession_unlocked = true
    # speaker:none
    Между нами появляется пауза, которую уже нельзя списать на ветер.
}

-> rooftop_route


// ================================================================
// РОУТИНГ ФИНАЛОВ
// ================================================================
=== rooftop_route

{SYNC >= 2 && INSIGHT >= 2 && TRUST >= 1:
    -> ending_true
- else:
    {SYNC >= 2 && INSIGHT >= 2:
        -> ending_true_without_trust
    - else:
        {TRUST >= 2:
            -> ending_npc
        - else:
            -> ending_system
        }
    }
}


// ================================================================
// NPC ENDING
// ================================================================
=== ending_npc
{confession_unlocked:
    -> ending_npc_confession
- else:
    {npc_opened_up:
        -> ending_npc_opened
    - else:
        -> ending_npc_soft
    }
}


=== ending_npc_soft
# speaker:npc
Слушай.

# speaker:npc
Может, не всё нужно чинить.

# speaker:npc
Иногда достаточно, чтобы рядом был кто-то.

# speaker:mc
...

# speaker:none
В этот момент становится легче.

Слишком легко.

~ current_iteration_end = "npc"
~ TRUST = TRUST + 1

-> rooftop_loop


=== ending_npc_opened
# speaker:npc
Слушай.

# speaker:npc
Я не знаю, что именно с тобой происходит.

# speaker:npc
Но когда ты не шутишь вместо ответа — я хотя бы вижу тебя настоящ{mc_gender == "female":ую|его}.

# speaker:mc
Это должно успокаивать?

# speaker:npc
Нет.

# speaker:npc
Это должно быть честнее.

# speaker:none
Становится легче.

Но теперь это не похоже на бегство.

~ current_iteration_end = "npc"
~ TRUST = TRUST + 1
~ npc_opened_up = true

-> rooftop_loop


=== ending_npc_confession
# speaker:npc
Слушай.

# speaker:npc
Я весь день пытал{mc_gender == "female":ся|ась} понять, почему ты смотришь так, будто прощаешься заранее.

# speaker:mc
Потому что я боюсь повторить всё неправильно.

# speaker:npc
Тогда не повторяй один{mc_gender == "female":а|}.

# speaker:mc
Я не хочу, чтобы ты стал{mc_gender == "female":а|} просто способом пережить этот день.

# speaker:npc
А кем?

# speaker:mc
Тем, ради кого я перестаю искать самый простой выход.

# speaker:none
Пауза не ломается.

Она выдерживает нас обоих.

~ current_iteration_end = "npc"
~ TRUST = TRUST + 2
~ npc_opened_up = true
~ confession_unlocked = true

# meta:add:loop_awareness:1

-> rooftop_loop


// ================================================================
// SYSTEM ENDING
// ================================================================
=== ending_system
# speaker:none
Всё работает.

Ошибок нет.
Система стабильна.

# speaker:mc
...

# speaker:none
На секунду мир “подвисает”.

fallback_decision_applied

# speaker:mc
Проблема не исчезла.

Она просто скрыта.

~ current_iteration_end = "system"
~ INSIGHT = INSIGHT + 1

-> rooftop_loop


// ================================================================
// TRUE ATTEMPT WITHOUT TRUST
// ================================================================
=== ending_true_without_trust
# speaker:mc
Я понял{mc_gender == "female":а|}.

# speaker:npc
Что именно?

# speaker:mc
Нельзя принимать решение,
если данных недостаточно.

# speaker:npc
Ты говоришь так, будто уже решил{mc_gender == "female":а|} уйти туда один{mc_gender == "female":а|}.

# speaker:mc
...

# speaker:none
Формула складывается.
Но в ней не хватает человека рядом.

# speaker:mc
Я знаю, где ошибка.

# speaker:mc
Но не знаю, как не повторить её снова.

~ current_iteration_end = "system"
~ INSIGHT = INSIGHT + 1
~ SYNC = SYNC + 1

# meta:add:loop_awareness:1

-> rooftop_loop


// ================================================================
// TRUE ENDING
// ================================================================
=== ending_true
# speaker:mc
Я понял{mc_gender == "female":а|}.

# speaker:npc
Что именно?

# speaker:mc
Нельзя принимать решение,
если данных недостаточно.

# speaker:mc
И нельзя делать вид, что всё ок.

# speaker:none
В этот момент всё складывается.

экран  
метро  
лог  
решение  

# speaker:mc
Это цикл.

# speaker:mc
И теперь я знаю, где искать разрыв.

~ current_iteration_end = "true"
~ INSIGHT = INSIGHT + 2
~ SYNC = SYNC + 2

# meta:add:loop_awareness:1

-> rooftop_loop


// ================================================================
// LOOP SIGNAL
// ================================================================
=== rooftop_loop
# speaker:none
Ветер замирает.

Город на секунду “зависает”.

# speaker:mc
...

{current_iteration_end == "true":
    # speaker:mc
    Я запомню. Не всё, но достаточно для следующего раза.
- else:
    # speaker:mc
    Что-то здесь не так. И это не закончится само.
}

# pulse:1.0,255,255,255
# shake:0.2,0.6

# speaker:none
И всё обрывается не как финал, а как сброс.

-> END
