# Dev Jump Checkpoints

`Dev Jump Checkpoints` — встроенный debug-инструмент, чтобы быстро попадать в середину или конец игры без полного прохождения с начала.

Работает только в debug-сборке Defold. В релизной сборке клавиши ничего не делают.

`F4` начинает новый runtime-run из выбранной точки и перезаписывает текущий `save.dat`. Это удобно для проверки `Continue` из середины игры, но для чистого ручного прохождения лучше не нажимать dev-клавиши.

## Горячие клавиши

| Клавиша | Действие |
| --- | --- |
| `F3` | выбрать следующий checkpoint |
| `F4` | прыгнуть в выбранный checkpoint |

Выбранная точка и успешный прыжок печатаются в консоль Defold с префиксом `[dev_jump]`.

## Где лежат checkpoint'ы

Основной файл:

```text
main/gui/modules/ui_manager_v2/dev_jump.lua
```

Внизу файла есть таблица `PRESETS`. Каждый элемент — отдельная точка для тестирования:

```lua
{
    id = "sunday_park_bench",
    label = "Sunday: park bench exploration",
    scene = "park_riverside_bench",
    state = park_state(),
}
```

Или прыжок не в exploration-сцену, а прямо в Ink-knot:

```lua
{
    id = "monday_office_choice",
    label = "Monday: office core choice",
    knot = "mon_office_core_choice",
    state = monday_office_state(),
    allow_chapter_end = true,
}
```

## `scene` или `knot`

`scene` используется, когда нужно попасть в point-and-click режим с хотспотами:

```lua
scene = "apartment_hub"
```

По умолчанию `scene` открывается с `skip_on_enter = true`, чтобы dev-прыжок не запускал вступительный `on_enter`-монолог. Если надо проверить именно `on_enter`, добавь:

```lua
skip_on_enter = false
```

`knot` используется, когда нужно начать конкретную Ink-сцену:

```lua
knot = "tue_rooftop_entry"
```

Для сюжетных route/finale knot'ов обычно ставь:

```lua
allow_chapter_end = true
```

Для коротких side-knot'ов хотспотов можно не ставить.

## Как добавлять новую точку

1. Найди нужный `scene_id` в `main/data/scenes/*.lua` или нужный `=== knot ===` в `main/story/chapters/*.ink`.
2. Добавь новый элемент в `PRESETS`.
3. Выставь нужное состояние через `state`.
4. Запусти игру в debug, `F3` выбери точку, `F4` прыгни.

Пример:

```lua
{
    id = "test_archive",
    label = "Tuesday: archive exploration",
    scene = "archive_hub",
    state = {
        flags = {
            phone_active = true,
            tuesday_started = true,
        },
        vars = {
            phone_active = true,
            tuesday_started = true,
        },
        items = { "phone" },
        quests = {
            follow_monday_trace = "active",
        },
    },
}
```

## Что можно выставлять в `state`

```lua
state = {
    flags = {
        phone_active = true,
        date_agreed = true,
    },
    vars = {
        phone_active = true,
        date_agreed = true,
    },
    items = { "phone", "mug" },
    quests = {
        find_phone = "done",
        meet_npc = "active",
    },
    sms = {
        { "mama", "Текст SMS" },
    },
    msg = {
        { "mila", "Текст Messenger" },
    },
    map_lock_to = "poi_home",
}
```

`flags` — это `game_state` флаги, которые используют Lua-сцены и хотспоты.

`vars` — это Ink-переменные. Если переменная есть и в Lua, и в Ink, ставь её в обе секции: `flags` для Lua-сцен/хотспотов, `vars` для условий внутри Ink.

`items` — предметы в инвентаре.

`quests` — статусы квестов: обычно `"active"` или `"done"`.

`sms` и `msg` — стартовые сообщения в телефоне.

Для карты можно использовать один из вариантов:

```lua
map_lock_all = true
map_lock_to = "poi_home"
map_allow = { "poi_home", "poi_park" }
```

## Важное правило

Не делай checkpoint простым прыжком в сцену без состояния, если сцена зависит от прошлых решений. Иначе можно получить неправильные хотспоты, пустой телефон, закрытую карту или сломанный маршрут. Лучше один раз описать нормальный `state`, чем потом ловить призраков из будущего.
