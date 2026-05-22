# GUI Utils модуль

Общие хелперы для gui_script'ов проекта. Раньше каждый gui_script держал
свои локальные копии get_node/set_text/set_node_enabled/set_color (~30-40
строк дубликата ×10 файлов). Теперь — один модуль.

**Файл:** `main/gui/modules/gui_utils.lua`

## Когда использовать

Подключай модуль в любом gui_script где есть стандартные операции с GUI-нодами:
- получить ноду по id (с защитой от отсутствия);
- включить/выключить группу нод;
- поставить текст / цвет / прозрачность / позицию / размер;
- обрезать длинный текст по UTF-8;
- сделать flash-feedback на тап;
- проверить попадание точки в rect.

Не нужен только если gui_script делает что-то очень специальное и стандартные
обёртки не подходят (например `phone_quests.set_border` строит border из
4 сегментов — оставлено локально).

## Подключение

Идиома проекта: короткое имя `U` для алиаса (по паттерну `dm`/`gs`).

```lua
local U = require "main.gui.modules.gui_utils"

-- Опционально — сделать локальные алиасы привычных имён, чтобы не править
-- весь файл при миграции:
local get_node         = U.get_node
local set_node_enabled = U.set_node_enabled
local set_text         = U.set_text
local set_color        = U.set_color
local clamp_text       = U.clamp_text
```

## API

### Lookup

| Функция | Описание |
|---------|----------|
| `U.get_node(id)` | pcall-safe, возвращает ноду или nil. Если передать уже ноду — вернёт её как есть |
| `U.get_node_safe(id)` | алиас для совместимости со старой версией модуля |

### Видимость

| Функция | Описание |
|---------|----------|
| `U.set_node_enabled(id, enabled)` | вкл/выкл одну ноду |
| `U.set_nodes_enabled(ids, enabled)` | вкл/выкл массив нод |

### Текст

| Функция | Описание |
|---------|----------|
| `U.set_text(id, value)` | ставит текст; nil → "" |
| `U.clamp_text(s, max_len, ellipsis?)` | UTF-8-aware truncation, по умолчанию ellipsis = `…` |

### Цвет / прозрачность

| Функция | Описание |
|---------|----------|
| `U.set_color(id, color, alpha?)` | rgb из color, alpha из аргумента или color.w или 1 |
| `U.set_color_keep_alpha(id, color)` | меняет только rgb, текущая альфа сохраняется |
| `U.set_alpha(id, alpha)` | меняет только альфу, цвет остаётся |
| `U.get_alpha(id)` | возвращает текущее значение color.w |

`color` принимается как `vmath.vector3` / `vmath.vector4` / таблица с полями
`x/y/z[/w]`. Если поля отсутствуют — берётся 0.

### Позиция / размер

| Функция | Описание |
|---------|----------|
| `U.set_pos(id, x, y, z?)` | позиция, z по умолчанию 0 |
| `U.set_size(id, w, h)` | размер по width/height |
| `U.set_pos_size(id, x, y, z, w, h)` | комбайн pos+size |
| `U.set_box(id, x, y, w, h, color?, alpha?, z?)` | box-нода: pos+size+color одним вызовом |

### Hit-testing

| Функция | Описание |
|---------|----------|
| `U.point_in_rect(x, y, rx, ry, rw, rh)` | проверка попадания в произвольный rect |
| `U.pick_node(id, x, y)` | gui.pick_node по id с проверкой is_enabled |

### Анимации / feedback

| Функция | Описание |
|---------|----------|
| `U.flash_node(id_or_node, opts?)` | короткое мерцание color.w (стандартный feedback на тап) |
| `U.cancel_animations(id_or_node)` | отменяет position/color/scale/rotation анимации |

`flash_node` opts: `{ low = 0.3, dur_down = 0.08, dur_up = 0.18 }`.

### Tree (templates)

| Функция | Описание |
|---------|----------|
| `U.clone_tree(id_or_node)` | gui.clone_tree с проверкой |
| `U.delete_tree(node)` | gui.delete_node с проверкой |

### Vector shortcuts

| Функция | Описание |
|---------|----------|
| `U.color4(r, g, b, a?)` | vmath.vector4(r, g, b, a or 1) |
| `U.vec3(x, y, z?)` | vmath.vector3(x, y, z or 0) |

## Типичный паттерн миграции gui_script'а

**Было:**

```lua
local function get_node(id)
    local ok, n = pcall(gui.get_node, id)
    if ok then return n end
    return nil
end

local function set_node_enabled(id, enabled)
    local n = get_node(id)
    if n then gui.set_enabled(n, enabled) end
end

local function set_text(id, value)
    local n = get_node(id)
    if n then gui.set_text(n, value or "") end
end

-- ... ещё 30-50 строк ...
```

**Стало:**

```lua
local U = require "main.gui.modules.gui_utils"

local get_node         = U.get_node
local set_node_enabled = U.set_node_enabled
local set_text         = U.set_text
local set_color        = U.set_color
local clamp_text       = U.clamp_text
```

Локальные алиасы — чтобы не трогать вызовы. Если нравится `U.set_text(...)`
напрямую — тоже ок, дело вкуса.

## NODE_IDS pattern

Многие gui_script'ы держат массив id всех управляемых нод в `NODE_IDS`,
чтобы централизованно вкл/выкл их при open/close. С модулем это пишется:

```lua
local NODE_IDS = { "card1_bg", "card1_text", "card2_bg", ... }

local function set_nodes_enabled(enabled)
    U.set_nodes_enabled(NODE_IDS, enabled)
end
```

Локальная обёртка нужна потому что `U.set_nodes_enabled` ожидает массив
явным первым аргументом, а в gui_script привычнее `set_nodes_enabled(true)`.

## Что НЕ покрывает модуль

- Custom-форматные хелперы вроде `phone_quests.set_border(prefix, x, y, w, h, color, alpha)`,
  где идея в построении 4 border-сегментов из префикса. Слишком специфично,
  оставлено в gui_script.
- `phone_messenger.clamp_text` — у него своя логика (байтовая, с "..." вместо "…").
  Если хочешь привести к стандарту — миграция рискованная без визуальной проверки.
- Анимации (pulsing, bobbing, кросс-фейды) — делаются прямо через
  `gui.animate(node, "color.w", ...)` в gui_script'е. Раньше была заготовка
  `gui_animations.lua` с готовыми хелперами, но она не прижилась — каждый
  компонент использует свои inline-анимации, удалена в мае 2026.

## Куда ещё применить

Уже мигрировано:
- `phone_call`, `phone_mail`, `phone_term` — все базовые helper'ы
- `phone_v2_root` — get_node/set_text/set_nodes_enabled/flash_node
- `phone_notes` — get_node/set_text/set_node_enabled

Можно ещё мигрировать (постепенно, при следующем касании файла):
- `dialogue_v2` — там 3 helper'а
- `hud_v2` — там 1 helper
- `choice_v2` — там 6 helper'ов, есть set_pos_size — подходит
- `main_menu_v2` — 1 helper
- `inventory_v2` — 2 helper'а
- `phone_messenger`, `phone_sms` — большая поверхность специфичных хелперов,
  миграция опционально и осторожно

## См. также

- `docs/guides/DRAG_SCROLL.md` — модуль drag-to-scroll, родственник gui_utils.
- `docs/guides/MESSAGES.md` — реестр msg-сообщений.
- `docs/guides/LOGGING.md` — единый logger.
