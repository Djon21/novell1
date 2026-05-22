# Ink Tag Reference For GPT

Этот файл - короткий справочник тегов для авторинга Ink. Его можно загружать в GPT вместо `main/scripts/dialogue_manager_ink.lua`, если задача только написать или проверить сценарий.

Source of truth в коде: `main/scripts/dialogue_manager_ink.lua`, функция `apply_tags`.

Если нужно изменить поведение тегов или добавить новый тег, тогда уже нужен сам Lua-файл. Для обычного написания сцен достаточно этого справочника.

## Фон, говорящий, эффекты

| Тег | Пример | Что делает |
|---|---|---|
| `bg:NAME` | `# bg:bg_apartment_bedroom_day` | Меняет фон диалога. `bg:none` или пустое значение убирает фон. |
| `color:R,G,B` | `# color:0.1,0.1,0.15` | Меняет цвет подложки, значения 0..1. |
| `speaker:ID` | `# speaker:mc` | Меняет говорящего. `mc` и `npc` подставляют текущие имена, `none` очищает говорящего. |
| `sfx:NAME` | `# sfx:phone_notify` | Одноразовый звук. |
| `shake:I,D` | `# shake:0.2,0.5` | Тряска экрана: сила и длительность. |
| `pulse:D,R,G,B` | `# pulse:0.8,0,255,0` | Цветовая вспышка, RGB 0..255. |

## Флаги, предметы, квесты

| Тег | Пример | Что делает |
|---|---|---|
| `set_flag:NAME=VALUE` | `# set_flag:coffee_drunk=true` | Ставит game_state flag. Значения `true`, `false`, числа и строки поддерживаются. |
| `flag:NAME=VALUE` | `# flag:coffee_drunk=true` | Legacy alias для `set_flag`. Для нового текста лучше `set_flag`. |
| `add_item:ID` | `# add_item:phone` | Добавляет предмет. |
| `remove_item:ID` | `# remove_item:mug` | Убирает предмет. |
| `item:add:ID` | `# item:add:phone` | Legacy alias для добавления предмета. |
| `item:remove:ID` | `# item:remove:mug` | Legacy alias для удаления предмета. |
| `quest:start:ID` | `# quest:start:make_coffee` | Ставит квест в `active`. |
| `quest:done:ID` | `# quest:done:make_coffee` | Ставит квест в `done`. |
| `quest:fail:ID` | `# quest:fail:reply_npc` | Ставит квест в `failed`. |
| `quest:ID=STATUS` | `# quest:make_coffee=done` | Прямо задаёт статус квеста. |

`quest:complete` не поддерживается.

## SMS и мессенджер

| Тег | Пример | Что делает |
|---|---|---|
| `sms:add:CONTACT:TEXT` | `# sms:add:mila:Есть планы?` | Добавляет входящее SMS. |
| `sms:add_hot:CONTACT:TEXT` | `# sms:add_hot:unknown:если помнишь, ответь.` | То же что `sms:add`, но сообщение в треде подсвечивается hot-стилем (красно-розовый акцент, выделенный border). Для напряжённых / тревожных входящих. |
| `sms:add_old:CONTACT:TIME:TEXT` | `# sms:add_old:mama:пн:Не забудь поесть.` | **Pre-existing** сообщение — уже прочитанное, с готовым временем (`пн`, `вчера`, `03:17` и т.п.). Не бампит unread-счётчик. Для seed телефонной истории на старте игры, чтобы лента не выглядела пустой. |
| `sms:reply_old:CONTACT:TIME:TEXT` | `# sms:reply_old:mama:пн:Да, всё нормально.` | Старое исходящее SMS от героя для seed-истории. Не бампит unread и **не** ставит `sms_<contact>_replied`. |
| `msg:add_old:CHAT:TIME:TEXT` | `# msg:add_old:work_team:пн:Планёрка перенесена.` | То же для Messenger. |
| `msg:reply_old:CHAT:TIME:TEXT` | `# msg:reply_old:friends:пт:Я могу отменить заранее.` | Старое исходящее сообщение героя в Messenger. Не бампит unread и **не** ставит `msg_<chat>_replied`. |
| `sms:reply:CONTACT:TEXT` | `# sms:reply:mila:Хорошо.` | Добавляет исходящее SMS от героя и ставит авто-флаг ответа. |
| `sms:read:CONTACT` | `# sms:read:mila` | Помечает SMS-чат прочитанным. |
| `sms:tag:CONTACT:TONE:LABEL` | `# sms:tag:unknown:hot:сигнал` | Ставит pin-тег на SMS-чат (цветной значок справа в списке). TONE ∈ `hot`, `amber`, `danger`, `warn`. LABEL — короткая подпись (выводится UPPERCASE, обрезается до ~8 символов). |
| `sms:tag:CONTACT:TONE` | `# sms:tag:prod:amber` | Тег без подписи — только цветная плашка-точка. |
| `sms:tag:CONTACT:clear` | `# sms:tag:unknown:clear` | Снять pin-тег с чата. |
| `sms:need_reply:CONTACT[:LABEL]` | `# sms:need_reply:mila` / `# sms:need_reply:prod:СРОЧНО` | Пин «ждёт ответа» — голубой акцент + label (дефолт `ОТВЕТЬ`). Автоматически снимается при `# sms:reply:CONTACT:...`. Используй когда без ответа в этот чат сюжет не пойдёт дальше. |
| `msg:add:CHAT:TEXT` | `# msg:add:mila:Привет` | Добавляет входящее сообщение в Messenger. |
| `msg:reply:CHAT:TEXT` | `# msg:reply:mila:Ок` | Добавляет исходящее сообщение в Messenger и ставит авто-флаг ответа. |
| `msg:read:CHAT` | `# msg:read:mila` | Помечает Messenger-чат прочитанным. |
| `msg:tag:CHAT:TONE[:LABEL]` | `# msg:tag:loop:hot:сигнал` | Pin-тег для Messenger. TONE ∈ `hot`, `amber`, `danger`, `warn`, `need_reply`. |
| `msg:tag:CHAT:clear` | `# msg:tag:loop:clear` | Снять pin-тег. |
| `msg:need_reply:CHAT[:LABEL]` | `# msg:need_reply:mila` | Пин «ждёт ответа» для Messenger. Авто-снимается при `# msg:reply:CHAT:...`. |
| `msg:prompt:CHAT:KNOT[:LABEL]` | `# msg:prompt:mila:park_message_where_are_you:НАПИСАТЬ` | Открытая инициатива в любом чате. См. ниже **«Открытая инициатива (`msg:prompt`)»**. |
| `msg:prompt:CHAT:clear` | `# msg:prompt:mila:clear` | Снять prompt вручную (если игрок ушёл из сцены не отправив). |

Если текст содержит двоеточие, лучше обернуть его в кавычки или проверить результат после сборки.

**Где хранить тексты сообщений:**

В проекте принят централизованный формат: сценовые `.ink` файлы не должны держать тексты SMS/Messenger напрямую. Сцены вызывают телефонные события через Ink tunnel, а сами теги сообщений лежат в телефонных файлах.

```ink
// В сцене:
-> phone_sms_seed_sunday_morning ->
-> phone_msg_seed_sunday_morning ->

// В 92_phone_sms.ink:
=== phone_sms_seed_sunday_morning ===
# sms:add_old:mama:пн:Не забудь поесть.
# sms:reply_old:mama:пн:Я поел.
->->

// В 93_phone_messenger.ink:
=== phone_msg_seed_sunday_morning ===
# msg:add_old:friends:пт:Доброе утро, выжившие.
->->
```

`92_phone_sms.ink` хранит `sms:*` и `bank:*`, потому что банковская система создаёт SMS. `93_phone_messenger.ink` хранит `msg:*`, включая `msg:prompt` и `msg:need_reply`. Если нужен новый текст сообщения, добавляй или меняй `phone_sms_*` / `phone_msg_*` event-knot, а в сцене оставляй только вызов.

**Порядок SMS:** runtime сортирует сообщения по внутреннему `sort_ts`, а не по строке на экране. Метки `пн/вт/ср/чт/пт/сб/вс` имеют абсолютный порядок недели. Метки `сегодня`, `вчера`, `позавчера` считаются относительно текущего дня Ink-сцены: в воскресенье `вчера` = суббота, в понедельник `вчера` = воскресенье и т.д. Если входящее и старый ответ должны идти парой, ставь `sms:add_old` и следующий за ним `sms:reply_old` с одинаковым `TIME` рядом друг с другом.

**Pin-теги:** хранятся в runtime-стейте (sms_state / messenger_state), сериализуются в save, переживают перезагрузку. Чтобы убрать тег — `# sms:tag:CONTACT:clear` / `# msg:tag:CHAT:clear`. Аватар в списке тоже подкрашивается под tone: `hot` → розовый/magenta, `amber`/`warn` → жёлтый, `danger` → красно-розовый, `need_reply` → розовый/magenta (тот же что у `hot`, с pingpong-анимацией alpha).

**`need_reply` vs обычный `tag`:** `need_reply` — это семантический пин «без ответа сюжет не двинется». Он автоматически снимается при `# sms:reply` / `# msg:reply` в этот чат, label по умолчанию `ОТВЕТЬ`. Обычные `tag` — это произвольный маркер (`hot:сигнал`, `amber:напомни`), руками снимается через `:clear`. Если игроку обязательно нужно ответить — используй `need_reply`, не `tag`.

**Read-only SMS / Messenger-ленты:**

Если контакт нужен только как сервисная или старая лента без ответа игрока, **не создавай** `sms_thread_<contact>` / `msg_thread_<chat>`. Достаточно добавлять историю через `# sms:add_old:...`, `# sms:add:...`, `# msg:add_old:...`, `# msg:add:...`.

Наличие thread-knot'а — это авторский сигнал UI, что input/SEND может открыть интерактивный Ink-ответ. Даже пустой `=== sms_thread_delivery === -> DONE` или `=== msg_thread_metro === -> DONE` может сделать чат похожим на интерактивный, если остальные runtime-условия позволяют.

`sms:read` и `msg:read` только снимают unread-состояние. Они **не** делают чат read-only.

Для SMS есть дополнительный runtime-предохранитель в `phone_contacts.lua`: `readonly = true` блокирует SEND даже при существующем `sms_thread_*`. Но для новых сервисных контактов всё равно держи канон проще: read-only = message history без thread-knot'а. Банк, доставка, такси, управдом, метро, маркет, клиника и похожие сервисы не должны получать `sms_thread_*`, если игрок реально не должен им отвечать.

Для Messenger `channel`, `bot`, `readonly` — это в основном presentation metadata. Если существует `msg_thread_<chat>` или активен `# msg:prompt:CHAT:KNOT`, input/SEND может стать интерактивным. Для каналов, ботов и старых лент не создавай `msg_thread_*` и не ставь `msg:prompt`.

**Открытая инициатива (`msg:prompt`):**

Синтаксис: `# msg:prompt:CHAT:KNOT[:LABEL]`

Это основной паттерн «дать игроку написать первым из сцены». Заменяет хотспоты «Написать». Делает за один тег сразу три вещи:

- ставит pin-плашку на чате CHAT в списке мессенджера (label = `LABEL` или `НАПИСАТЬ` по дефолту, мигает розовым);
- разрешает писать в чат **игнорируя** `msg_<chat>_replied` — даже если игрок уже отвечал в этот чат раньше;
- при тапе input'а в чате диверитит **в указанный KNOT** (не в `msg_thread_<chat>`).

Авто-снимается при первом `# msg:reply:CHAT:...` внутри KNOT. Если игрок не отправил и инициатива больше не нужна — снять вручную: `# msg:prompt:CHAT:clear`.

Пример (парк, игрок не нашёл NPC):

```ink
=== sunday_date_park_arrival ===
# speaker:none
В Messenger мигает чат — можно написать {npc_name_dat}, где вы разминулись.

{mc_gender == "female":
    # msg:prompt:artem:park_message_where_are_you:НАПИСАТЬ
- else:
    # msg:prompt:mila:park_message_where_are_you:НАПИСАТЬ
}
# hud:hint:phone
# return_to_scene
-> DONE

=== park_message_where_are_you ===
# speaker:mc
«Ты где?»

* [Спросить]
    # msg:reply:mila:Ты где?     // pin/prompt снимется автоматически
    # msg:add:mila:У воды, ближе к лавочкам.
    # hud:hint:phone:off
    -> DONE
```

**Когда что использовать:**
- Игроку приходит сообщение, надо ответить → `# msg:need_reply` (pin «ОТВЕТЬ», использует штатный `msg_thread_<chat>`).
- Игрок должен написать первым из конкретной сцены → `# msg:prompt:CHAT:KNOT` (pin «НАПИСАТЬ», свой knot).
- Просто визуальный маркер на чате без авто-снятия → `# msg:tag:CHAT:TONE:LABEL`.

## Splash-перебивки (полноэкранные заглушки)

Полноэкранный overlay с анимацией. Используется для смены дня, перехода между локациями, воспоминаний, тревожных моментов, произвольных «текстовых пауз». Ждёт **тапа игрока** для продолжения (всегда). Ink ставится на паузу до клика по splash'у.

| Тег | Пример | Что делает |
|---|---|---|
| `splash:day:DAY` | `# splash:day:monday` | Смена дня. Terminal-лог + крупное название дня. DAY ∈ `sunday`, `monday`, `tuesday`, `wednesday`. Для `wednesday` визуально включается «тревожный» режим (hot+amber) — использовать **один раз** в кульминационный момент. |
| `splash:location:SCENE_ID` | `# splash:location:park_riverside_bench` | Прибытие в локацию. Eyebrow «ЛОКАЦИЯ» + название места (берётся из `scenes.lua` `label`). |
| `splash:text:TITLE` | `# splash:text:Воспоминание` | Нейтральный title-only. |
| `splash:text:TITLE:SUBTITLE` | `# splash:text:Москва:Три года назад` | Title + subtitle. |
| `splash:memory:TITLE` | `# splash:memory:Вчера вечером` | Тёплая палитра (amber), eyebrow «ВОСПОМИНАНИЕ». |
| `splash:alarm:TITLE` | `# splash:alarm:Сбой системы` | Hot-палитра (розовый), eyebrow «ВНИМАНИЕ». Для критических/тревожных моментов. |
| `day_transition:to:DAY` | (legacy) | Алиас `splash:day:DAY`, сохранён для совместимости. Использовать новый тег. |

**Backward-compat:** старый `# day_transition:to:DAY` работает как алиас `splash:day:DAY`.

Пример — переход дня:

```ink
=== sunday_evening_sleep ===
Ты ложишься спать. Веки тяжелеют почти мгновенно.

# splash:day:monday

// Ink ставится на паузу пока splash не закрыт игроком (тап). Затем продолжается.
# bg:bg_apartment_bedroom_day
Будильник звенит ровно в семь. Понедельник начался.
-> monday_morning_start
```

Пример — переход в локацию через карту:

```ink
=== travel_to_park ===
# splash:location:park_riverside_bench
# explore:park_riverside_bench
-> DONE
```

**Когда что использовать:**
- Смена дня (sleep → утро) → `splash:day:DAY`
- Прибытие в новую локацию (карта → сцена) → `splash:location:SCENE_ID`
- Флешбэк / воспоминание / монтажная пауза → `splash:memory:TITLE`
- Аномалия / системный сбой / разрыв петли → `splash:alarm:TITLE`
- Свободный заголовок («Глава 1», «Шесть месяцев назад») → `splash:text:TITLE[:SUBTITLE]`

## Transit (атмосферный overlay на время монтажа)

В отличие от splash, **transit не блокирует ink и не требует тапа**. Это атмосферная «подложка» на верхнюю часть экрана — пока внизу через dialogue-панель идут текстовые параграфы. Используется для нарративных монтажей: дорога на работу, сборы, флешбэк-секвенция, телефонный звонок (фон «трубка»), и т.п.

| Тег | Пример | Что делает |
|---|---|---|
| `transit:start:TITLE` | `# transit:start:На автомате` | Открывает overlay с eyebrow «В ПУТИ» и крупным TITLE. |
| `transit:start:TITLE:SUBTITLE` | `# transit:start:На автомате:знакомый маршрут` | + подзаголовок мелким шрифтом. |
| `transit:start:TITLE:SUBTITLE:EYEBROW` | `# transit:start:Дорога:к метро:УТРО ПОНЕДЕЛЬНИКА` | + кастомный eyebrow (по умолчанию «В ПУТИ»). |
| `transit:end` | `# transit:end` | Скрывает overlay (~0.4 сек fade-out). Обязательно вызывать перед следующим `# bg:` чтобы не остался поверх новой сцены. |

Внутри overlay есть animated motion-dot, бегущий по горизонтальной линии — визуальный сигнал «движение идёт». Останавливается на `transit:end`.

Пример — три варианта дороги на работу с разными подписями:

```ink
=== mon_commute_walk_auto ===
# transit:start:На автомате:знакомый маршрут — ничего нового
# speaker:none
Автоматический маршрут удобен тем, что не требует участия.
...

# speaker:mc
Главное — не начать так же работать.

# transit:end
-> mon_commute_work_district
```

**Когда transit, когда splash:**
- Splash = ОДНА перебивка-картинка, игрок тапает чтобы продолжить. Для смен дня, прибытия в локацию, заголовков глав.
- Transit = ДЛИТЕЛЬНЫЙ overlay на 2-4 параграфа текста. Игрок читает реплики поверх атмосферного фона. Закрывается явным `transit:end`.

**Важно:** transit не подменяет `# bg:` навсегда — он добавляется поверх. Если забыть `# transit:end` перед следующей сценой, overlay останется поверх нового bg.

## Телефонные приложения и данные

| Тег | Пример | Что делает |
|---|---|---|
| `phone:map` | `# phone:map` | Открывает телефон сразу на карте. |
| `phone:app:NAME` | `# phone:app:sms` | Открывает конкретное приложение телефона. |
| `phone:close` | `# phone:close` | Закрывает phone overlay. Использовать только в специальных случаях. |
| `phone:loop_reset` | `# phone:loop_reset` | Очищает телефонный runtime-слой новой петли: SMS, Messenger, unread, tags/prompts и банк/баланс. Не трогает meta-state и выбор персонажа. |
| `note:add:TITLE:BODY` | `# note:add:Кейс:не хватает данных` | Добавляет заметку. |
| `mail:add:FROM:SUBJECT` | `# mail:add:system:Кейс 017` | Добавляет письмо без отдельного тела. |
| `mail:add:FROM:SUBJECT:BODY` | `# mail:add:system:Кейс 017:Текст` | Добавляет письмо с телом. |
| `mail:read` | `# mail:read` | Помечает всю почту прочитанной. |
| `mail:read:INDEX` | `# mail:read:1` | Помечает одно письмо прочитанным. `1` - самое свежее. |
| `call:in:WHO` | `# call:in:mila` | Входящий звонок. |
| `call:out:WHO` | `# call:out:mila` | Исходящий звонок. |
| `call:missed:WHO` | `# call:missed:mila` | Пропущенный звонок. |
| `call:seen` | `# call:seen` | Сбрасывает счётчик пропущенных. |
| `clue:add:ID:LABEL` | `# clue:add:repeat:Повтор сигнала` | Добавляет улику. |

## Банк и деньги

| Тег | Пример | Что делает |
|---|---|---|
| `bank:set:AMOUNT` | `# bank:set:272229` | Выставляет текущий баланс банковской карты в runtime. Используй при seed старой истории телефона. |
| `bank:charge:AMOUNT:MERCHANT` | `# bank:charge:980:Кофейня «петля»` | Списывает сумму, пересчитывает баланс и автоматически добавляет SMS от `bank`. |

Не пиши банковские SMS со статичным остатком вручную для новых покупок. Ink должен знать только сумму и место покупки, а баланс считает Lua-система банка.

## Терминал

| Тег | Пример | Что делает |
|---|---|---|
| `term:ok:TEXT` | `# term:ok:Готово` | Добавляет строку уровня `ok`. |
| `term:warn:TEXT` | `# term:warn:Нет поля` | Добавляет предупреждение. |
| `term:err:TEXT` | `# term:err:Ошибка` | Добавляет ошибку. |
| `term:info:TEXT` | `# term:info:Запрос принят` | Добавляет информационную строку. |
| `term:prompt:TEXT` | `# term:prompt:>` | Добавляет prompt-строку. |
| `term:plain:TEXT` | `# term:plain:...` | Добавляет обычную строку. |
| `term:clear` | `# term:clear` | Очищает терминал. |
| `term:defaults` | `# term:defaults` | Возвращает дефолтный лог терминала. |

## Карта

| Тег | Пример | Что делает |
|---|---|---|
| `map:allow:POI_ID` | `# map:allow:poi_cafe` | Разрешает конкретную точку. |
| `map:allow:reset` | `# map:allow:reset` | Сбрасывает временные ограничения карты. |
| `map:lock_to:POI_ID` | `# map:lock_to:poi_cafe` | Оставляет доступной только одну точку. |
| `map:lock_all` | `# map:lock_all` | Блокирует все точки. |
| `map:lock:all` | `# map:lock:all` | То же, более читаемый вариант. |

Карта живёт **внутри телефона** (`phone_map`). Открывается через `# phone:map` или через тап иконки карты в phone-launcher'е. Standalone-карты больше нет — `# map:hub:` снят, теги выше управляют только доступностью POI на phone-карте.

## Сцены исследования

| Тег | Пример | Что делает |
|---|---|---|
| `explore:SCENE_ID` | `# explore:apartment_bedroom` | Передаёт управление exploration scene. |
| `goto_scene:SCENE_ID` | `# goto_scene:apartment_bedroom` | Alias для `explore`. |
| `return_to_scene` | `# return_to_scene` | Возвращает в последнюю exploration scene. Обычно ставится в конце side-knot. |

Если `return_to_scene`, `explore`, `goto_scene`, `phone:*` или `adv:*` стоят после последнего текста, они выполняются после того, как игрок дочитает параграф.

## Scene characters (full-figure на фоне)

«Сценные персонажи» — спрайты-фигуры на фоне exploration-сцены
(в стиле Persona 5), не путать с диалоговыми портретами в `dialogue_v2`.
Конфиг — `main/scripts/scene_characters.lua` (`SCENE_GROUPS` + `SCENES`).
Реальный список доступных групп/персонажей — в `PROJECT_INVENTORY.md`
секция **Scene Characters**.

| Тег | Пример | Что делает |
|---|---|---|
| `scene_char:show:GROUP:KEY` | `# scene_char:show:park:mila_idle` | Показать персонажа `KEY` в группе `GROUP`. |
| `scene_char:hide:GROUP:KEY` | `# scene_char:hide:park:mila_idle` | Спрятать конкретного персонажа. |
| `scene_char:hide_all` | `# scene_char:hide_all` | Спрятать всех персонажей текущей группы. |

Auto-hide при смене группы сцен — встроенное поведение. При переходе
между sub-сценами одной группы (например `park_hub` → `park_riverside_bench`,
обе в группе `park`) персонажи **остаются**. При выходе из группы (выход
из парка по `leave_park`) — авто-`hide_all`, явный тег не нужен.

Если у scene character есть `action.type = "ink_knot"`, клик по нему
запускает соответствующий knot — это альтернатива хотспоту на области
персонажа. См. `scene_characters.lua` SCENES конфиг и
`docs/guides/HOW_TO_ADD_SCENE_CHARACTERS.md`.

## HUD hints

| Тег | Пример | Что делает |
|---|---|---|
| `hud:hint:phone` | `# hud:hint:phone` | Подсветить/пульсировать кнопку телефона. |
| `hud:hint:bag` | `# hud:hint:bag` | Подсветить/пульсировать кнопку инвентаря. |
| `hud:hint:reset` | `# hud:hint:reset` | Снять подсказки. |
| `hud:hint:phone:off` | `# hud:hint:phone:off` | Снять подсказку телефона, если обработчик поддерживает target `phone:off`. |
| `hud:hint:bag:off` | `# hud:hint:bag:off` | Снять подсказку инвентаря, если обработчик поддерживает target `bag:off`. |

`dialogue_manager_ink.lua` передаёт весь target после `hint:` в команду `hud_hint`. Конкретную поддержку target проверять в UI/message flow, если добавляется новый вариант.

## Реклама

**Канонические теги — только эти два:**

| Тег | Пример | Что делает |
|---|---|---|
| `adv:fullscreen` | `# adv:fullscreen` | Полноэкранная (interstitial) реклама. |
| `adv:rewarded:FLAG` | `# adv:rewarded:watched_hint_ad` | Rewarded-видео; при успешном просмотре ставит `FLAG=true`. |

Рекламу лучше ставить в паузах: перед картой, после эпизода, перед сменой
локации — а не посреди реплики.

> **Legacy aliases** (runtime принимает, но в новых сценах НЕ использовать):
> `ad:fullscreen`, `adv:interstitial`, `ad:interstitial`,
> `adv:rewarded` (без FLAG), `ad:rewarded:FLAG`.
> Парсер в `dialogue_manager_ink.lua` поддерживает обе формы (`adv` и `ad`,
> `fullscreen` и `interstitial`), но в narrative используем строго каноничные —
> чтобы не разъезжалось с `NARRATIVE_STATE.md` и было одно очевидное имя для
> каждого вида рекламы.

## Meta и концовки

| Тег | Пример | Что делает |
|---|---|---|
| `meta:add:KEY:DELTA` | `# meta:add:loop_awareness:1` | Увеличивает числовое meta-поле. |
| `meta:set:KEY:VALUE` | `# meta:set:loop_awareness:2` | Задаёт meta-поле. |
| `loop:end:false:ID` | `# loop:end:false:ending_a` | Помечает ложную концовку. |
| `loop:end:true` | `# loop:end:true` | Помечает истинную концовку. |

Поддержанные numeric meta keys:

- `iteration_number`
- `completed_iterations`
- `loop_awareness`
- `false_endings_count`

## Типовой side-knot из хотспота

```ink
=== look_at_table ===
# speaker:none
На столе лежит чашка. Кофе давно остыл.

# set_flag:table_seen=true
# return_to_scene
-> DONE
```

## Типовой выход к карте

```ink
=== leave_apartment_to_map ===
# speaker:none
Дверь закрывается слишком тихо.

# map:allow:reset
# phone:map
-> DONE
```

## Типовой сюжетный маршрут только в одну точку

```ink
=== go_to_cafe_only ===
# speaker:none
Сейчас есть только один нормальный вариант.

# map:lock_to:poi_cafe
# phone:map
-> DONE
```
