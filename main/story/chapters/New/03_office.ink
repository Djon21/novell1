// ================================================================
// AVOS_S — 03_office.ink
// Stage function:
// - core-конфликт главы
// - неопределённость как проблема
// - соблазн fallback_decision
// - превращение INSIGHT -> SYNC
// - подготовка rooftop-финала
// ================================================================


// ================================================================
// ВХОД В ОФИС
// ================================================================
=== office_entry
# bg:bg_office_open # color:0.16,0.18,0.22 # speaker:none
Офис встречает привычной тишиной до начала рабочего дня.

Ещё не шумно.
Только кондиционер,
редкие шаги,
и фон из уже открытых рабочих окон.

# speaker:mc
Рано.

# speaker:none
На мониторах — тёмная тема, таблицы, логи, дашборды.
Всё выглядит так, будто система уже давно проснулась и теперь ждёт, пока до неё дотянутся люди.

{future_hint_seen:
# speaker:mc
И почему-то у меня ощущение, что часть этого дня уже отработана без меня.
- else:
# speaker:mc
Ненавижу этот момент.
Когда день ещё можно сломать почти любым решением.
}

-> office_npc_intro


// ================================================================
// NPC КАК КОМФОРТ И "НЕ УГЛУБЛЯЙСЯ"
// ================================================================
=== office_npc_intro
# speaker:npc
Ты успел{mc_gender == "female":а|} кофе?
Выглядишь чуть живее.

* [Пошутить в ответ]
    ~ TRUST = TRUST + 1
    # speaker:mc
    Кофеин — это просто outsource сознания.
    -> office_npc_intro_end

* [Сказать, что утро было странным]
    ~ TRUST = TRUST + 1
    # speaker:mc
    Утро было каким-то... кривым.
    -> office_npc_strange

* [Сразу переключиться на работу]
    # speaker:mc
    Что у нас горит?
    -> office_task_setup


=== office_npc_strange
# speaker:npc
Это потому что мы оба перерабатываем.

# speaker:npc
Не надо искать в этом смысл.
Надо дожить до вечера.

# speaker:mc
Утешение уровня senior.

=== office_npc_intro_end
-> office_task_setup


// ================================================================
// ПОСТАНОВКА ЗАДАЧИ
// ================================================================
=== office_task_setup
# bg:bg_office_desk # color:0.12,0.14,0.18 # speaker:none
На рабочем столе открыт проект.

AVOS.
Сборка пайплайна.
Очередь входящих кейсов.

# speaker:none
Один из кейсов подсвечен красным.

input state: ambiguous
confidence: insufficient
response deadline: immediate

# speaker:mc
Вот и оно.

{understood_uncertainty:
# speaker:mc
Неполные данные.
Система не должна решать это сама.
- else:
# speaker:mc
Неполные данные.
Самое неприятное состояние.
}
-> office_pressure


// ================================================================
// ДАВЛЕНИЕ: СОБЛАЗН БЫСТРОГО РЕШЕНИЯ
// ================================================================
=== office_pressure
# speaker:npc
Этот кейс лучше закрыть быстро.
Иначе он зависнет в очереди и начнёт тянуть остальные.

# speaker:npc
Там можно пройти по сокращённому пути.

# speaker:mc
По какому именно?

# speaker:npc
Ну...
Не ждать идеальной определённости.
Система может добрать решение сама.

# speaker:mc
То есть fallback.

# speaker:npc
То есть рабочий день закончится вовремя.

{INSIGHT > 1:
# speaker:mc
И вот именно эта фраза уже начинает звучать как угроза.
- else:
# speaker:mc
Звучит удобно.
}
-> office_core_choice


// ================================================================
// КЛЮЧЕВОЙ ВЫБОР
// ================================================================
=== office_core_choice
# speaker:none
Перед тобой не просто задача.

Перед тобой стиль мышления.

* [Включить fallback_decision и закрыть кейс быстро]
    ~ used_fallback = true
    ~ office_strategy = "fallback"
    ~ day_strategy = "ignore"
    -> office_fallback_path

* [Остановиться и проверить, можно ли запросить уточнение]
    ~ office_strategy = "clarify"
    ~ INSIGHT = INSIGHT + 1
    -> office_clarify_path

* [Отложить кейс до появления данных]
    ~ office_strategy = "defer"
    ~ decision_deferred = true
    -> office_defer_path

* {understood_uncertainty or INSIGHT >= 3} [Отказаться от автоматического решения принципиально]
    ~ office_strategy = "principled_refusal"
    ~ INSIGHT = INSIGHT + 1
    -> office_refusal_path


// ================================================================
// ПУТЬ 1: FALLBACK
// Это ложная эффективность.
// ================================================================
=== office_fallback_path
# speaker:none
Ты активируешь fallback-маршрут.

# speaker:none
На экране одна за другой проходят строки:

validate...
soft check...
fallback_decision applied
resolved

# speaker:mc
Слишком быстро.

# speaker:npc
Именно.
Смотри, всё зелёное.

# speaker:none
Дашборд обновляется.
Кейс исчезает из очереди.
Формально задача решена.

* [Принять это как успех]
    ~ SYNC = SYNC - 1
    -> office_fallback_accept

* [Признать, что решение вызывает тревогу]
    ~ INSIGHT = INSIGHT + 1
    -> office_fallback_doubt


=== office_fallback_accept
# speaker:mc
Работает — значит работает.

# speaker:none
Фраза звучит почти профессионально.

# speaker:none
И почти как капитуляция.

-> office_result_system_bias


=== office_fallback_doubt
# speaker:mc
Да.
Только это не выглядит как обработка.

# speaker:mc
Это выглядит как отказ думать.

# speaker:npc
Иногда отказ думать и называется приоритизацией.

# speaker:mc
Удобная формулировка.

~ anomaly_interpreted = true
-> office_result_system_bias


// ================================================================
// ПУТЬ 2: УТОЧНЕНИЕ
// Лучший путь для SYNC.
// ================================================================
=== office_clarify_path
# speaker:none
Ты убираешь курсор с кнопки быстрого решения.

# speaker:mc
Если данных недостаточно, нужно не выбирать за пользователя,
а признать, что данных недостаточно.

# speaker:none
Ты открываешь схему пайплайна.
Ветвь выглядит простой:

validate
?
fallback_decision

Слишком простой.

* [Добавить request_input]
    ~ requested_clarification = true
    ~ understood_uncertainty = true
    ~ SYNC = SYNC + 2
    -> office_clarify_success

* [Заменить fallback на wait]
    ~ decision_deferred = true
    ~ understood_uncertainty = true
    ~ SYNC = SYNC + 1
    -> office_wait_success

* [Передумать и вернуть fallback]
    ~ used_fallback = true
    ~ office_strategy = "fallback"
    -> office_fallback_path


=== office_clarify_success
# speaker:none
Ты перестраиваешь поток:

validate
request_input
wait_for_response

# speaker:none
Статус кейса меняется:

needs clarification

# speaker:npc
Это дольше.

# speaker:mc
Да.

# speaker:mc
Потому что реальность дольше, чем имитация уверенности.

~ requested_clarification = true
~ understood_uncertainty = true
~ INSIGHT = INSIGHT + 1

# note:add:Pipeline:"validate -> request_input -> wait_for_response"

-> office_result_true_bias


=== office_wait_success
# speaker:none
Ты отключаешь автоматическое решение и переводишь кейс в ожидание.

# speaker:none
Статус:
deferred pending valid input

# speaker:npc
Это никому не понравится.

# speaker:mc
Зато это честно.

~ decision_deferred = true
~ understood_uncertainty = true
~ INSIGHT = INSIGHT + 1

# note:add:Pipeline:"ambiguous case -> wait, no auto-resolution"

-> office_result_true_bias


// ================================================================
// ПУТЬ 3: ОТЛОЖИТЬ БЕЗ ОСМЫСЛЕНИЯ
// Средняя ветка: не ошибка, но и не понимание.
// ================================================================
=== office_defer_path
# speaker:none
Ты уводишь кейс в сторону, не давая системе решить его автоматически.

# speaker:none
Но и не меняя сам принцип обработки.

# speaker:mc
Не сейчас.

# speaker:mc
Пусть повисит.

# speaker:npc
Тоже вариант.

# speaker:none
Да.
Вариант не сломать всё прямо сейчас.

# speaker:none
Но не вариант понять, почему всё вообще можно было сломать.

~ SYNC = SYNC + 0
~ INSIGHT = INSIGHT + 0

-> office_result_neutral


// ================================================================
// ПУТЬ 4: ПРИНЦИПИАЛЬНЫЙ ОТКАЗ
// Это зрелая ветка: игрок уже понял рамку проблемы.
// ================================================================
=== office_refusal_path
# speaker:mc
Нет.

# speaker:mc
Если данные неоднозначны, система не имеет права притворяться, что неоднозначности нет.

# speaker:none
Эта мысль оформляется слишком чётко.
Словно ты не придумал{mc_gender == "female":а|} её сейчас,
а вспомнил{mc_gender == "female":а|}.

# speaker:npc
Ты сейчас звучишь так, как будто споришь не с задачей, а с чем-то большим.

# speaker:mc
Возможно.

# speaker:mc
Потому что задача всегда была больше.

~ requested_clarification = true
~ understood_uncertainty = true
~ INSIGHT = INSIGHT + 2
~ SYNC = SYNC + 2

# note:add:Принцип:"неопределённость нельзя маскировать решением"

-> office_result_true_bias


// ================================================================
// РЕЗУЛЬТАТЫ: ПОДГОТОВКА К РУФТОПУ
// ================================================================
=== office_result_system_bias
# bg:bg_office_evening # color:0.18,0.12,0.12 # speaker:none
Рабочий день продолжается.

Снаружи всё выглядит нормально.
Дашборды зелёные.
Очередь не горит.
Система благодарно молчит.

# speaker:mc
Именно это и пугает.

{used_fallback:
# speaker:mc
Ошибки такого типа опасны не потому, что кричат.
А потому, что слишком легко сходят за успех.
}

# speaker:none
На секунду экран гаснет.

В отражении —
та же строка, что в метро:

fallback_decision applied

# speaker:mc
Понял{mc_gender == "female":а|}.

# speaker:mc
То есть нет.
Но уже почти понял{mc_gender == "female":а|}.

-> office_day_end


=== office_result_true_bias
# bg:bg_office_evening # color:0.12,0.16,0.18 # speaker:none
Рабочий день продолжается.

Кейс не исчез.
Он просто перестал быть фальшиво решённым.

# speaker:npc
Ты сегодня слишком серьёзно к этому отнёс{mc_gender == "female":лась|ся}.

* [“Потому что это важно”]
    ~ TRUST = TRUST + 1
    ~ player_was_honest = true
    # speaker:mc
    Потому что это важно.
    -> office_result_true_bias_end

* [“Просто не люблю грязные решения”]
    # speaker:mc
    Просто не люблю, когда система врёт с уверенным видом.
    -> office_result_true_bias_end

=== office_result_true_bias_end
# speaker:none
На экране остаётся честный статус.

needs clarification
или
pending valid input

# speaker:mc
Не красиво.
Зато по-настоящему.

-> office_day_end


=== office_result_neutral
# bg:bg_office_evening # color:0.16,0.16,0.18 # speaker:none
День не ломается.

Но и не собирается в форму.

# speaker:mc
Я ничего не испортил{mc_gender == "female":а|}.

# speaker:mc
И ничего не исправил{mc_gender == "female":а|}.

# speaker:none
Самая тихая из неудач.

-> office_day_end


// ================================================================
// КОНЕЦ РАБОЧЕГО ДНЯ
// ================================================================
=== office_day_end
# speaker:none
Мониторы постепенно гаснут.

Офис пустеет.
Шум становится мягче.
Мысли — нет.

# speaker:npc
Пойдём наверх?

# speaker:mc
На крышу?

# speaker:npc
Куда же ещё.
У нас же корпоративная традиция драматизировать день на высоте.

# speaker:mc
Справедливо.

-> rooftop_entry