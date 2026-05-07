# Как писать ink-файлы для AVOS

> Этот файл — **единственный** источник правды по нашему ink. Если даёшь сценарий
> на правку нейронке — скопируй его целиком в системный промпт.
>
> Движок: `dialogue_manager_ink.lua` + `scene_controller.lua`. Ink-ранером
> занимается `defold-ink`; наш слой поверх него — только теги (`#`) и VAR.

---

## Содержание

1. [Файлы и компиляция](#1-файлы-и-компиляция)
2. [Скелет ink-файла](#2-скелет-ink-файла)
3. [Структура knot'а — шаблон](#3-структура-knota--шаблон)
4. [Все поддерживаемые теги](#4-все-поддерживаемые-теги)
5. [VAR vs `# set_flag:` — двойная система состояния](#5-var-vs--set_flag--двойная-система-состояния)
6. [Lua → Ink: переменные от движка](#6-lua--ink-переменные-от-движка)
7. [Выборы (* и +)](#7-выборы)
8. [Условные блоки и гендерные форки](#8-условные-блоки-и-гендерные-форки)
9. [Драм-флаги TRUST / INSIGHT / SYNC](#9-драм-флаги-trust--insight--sync)
10. [Как knot связан со сценой](#10-как-knot-связан-со-сценой)
11. [Карта и POI lock](#11-карта-и-poi-lock)
12. [Телефон — жёсткие правила](#12-телефон--жёсткие-правила)
13. [Чеклист перед коммитом](#13-чеклист-перед-коммитом)
14. [Типичные ошибки — НЕ ДЕЛАЙ ТАК](#14-типичные-ошибки--не-делай-так)
15. [Что не поддерживается](#15-что-не-поддерживается)
16. [Примеры готовых knot'ов](#16-примеры-готовых-knotов)

---

## 1. Файлы и компиляция

### Где лежит ink

```
main/story/
├── chapter_01.ink
├── chapter_01.json
└── chapters/
    ├── 00_bootstrap.ink
    ├── 01_apartment.ink
    ├── 02_sunday_date.ink
    ├── 20_monday_home.ink
    ├── 21_monday_commute.ink
    ├── 22_monday_office.ink
    ├── 30_tuesday_home.ink
    ├── 31_tuesday_investigation.ink
    ├── 32_tuesday_rooftop.ink
    └── 91_inventory_actions.ink
```

`chapter_01.ink` хранит **только** `INCLUDE chapters/...`. Ничего больше там не пишется.

### Команды компиляции

После любой правки `.ink` обязательно компилировать в JSON:

```bash
tools\compile_ink.bat              # все главы
tools\compile_ink.bat chapter_01   # только chapter_01
```

Git Bash / Linux:

```bash
./tools/compile_ink.sh
./tools/compile_ink.sh chapter_01
```

Без перекомпиляции Defold продолжит играть старый JSON.

### После правки сюжета

1. Перекомпилировать `chapter_01.json`.
2. Запустить игру, проверить старт новой игры.
3. Проверить `Continue`, если правка могла затронуть replay history.
4. Проверить телефон, карту и инвентарь, если добавлялись соответствующие теги.

---

## 2. Скелет ink-файла

```ink
// Комментарий (две косые черты). Можно в начале строки или в конце.

// Все VAR-объявления глобальные — лежат в 00_bootstrap.ink.
// В локальных файлах ничего не объявляем — только используем.

=== wake_intro ===
# bg:bg_apartment_bedroom_morning # speaker:mc
Текст параграфа. Каждый абзац — отдельный «клик» игрока.
-> choose_character
```

- Knot: `=== name ===` (три знака равенства, имя без пробелов и кириллицы — латиница/цифры/подчёркивания).
- Конец ветки: `-> другой_knot` или `-> DONE` (тупик), или `-> END` (конец истории).
- Файл `chapter_01.ink` имеет один root-knot — стартовая точка истории.

---

## 3. Структура knot'а — шаблон

```ink
=== имя_knota ===
# bg:имя_фона # speaker:none
Текст, который увидит игрок.
Второй абзац (если нужен).
# set_flag:название_флага=true
# quest:done:id_квеста
# add_item:id_предмета
# return_to_scene
-> DONE
```

**Правила:**
- `# bg:` и `# speaker:` — **первой строкой**, до текста
- Текст — середина
- Флаги, квесты, предметы — **после текста**, перед `# return_to_scene`
- `# return_to_scene` — **всегда последний** тег (кроме `-> DONE`)
- `-> DONE` — обязательная последняя строка

### Висячие теги в конце knot'а

Если после последнего параграфа стоят голые теги и `-> DONE`, они применяются **после того как игрок прочитает всё**. Так удобно вешать возврат в сцену:

```ink
=== take_phone ===
# speaker:mc
Холодный. Ладно. Нашёлся — уже хорошо.

# set_flag:coffee_drunk=true
# return_to_scene
-> DONE
```

---

## 4. Все поддерживаемые теги

### Фон, говорящий, эффекты

| Тег | Пример | Что делает |
|---|---|---|
| `bg:NAME` | `# bg:bg_apartment_bedroom_morning` | Меняет фон. `bg:none` — убрать. Каждому `bg_name` нужен dedicated atlas в `main/images/backgrounds/` И регистрация в `ui_manager_v2.script` (см. `HOW_TO_ADD_SCENES.md`). |
| `color:R,G,B` | `# color:0.1,0.1,0.15` | Тинт фона (0…1). |
| `speaker:ID` | `# speaker:mc` / `# speaker:npc` / `# speaker:none` / `# speaker:Аня` | Имя говорящего. `mc`/`npc` подменяются на `mc_name`/`npc_name`. `none` — без таблички (нарратор). |
| `sfx:NAME` | `# sfx:phone_notify` | Одноразовый звук. Добавление: `.ogg` в `main/sounds/` + `.sound` descriptor + component в `sfx_player` в `main_v2.collection` + запись в `M.SFX_URLS` в `ui_manager_v2.script`. |
| `shake:I,D` | `# shake:0.2,0.5` | Тряска экрана. `I` — сила (0…1), `D` — длительность сек. |
| `pulse:D,R,G,B` | `# pulse:0.8,0,255,0` | Мерцание цветом (RGB 0…255). |

### Состояние игры

| Тег | Пример | Что делает |
|---|---|---|
| `set_flag:NAME=VAL` | `# set_flag:coffee_drunk=true` | Канонический. Пишет флаг в `game_state`. Читается из `scenes.lua` через `gs.get_flag(...)`. Значения: `true`/`false`/число/строка. |
| `flag:NAME=VAL` | `# flag:coffee_drunk=true` | Алиас, legacy. Работает идентично. |
| `add_item:ID` | `# add_item:mug` | Канонический. Добавить предмет в инвентарь. |
| `remove_item:ID` | `# remove_item:mug` | Канонический. Убрать предмет. |
| `item:add:ID` / `item:remove:ID` | — | Алиасы (legacy), работают. |
| `quest:start:ID` | `# quest:start:make_coffee` | Активировать квест (статус `active`). |
| `quest:done:ID` | `# quest:done:go_to_office` | Закрыть квест (статус `done`). |
| `quest:fail:ID` | `# quest:fail:reply_mila` | Провалить квест. |

> ❌ `quest:complete` НЕ поддерживается. Только `start`/`done`/`fail` — любое другое значение силент-фейлится.

### Телефон (SMS, заметки, почта, звонки, улики, камера, терминал)

| Тег | Пример | Что делает |
|---|---|---|
| `sms:add:CONTACT:TEXT` | `# sms:add:mila:Есть планы?` | Входящее SMS от контакта (unread). |
| `sms:reply:CONTACT:TEXT` | `# sms:reply:mila:Хорошо, позже.` | Исходящее SMS от ГГ. **Auto-flag:** `sms_<contact>_replied = true`. |
| `sms:read:CONTACT` | `# sms:read:mila` | Гасит unread-флаг чата вручную. |
| `note:add:TITLE:BODY` | `# note:add:Коммит:хеш 03:47` | Добавить заметку. |
| `mail:add:FROM:SUBJECT[:BODY]` | `# mail:add:hr:Расписание:Пн 10:00` | Добавить письмо. |
| `mail:read` / `mail:read:INDEX` | `# mail:read:0` | Помечает почту прочитанной. |
| `call:in:WHO` | `# call:in:mila` | Входящий звонок. |
| `call:out:WHO` | `# call:out:mila` | Исходящий звонок. |
| `call:missed:WHO` | `# call:missed:mila` | Пропущенный звонок, увеличивает missed-бейдж. |
| `call:seen` | `# call:seen` | Журнал звонков просмотрен, missed-счётчик сброшен. |
| `clue:add:ID:LABEL` | `# clue:add:repeat:Повторяющийся сигнал` | Добавить улику. |
| `camera:STATUS:MESSAGE:META` | `# camera:online:Видна шторка:CAM-01` | Обновить камеру. STATUS: `offline`/`online`/`error`. |
| `camera:reset` | — | Сбросить камеру. |
| `term:LEVEL:TEXT` | `# term:warn:cycle drift +14ms` | Строка терминала. LEVEL: `ok`/`warn`/`err`/`info`/`prompt`/`plain`. |
| `term:clear` / `term:defaults` | — | Очистить / вернуть дефолтные строки. |
| `phone:close` | `# phone:close` | Закрыть телефон-overlay (только в специальном `phone_close` knot'е). |
| `phone:map` | `# phone:map` | Открыть телефон сразу на карте. |
| `phone:app:NAME` | `# phone:app:sms` | Открыть конкретное приложение. NAME: `sms`/`map`/`notes`/etc. |

> **Автоматические флаги SMS** (НЕ ставить руками):
> - Игрок открыл SMS-приложение → `sms_<contact>_read = true` для всех непрочитанных диалогов
> - В ink встретился `# sms:reply:contact:...` → `sms_<contact>_replied = true`

> **Переписка как ink-knot:** тап на строку переписки в телефоне открывает knot `sms_thread_<contact_id>`. Пример: `sms_thread_mila` в `01_apartment.ink`.
>
> **Защита от повторного ответа:** после первого `# sms:reply:contact:...` авто-флаг `sms_<contact>_replied = true` блокирует повторный вход в thread-knot — иначе `*`-выборы появлялись бы снова (`dm.jump_to_knot` сбрасывает visit-counts). Игрок остаётся в SMS-приложении и видит историю.

### Сцены и навигация (point-and-click)

| Тег | Пример | Что делает |
|---|---|---|
| `explore:SCENE_ID` | `# explore:apartment_hub` | Отдать управление в point-and-click. Ink ждёт. |
| `goto_scene:SCENE_ID` | `# goto_scene:kitchen` | Алиас `explore:`. |
| `return_to_scene` | `# return_to_scene` | Вернуться в **предыдущую** point-and-click сцену. Ставится в самом конце knot'а. |

> `# return_to_scene` всегда висит в конце knot'а, после всего текста. Игрок сначала читает текст, потом попадает в сцену.

### Карта (`# map:*`)

| Тег | Что делает |
|---|---|
| `map:hub:KNOT` | Открыть `map_v2` в hub-режиме. Пин с `route_knot=KNOT` прыгнет в этот ink-узел; при закрытии без выбора — fallback на тот же KNOT. |
| `map:allow:POI_ID` | Разрешить POI на phone_map (добавить в allow-set). |
| `map:allow:reset` | Сбросить allow-set (все POI снова разрешены, default). |
| `map:lock_to:POI_ID` | Clear + добавить (только этот POI разрешён, остальные показывают «не туда»). |

### Meta и Loop

| Тег | Что делает |
|---|---|
| `meta:add:loop_awareness:1` | Увеличивает meta-поле. |
| `meta:set:loop_awareness:2` | Задаёт meta-поле. |
| `chapter_finished` | Линейный конец — переход в следующую итерацию. |
| `loop:end:false:ID` | Ложная концовка (только итер 002+), restart текущей итерации. |
| `loop:end:true` | Истинная концовка (только итер 002+, требует `false_endings_count >= 2`). |

Важно:
`loop_awareness` и `false_endings_count` связаны, но не равны.

- `loop_awareness` — общее накопленное понимание петли.
- `false_endings_count` — количество уникальных ложных концовок,
  найденных в текущем Stage/цикле.
- True Ending гейтится через `false_endings_count >= 2`.

> **Итерация 001 — линейная:** все `# loop:end:*` на ней трактуются как `# chapter_finished` (страховка). Best practice — гейтить ложные концовки в ink:
>
> ```ink
> {iteration_number > 1:
>     # loop:end:false:my_ending
> - else:
>     # chapter_finished
> }
> ```
>
> Подробнее — `docs/reference/LOOP_SYSTEM.md` §4.

---

## 5. VAR vs `# set_flag:` — двойная система состояния

В Ink есть **две параллельные системы**:

| Хранилище | Где видно | Синтаксис |
|---|---|---|
| **Ink-переменные** | условия `{x:}` / выражения `{x}` внутри ink | `VAR x = false` + `~ x = true` |
| **game_state флаги** | `scenes.lua`, `quests.lua` (через `gs.get_flag(name)`) | `# set_flag:x=true` |

### Когда что использовать

| Хочешь… | Что нужно |
|---|---|
| Ветвить **внутри ink**: `{coffee_drunk: ...}` | VAR + `~` |
| Открыть/закрыть **hotspot** или скрыть объект на сцене | `# set_flag:` |
| Двигать квест | `# quest:*` (game_state, не VAR) |
| И то, и другое | **дублируй** оба синтаксиса |

```ink
~ coffee_drunk = true               // для ink-условий {coffee_drunk:}
# set_flag:coffee_drunk=true        // для scenes.lua и quests.lua
```

### Когда нужен только `# set_flag:`

Если флаг используется **только** в `scenes.lua` / `quests.lua` и в ink не фигурирует в `{…}` — VAR не нужен:

```ink
# set_flag:left_apartment=true   // достаточно
```

### Когда нужны оба

Если в ink есть `{coffee_drunk:` или `{not coffee_drunk:` — обязательно:
1. Объявить `VAR coffee_drunk = false` в `00_bootstrap.ink`
2. В knot'е делать `~ coffee_drunk = true`
3. И дублировать `# set_flag:coffee_drunk=true`

### Проверка: нужен ли VAR?

Посмотри в своём ink — есть ли такое:
```ink
{coffee_drunk:        ← условие? → нужен VAR
{not coffee_drunk: ← условие? → нужен VAR
{mug_taken and coffee_drunk: ← нужен VAR для обоих
```

Нет условий → VAR не нужен.

### Нейминг флагов / VAR

- предметы у игрока — НЕ через флаги, а через `gs.has_item("phone")` в scenes.lua и `# add_item:phone` в ink
- `X_seen` — сцена/реплика уже была (`bedroom_morning_seen`, `kitchen_intro_seen`)
- `sms_<contact>_read` / `sms_<contact>_replied` — авто-флаги (ставит движок)
- `need_X` — промежуточная цель активирована (`need_phone`)
- `X_drunk` / `X_done` / `X_active` — результат действия
- `_underscore_в_начале` — служебные, задаются движком

---

## 6. Lua → Ink: переменные от движка

Движок до старта истории прокидывает в Ink:

| VAR | Источник |
|---|---|
| `mc_gender` | `save_manager` / выбор игрока |
| `mc_name` | `save_manager` |
| `npc_name` | `save_manager` |
| `iteration_number` | `meta_state` |
| `iteration_label` | `meta_state` |
| `loop_awareness` | `meta_state` |
| `completed_iterations` | `meta_state` |
| `false_endings_count` | `meta_state` |

Эти переменные **не объявляй сам** в bootstrap — они уже есть. Просто используй: `{iteration_number > 1: ...}`, `{mc_name}`, и т.д.

---

## 7. Выборы

```ink
* [Проверить уведомления]
    ~ INSIGHT = INSIGHT + 1
    # speaker:none
    Открываю приложение. Три патча в очереди.
    -> metro_continue

* [Отложить]
    ~ SYNC = SYNC + 1
    # speaker:mc
    Потом. Сейчас не до этого.
    -> metro_continue
```

- `*` — одноразовый выбор (пропадает после клика). `+` — многоразовый.
- Текст в `[квадратных скобках]` — **только** на кнопке, как реплика не показывается.
- Внутри тела выбора: `~`, теги, реплики, `->`.
- Условный выбор: `* {SYNC >= 2 && INSIGHT >= 2} [<<Синхронизировать ритм>>]` — если условие `false`, пункт скрыт.

---

## 8. Условные блоки и гендерные форки

### Простой условный блок

```ink
{coffee_drunk:
    Кофеин ещё действует. Руки не дрожат.
}
{not coffee_drunk:
    Голова немного тяжёлая.
}
```

### Гендерные форки (короткая форма)

```ink
Проснул{mc_gender == "female":ась|ся}.
В отражении — {mc_gender == "female":женское|мужское} лицо.
Я не замети{mc_gender == "female":ла|л}.
```

- Внутри `{...:A|B}`: если условие истинно — `A`, иначе — `B`.
- Для пустой ветки оставь пусто: `замети{mc_gender == "female":ла|}`.

Имена подставляются автоматически: `{mc_name}`, `{npc_name}`.

---

## 9. Драм-флаги TRUST / INSIGHT / SYNC

Это три счётчика эмоциональной оси. Объявлены в `00_bootstrap.ink`.

```ink
~ TRUST = TRUST + 1                   // увеличить
{INSIGHT > 3: текст}                  // проверить в блоке
* {SYNC >= 2 && INSIGHT >= 2} [ветка] // условный выбор
```

Диапазон практически любой, но держи инкременты маленькими (±1, ±2). На конец главы — сумма 3–8 по каждой оси.

---

## 10. Как knot связан со сценой

Knot'ы вызываются из `scenes.lua` двумя способами:

### Способ A — `on_enter` (автоматически при входе в сцену)

В `scenes.lua`:
```lua
on_enter = {
    knot = "apartment_bedroom_intro",
    condition = function(gs)
        return not gs.get_flag("bedroom_morning_seen")
    end,
},
```

В ink:
```ink
=== apartment_bedroom_intro ===              ← имя должно совпадать
# set_flag:bedroom_morning_seen=true         ← флаг должен совпадать с condition
# return_to_scene
-> DONE
```

> **Главное правило `on_enter`:** knot обязан выставить флаг, который `condition` проверяет на `false`. Иначе — вечный цикл.

### Способ B — hotspot (по клику игрока)

В `scenes.lua`:
```lua
action = { type = "ink_knot", knot = "take_phone" }
```

В ink:
```ink
=== take_phone ===
# speaker:none
...текст...
# set_flag:coffee_drunk=true
# return_to_scene
-> DONE
```

После последнего клика игрок возвращается в ту же сцену; hotspot перерисуется (если у него `condition` зависит от флага).

### Паттерн «выход из сюжетной сцены в point-and-click»

```ink
=== wake_after_choice ===
# bg:bg_bedroom_03 # speaker:mc
...длинный монолог...
-> apartment_hub

=== apartment_hub ===
# bg:bg_apartment_bedroom_morning # explore:apartment_hub # speaker:mc
Коридор. Тихо.
-> DONE
```

Тег `# explore:apartment_hub` отдаёт управление `scene_controller` на сцене `apartment_hub`. Ink-сторона переходит в состояние «ждёт».

---

## 11. Карта и POI lock

### Открыть карту в hub-режиме

```ink
# map:hub:metro
-> DONE
```

`map_v2` откроется как hub. Если игрок выбирает пин с `route_knot`, ui_manager прыгнет в этот knot. Если карту закрыли без выбора — fallback на primary knot.

### Phone_map: разрешить только определённые POI

После SMS-ответа, когда сюжет требует определённого места:

```ink
* [«Давай в кафе.»]
    # sms:reply:mila:Давай в кафе.
    # map:lock_to:poi_cafe          ← на phone_map кликабелен только этот POI
    -> sms_npc_place_sent
```

После прибытия и закрытия квеста:

```ink
# quest:done:meet_npc
# map:allow:reset                   ← все POI снова доступны
# return_to_scene
```

POI ID берутся из `phone_map.gui_script` → `POI_SCENES`: `poi_home`, `poi_work`, `poi_cafe`, `poi_park`, `poi_shop`, `poi_bar`, `poi_view`, `poi_archive`.

При клике на запрещённый POI игрок видит «Сейчас не время. Мне туда не надо.»

---

## 12. Телефон — жёсткие правила

Телефон **НЕ является Ink-сценой**. Это Lua-оверлей поверх игры.

### ❌ Запрещено

- Писать phone-контент в knot'ах напрямую
- Делать `=== phone_*` как сцену
- Управлять UI телефона из ink

### ✅ Разрешено (только теги)

- `# sms:add:contact:текст` — входящее
- `# sms:reply:contact:текст` — исходящее ГГ
- `# note:add:title:body` — заметка
- `# mail:add:from:subject` / `# call:add:` / `# clue:add:` / `# camera:` / `# term:`
- `# quest:start/done/fail:id`
- `# phone:close` — закрыть телефон (только в специальном `phone_close` knot'е)
- `# phone:map` / `# phone:app:NAME` — открыть телефон на нужной вкладке

Все остальное — ошибка архитектуры.

### Loop-aware контент в телефоне

```ink
{iteration_number >= 2:
    # sms:add:anya:Ты тоже это помнишь?
    # clue:add:repeat_signal:Повторяющийся сигнал
}
```

Если тег может сработать повторно внутри одной итерации, защити его ink-флагом:
```ink
{not anya_repeat_sms_sent:
    # sms:add:anya:Ты тоже это помнишь?
    ~ anya_repeat_sms_sent = true
}
```

---

## 13. Чеклист перед коммитом

- [ ] Все knot'ы начинаются с `=== name ===` (имя `latin_snake_case`)
- [ ] Все ветки заканчиваются `-> name`, `-> DONE`, или `-> END`
- [ ] Каждому новому фону `bg:NAME` соответствует dedicated atlas в `main/images/backgrounds/` И запись в `ui_manager_v2.script` (`go.property` + `DEDICATED_BG_ATLAS_PROPS`)
- [ ] Все `sfx:NAME` существуют в `main/sounds/` (иначе silent fail)
- [ ] `{mc_gender == "female":ж|м}` проверен по всем репликам MC (нет просто `вернулся` без форки)
- [ ] Используются только поддерживаемые статусы квестов: `quest:start`, `quest:done`, `quest:fail`
- [ ] VAR'ы, на которые завязаны `{...}` в ink, объявлены в `00_bootstrap.ink`
- [ ] Флаги для `scenes.lua` / `quests.lua` дублируются `# set_flag:`
- [ ] Если `on_enter.condition` проверяет флаг — knot его ставит
- [ ] `# return_to_scene` стоит в конце knot'а, который вызван из hotspot или `on_enter`
- [ ] `tools/compile_ink.bat chapter_01` прошёл с `[OK]` без ошибок
- [ ] Smoke-тест: новый старт + Continue работают

---

## 14. Типичные ошибки — НЕ ДЕЛАЙ ТАК

### Ошибка 1: неправильный синтаксис тегов

| Неправильно | Правильно |
|---|---|
| `# setflag:bedroom_seen=true` | `# set_flag:bedroom_seen=true` |
| `# additem:phone` | `# add_item:phone` |
| `# queststart:make_coffee` | `# quest:start:make_coffee` |
| `# questdone:make_coffee` | `# quest:done:make_coffee` |
| `# quest:complete:make_coffee` | `# quest:done:make_coffee` |

### Ошибка 2: имя knot'а не совпадает с scenes.lua

```lua
-- scenes.lua говорит:
knot = "apartment_bedroom_intro"
```
```ink
-- а в ink написано:
=== bedroom_intro ===   ← НЕПРАВИЛЬНО
```

**Как проверить:** скопируй имя из scenes.lua и вставь в ink без изменений.

### Ошибка 3: on_enter без флага-заглушки → вечный цикл

```lua
-- scenes.lua:
condition = function(gs) return not gs.get_flag("seen") end
```
```ink
-- ink — НЕ ставит флаг:
=== my_intro ===
Текст.
# return_to_scene    ← цикл!
-> DONE
```

**Правильно:**
```ink
=== my_intro ===
Текст.
# set_flag:seen=true   ← ОБЯЗАТЕЛЬНО
# return_to_scene
-> DONE
```

### Ошибка 4: VAR не объявлен, но используется в условии

```ink
-- 00_bootstrap.ink — нет VAR coffee_drunk
-- 01_apartment.ink:
{coffee_drunk:  ← Unresolved variable: coffee_drunk
```

**Правильно:** добавить `VAR coffee_drunk = false` в `00_bootstrap.ink`.

### Ошибка 5: несуществующий id квеста

```ink
# quest:start:get_coffee   ← такого квеста нет в quests.lua
```

**Как проверить:** открой `main/scripts/quests.lua`, сверь id.

### Ошибка 6: только VAR без `# set_flag:`, или наоборот

```ink
~ coffee_drunk = true
// scenes.lua проверяет gs.get_flag("coffee_drunk") → false → hotspot не пропадёт
```

**Правильно:** оба синтаксиса вместе (см. §5).

---

## 15. Что не поддерживается

- `EXTERNAL` функции, `LIST` — игнорируются
- Stitches (`= substitch`) — можно, но как «адресуемые» точки используем только `=== knot`
- Теги на VAR-строках — игнорируются
- `# TODO`, `# XXX`, любые «заметки разработчика» в тегах — игнорируются (можно использовать как комментарии для себя)
- Tunnels (`-> tunnel ->`) — технически работают, но не используем
- `quest:complete` и любые статусы квеста кроме `start`/`done`/`fail`

---

## 16. Примеры готовых knot'ов

### Простой монолог (осмотр объекта)

```ink
=== look_bed_morning ===
# speaker:none
Постель скомкана. Сон был неровным.
# return_to_scene
-> DONE
```

### Монолог с получением предмета

```ink
=== take_mug ===
# speaker:none
Кружка в шкафчике. Берёшь её.
# add_item:mug
~ coffee_drunk = true
# set_flag:coffee_drunk=true
# return_to_scene
-> DONE
```

> Нужно `~ coffee_drunk = true` потому что в ink есть условие `{coffee_drunk:}`.
> Дублируем `# set_flag:coffee_drunk=true` для scenes.lua / quests.lua.

### `on_enter`-монолог (один раз при входе в сцену)

```ink
=== apartment_bedroom_intro ===
# bg:bg_apartment_bedroom_morning # speaker:none
Комната держит сон: смятая постель, слабый свет через жалюзи.
На тумбочке что-то лежит экраном вниз.
# set_flag:bedroom_morning_seen=true
# quest:start:find_phone
# return_to_scene
-> DONE
```

> Флаг `bedroom_morning_seen` выставляется до клика «Далее». Когда после клика сработает `return_to_scene`, `on_enter.condition` уже вернёт `false` — цикла не будет.

### Монолог с SMS, квестом и map lock

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

### Выбор с разветвлением и POI lock

```ink
=== sms_thread_mila ===
# speaker:none
Открываешь переписку. Мила написала:
«Есть планы на сегодня?»

* [«Давай в кафе.»]
    # sms:reply:mila:Давай в кафе.
    # set_flag:date_place_cafe=true
    # map:lock_to:poi_cafe
    ~ date_place_cafe = true
    ~ TRUST = TRUST + 1
    -> sms_sent

* [«Давай в парк.»]
    # sms:reply:mila:Давай в парк.
    # set_flag:date_place_park=true
    # map:lock_to:poi_park
    ~ date_place_park = true
    ~ TRUST = TRUST + 1
    -> sms_sent

= sms_sent
# speaker:none
Сообщение отправлено.
# quest:done:reply_mila
# return_to_scene
-> DONE
```

### Итерационно-зависимый текст

```ink
=== look_hall_mirror ===
# speaker:none
{iteration_number > 1:
Знакомое лицо. Слишком знакомое — будто уже видел его сегодня.
~ INSIGHT = INSIGHT + 1
- else:
Обычное отражение. Ничего странного.
}
# return_to_scene
-> DONE
```

### Knot с действиями инвентаря (`inv_*`)

Контракт поиска knot'а для предмета:
1. `inv_<scene_id>_<verb>_<item_id>`
2. `inv_<verb>_<item_id>`
3. `inv_<verb>_fallback`
4. `inv_fallback`

Verbs: `use`, `inspect`, `read`, `give`, `combine`.

Особые случаи:
- `phone + use/read` открывает phone_v2 напрямую;
- `give` работает только если текущая сцена в `scenes.lua` имеет поле `npc`;
- `combine` работает внутри инвентаря и ищет:
  `inv_combine_<low>_with_<high>` → `inv_combine_fallback` → `inv_fallback`.

```ink
=== inv_inspect_mug ===
# speaker:none
Кружка с трещиной на ручке. Каждый раз стоит на своём месте.
# return_to_scene
-> DONE
```

---

## Быстрая справка — одним взглядом

```
=== имя_из_scenes_lua ===
# bg:имя_фона # speaker:none          ← первой строкой
Текст для игрока.
~ ink_var = true                       ← если есть {ink_var:} условие
# set_flag:флаг_из_condition=true     ← ОБЯЗАТЕЛЬНО если on_enter
# quest:start:id_из_quests_lua        ← только существующие id
# quest:done:id_из_quests_lua
# add_item:id_предмета
# sms:add:контакт:текст
# return_to_scene                     ← последний тег
-> DONE                               ← последняя строка
```

**Если в ink есть `{флаг:` или `{not флаг:` → в `00_bootstrap.ink` нужен `VAR флаг = false`**

## 17. Структура Ink-файлов и нейминг knot'ов

## Файлы главы

`chapter_01.ink` остаётся root-файлом и содержит только `INCLUDE`.

Рекомендуемая сетка файлов:

```text
00_bootstrap.ink              — глобальные VAR и стартовый переход

01_apartment.ink              — воскресное домашнее утро / onboarding
02_sunday_date.ink            — воскресная встреча и возвращение домой

20_monday_home.ink            — понедельник: утро дома и сборы на работу
21_monday_commute.ink         — понедельник: путь до офиса без карты и без метро
22_monday_office.ink — понедельник: офисный рабочий блок и playable office task

30_tuesday_home.ink           — вторник: дом / последствия, когда дойдём
31_tuesday_investigation.ink  — вторник: расследование / маршруты, когда дойдём
32_tuesday_rooftop.ink        — вторник / крыша / концовки, когда будет миграция

91_inventory_actions.ink      — универсальные действия предметов
```


## Нейминг knot'ов

Префикс показывает день и слой сцены:

```text
sunday_*        — воскресная встреча / воскресные хабы
mon_home_*      — понедельник, квартира
mon_commute_*   — понедельник, путь до офиса
mon_office_*    — понедельник, офис
mon_evening_*   — понедельник, вечер, если появится

tue_home_*      — вторник, квартира
tue_route_*     — вторник, маршруты / город
tue_rooftop_*   — вторник, крыша / концовки

inv_*           — действия предметов инвентаря
sms_thread_*    — side-knot переписки телефона
```

`monday_morning_start` можно оставить как публичную точку входа из воскресного сна. Всё, что ниже неё, должно идти через `mon_*`.

## Правило scene_id

Если у локации разные дни/время суток, есть два допустимых паттерна:

1. Отдельные scene_id — когда меняется логика, набор hotspot'ов или флаги маршрута.
   Пример: monday_apartment_* и tuesday_apartment_*.

2. Universal hub — когда локация та же, hotspot'ы в основном общие, а меняется только фон/время суток.
   Пример: apartment_hub / apartment_bedroom / apartment_kitchen и work_hub / office_workspace / office_meeting_room.

Для universal hub использовать:
`bg = function(gs) return "bg_name" end`

Hotspot'ы по состояниям гейтить через `visible_when` или `condition`.

## Карта и маршрут на работу

Путь на работу не должен использовать `# phone:map`, если это линейная рабочая дорога.

Карта нужна для свободного выбора POI-хабов. Понедельничный путь до офиса — scripted commute:

```text
mon_home_leave_apartment -> mon_commute_entry -> mon_commute_work_district -> office_entry
```

Метро не используется, пока на карте нет отдельной логики для метро и пока география мира говорит, что офис ближе воскресных хабов.

## Playable task в первой итерации

Итерация 001 линейна по концовке, но не обязана быть пассивной.

Разрешены:
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

Пример: понедельничный office task.
Игрок проходит турникет, читает задачу, собирает папку, передаёт кейс,
но системное решение в первой итерации всё равно применяется автоматически.