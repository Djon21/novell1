# Locations Guide

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
| `main/data/scenes/cafe.lua` | Кафе (cafe_hub) |
| `main/data/scenes/shop.lua` | Магазин 24/7 (shop_hub) |
| `main/data/scenes/bar.lua` | Бар Maybe (bar_hub) |
| `main/data/scenes/viewpoint.lua` | Смотровая (view_hub) |
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

## Структура хотспота

```lua
{
    id = "example_hotspot",                        -- стабильный id, на него ссылаются
    rect = { x = 100, y = 120, w = 180, h = 140 }, -- зона клика в game-coords 1280×720
    label = "Осмотреть",                            -- подпись под хотспотом
    icon = "search",                                -- ключ из icons таблицы _shared.lua
    hotspot_style = STYLE_INSPECT,                  -- стиль кружка (см. _shared.lua)
    icon_offset_x = 0,                              -- ручная коррекция иконки
    icon_offset_y = -4,
    action = { type = "ink_knot", knot = "example_inspect" },
    visible_when = function(gs)
        return gs.get_flag("some_flag")
    end,
    condition = function(gs)
        return not gs.get_flag("locked_flag")
    end,
}
```

### Поля

| Поле | Описание |
|---|---|
| `id` | Стабильный уникальный id внутри сцены. На него ссылается inventory armed-state, dev-jump, и т.д. |
| `rect` | Прямоугольник кликабельной зоны в game coords 1280×720, origin bottom-left. |
| `label` | Текст под кружком. Краткий — одно-два слова. |
| `icon` | Ключ из icons-таблицы (см. `_shared.lua`). Реальный набор иконок проверять там. |
| `hotspot_style` | Стиль (цвет круга, пульс). Реальный набор стилей в `_shared.lua` — `STYLE_NAV`, `STYLE_INSPECT`, `STYLE_PICKUP`, `STYLE_USE`, `STYLE_ITEM_TARGET`, `STYLE_STORY`, `STYLE_NEUTRAL`. |
| `icon_offset_x/y` | Если иконка визуально не по центру (особенности шрифта). Не двигай весь хотспот — двигай иконку. |
| `action` | См. ниже |
| `visible_when(gs)` | Видим ли хотспот вообще |
| `condition(gs)` | Кликабелен ли (виден но locked если false) |

### Action types

| Тип | Поле | Поведение |
|---|---|---|
| `ink_knot` | `knot = "<name>"` | Прыжок в ink-knot, возврат через `# return_to_scene` |
| `goto_scene` | `scene = "<scene_id>"` | Переход в другую exploration-сцену |
| `set_flag` | `flag = "<name>", value = ...` | Установить флаг, остаться в сцене |
| `add_item` | `item = "<id>"` | Дать предмет, остаться в сцене |

Если нужен новый тип — это **фича для кода**, не сценарная правка. См. dm_commands.lua и scene_controller.lua.

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

Иконка — из icon-font'а проекта. Реальный набор — в `_shared.lua` таблица `icons` (search, phone, mug, note, lock, и т.д.).

Стиль — из `STYLE_*` constants там же. Они определяют:
- Цвет ring + circle (например STYLE_INSPECT — синий, STYLE_PICKUP — жёлтый)
- Анимацию пульса (некоторые стили пульсируют сильнее)
- Альфу

Если стиль/иконка не подходят — расширяй существующие constants в `_shared.lua`, **не** хардкодь цвета в самом хотспоте.

---

## Хороший vs плохой ответ AI про новую локацию

**Хороший ответ** содержит:
- `scene_id` (с проверкой что не дублируется)
- bg атлас (из существующих, см. `PROJECT_INVENTORY.md` секция Backgrounds)
- Список хотспотов, для каждого: `id`, `rect`, `label`, `icon`, `hotspot_style`, `action`
- Какие новые knot'ы нужны (а не «пусть будет какой-нибудь knot»)
- Какие новые / существующие флаги управляют видимостью
- Какие переходы могут сломаться

**Плохой ответ**:
- «добавь кнопку в GUI» (нет — хотспоты конфигурятся в Lua, не в GUI)
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

Связь между sub-сценами — через хотспот с `action = { type = "goto_scene", scene = "<other_sub_scene>" }`. Игрок ходит между ними как между «комнатами» одной локации.

**Для scene_characters** (Persona-style персонажи на фоне) sub-сцены могут быть объединены в одну группу через `SCENE_GROUPS` в `scene_characters.lua` — тогда персонаж следует за игроком по всем sub-сценам группы. См. `HOW_TO_ADD_SCENE_CHARACTERS.md`.

---

## Слоты GUI (hotspots_v2)

В `hotspots_v2.gui` есть пул переиспользуемых нод-слотов. Это **не значит** что нужно править GUI для каждого нового хотспота — сценический Lua описывает данные, GUI-скрипт раскладывает текущие хотспоты по доступным слотам.

Если в сцене больше хотспотов чем поддерживает пул слотов — расширять систему слотов в `hotspots_v2.gui_script` (увеличить `M.HOTSPOT_COUNT`).
