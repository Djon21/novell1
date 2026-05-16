# Hotspots: данные, стили, иконки, F1-редактор

Один документ про всё, что связано с хотспотами:
1. Структура данных хотспота
2. Recipes / готовые стили в `_shared.lua`
3. Per-hotspot override стиля / иконки / action
4. Material Icons и таблица `ICONS`
5. F1-редактор: позиция, размер, стиль
6. PNG-круги/кольца и продвинутые цветовые поля
7. Чек-лист отладки

---

## 1. Структура данных хотспота

Хотспоты живут в `main/data/scenes/<location>.lua`. Каждая сцена — таблица с `bg`, `label`, опциональным `on_enter` и массивом `hotspots`. Один хотспот:

```lua
{
    id = "park_bench",
    rect = { x = 420, y = 140, w = 120, h = 120 },   -- 1280×720, origin bottom-left
    label = "Скамейка",
    icon = "left_click",
    hotspot_style = STYLE_INSPECT,
    action = { type = "ink_knot", knot = "park_bench_interact" },
    visible_when = function(gs) return gs.get_flag("met_npc_sunday") end,
    condition    = function(gs) return not gs.get_flag("park_bench_used") end,
}
```

| Поле | Что делает |
|---|---|
| `id` | Стабильное имя внутри сцены. Используется в save-state, inventory armed-state, F1-редакторе. |
| `rect` | Кликабельная область. **Game coords 1280×720, origin bottom-left** (как в Defold). |
| `label` | Подпись под кружком. Короткая, 1–2 слова. |
| `icon` | Ключ из `ICONS` (см. §4). `icon = ""` = кружок без иконки. |
| `hotspot_style` | Стиль (цвет ring/circle/icon). Берётся из `_shared.lua` (см. §2). |
| `action` | Что произойдёт по клику (см. ниже). |
| `visible_when(gs)` | Если `false` — хотспот полностью невидим. |
| `condition(gs)` | Если `false` — хотспот виден, но locked (тусклый, не кликается). |
| `icon_offset_x` / `icon_offset_y` | Точечный сдвиг glyph'а внутри кружка. По умолчанию `-4 / 0`. |

### Action types

| `action.type` | Поля | Что делает |
|---|---|---|
| `ink_knot` | `knot = "<name>"` | Прыжок в ink-knot. Возврат через `# return_to_scene`. |
| `goto_scene` | `scene = "<scene_id>"` | Переход в другую exploration-сцену. |
| `set_flag` | `flag = "<name>", value = ...` | Поставить флаг, остаться в сцене. |
| `add_item` | `item = "<id>"` | Дать предмет, остаться в сцене. |
| `remove_item` | `item = "<id>"` | Убрать предмет, остаться в сцене. |

Новый `action.type` — **это код**, не сценарная правка. См. `dm_commands.lua` и `scene_controller.lua`.

### Визуальные слои

```text
hotspot_box        — невидимый клик-rect (в редакторе — полупрозрачный)
hotspot_label      — текстовая подпись под кружком
hotspot_ring       — PNG-кольцо
hotspot_circle     — PNG-круг (подложка)
hotspot_icon       — Material Icons glyph
```

В `hotspots_v2.gui` есть 6 слотов (`hotspot_1..6`). `scene_controller` берёт только видимые хотспоты и распределяет по слотам по порядку.

---

## 2. Recipes — готовые билдеры в `_shared.lua`

Чтобы не писать `icon` + `hotspot_style` + `action.type` на каждом хотспоте, используй рецепты из `main/data/scenes/_shared.lua`. Все принимают `opts` таблицу и возвращают полную hotspot-таблицу с правильными дефолтами.

```lua
local s = require "main.data.scenes._shared"

return {
    cafe_hub = {
        bg = "bg_cafe_morning",
        label = "Кафе",
        hotspots = {
            s.use{
                id = "cafe_bar",
                rect = { x = 360, y = 205, w = 380, h = 280 },
                label = "Стойка",
                icon = "coffee",
                knot = "cafe_bar_interact",
            },
            s.leave{
                id = "leave_cafe",
                rect = { x = 0, y = 0, w = 170, h = 220 },
                knot = "leave_cafe",
            },
        },
    },
}
```

### Доступные рецепты

| Рецепт | Стиль | Action | Дефолт `icon` | Когда юзать |
|---|---|---|---|---|
| `s.nav_scene{...scene=...}` | `STYLE_NAV` | `goto_scene` | твой | переход в sub-сцену внутри хаба |
| `s.nav_ink{...knot=...}` | `STYLE_NAV` | `ink_knot` | твой | навигация с ink-обвязкой |
| `s.inspect{...knot=...}` | `STYLE_INSPECT` | `ink_knot` | `"left_click"` | осмотреть / прочитать |
| `s.pickup{...knot=...}` | `STYLE_PICKUP` | `ink_knot` | `"left_click"` | взять в инвентарь |
| `s.use{...knot=...}` | `STYLE_USE` | `ink_knot` | `"left_click"` | совершить действие с объектом |
| `s.story{...knot=...}` | `STYLE_STORY` | `ink_knot` | `"left_click"` | сюжетный gate, важный момент |
| `s.item_target{...knot=...}` | `STYLE_ITEM_TARGET` | `ink_knot` | `"left_click"` | цель для применения предмета |
| `s.leave{...knot=...}` | `STYLE_NAV` | `ink_knot` | `"left"` + label `"Выйти"` | выход с локации |

Все рецепты автоматически добавляют `icon_offset_x = -4` (универсальная компенсация Material Icons по X). Можно переопределить через `opts.icon_offset_x`.

### Стили: семантика

| Стиль | Цвет ring | Семантика |
|---|---|---|
| `STYLE_NAV` | cyan | переход (внутри хаба / выход) |
| `STYLE_INSPECT` | violet | осмотреть / прочитать |
| `STYLE_PICKUP` | magenta-pink | взять в инвентарь |
| `STYLE_USE` | amber | действие с объектом |
| `STYLE_ITEM_TARGET` | green | цель для armed-предмета |
| `STYLE_STORY` | hot pink | сюжетный момент / обязательное действие |

Точные RGB/alpha — в `_shared.lua` блок `M.STYLE_*`.

---

## 3. Override per-hotspot

Любое поле рецепта можно перебить через `opts`:

| Override | Эффект |
|---|---|
| `hotspot_style = s.STYLE_X` | Поменять стиль конкретного хотспота, не меняя рецепт |
| `action = {...}` | Поменять полностью action (например `set_flag` вместо `ink_knot`) |
| `icon = "name"` | Поменять glyph |
| `icon_offset_x` / `icon_offset_y` | Точечно подвинуть иконку |

```lua
-- inspect-хотспот, но кружок в стиле USE (визуальный акцент):
s.inspect{
    id = "weird_one",
    rect = {...},
    label = "...",
    knot = "...",
    hotspot_style = s.STYLE_USE,
},

-- inspect-хотспот, но action — сразу set_flag, без захода в ink:
s.inspect{
    id = "park_marker",
    rect = {...},
    label = "Маркер",
    knot = "unused",
    action = { type = "set_flag", flag = "park_marker_seen", value = true },
},
```

---

## 4. Material Icons и таблица `ICONS`

Иконка — символ из шрифта `MaterialIcons-Regular.ttf` (классический Material Icons, не Material Symbols). В коде хотспота пишешь короткое имя:

```lua
icon = "left"
icon = "coffee"
icon = "phone"
```

Имя резолвится в UTF-8 байты через таблицу `ICONS` в `hotspots_v2.gui_script`:

```lua
local ICONS = {
    left  = string.char(0xEE, 0x97, 0x84),  -- arrow_back
    right = string.char(0xEE, 0x97, 0x88),  -- arrow_forward
    up    = string.char(0xEE, 0x97, 0x98),
    down  = string.char(0xEE, 0x97, 0x9B),
    left_click = string.char(0xEE, 0xA4, 0x93),
    phone      = string.char(0xEE, 0xA4, 0x93),  -- alias на left_click (legacy)
    coffee  = string.char(0xEE, 0x95, 0x81),
    mug     = string.char(0xEE, 0x95, 0x81),
    note    = string.char(0xEE, 0x8B, 0x87),
    lock    = string.char(0xEE, 0xA2, 0x97),
    warning = string.char(0xEE, 0x80, 0x82),
    delete  = string.char(0xEE, 0xA1, 0xB2),
}
```

Если имя не найдено в `ICONS` — скрипт считает что ты передал готовый glyph и рисует его как есть.

### Как добавить новую иконку

1. Найди glyph в **классическом Material Icons** (не Symbols): https://fonts.google.com/icons → переключатель «Material Icons» в фильтре. Запиши hex-codepoint (например `e8b6` = `search`).
2. Конвертируй в UTF-8 байты:
   ```python
   chr(0xe8b6).encode('utf-8').hex()  # → 'ee a2 b6'
   ```
3. Добавь в `ICONS` в `hotspots_v2.gui_script`:
   ```lua
   search = string.char(0xEE, 0xA2, 0xB6),
   ```
4. Используй: `icon = "search"`.

> **Material Icons vs Material Symbols.** У нас классический Material Icons (~2100 иконок, заморожен в 2019). Material Symbols — новый шрифт Google (3500+ иконок, переменные оси), у нас не используется. Если нужная иконка только в Symbols — либо делай кастомный SVG-спрайт, либо предлагай переход (полу-инвазивная задача).

---

## 5. F1-редактор хотспотов

Дев-инструмент: правишь координаты, размер и стиль хотспотов прямо в игре, потом копируешь готовые строки из консоли в `.lua`-файл сцены.

### Когда работает

Только когда активен `scene_controller` — внутри exploration-сцены. В обычном ink-диалоге F1 ничего не делает.

### Управление

| Клавиша | Действие |
|---|---|
| `F1` | вкл / выкл редактор |
| `Esc` | выйти из режима |
| `Tab` | следующий **видимый** hotspot → object → hotspot (циклично) |
| Клик мышью | выбрать видимый hotspot |
| `← → ↑ ↓` | двигать (5 px, `Shift` = 20 px) |
| `[` / `]` | ширина −/+ |
| `;` / `'` | высота −/+ |
| `,` / `.` | предыдущий / следующий стиль |
| `P` | напечатать координаты + стиль в консоль |

### Что редактируется

- Hotspot: `rect.x`, `rect.y`, `rect.w`, `rect.h`, `hotspot_style`
- Scene object: `pos.x`, `pos.y`, `size.w`, `size.h`

### Скрытые хотспоты

Редактор **не выбирает скрытые хотспоты** (где `visible_when(gs) → false`). Tab крутит только видимые, клик ловит только видимые. Так игрок всегда видит, что выбрано.

Если нужно отредактировать скрытый хотспот — временно убери `visible_when` или поставь условие в `true` в `_shared.lua`-helper, перезапусти, поправь, верни условие назад.

### Workflow

1. Добавь хотспот в `main/data/scenes/<location>.lua`
2. Запусти игру
3. Зайди в exploration-сцену, где этот хотспот видим
4. Жми `F1` → ткни в нужный хотспот (или Tab до него)
5. Двигай стрелками, ресайзь `[]` / `;'`, переключай стиль `,` / `.`
6. Жми `P` → копируй из консоли:
   ```
   [hotspot_editor] cafe_hub / hotspot cafe_bar →
       rect = { x = 360, y = 205, w = 380, h = 280 },
       -- стиль: STYLE_USE (если рецепт не совпадает — добавь hotspot_style = s.STYLE_USE,)
   ```
7. Вставь обратно в `.lua`-файл сцены. Если поменял стиль — либо смени рецепт (`s.inspect{}` → `s.use{}`), либо оставь рецепт и добавь `hotspot_style = s.STYLE_X,` override.

> **Важно:** редактор пишет в память, не на диск. Если перезапустишь игру — изменения пропадут. `P` + копипаста — единственный способ сохранить.

### Troubleshooting

- **F1 не реагирует** — проверь что ты в exploration-сцене (не ink-диалог, не телефон).
- **Tab прыгает не туда** — проверь `visible_when` у соседних хотспотов; скрытые пропускаются.
- **Выбран `hidden`** в описании — это редкий случай, когда выбор сделан до того, как сцена пересобрала visible-список. Жми Tab — встанет на ближайший видимый.

---

## 6. Продвинутые цветовые поля (без рецептов)

Если стилей `STYLE_*` недостаточно и нужно полностью кастомное оформление одного хотспота — можно задать цвета напрямую. Эти поля идут **в обход** `hotspot_style` и переопределяют его поля по одному:

```lua
{
    id = "locked_door",
    rect = {...},
    label = "Закрыто",
    icon = "lock",
    circle_color = { r = 0.20, g = 0.02, b = 0.04 },
    ring_color   = { r = 1.00, g = 0.18, b = 0.28 },
    icon_color   = { r = 1.00, g = 0.75, b = 0.78 },
    circle_alpha = 0.65,
    ring_alpha   = 0.85,
    icon_alpha   = 1.00,
    hotspot_scale = 1.10,  -- или circle_scale/ring_scale/icon_scale по отдельности
    action = { type = "ink_knot", knot = "door_locked" },
}
```

Значения цвета **0.0–1.0** (не 0–255).

Если хотспот стал `locked = true` через `condition(gs) → false`, скрипт сам приглушает alpha. Явные `*_alpha` переопределяют это поведение.

### Кастомные PNG-текстуры

Можно дать хотспоту свою PNG-форму:

1. Положи `main/images/hotspot_circle_danger.png` и `hotspot_ring_danger.png`.
2. Добавь в `main/images/hotspots.atlas`.
3. В хотспоте:
   ```lua
   circle_texture = "hotspot_circle_danger",
   ring_texture   = "hotspot_ring_danger",
   ```

Если текстура не найдена — Defold ругнётся в консоль, glyph не сменится.

---

## 7. Чек-лист отладки

**Хотспот не виден:**
- `visible_when` возвращает `false`? Проверь флаги в `gs`.
- В сцене больше 6 видимых хотспотов? GUI рассчитан на 6 слотов (`HOTSPOT_COUNT`).
- `rect` за пределами экрана? Кружок ставится в центр rect.
- Свежая сборка? Иногда Defold кэширует.

**Круг не того цвета:**
- Значения в RGB должны быть 0.0–1.0.
- Если есть `condition → false`, хотспот locked → alpha занижается. Override через явный `circle_alpha`.
- Прямое `circle_color` поле перебивает `hotspot_style.circle_color`.

**Иконка визуально кривая:**
- Material Icons glyph'ы внутри своего box'а часто смещены. Дефолт `icon_offset_x = -4` чинит большинство.
- Для phone-glyph'а и других центрированных — поставь `icon_offset_x = 0` (см. примеры в `apartment.lua`).
- Если иконка низко — `icon_offset_y = 2..4`. Если высоко — `-2..-4`.

**Новая PNG-текстура не появилась:**
- Файл в `main/images/`?
- Добавлен в `main/images/hotspots.atlas`?
- В коде имя без `.png`?
- Defold проект пересобран?

**F1-редактор печатает координаты, но в игре не двигается:**
- Координатная система **1280×720, origin bottom-left**. Если копируешь из старого инструмента с top-left — переверни `y`.

---

## 8. Где что лежит

| Что | Файл |
|---|---|
| Стили (`STYLE_*`) + список `STYLES` | `main/data/scenes/_shared.lua` |
| Рецепты (`s.inspect`, `s.leave`, …) | `main/data/scenes/_shared.lua` |
| Конкретные хотспоты сцены | `main/data/scenes/<location>.lua` |
| Реестр сцен / aliases | `main/scripts/scenes.lua` |
| Пайплайн сцена → GUI | `main/scripts/scene_controller.lua` |
| Whitelist полей хотспота для GUI | `main/gui/modules/ui_manager_v2/scene_flow.lua` |
| Отрисовка хотспотов | `main/gui/components_v2/hotspots_v2.gui_script` |
| GUI-ноды хотспотов | `main/gui/components_v2/hotspots_v2.gui` |
| Иконочный шрифт + таблица `ICONS` | `main/fonts/MaterialIcons-Regular.ttf` + `hotspots_v2.gui_script` |
| F1-редактор runtime | `main/scripts/hotspot_editor.lua` |
| F1 keybindings | `input/game.input_binding` |
