# Система инвентаря — добавление предметов и взаимодействия

Инвентарь открывается кнопкой BAG в HUD (правый верхний угол).
Игрок видит сетку до 12 слотов, выбирает предмет и нажимает глагол — ОСМОТРЕТЬ / ИСПОЛЬЗОВАТЬ / ПРОЧИТАТЬ.
Глагол → ink-монолог → возврат в сцену.

---

## Архитектура одним взглядом

```
items_catalog.lua    ← справочник всех предметов (имя, иконка, глаголы, описание)
game_state.lua       ← инвентарь игрока [массив item_id]
inventory_v2.gui_script  ← рендер сетки + клики
ui_manager_v2.script     ← resolve_inventory_knot → запускает ink-монолог
ink-скрипты          ← реакция на глагол
```

---

## Быстрый старт: добавить новый предмет

### Шаг 1 — Регистрация в `items_catalog.lua`

Открой `main/scripts/items_catalog.lua` и добавь запись в таблицу `M.items`:

```lua
M.items = {
    -- ... существующие предметы ...

    flashlight = {
        name   = "Фонарик",
        type   = "ключ",          -- тип предмета (см. ниже)
        source = "ящик стола",    -- откуда взят (показывается в деталях)
        iter   = "#017",          -- итерация; "#017" = текущая (подставляется автоматически)
        clue   = "нет",           -- "да" = улика (подсвечивается розовым)
        desc   = "Разряженный. Батарейки где-то рядом.",   -- короткое описание
        description = "Старый фонарик. Не работает без батареек.",  -- длинное (legacy)
        verbs  = { "use", "inspect" },   -- глаголы для этого предмета
        icon   = ICON_FLASH,      -- Material Icon (см. раздел Иконки)
        qty    = 1,               -- количество в badge; если 1 — badge не показывается
    },
}
```

**Типы предметов** (`type`) влияют на цвет иконки в слоте:

| type | цвет | когда использовать |
|------|------|--------------------|
| `"расход."` | бумажный (бежевый) | потребляемые предметы |
| `"ключ"` | янтарный | ключевые сюжетные предметы |
| `"улика"` | розовый/горячий | улики; то же если `clue = "да"` |
| `"редкий"` | фиолетовый | редкие/особые |

### Шаг 2 — Иконка

Иконки берутся из шрифта Material Icons (те же, что на хотспотах).
В начале `items_catalog.lua` уже определены константы через `string.char()`:

```lua
-- Уже есть:
local ICON_MUG   = string.char(0xEE, 0x95, 0x81)  -- кружка (coffee)
local ICON_PHONE = string.char(0xEE, 0xA4, 0x93)  -- смартфон
local ICON_KEY   = string.char(0xEE, 0x9C, 0xBC)  -- ключ (vpn_key)
local ICON_CUP   = string.char(0xEE, 0xBF, 0xAF)  -- стакан
local ICON_NOTE  = string.char(0xEE, 0x81, 0xAF)  -- записка
local ICON_CARD  = string.char(0xEE, 0xA1, 0xB0)  -- карточка (credit_card)
local ICON_USB   = string.char(0xEE, 0x87, 0xA0)  -- USB
local ICON_CIG   = string.char(0xEE, 0x9F, 0xB5)  -- сигарета (smoking_rooms)
local ICON_CASH  = string.char(0xEE, 0xBD, 0xA3)  -- деньги (payments)
```

Чтобы добавить новую иконку:
1. Найди нужную на [fonts.google.com/icons](https://fonts.google.com/icons) (убедись, что это **Material Icons**, не Symbols)
2. Запиши Unicode codepoint, например `U+E792` (flashlight)
3. Переведи в UTF-8 трёхбайтную последовательность:
   - `U+E000..U+EFFF` → байты: `0xEE`, `(codepoint >> 6 & 0x3F) | 0x80`, `(codepoint & 0x3F) | 0x80`
   - Для `U+E792`: `0xEE`, `(0xE792 >> 6 & 0x3F | 0x80)` = `0x9E`, `(0x12 | 0x80)` = `0x92`
   - → `string.char(0xEE, 0x9E, 0x92)`
4. Добавь константу в начало файла и используй в предмете

> **Подсказка**: проще всего открыть проект Material Icons в браузере, найти иконку,
> скопировать hex codepoint из URL и пересчитать по формуле.

### Шаг 3 — Выдать предмет игроку через ink

В любом ink-монологе добавь тег:

```ink
=== найти_фонарик ===
# speaker:mila
Я открыла ящик — там лежал старый фонарик.
# add_item:flashlight
Взяла его. Батарей нет, но вдруг пригодится.
# return_to_scene
->DONE
```

Тег `# add_item:flashlight` — scene_controller подхватывает его и вызывает `gs.add_item("flashlight")`.
После этого предмет сразу появляется в инвентаре.

Для удаления:
```ink
# remove_item:flashlight
```

### Шаг 4 — Написать ink-реакции на глаголы

Когда игрок нажимает глагол в инвентаре, система ищет ink-knot по цепочке приоритетов:

```
1. inv_{scene_id}_{verb}_{item_id}   ← только в этой сцене
2. inv_{verb}_{item_id}              ← везде (универсальный)
3. inv_{verb}_fallback               ← если нет ничего для этого глагола
4. inv_fallback                      ← последний резерв
```

Пример для фонарика (универсальный ответ):

```ink
=== inv_inspect_flashlight ===
# speaker:mila
Старый металлический фонарик. Батарейки нужны.
# return_to_scene
->DONE

=== inv_use_flashlight ===
# speaker:mila
Нажимаю кнопку — ничего. Нужны батарейки.
# return_to_scene
->DONE
```

Пример реакции только в конкретной сцене (подвал):

```ink
=== inv_cellar_use_flashlight ===
# speaker:mila
Чиркаю кнопкой — вспыхивает тусклый луч. Батарейки нашлись сами.
# set_flag:flashlight_works=true
# return_to_scene
->DONE
```

> **Важно**: в конце каждого ink-блока для инвентаря ставь `# return_to_scene`, иначе игрок застрянет в dialogue-режиме.

---

## Справочник: поля предмета в `items_catalog.lua`

| Поле | Тип | Обязательно | Описание |
|------|-----|-------------|----------|
| `name` | string | ✅ | Отображаемое название (напр. `"Фонарик"`) |
| `type` | string | ✅ | Тип: `"расход."`, `"ключ"`, `"улика"`, `"редкий"` |
| `source` | string | ✅ | Откуда взят (показывается в панели деталей) |
| `iter` | string | ✅ | Итерация. Ставь `"#017"` — заменится автоматически |
| `clue` | string | ✅ | `"да"` или `"нет"` (улика = розовая подсветка) |
| `desc` | string | ✅ | Короткое описание (показывается в деталях) |
| `description` | string | ❌ | Длинное описание (legacy-поле, дубль `desc`) |
| `verbs` | table | ✅ | Список глаголов: `"use"`, `"inspect"`, `"read"`, `"combine"`, `"give"` |
| `icon` | string | ✅ | Material Icons UTF-8 символ |
| `qty` | number | ✅ | Количество. `1` → badge не показывается |

---

## Глаголы (verbs)

### Активные в MVP

| Глагол | Кнопка | Ink-паттерн |
|--------|--------|-------------|
| `inspect` | ОСМОТРЕТЬ | `inv_inspect_{item_id}` |
| `use` | ИСПОЛЬЗОВАТЬ | `inv_use_{item_id}` |
| `read` | ПРОЧИТАТЬ | `inv_read_{item_id}` |

### Отключены в MVP (для будущего)

| Глагол | Кнопка |
|--------|--------|
| `combine` | СОЕДИНИТЬ |
| `give` | ОТДАТЬ |

Кнопка показывается только если:
1. Глагол есть в массиве `verbs` предмета
2. Глагол есть в `ACTIVE_VERBS` (сейчас: use, inspect, read)

Кнопки без этих условий отображаются тусклыми (недоступны для клика).

---

## Управление инвентарём из скриптов

Используй `game_state` напрямую (в Lua-скриптах, не в ink):

```lua
local gs = require "main.scripts.game_state"

gs.add_item("flashlight")           -- добавить предмет
gs.remove_item("flashlight")        -- убрать предмет
local has = gs.has_item("flashlight")  -- проверить наличие (true/false)
local inv = gs.get_inventory()      -- массив всех item_id: {"key", "flashlight", ...}
```

После добавления/удаления предмета вне ink нужно вручную обновить рендер инвентаря:

```lua
msg.post("#ui_manager_v2", "refresh_inventory")
```

Лимит: **12 слотов** (`gs.MAX_INVENTORY_SLOTS`). При превышении `add_item` не добавляет предмет (проверь лог).

---

## Управление инвентарём из ink

| Тег | Что делает |
|-----|-----------|
| `# add_item:key` | Добавить предмет `key` |
| `# remove_item:mug` | Убрать предмет `mug` |

Проверка наличия предмета в условии хотспота или `on_enter`:

```lua
condition = function(gs)
    return gs.has_item("key")
end,
```

---

## Специальный предмет: телефон (`phone`)

У предмета `phone` зашита особая логика в `ui_manager_v2`:
если игрок нажимает **ИСПОЛЬЗОВАТЬ** или **ПРОЧИТАТЬ** на телефоне — инвентарь закрывается
и сразу открывается экран телефона.

Писать ink-knot для `inv_use_phone` **не нужно** — это обрабатывается автоматически.

---

## Предмет не найден в каталоге

Если `game_state` содержит id, которого нет в `items_catalog.lua`, система создаёт
фиктивный предмет с предупреждением:

```
Добавьте item_id 'flashlight' в main/scripts/items_catalog.lua.
```

Такой предмет отображается в слоте с иконкой `?` и только глаголом `inspect`.

---

## Пример: добавить батарейки к фонарику

### `items_catalog.lua`

```lua
battery = {
    name   = "Батарейки",
    type   = "расход.",
    source = "магазин",
    iter   = "#017",
    clue   = "нет",
    desc   = "АА, две штуки. Подходят к фонарику.",
    description = "Две батарейки типа АА.",
    verbs  = { "use", "inspect" },
    icon   = ICON_USB,   -- временно, пока нет icon_battery
    qty    = 2,
},
```

### ink-скрипт

```ink
=== inv_use_battery ===
# speaker:mila
Куда вставить?

* [В фонарик]
    -> inv_use_battery_in_flashlight
* [Просто убрать]
    Подержу пока.
    # return_to_scene
    ->DONE

=== inv_use_battery_in_flashlight ===
~ has_flashlight = has_item("flashlight")
{has_flashlight:
    # remove_item:battery
    # set_flag:flashlight_works=true
    Вставила. Фонарик вспыхнул.
|
    Некуда.
}
# return_to_scene
->DONE
```

---

## Чеклист: добавить новый предмет

- [ ] Добавить запись в `M.items` в `items_catalog.lua`
- [ ] Добавить иконку (константа `ICON_*` + `string.char(...)`)
- [ ] Написать ink-knots для каждого глагола из `verbs`
  - [ ] Минимум: `inv_inspect_{id}` (осмотр всегда ожидается)
  - [ ] При необходимости: `inv_use_{id}`, `inv_read_{id}`
- [ ] Добавить выдачу через `# add_item:{id}` в нужном ink-монологе
- [ ] Проверить: предмет появляется в инвентаре → клик по нему → детали заполнены → глаголы активны → монолог запускается → `# return_to_scene` возвращает в хаб
