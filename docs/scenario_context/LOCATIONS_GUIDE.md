# Locations Guide

**Каноничная версия для AI-сценариста.** Если file search находит другой
`LOCATIONS_GUIDE.md` или старые guides с verbose-hotspot форматом, считать их
устаревшими для сценарных задач. Нормальный формат новых хотспотов сейчас —
**recipes из `main/data/scenes/_shared.lua`**.

Как устроены хабы / локации / фоны в проекте и как правильно их править
или добавлять. Этот документ — концептуальный. Список **существующих**
scene_id, hotspot id, bg-атласов — в `PROJECT_INVENTORY.md`.

---

## Где живут сцены

Файлы сцен:

| Файл | Что внутри |
|---|---|
| `main/data/scenes/_shared.lua` | Стили (`STYLE_NAV`, `STYLE_INSPECT`, ...), иконки, helper'ы (`apartment_bg(...)` и т.п.) |
| `main/data/scenes/apartment.lua` | Воскресная квартира (apartment_hub / _bedroom / _bathroom / _kitchen) |
| `main/data/scenes/apartment_monday.lua` | Квартира в понедельник (monday_apartment_*) |
| `main/data/scenes/apartment_tuesday.lua` | Квартира во вторник (tuesday_apartment_*) |
| `main/data/scenes/office_monday.lua` | Офис в понедельник (work_hub / office_workspace / office_meeting_room) |
| `main/data/scenes/office_tuesday.lua` | Stub: вторничный офис пока без собственных хотспотов |
| `main/data/scenes/park.lua` | Парк у реки (park_hub + park_riverside_bench + park_riverside_path) |
| `main/data/scenes/cafe.lua` | Кафе (cafe_hub / cafe_corner / cafe_backroom) |
| `main/data/scenes/shop.lua` | Магазин 24/7 (shop_street / shop_front / shop_household / shop_hub alias) |
| `main/data/scenes/bar.lua` | Бар Maybe (bar_hub) |
| `main/data/scenes/viewpoint.lua` | Смотровая (view_hub / view_corner) |
| `main/data/scenes/archive.lua` | Архив (archive_hub) |

Сборка в общий список — `main/scripts/scenes.lua`.

Если AI должен **править** хаб, нужны:
- нужный файл из `main/data/scenes/`
- `main/data/scenes/_shared.lua` (для STYLE_*, icons, bg helpers)
- `main/scripts/scenes.lua` (для проверки регистрации)
- связанный ink-файл, если хотспот вызывает `ink_knot`

См. `SOURCE_FILE_PACKS.md` для точных наборов.

---

## scene_id

`scene_id` — имя сцены, в которую можно перейти через `goto_scene` или
ink-тег `# explore:`.

Полный список scene_id, их фонов и hotspot'ов — в `PROJECT_INVENTORY.md`.
Перед добавлением перехода **всегда** проверь что `scene_id` действительно
существует.

---

## Структура хотспота — только recipes из `_shared.lua`

Хотспоты создаются через **рецепты** — функции из `_shared.lua`, которые сами подставляют стиль и тип action.

Для AI-сценариста правило простое: **не писать** `hotspot_style = STYLE_X` и
`action = { type = ... }` руками. Нужно выбрать правильный рецепт:
`s.inspect{}`, `s.pickup{}`, `s.use{}`, `s.story{}`, `s.item_target{}`,
`s.nav_scene{}`, `s.nav_ink{}` или `s.leave{}`.

```lua
local s = require "main.data.scenes._shared"

s.inspect{
    id = "example_hotspot",
    rect = { x = 100, y = 120, w = 180, h = 140 },  -- 1280×720, origin bottom-left
    label = "Осмотреть",
    knot = "example_inspect",
    visible_when = function(gs) return gs.get_flag("some_flag") end,
    condition    = function(gs) return not gs.get_flag("locked_flag") end,
},
```

### Доступные рецепты

| Рецепт | Стиль | Action | Дефолтная иконка | Когда юзать |
|---|---|---|---|---|
| `s.nav_scene{...scene=...}` | NAV | `goto_scene` | твоя (обязательна) | переход в sub-сцену (`up`/`down`/`left`/`right`) |
| `s.nav_ink{...knot=...}` | NAV | `ink_knot` | твоя | навигация с ink-обвязкой |
| `s.inspect{...knot=...}` | INSPECT | `ink_knot` | `"left_click"` | осмотреть / прочитать |
| `s.pickup{...knot=...}` | PICKUP | `ink_knot` | `"left_click"` | взять в инвентарь |
| `s.use{...knot=...}` | USE | `ink_knot` | `"left_click"` | действие с объектом (кофе, турникет) |
| `s.story{...knot=...}` | STORY | `ink_knot` | `"left_click"` | сюжетный gate, важный момент |
| `s.item_target{...knot=...}` | ITEM_TARGET | `ink_knot` | `"left_click"` | цель для применения предмета |
| `s.leave{...knot=...}` | NAV | `ink_knot` | `"left"` + label `"Выйти"` | выход с локации |

### Поля opts

| Поле | Обязательно | Описание |
|---|---|---|
| `id` | да | стабильный уникальный id внутри сцены |
| `rect` | да | `{ x, y, w, h }` в 1280×720, origin bottom-left |
| `label` | да | подпись под кружком |
| `knot` / `scene` | да (зависит от рецепта) | куда вести по клику |
| `icon` | если дефолт не подходит | ключ из таблицы ICONS (см. HOTSPOTS.md) |
| `visible_when(gs)` | нет | если `false` — хотспот полностью невидим |
| `condition(gs)` | нет | если `false` — хотспот тусклый, не кликается |
| `hotspot_style = s.STYLE_X` | нет для AI | низкоуровневый override, не обычный формат |
| `action = {...}` | нет для AI | низкоуровневый override, только если это отдельная кодовая задача |
| `icon_offset_x/y` | нет | точечный сдвиг glyph'а |

### Низкоуровневые overrides

В `_shared.lua` технически есть возможность перебить стиль или action рецепта.
Но для сценарного GPT это **не основной формат**, а исключение.

Используй overrides только если:

- пользователь явно попросил изменить низкоуровневое поведение;
- у AI на руках есть `_shared.lua` и нужный `main/data/scenes/*.lua`;
- обычный рецепт не выражает нужную семантику;
- результат помечен как code-level правка, а не обычный сценарный hotspot.

Обычная замена стиля почти всегда означает, что выбран не тот рецепт:

- нужно действие с объектом → `s.use{}`;
- нужно взять предмет → `s.pickup{}`;
- нужен сюжетный gate → `s.story{}`;
- нужен переход → `s.nav_scene{}` или `s.nav_ink{}`.

Только для понимания внутреннего устройства:

```lua
-- Низкоуровневое исключение, НЕ шаблон для обычных хотспотов:
s.inspect{ id=..., rect=..., label=..., knot=..., hotspot_style = s.STYLE_USE },

-- Низкоуровневое исключение, НЕ шаблон для обычных хотспотов:
s.inspect{
    id = "park_marker",
    rect = {...}, label = "Маркер", knot = "ignored",
    action = { type = "set_flag", flag = "park_marker_seen", value = true },
},
```

Доступные `action.type`: `ink_knot`, `goto_scene`, `set_flag`, `add_item`, `remove_item`. Новый тип — **фича для кода**, не сценарная правка.

Полная низкоуровневая спецификация — `docs/guides/HOTSPOTS.md`. Для AI-сценариста
канон всё равно этот документ и `TEMPLATES.md`.

---

## visible_when vs condition

| | `visible_when` | `condition` |
|---|---|---|
| Когда применять | Объект не должен ПОЯВЛЯТЬСЯ до события | Объект виден, но временно недоступен |
| Поведение если false | Хотспот не отображается вообще | Хотспот тусклый, клик молча игнорируется |
| Пример | «Урна не появляется пока нет стаканчика в инвентаре» | «Окно открыть можно только после открытия штор» |

---

## Координаты

Хотспоты — game coords `1280×720`, origin **bottom-left** (Defold convention).

- `x, y` — позиция нижне-левого угла прямоугольника
- `w, h` — ширина и высота

Для разметки используй **F1 hotspot editor** в проекте (см. `HOTSPOTS.md`). Это интерактивный режим прямо в игре.

---

## Иконки и стили

**Иконки** — Material Icons (классический шрифт, не Symbols). Имя резолвится через таблицу `ICONS` в `hotspots_v2.gui_script`. Базовый набор: `left`, `right`, `up`, `down`, `left_click`, `phone`, `coffee`, `mug`, `note`, `lock`, `warning`, `delete`. Если нужна новая — добавляется в `ICONS` (см. `HOTSPOTS.md` §4).

**Стили** — `STYLE_NAV` / `INSPECT` / `PICKUP` / `USE` / `ITEM_TARGET` / `STORY` в `_shared.lua`. Цвета: cyan / violet / magenta-pink / amber / green / hot-pink соответственно. Кодируют ДЕЙСТВИЕ, не предмет.

AI **не задаёт** стиль вручную — берёт правильный recipe (`s.use{}` для USE,
`s.pickup{}` для PICKUP и т.д.). Если кажется, что нужен
`hotspot_style = s.STYLE_X`, сначала предложи сменить recipe. Override стиля —
только code-level исключение после явного запроса пользователя.

---

## Хороший vs плохой ответ AI про новую локацию

**Хороший ответ** содержит:
- `scene_id` (с проверкой что не дублируется)
- bg атлас (из существующих, см. `PROJECT_INVENTORY.md` секция Backgrounds)
- Список хотспотов через **рецепты** (`s.inspect{}`, `s.use{}`, `s.leave{}`, ...) — не verbose-форма с `hotspot_style` и `action.type` на каждом
- Для каждого хотспота: `id`, `rect`, `label`, `knot` (или `scene`), `icon` если нестандартный
- Какие новые knot'ы нужны (а не «пусть будет какой-нибудь knot»)
- Какие новые / существующие флаги управляют видимостью
- Какие переходы могут сломаться

**Плохой ответ**:
- «добавь кнопку в GUI» (нет — хотспоты конфигурятся в Lua, не в GUI)
- Verbose-форма хотспота с `hotspot_style = STYLE_X` и `action = { type = "ink_knot", knot = ... }` (нет — это легаси, бери рецепт)
- «поставь любой id» (нет — id стабильный)
- «пусть action = open_map_old» (нет — `goto_scene/ink_knot/set_flag/add_item`)
- «координаты потом подберёшь» (нет — давай конкретные числа или явно «нужен F1 editor»)
- «создай новый action type» (это код, не сценарий)

---

## Фоны

Реальный каталог bg-атласов — в `PROJECT_INVENTORY.md` секция **Backgrounds**.

Концепция:
- Bg-атласы лежат в `main/images/backgrounds/<bg_name>.atlas`
- Каждый bg — один атлас, один полноэкранный PNG/JPG
- В коде регистрируются через `go.property("bg_<name>_atlas", ...)` в `ui_manager_v2.script` + `DEDICATED_BG_ATLAS_PROPS` mapping

Чтобы **добавить новый фон**:

1. Положить изображение `main/images/backgrounds/bg_<name>/bg_<name>.jpg`
2. Создать `main/images/backgrounds/bg_<name>.atlas` ссылающийся на это изображение
3. Добавить `go.property("bg_<name>_atlas", resource.atlas("..."))` в `ui_manager_v2.script`
4. Добавить mapping в `DEDICATED_BG_ATLAS_PROPS`
5. Использовать как `bg = "bg_<name>"` в `main/data/scenes/*.lua` или `# bg:bg_<name>` в ink

См. `HOW_TO_ADD_SCENES.md` для подробного pipeline.

---

## Несколько sub-сцен одной локации

Локация может состоять из нескольких scene_id (entrance, bench, path). Каждый
sub-scene — отдельный hub со своим набором хотспотов.

Связь между sub-сценами — через recipe:

```lua
s.nav_scene{
    id = "to_other_sub_scene",
    rect = { x = ..., y = ..., w = ..., h = ... },
    label = "Перейти",
    icon = "up",
    scene = "<other_sub_scene>",
}
```

Внутри recipe это станет `goto_scene`, но AI-сценарист не должен писать
`action = { type = "goto_scene", ... }` руками.

**Для scene_characters** (Persona-style персонажи на фоне) sub-сцены могут быть объединены в одну группу через `SCENE_GROUPS` в `scene_characters.lua` — тогда персонаж следует за игроком по всем sub-сценам группы. См. `HOW_TO_ADD_SCENE_CHARACTERS.md`.

---

## Слоты GUI (hotspots_v2)

В `hotspots_v2.gui` есть пул переиспользуемых нод-слотов. Это **не значит** что нужно править GUI для каждого нового хотспота — сценический Lua описывает данные, GUI-скрипт раскладывает текущие хотспоты по доступным слотам.

Если в сцене больше хотспотов чем поддерживает пул слотов — расширять систему слотов в `hotspots_v2.gui_script` (увеличить `M.HOTSPOT_COUNT`).
