# Hub And Hotspot Workflow

Этот документ нужен, потому что GPT помогает не только писать сценарий, но и достраивать хабы, локации и хотспоты.

## Где находятся сцены

Основные scene/hub данные лежат в `main/data/scenes/`.

Текущая структура:

- `_shared.lua` - общие стили, иконки, утилиты.
- `apartment.lua` - воскресная квартира.
- `apartment_monday.lua` - квартира в понедельник.
- `apartment_tuesday.lua` - квартира во вторник.
- `office.lua` - офисные сцены.
- `locations.lua` - внешние локации: кафе, парк, магазин, бар, смотровая, архив и т.п.

`main/scripts/scenes.lua` собирает эти файлы в общий список сцен.

Если GPT должен реально править hub, ему недостаточно этого документа. Нужно дать ему актуальные:

- файл сцены из `main/data/scenes/`;
- `main/data/scenes/_shared.lua`;
- `main/scripts/scenes.lua`;
- связанный Ink-файл, если хотспоты вызывают `ink_knot`.

Подробные наборы файлов лежат в `SOURCE_FILE_PACKS.md`.

## Что такое scene_id

`scene_id` - это имя сцены, в которую можно перейти через `goto_scene` или через Ink-тег исследования.

Примеры:

- `apartment_hub`
- `apartment_bedroom`
- `apartment_bathroom`
- `apartment_kitchen`
- `monday_apartment_bedroom_morning`
- `monday_apartment_hall_morning`
- `monday_apartment_kitchen_morning`
- `tuesday_apartment_bedroom_morning`
- `tuesday_apartment_hall_morning`
- `tuesday_apartment_kitchen_morning`
- `work_hub`
- `office_workspace`
- `office_meeting_room`
- `cafe_hub`
- `park_hub`
- `park_riverside_bench`
- `park_riverside_path`
- `shop_hub`
- `bar_hub`
- `view_hub`
- `archive_hub`

Перед добавлением перехода всегда проверяй, что такой `scene_id` существует.

## Формат хотспота

Пример:

```lua
{
    id = "example_hotspot",
    rect = { x = 100, y = 120, w = 180, h = 140 },
    label = "Осмотреть",
    icon = icons.search,
    action = { type = "ink_knot", knot = "example_inspect" },
    visible_when = function(gs)
        return gs.get_flag("some_flag")
    end,
    condition = function(gs)
        return not gs.get_flag("locked_flag")
    end,
    style = styles.blue,
    icon_offset = { x = 0, y = -4 },
}
```

Реальный синтаксис `icons` и `styles` надо смотреть в `_shared.lua`, потому что набор имён может меняться.

Поэтому для точной работы с иконками и стилями всегда добавляй GPT файл `main/data/scenes/_shared.lua`.

## Action types

Поддерживаемые типы действий:

- `goto_scene` - перейти в другую сцену исследования.
- `ink_knot` - вызвать Ink-knot.
- `set_flag` - выставить флаг.
- `add_item` - добавить предмет.

Если GPT предлагает новый тип действия, это не готовая правка, а новая фича, которую сначала надо реализовать в коде.

## visible_when и condition

`visible_when` отвечает за то, видит ли игрок хотспот.

`condition` отвечает за то, можно ли сейчас выполнить действие. Хотспот может быть виден, но действие будет заблокировано.

Используй `visible_when`, если объект не должен появляться до события. Используй `condition`, если объект виден, но сюжетно недоступен.

## Координаты

Хотспоты размечаются в координатах GUI 1280x720.

- `x` и `y` - позиция прямоугольника.
- `w` и `h` - ширина и высота зоны.
- Начало координат в GUI-логике Defold обычно снизу слева.

Для точной разметки лучше использовать F1 hotspot editor, если он включён в проекте.

## Иконки и круги

Круг/фон хотспота задаётся не в Ink, а стилем хотспота в Lua.

Иконка обычно берётся из подключённого icon font или из общего набора `icons`. Если иконка визуально стоит не по центру, не надо двигать весь хотспот. Используй `icon_offset`.

Пример:

```lua
icon_offset = { x = 0, y = -6 }
```

## Слоты GUI

В `hotspots_v2.gui` может быть несколько слотов. Это не значит, что для каждого конкретного хотспота надо руками править отдельную GUI-ноду.

Слоты - это переиспользуемые визуальные контейнеры. Сцена описывает данные хотспотов в Lua, а GUI-скрипт раскладывает текущие хотспоты по доступным слотам.

Если в сцене больше видимых хотспотов, чем поддерживает GUI, надо расширять систему слотов или оптимизировать сцену.

## Как GPT должен помогать с новой локацией

Хороший ответ GPT для локации должен содержать:

- `scene_id`;
- фон/background id;
- список хотспотов;
- для каждого хотспота: `id`, `rect`, `label`, `icon`, `action`;
- какие Ink-knot нужны для `ink_knot`;
- какие флаги нужны для видимости/блокировки;
- краткую проверку, какие переходы могут сломаться.

Плохой ответ GPT:

- "добавь кнопку в GUI";
- "поставь любой id";
- "пусть action будет open_map_old";
- "координаты потом сам подберёшь";
- "создай новый системный тег".
