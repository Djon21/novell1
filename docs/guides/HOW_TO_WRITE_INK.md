# Как писать Ink-файлы для AVOS_S

Единственный source of truth по авторингу Ink для текущего runtime: `dialogue_manager_ink.lua`, `scene_controller.lua`, `game_state.lua` и flow-модули `main/gui/modules/ui_manager_v2/`.

Правило: Ink пишет текст и шлёт теги-команды; состояние сцен, инвентарь, телефон, карту и квесты исполняет Lua.

---

## Содержание

1. [Файлы и компиляция](#1-файлы-и-компиляция)
2. [Минимальный шаблон knot'а](#2-минимальный-шаблон-knota)
3. [Поддерживаемые теги](#3-поддерживаемые-теги)
4. [VAR vs `# set_flag:`](#4-var-vs--set_flag)
5. [Lua → Ink переменные](#5-lua--ink-переменные)
6. [Выборы, условия и гендерные форки](#6-выборы-условия-и-гендерные-форки)
7. [Сцены, хабы и `# return_to_scene`](#7-сцены-хабы-и--return_to_scene)
8. [Карта и POI lock](#8-карта-и-poi-lock)
9. [Телефон](#9-телефон)
10. [Инвентарь и `inv_*` knot'ы](#10-инвентарь-и-inv_-knotы)
11. [Loop / endings](#11-loop--endings)
12. [Структура файлов и нейминг](#12-структура-файлов-и-нейминг)
13. [Playable task в первой итерации](#13-playable-task-в-первой-итерации)
14. [Чеклист перед коммитом](#14-чеклист-перед-коммитом)
15. [Типичные ошибки](#15-типичные-ошибки)

---

## 1. Файлы и компиляция

### Актуальная сетка Ink

```text
main/story/
├── chapter_01.ink
├── chapter_01.json
└── chapters/
    ├── 00_bootstrap.ink
    ├── 10_apartment.ink
    ├── 02_sunday_date.ink
    ├── 20_monday_home.ink
    ├── 21_monday_commute.ink
    ├── 22_monday_office.ink
    ├── 30_tuesday_home.ink
    ├── 31_tuesday_investigation.ink
    ├── 32_tuesday_rooftop.ink
    └── 91_inventory_actions.ink
```

`chapter_01.ink` содержит только `INCLUDE chapters/...`. Не добавлять туда текст, VAR или knot'ы.

### Компиляция

После любой правки `.ink` обязательно собрать JSON:

```bash
tools\compile_ink.bat chapter_01
```

Git Bash / Linux:

```bash
./tools/compile_ink.sh chapter_01
```

Без этого Defold будет играть старый `chapter_01.json`.

---

## 2. Минимальный шаблон knot'а

```ink
=== имя_knota ===
# bg:bg_name # speaker:none
Текст, который увидит игрок.

# set_flag:some_flag=true
# quest:done:some_quest
# add_item:some_item
# return_to_scene
-> DONE
```

Правила:

- Имя knot'а: латиница, цифры, подчёркивания. Без кириллицы и пробелов.
- `# bg:` и `# speaker:` ставь первой строкой, если knot сам задаёт фон/говорящего.
- Флаги, квесты, предметы — после текста.
- `# return_to_scene` — последний тег перед `-> DONE`, если knot вызван из point-and-click.
- Любой `ink_knot` из `scenes.lua` обязан реально существовать в подключённом `.ink`.

### Висячие теги

Если теги стоят после последнего параграфа, они применятся после того, как игрок дочитает текст. Это правильно для `# return_to_scene`.

```ink
=== look_table ===
# speaker:none
На столе ничего нового.

# set_flag:table_seen=true
# return_to_scene
-> DONE
```

---

## 3. Поддерживаемые теги

### Фон, говорящий, эффекты

| Тег | Пример | Что делает |
|---|---|---|
| `bg:NAME` | `# bg:bg_apartment_bedroom_day` | Меняет фон. `NAME` должен быть зарегистрирован как dedicated atlas в `ui_manager_v2.script`. |
| `bg:none` | `# bg:none` | Убирает фон. Использовать редко. |
| `color:R,G,B` | `# color:0.1,0.1,0.15` | Тинт фона, значения 0…1. |
| `speaker:ID` | `# speaker:mc`, `# speaker:npc`, `# speaker:none` | `mc`/`npc` подменяются на текущие имена. `none` — нарратор. |
| `sfx:NAME` | `# sfx:phone_notify` | Одноразовый звук. |
| `shake:I,D` | `# shake:0.2,0.5` | Тряска экрана: сила, длительность. |
| `pulse:D,R,G,B` | `# pulse:0.8,0,255,0` | Цветовая вспышка RGB 0…255. |

### State / inventory / quests

| Тег | Пример | Что делает |
|---|---|---|
| `set_flag:NAME=VAL` | `# set_flag:coffee_drunk=true` | Канонический флаг в `game_state`. |
| `flag:NAME=VAL` | `# flag:coffee_drunk=true` | Legacy alias. Работает, но для нового контента не использовать. |
| `add_item:ID` | `# add_item:mug` | Добавить предмет. |
| `remove_item:ID` | `# remove_item:mug` | Убрать предмет. |
| `item:add:ID` / `item:remove:ID` | — | Legacy aliases. Для нового контента не использовать. |
| `quest:start:ID` | `# quest:start:make_coffee` | Активировать phone quest. |
| `quest:done:ID` | `# quest:done:make_coffee` | Закрыть phone quest. |
| `quest:fail:ID` | `# quest:fail:reply_npc` | Провалить phone quest. |

`quest:complete` не поддерживается.

### Телефонные данные

| Тег | Пример | Что делает |
|---|---|---|
| `sms:add:CONTACT:TEXT` | `# sms:add:mila:Есть планы?` | Входящее SMS. |
| `sms:reply:CONTACT:TEXT` | `# sms:reply:mila:Хорошо.` | Исходящее SMS от ГГ. Авто-флаг: `sms_<contact>_replied=true`. |
| `sms:read:CONTACT` | `# sms:read:mila` | Пометить чат прочитанным вручную. |
| `msg:add:CHAT:TEXT` | `# msg:add:mila:Привет в мессенджере` | Входящее сообщение в Messenger-приложение (отдельно от SMS). |
| `msg:reply:CHAT:TEXT` | `# msg:reply:mila:Ок` | Исходящее в Messenger. Авто-флаг: `msg_<chat>_replied=true`. |
| `msg:read:CHAT` | `# msg:read:mila` | Пометить чат прочитанным вручную. Авто-флаг `msg_<chat>_read=true` ставится при открытии Messenger. |
| `note:add:TITLE:BODY` | `# note:add:Кейс:не хватает данных` | Добавить заметку. |
| `mail:add:FROM:SUBJECT[:BODY]` | `# mail:add:system:Кейс 017:Собрать пакет` | Добавить письмо. |
| `mail:read` / `mail:read:INDEX` | `# mail:read` | Пометить почту прочитанной. |
| `call:in:WHO` | `# call:in:mila` | Входящий звонок. |
| `call:out:WHO` | `# call:out:mila` | Исходящий звонок. |
| `call:missed:WHO` | `# call:missed:mila` | Пропущенный звонок. |
| `call:seen` | `# call:seen` | Сбросить missed-счётчик. |
| `clue:add:ID:LABEL` | `# clue:add:repeat:Повторяющийся сигнал` | Добавить улику. |
| `term:LEVEL:TEXT` | `# term:warn:missing field` | Строка терминала. LEVEL: `ok`/`warn`/`err`/`info`/`prompt`/`plain`. |
| `term:clear` / `term:defaults` | — | Очистить / вернуть дефолтный терминал. |

### Сцены и overlays

| Тег | Пример | Что делает |
|---|---|---|
| `explore:SCENE_ID` | `# explore:apartment_hub` | Отдать управление point-and-click сцене. |
| `goto_scene:SCENE_ID` | `# goto_scene:apartment_bedroom` | Alias `explore`. |
| `return_to_scene` | `# return_to_scene` | Вернуться в предыдущую point-and-click сцену. |
| `phone:map` | `# phone:map` | Открыть телефон сразу на карте. |
| `phone:app:NAME` | `# phone:app:sms` | Открыть конкретное приложение телефона. |
| `phone:close` | `# phone:close` | Закрыть телефон-overlay. Использовать только в специальных телефонных knot'ах. |
| `hud:hint:phone` | `# hud:hint:phone` | Кнопка PHN в HUD начинает пульсировать. Hint **устойчив**: переживает open/close телефона и держится пока автор не снимет явно. |
| `hud:hint:bag` | `# hud:hint:bag` | То же для кнопки инвентаря BAG. |
| `hud:hint:phone:off` / `hud:hint:bag:off` | — | Снять подсказку (использовать в knot'е выполнения нужного действия — например после `# sms:reply:`). |
| `hud:hint:reset` | `# hud:hint:reset` | Снять обе подсказки. |

> **Поведение pulse:**
> - Hint включается → кнопка пульсирует
> - Игрок открывает overlay (тап PHN/BAG ИЛИ через `# phone:app:sms`) → pulse визуально приостанавливается
> - Игрок закрывает overlay БЕЗ выполнения действия → pulse возобновляется
> - Автор снимает hint в knot'е выполнения (`# hud:hint:phone:off`) → pulse останавливается окончательно
>
> Типовой паттерн «ответить на SMS чтобы продвинуться»:
> ```ink
> === incoming_sms ===
> # sms:add:mila:Текст
> # hud:hint:phone        ← пульс начинается
> # phone:app:sms         ← телефон открывается, pulse визуально гасится
> # return_to_scene
> -> DONE
>
> === sms_thread_mila ===
> * [Ответить]
>     # sms:reply:mila:Хорошо
>     # hud:hint:phone:off   ← pulse полностью снят
>     -> done
> ```
> Если игрок закроет телефон не ответив — pulse возобновится в HUD до тех пор, пока он не зайдёт и не ответит.

### Реклама Яндекс Игр

| Тег | Пример | Что делает |
|---|---|---|
| `adv:fullscreen` | `# adv:fullscreen` | Показывает полноэкранную рекламу через Yandex Games SDK. |
| `ad:fullscreen` | `# ad:fullscreen` | Короткий alias для `adv:fullscreen`. |
| `adv:rewarded` | `# adv:rewarded` | Показывает rewarded video без автоматической награды. |
| `adv:rewarded:FLAG` | `# adv:rewarded:watched_hint_ad` | Показывает rewarded video и ставит `game_state` flag в `true`, если просмотр засчитан. |

Рекламу ставить только в логических паузах: перед переходом на новую сцену, перед картой, после завершения эпизода, перед новой итерацией. Не ставить посреди реплики или под случайный тап игрока.

Если после `# adv:fullscreen` в той же пачке тегов стоит переход (`# goto_scene:*`, `# phone:map`, `# return_to_scene`), runtime сначала дождется закрытия рекламы, а потом выполнит оставшиеся команды.

```ink
# speaker:none
До офиса еще двадцать минут дороги.

# adv:fullscreen
# phone:map
-> DONE
```

### Карта

| Тег | Что делает |
|---|---|
| `map:hub:KNOT` | Открыть карту в hub-режиме с fallback-knot. |
| `map:allow:POI_ID` | Разрешить POI. |
| `map:allow:reset` | Очистить allow-set. Если set пустой — доступны все POI. |
| `map:lock_to:POI_ID` | Очистить allow-set и разрешить только один POI. |
| `map:lock_all` | Заблокировать все POI. |
| `map:lock:all` | То же, альтернативная запись. |

### Meta / loop

| Тег | Что делает |
|---|---|
| `meta:add:KEY:DELTA` | Увеличить числовое meta-поле. |
| `meta:set:KEY:VALUE` | Установить meta-поле. |
| `chapter_finished` | Линейный конец итерации. |
| `loop:end:false:ID` | Ложная концовка, только 002+. |
| `loop:end:true` | Истинная концовка, только 002+, требует `false_endings_count >= 2`. |

---

## 4. VAR vs `# set_flag:`

В игре есть две системы состояния:

| Хранилище | Где читается | Как писать |
|---|---|---|
| Ink VAR | внутри Ink: `{coffee_drunk: ...}` | `VAR coffee_drunk = false` + `~ coffee_drunk = true` |
| `game_state` flag | `scenes.lua`, `quests.lua`, телефон, save | `# set_flag:coffee_drunk=true` |

Если флаг нужен и Ink, и сценам/квестам — ставь оба:

```ink
~ coffee_drunk = true
# set_flag:coffee_drunk=true
```

Если флаг читается только в `scenes.lua` / `quests.lua`, достаточно `# set_flag:`.

Предметы не храним через `has_*` флаги. Source of truth предмета: `# add_item:phone` и `gs.has_item("phone")`.

---

## 5. Lua → Ink переменные

Движок прокидывает в Ink:

| VAR | Источник |
|---|---|
| `mc_gender` | выбор игрока / `save_manager` |
| `mc_name` | `save_manager` |
| `npc_name` | `save_manager` |
| `iteration_number` | `meta_state` |
| `iteration_label` | `meta_state` |
| `loop_awareness` | `meta_state` |
| `completed_iterations` | `meta_state` |
| `false_endings_count` | `meta_state` |
| `inventory_item_id` | inventory side-knot context |
| `inventory_item_name` | inventory side-knot context |
| `inventory_item_verb` | inventory side-knot context |
| `inventory_scene_id` | inventory side-knot context |
| `inventory_target_id` | hotspot / npc / item target |
| `inventory_target_kind` | `"hotspot"` / `"npc"` / `"item"` / `""` |

Эти VAR не объявлять вручную в локальных `.ink`.

---

## 6. Выборы, условия и гендерные форки

```ink
* [Проверить уведомления]
    ~ INSIGHT = INSIGHT + 1
    # speaker:none
    Открываю уведомления.
    -> next_knot

* [Отложить]
    ~ SYNC = SYNC + 1
    # speaker:mc
    Потом.
    -> next_knot
```

- `*` — одноразовый выбор.
- `+` — многоразовый выбор.
- Текст в `[квадратных скобках]` — только на кнопке.
- Условный выбор: `* {SYNC >= 2} [Синхронизировать]`.

Гендерные форки:

```ink
Проснул{mc_gender == "female":ась|ся}.
Я не замети{mc_gender == "female":ла|л}.
```

---

## 7. Сцены, хабы и `# return_to_scene`

### `on_enter`

`scenes.lua`:

```lua
on_enter = {
    knot = "apartment_bedroom_intro",
    condition = function(gs)
        return not gs.get_flag("bedroom_morning_seen")
    end,
}
```

Ink:

```ink
=== apartment_bedroom_intro ===
# speaker:none
Комната держит сон.
# set_flag:bedroom_morning_seen=true
# return_to_scene
-> DONE
```

Правило: `on_enter`-knot обязан поставить флаг, который выключает `condition`. Иначе получится вечный цикл.

### Hotspot

`scenes.lua`:

```lua
action = { type = "ink_knot", knot = "take_phone" }
```

Ink:

```ink
=== take_phone ===
# speaker:none
Телефон вспыхивает экраном. Есть сообщения.
# sfx:phone_notify
# add_item:phone
# set_flag:phone_taken=true
# set_flag:phone_active=true
# sms:add:mila:Есть планы на сегодня?
# quest:done:find_phone
# quest:start:reply_npc
# return_to_scene
-> DONE
```

### Вход в point-and-click из сюжета

```ink
=== wake_after_choice ===
# bg:bg_apartment_bedroom_day # speaker:mc
Утро начинается слишком ровно.
# explore:apartment_bedroom
-> DONE
```

`# explore:` / `# goto_scene:` переводит игру в `scene_controller`.

---

## 8. Карта и POI lock

Для свободного выбора POI используй телефонную карту:

```ink
# phone:map
-> DONE
```

Для сюжетного маршрута с одним разрешённым местом:

```ink
# map:lock_to:poi_cafe
# phone:map
-> DONE
```

Чтобы временно закрыть вообще все точки:

```ink
# map:lock_all
# phone:map
-> DONE
```

После `map:lock_all` можно открыть одну конкретную точку через `# map:allow:poi_cafe`; это снимет полный блок и оставит доступной только добавленную точку.

После завершения маршрута:

```ink
# map:allow:reset
```

Понедельничный путь на работу в первой итерации — scripted commute, без `# phone:map`.

---

## 9. Телефон

Телефон — не Ink-сцена. Это Lua overlay с data-driven приложениями.

Разрешено:

- добавлять SMS / почту / заметки / звонки / улики тегами;
- добавлять сообщения в Messenger через `# msg:add:` / `# msg:reply:`;
- открывать карту или приложение через `# phone:*`;
- писать `sms_thread_<contact>` для side-dialogue переписки в SMS;
- писать `msg_thread_<chat>` для интерактивного ответа в Messenger.

> **Поведение pulse-индикатора:** в открытом thread-вью (и SMS, и Messenger) поле ввода и кнопка SEND начинают пульсировать, **только если** есть соответствующий `sms_thread_<contact>` / `msg_thread_<chat>` knot **и** игрок ещё не отвечал (`*_replied != true`). Если автор не написал thread-knot, чат остаётся read-only — без пульса, тап на input/send игнорируется. Так meme-чаты, боты-нотификации и каналы без интерактивного ответа выглядят правильно. Игрок тапает по чату → видит inline bubbles → тапает по полю/SEND (если оно пульсирует) → попадает в thread-knot для выбора ответа.

Запрещено:

- делать телефон отдельной `scene_id`;
- писать статичные “экраны телефона” в Ink;
- вручную ставить авто-флаги `sms_<contact>_read` / `sms_<contact>_replied` / `msg_<chat>_read` / `msg_<chat>_replied`.

---

## 10. Инвентарь и `inv_*` knot'ы

Активные verbs:

```text
inspect / read / use / give / combine
```

### `inspect` / `read`

```text
inv_<scene>_<verb>_<item>
→ inv_<verb>_<item>
→ inv_<verb>_fallback
→ inv_fallback
```

### `use` на hotspot

Игрок выбирает предмет → `ИСПОЛЬЗОВАТЬ` → кликает hotspot.

```text
inv_<scene>_use_<item>_on_<hotspot>
→ inv_use_<item>_on_<hotspot>
→ inv_use_<item>_on_fallback
→ inv_use_on_<hotspot>
→ inv_use_fallback
→ inv_fallback
```

Пример:

```ink
=== inv_apartment_kitchen_use_mug_on_coffee_setup ===
# speaker:mc
Ставлю кружку рядом с чайником.
~ coffee_drunk = true
# set_flag:coffee_drunk=true
# quest:done:make_coffee
# return_to_scene
-> DONE
```

### `combine`

Каноническое имя пары — лексикографическая сортировка item_id:

```text
inv_combine_<low>_with_<high>
→ inv_combine_fallback
→ inv_fallback
```

Пример:

```ink
=== inv_combine_folder_with_report_page ===
# speaker:mc
Складываю распечатку в папку.
# remove_item:folder
# remove_item:report_page
# add_item:case_file
# set_flag:monday_case_file_assembled=true
# return_to_scene
-> DONE
```

### `give`

`give` работает, если у текущей сцены есть `npc = "..."`.

```text
inv_<scene>_give_<item>_on_<npc>
→ inv_give_<item>_on_<npc>
→ inv_give_<item>_on_fallback
→ inv_give_on_<npc>
→ inv_give_fallback
→ inv_fallback
```

Для воскресных сцен с NPC использовать target `npc`, потому что имя персонажа зависит от пола MC.

---

## 11. Loop / endings

### Итерация 001

Линейная. Игрок ещё не понимает петлю.

Разрешено:

- point-and-click задачи;
- inventory use-on-target;
- combine;
- give;
- locked hotspots;
- phone quests;
- mail / notes / terminal / clues.

Запрещено:

- ложные концовки;
- true ending;
- прямое знание о петле;
- journal-записи о ложных концовках.

Финал: `# chapter_finished`.

### Итерация 002+

Ложная концовка:

```ink
# loop:end:false:ending_npc
```

Истинная концовка:

```ink
# loop:end:true
```

True Ending доступен только при `false_endings_count >= 2`. `loop_awareness` влияет на тон и loop-aware реплики, но не является прямым гейтом True Ending.

---

## 12. Структура файлов и нейминг

| Файл | Назначение |
|---|---|
| `00_bootstrap.ink` | Глобальные VAR и стартовый переход. |
| `10_apartment.ink` | Воскресное домашнее утро / onboarding. |
| `02_sunday_date.ink` | Воскресная встреча и возвращение домой. |
| `20_monday_home.ink` | Понедельник: дом и сборы. |
| `21_monday_commute.ink` | Понедельник: путь до офиса. |
| `22_monday_office.ink` | Понедельник: офис, work error, playable office task. |
| `30_tuesday_home.ink` | Вторник: дом и последствия. |
| `31_tuesday_investigation.ink` | Вторник: расследование. |
| `32_tuesday_rooftop.ink` | Вторник: крыша / финал итерации. |
| `91_inventory_actions.ink` | Универсальные действия предметов. |

Префиксы knot'ов:

```text
sunday_*        — воскресная встреча / воскресные хабы
mon_home_*      — понедельник, квартира
mon_commute_*   — понедельник, путь до офиса
mon_office_*    — понедельник, офис

tue_home_*      — вторник, квартира
tue_route_*     — вторник, маршруты / город
tue_rooftop_*   — вторник, крыша / концовки

inv_*           — действия предметов инвентаря
sms_thread_*    — side-knot переписки телефона
```

`monday_morning_start` можно оставить публичной точкой входа из воскресного сна. Внутренние knot'ы понедельника — через `mon_*`.

### Scene ID

Есть два допустимых паттерна:

1. **Отдельные scene_id** — когда меняется логика, маршрут, набор обязательных действий или флаги дня. Пример: `monday_apartment_*`, `tuesday_apartment_*`.
2. **Universal hub** — когда локация та же, hotspot'ы в основном общие, а меняется только фон/время. Пример текущей квартиры: `apartment_hub`, `apartment_bedroom`, `apartment_kitchen`.

Universal hub задаётся в `scenes.lua` через `bg = function(gs) return "bg_name" end`.

---

## 13. Playable task в первой итерации

Итерация 001 линейна по концовке, но не пассивна по геймплею.

Хороший playable task:

1. даёт понятную цель в phone quest;
2. требует осмотреть сцену;
3. использует хотя бы один предмет;
4. показывает locked hotspot или gated hotspot;
5. закрывается флагом в `game_state`;
6. не раскрывает петлю напрямую.

Пример: понедельничный office task — игрок проходит турникет, читает задачу, собирает папку, передаёт кейс, но стандартное решение в первой итерации применяется автоматически.

---

## 14. Чеклист перед коммитом

- [ ] Все новые knot'ы подключены через `chapter_01.ink` indirectly через `INCLUDE`.
- [ ] Все `ink_knot` из `scenes.lua` существуют в `.ink`.
- [ ] `on_enter.condition` выключается флагом внутри knot'а.
- [ ] Все `# bg:*` зарегистрированы как фоны в `ui_manager_v2.script`.
- [ ] Все `# quest:*` используют существующие id из `quests.lua`.
- [ ] Все `# add_item:*` используют id из `items_catalog.lua`.
- [ ] Если Ink проверяет `{var:}`, VAR объявлен в `00_bootstrap.ink`.
- [ ] Если сценам/квестам нужен флаг, стоит `# set_flag:`.
- [ ] Для side-knot из сцены в конце есть `# return_to_scene`.
- [ ] После правки `.ink` пересобран `chapter_01.json`.
- [ ] Smoke-тест: new game, Continue, phone, inventory, map.

---

## 15. Типичные ошибки

| Ошибка | Правильно |
|---|---|
| `# setflag:x=true` | `# set_flag:x=true` |
| `# additem:phone` | `# add_item:phone` |
| `# queststart:make_coffee` | `# quest:start:make_coffee` |
| `# quest:complete:make_coffee` | `# quest:done:make_coffee` |
| `# call:add:mila:missed` | `# call:missed:mila` |
| `# return_to_scene` в середине текста | Последним тегом перед `-> DONE` |
| `~ coffee_drunk = true`, но нет `# set_flag:coffee_drunk=true` | Ставить оба, если флаг нужен сценам/квестам |
| `# bg:bg_new_scene`, но фон не зарегистрирован | Добавить atlas + `go.property` + `DEDICATED_BG_ATLAS_PROPS` |
| Hotspot с `knot="x"`, но нет `=== x ===` | Добавить knot или удалить hotspot |

Не использовать для нового контента:

- `quest:complete`;
- `call:add:*`;
- старые `item:add/remove`, если можно написать `add_item/remove_item`;
- `# TODO` как тег. Комментарии писать через `//`.
