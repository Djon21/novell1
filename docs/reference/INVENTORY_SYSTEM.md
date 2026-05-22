# Inventory System

Актуально на `2026-05`. Объединил `INVENTORY_SYSTEM.md` (архитектура) и
`INVENTORY_SYSTEM_guide.md` (рецепты добавления) в один документ.

Инвентарь открывается кнопкой BAG в HUD (правый верхний угол). Игрок видит
сетку до 12 слотов, выбирает предмет и нажимает глагол:
**ОСМОТРЕТЬ / ИСПОЛЬЗОВАТЬ / СОЕДИНИТЬ / ПРОЧИТАТЬ / ОТДАТЬ**.
Глагол → ink-монолог → возврат в сцену.

---

## Содержание

1. [Архитектура одним взглядом](#1-архитектура-одним-взглядом)
2. [Source of truth](#2-source-of-truth)
3. [Ограничения MVP](#3-ограничения-mvp)
4. [Verbs — 5 типов с flow и ink-цепочками](#4-verbs--5-типов-с-flow-и-ink-цепочками)
5. [Контекст в Ink](#5-контекст-в-ink)
6. [Особый случай: телефон](#6-особый-случай-телефон)
7. [Как добавить новый предмет](#7-как-добавить-новый-предмет)
8. [Поля предмета в `items_catalog.lua`](#8-поля-предмета-в-items_cataloglua)
9. [Material Icons](#9-material-icons)
10. [Управление инвентарём из Lua и Ink](#10-управление-инвентарём-из-lua-и-ink)
11. [Чеклист добавления нового предмета](#11-чеклист-добавления-нового-предмета)

---

## 1. Архитектура одним взглядом

```
items_catalog.lua    ← справочник всех предметов (имя, иконка, глаголы, описание)
game_state.lua       ← инвентарь игрока [массив item_id]
inventory_v2.gui_script  ← рендер сетки + клики по слотам и verbs
inventory_flow.lua        ← resolve_inventory_knot → запускает ink-монолог
ink-скрипты              ← сюжетная реакция на глагол
ui_state.lua             ← armed-state для USE-on-target
```

---

## 2. Source of truth

- **runtime-state предметов** хранится в `game_state.lua`
- **UI-метаданные** живут в `items_catalog.lua`
- **`inventory_v2`** только рендерит состояние и шлёт `inventory_verb` наружу
- **`inventory_flow.lua`** решает, что делать с verb (включая armed-режим для USE)
- **`ui_manager_v2.script`** остаётся мостом между Defold-сообщениями и flow-модулями

`mug` и `phone` — единственный источник правды по этим предметам: hotspots проверяют через `gs.has_item("mug")`/`gs.has_item("phone")`, ink добавляет через `# add_item:mug`/`# add_item:phone`. Старых флагов `has_mug`/`has_phone` больше нет (после рефакторинга 2026-05).

---

## 3. Ограничения MVP

- максимум `12` уникальных предметов (`gs.MAX_INVENTORY_SLOTS`)
- активные verbs: `use`, `inspect`, `read`, `give`, `combine`
- если `item_id` отсутствует в `items_catalog.lua`, инвентарь покажет fallback-карточку с `?` и доступным только `inspect`

---

## 4. Verbs — 5 типов с flow и ink-цепочками

### `inspect` / `read` — простой монолог

Закрывают инвентарь и сразу прыгают в ink-knot:

```
inv_<scene>_<verb>_<item>   →   inv_<verb>_<item>   →   inv_<verb>_fallback   →   inv_fallback
```

Пример:

```ink
=== inv_inspect_flashlight ===
# speaker:mc
Старый металлический фонарик. Батарейки нужны.
# return_to_scene
-> DONE
```

### `use` — armed-режим (use-on-target)

1. Игрок жмёт `ИСПОЛЬЗОВАТЬ`
2. Инвентарь закрывается, в HUD появляется баннер «Использовать <предмет> — выбери цель» + кнопка `ОТМЕНА`. `ui_state.armed_inventory = { item_id, verb = "use" }`
3. Следующий клик по hotspot'у запускает knot:
   - `inv_<scene>_use_<item>_on_<hotspot_id>`
   - `inv_use_<item>_on_<hotspot_id>`
   - `inv_use_<item>_on_fallback`
   - `inv_use_on_<hotspot_id>` (любой предмет на этом хотспоте)
   - `inv_use_fallback`
   - `inv_fallback`
4. Отмена armed:
   - кнопка `ОТМЕНА` на баннере
   - клик мимо hotspot'ов
   - повторное открытие инвентаря
   - старт новой игры/итерации

В ink-knot: `inventory_target_id` = hotspot_id, `inventory_target_kind` = `"hotspot"`.

### `combine` — соединить два предмета

Двухкликовая операция **внутри инвентаря**, без выхода в сцену:

1. Выделить item A → жать `СОЕДИНИТЬ`
2. Details panel переходит в режим «Соединить с …»; кнопка `СОЕДИНИТЬ` превращается в `ОТМЕНА`
3. Клик на другой item B → запускает knot:
   - **Имена knot'ов канонизированы лексикографической сортировкой** — для пары `(matchbox, lighter)` всегда ищется `inv_combine_lighter_with_matchbox` (потому что `l < m`). Автору один файл, не оба порядка
   - Цепочка: `inv_combine_<low>_with_<high>` → `inv_combine_fallback` → `inv_fallback`
4. Отмена: повторный клик `ОТМЕНА`, клик на тот же A, закрытие инвентаря

В ink-knot: `inventory_item_id` = A (первый), `inventory_target_id` = B (второй), `inventory_target_kind` = `"item"`.

Пример:

```ink
=== inv_combine_lighter_with_matchbox ===
# speaker:mc
Зажигалка прикуривает от спички. Удобно.
# remove_item:matchbox
# add_item:lit_match
# return_to_scene
-> DONE
```

### `give` — передать NPC текущей сцены

1. В `scenes.lua` сцена объявляет NPC: `npc = "npc"` (или конкретное имя)
2. Игрок жмёт `ОТДАТЬ`
3. Инвентарь закрывается, ui_manager берёт `scene.npc` и стреляет:
   - `inv_<scene>_give_<item>_on_<npc>`
   - `inv_give_<item>_on_<npc>`
   - `inv_give_<item>_on_fallback`
   - `inv_give_on_<npc>`
   - `inv_give_fallback` → `inv_fallback`
4. Если у сцены НЕТ поля `npc` — сразу `inv_give_<item>` → `inv_give_fallback`

В ink-knot: `inventory_target_id` = npc_id, `inventory_target_kind` = `"npc"`.

> **Convention:** для воскресных сцен (cafe_hub/park_hub) target = `"npc"` (не конкретное имя), потому что NPC меняется по гендеру MC. Внутри knot можно делать `{mc_gender == "female": Артём - else: Мила}`.

---

## 5. Контекст в Ink

Перед прыжком в side-knot `dialogue_manager_ink` выставляет:

| VAR | Значение |
|---|---|
| `inventory_item_id` | id первого/основного предмета |
| `inventory_item_name` | человекочитаемое имя из catalog |
| `inventory_item_verb` | `"use"` / `"inspect"` / `"read"` / `"give"` / `"combine"` |
| `inventory_scene_id` | id текущей сцены |
| `inventory_target_id` | hotspot_id / npc_id / item_id (combine), либо `""` |
| `inventory_target_kind` | `"hotspot"` / `"npc"` / `"item"` / `""` |

Использовать в fallback-реплике или scene-specific knot:

```ink
=== inv_use_on_fallback ===
# speaker:mc
{inventory_item_name != "":
    {inventory_item_name} здесь не пригодится.
- else:
    Не пригодится.
}
# return_to_scene
-> DONE
```

---

## 6. Особый случай: телефон

`phone` не ведёт себя как обычный предмет. На `use` или `read` он **не** прыгает в ink, а открывает `phone_v2` напрямую. Так задумано — телефон data-driven, статичный ink-экран ему не нужен.

Писать `inv_use_phone` или `inv_read_phone` **не нужно** — это обрабатывается автоматически в `inventory_flow.lua`.

Если хочешь короткий текст — используй `inv_inspect_phone`.

---

## 7. Как добавить новый предмет

### Шаг 1. Регистрация в `items_catalog.lua`

```lua
M.items = {
    -- ... существующие ...

    flashlight = {
        name        = "Фонарик",
        type        = "ключ",
        source      = "ящик стола",
        iter        = "#017",
        clue        = "нет",
        desc        = "Разряженный. Батарейки где-то рядом.",
        description = "Старый фонарик. Не работает без батареек.",
        verbs       = { "use", "inspect" },
        icon        = ICON_FLASH,
        qty         = 1,
    },
}
```

### Шаг 2. Иконка

См. §9 — добавь `ICON_FLASH = string.char(0xEE, 0x9E, 0x92)` в начало файла, используй в предмете.

### Шаг 3. Выдать предмет в ink

В любом knot:

```ink
=== найти_фонарик ===
# speaker:mc
Я открыла ящик — там лежал старый фонарик.
# add_item:flashlight
Взяла его.
# return_to_scene
-> DONE
```

Удаление: `# remove_item:flashlight`.

### Шаг 4. Написать ink-реакции

Минимум — `inv_inspect_<id>` (осмотр всегда ожидается):

```ink
=== inv_inspect_flashlight ===
# speaker:mc
Старый металлический фонарик. Батарейки нужны.
# return_to_scene
-> DONE
```

Контекстные действия — см. §4 (например, `inv_use_flashlight_on_basement_door` для подвала).

---

## 8. Поля предмета в `items_catalog.lua`

| Поле | Тип | Обяз. | Описание |
|---|---|---|---|
| `name` | string | ✅ | Отображаемое название |
| `type` | string | ✅ | `"расход."` / `"ключ"` / `"улика"` / `"редкий"` |
| `source` | string | ✅ | Откуда взят (показывается в деталях) |
| `iter` | string | ✅ | Итерация. Ставь `"#017"` — заменится автоматически |
| `clue` | string | ✅ | `"да"` или `"нет"` (улика = розовая подсветка) |
| `desc` | string | ✅ | Короткое описание (в деталях) |
| `description` | string | ❌ | Длинное описание (legacy-поле, дубль `desc`) |
| `verbs` | table | ✅ | Список verbs: `"use"`, `"inspect"`, `"read"`, `"combine"`, `"give"` |
| `icon` | string | ✅ | Material Icons UTF-8 символ |
| `qty` | number | ✅ | Количество. `1` → badge не показывается |

### Типы и цвета

| `type` | цвет иконки | использовать для |
|---|---|---|
| `"расход."` | бумажный (бежевый) | потребляемое |
| `"ключ"` | янтарный | ключевые сюжетные |
| `"улика"` | розовый | улики (то же если `clue = "да"`) |
| `"редкий"` | фиолетовый | редкие/особые |

---

## 9. Material Icons

Иконки берутся из шрифта Material Icons (те же что на хотспотах). В начале `items_catalog.lua` уже определены готовые константы:

```lua
local ICON_MUG   = string.char(0xEE, 0x95, 0x81)  -- кружка (coffee)
local ICON_PHONE = string.char(0xEE, 0xA4, 0x93)  -- смартфон
local ICON_KEY   = string.char(0xEE, 0x9C, 0xBC)  -- ключ
local ICON_CUP   = string.char(0xEE, 0xBF, 0xAF)  -- стакан
local ICON_NOTE  = string.char(0xEE, 0x81, 0xAF)  -- записка
local ICON_CARD  = string.char(0xEE, 0xA1, 0xB0)  -- карточка
local ICON_USB   = string.char(0xEE, 0x87, 0xA0)  -- USB
local ICON_CIG   = string.char(0xEE, 0x9F, 0xB5)  -- сигарета
local ICON_CASH  = string.char(0xEE, 0xBD, 0xA3)  -- деньги
```

### Как добавить новую иконку

1. Найди на [fonts.google.com/icons](https://fonts.google.com/icons) — **Material Icons** (не Symbols)
2. Возьми Unicode codepoint (например `U+E792` для `flashlight`)
3. Конвертируй в UTF-8 трёхбайтную последовательность для диапазона `U+E000..U+EFFF`:
   - byte0 = `0xEE`
   - byte1 = `((codepoint >> 6) & 0x3F) | 0x80`
   - byte2 = `(codepoint & 0x3F) | 0x80`
   - Для `U+E792`: `0xEE, 0x9E, 0x92` → `string.char(0xEE, 0x9E, 0x92)`
4. Добавь константу в начало файла, используй в предмете

---

## 10. Управление инвентарём из Lua и Ink

### Из Lua

```lua
local gs = require "main.scripts.game_state"

gs.add_item("flashlight")
gs.remove_item("flashlight")
local has = gs.has_item("flashlight")
local inv = gs.get_inventory()  -- массив item_id
```

После изменения вне ink можно дёрнуть рендер:

```lua
msg.post("#ui_manager_v2", "refresh_inventory")
```

При превышении лимита 12 слотов `add_item` возвращает `false` и логирует warning.

### Из Ink

| Тег | Что делает |
|---|---|
| `# add_item:<id>` | Добавить предмет |
| `# remove_item:<id>` | Убрать предмет |

Проверка наличия в условии scenes.lua:

```lua
condition = function(gs)
    return gs.has_item("key")
end,
```

---

## 11. Чеклист добавления нового предмета

- [ ] Запись в `M.items` в `items_catalog.lua`
- [ ] Иконка (готовая из списка или новая константа `ICON_*`)
- [ ] Минимум один ink-knot: `inv_inspect_<id>` (осмотр ожидается всегда)
- [ ] Контекстные knots для нужных verbs из массива `verbs` предмета
- [ ] Выдача через `# add_item:<id>` где-то в ink
- [ ] Перекомпиляция: `tools/compile_ink.bat chapter_01`
- [ ] Smoke-тест:
  - открыть инвентарь → предмет на месте
  - детали заполнены, нужные verbs активны
  - каждый verb запускает свой knot
  - после `# return_to_scene` игрок возвращается в exploration

---

## Связанные документы

- `docs/guides/HOW_TO_WRITE_INK.md` — теги ink, в т.ч. `# add_item:`/`# remove_item:`
- `docs/guides/HOW_TO_ADD_SCENES.md` — `npc` поле сцены для `give`, hotspot'ы для `use`
