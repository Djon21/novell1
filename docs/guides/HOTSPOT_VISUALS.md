# Hotspot visuals: иконки, круги, кольца и стили

Этот документ описывает, откуда берётся внешний вид хотспотов в игре и как менять:

- координаты клика;
- подпись;
- иконку;
- круг-подложку;
- кольцо вокруг круга;
- цвет, прозрачность и размер;
- PNG-текстуры для разных типов кругов.

Основные файлы:

| Что меняем | Файл |
|---|---|
| Список хотспотов, координаты, подписи, иконки, стили | `main/scripts/scenes.lua` |
| Передача хотспотов из сцены в UI-адаптер | `main/scripts/scene_controller.lua` |
| Whitelist полей хотспота для отправки в GUI component | `main/gui/modules/ui_manager_v2/scene_flow.lua` |
| Логика отрисовки хотспотов | `main/gui/components_v2/hotspots_v2.gui_script` |
| GUI-ноды хотспотов | `main/gui/components_v2/hotspots_v2.gui` |
| Атлас PNG для круга/кольца/точек | `main/images/hotspots.atlas` |
| PNG круга | `main/images/hotspot_circle.png` |
| PNG кольца | `main/images/hotspot_ring.png` |
| PNG точек орбиты | `main/images/hotspot_dot.png` |
| Шрифт иконок | `main/fonts/MaterialIcons-Regular.ttf` |
| Defold font resource для иконок | `main/fonts/material_icons.font` |

## 1. Как устроен один хотспот

Пример хотспота в `main/scripts/scenes.lua`:

```lua
{
    id = "back_to_hall_from_bedroom",
    rect = { x = 1035, y = 70, w = 170, h = 220 },
    label = "В коридор",
    icon = "arrow_back",
    action = { type = "goto_scene", scene = "apartment_hub" },
    visible_when = function(gs)
        return gs.get_flag("washed_up")
    end,
}
```

Поля:

| Поле | Что делает |
|---|---|
| `id` | Внутреннее имя хотспота. Нужен для отладки и читаемости. |
| `rect` | Область клика на экране. `x`, `y` - левый нижний угол, `w`, `h` - ширина и высота. |
| `label` | Текстовая подпись хотспота. |
| `icon` | Символ из Material Icons. Если пустая строка, круг и иконка не показываются. |
| `action` | Что произойдёт при клике: переход в сцену, запуск Ink knot и т.п. |
| `visible_when` | Условие видимости. Если функции нет, хотспот виден всегда. |

Визуально хотспот состоит из слоёв:

```text
hotspot_ring.png      -- светящееся внешнее кольцо
hotspot_circle.png    -- тёмный круг-подложка
Material icon         -- стрелка, телефон, кофе и т.п.
```

Путь данных такой:

```text
scenes.lua
  -> scene_controller.lua
      -> scene_flow.lua
          -> hotspots_v2.gui_script
              -> hotspots_v2.gui
```

Если добавляешь новое поле в хотспот, оно должно дойти по этой цепочке до `hotspots_v2.gui_script`. Сейчас `scene_controller.lua` передаёт весь объект хотспота целиком, поэтому поля вроде `circle_color`, `ring_color`, `icon_color`, `hotspot_style`, `circle_texture` и `ring_texture` доходят до GUI.

`scene_flow.lua` дополнительно делает безопасную копию данных перед `msg.post`. Если в будущем появится новое поле стиля, например `pulse_speed`, его нужно добавить в whitelist внутри `set_hotspot = function(i, data)` в `main/gui/modules/ui_manager_v2/scene_flow.lua`.

## 2. Откуда берётся стрелка и как задавать иконки

Иконка - это не картинка. Это символ из шрифта Material Icons. Сейчас основной удобный способ - писать имя иконки:

```lua
icon = "arrow_back"
icon = "phone"
icon = "coffee"
```

Словарь имён находится в `main/gui/components_v2/hotspots_v2.gui_script`, таблица `ICONS`. Скрипт превращает имя в реальный символ перед отрисовкой:

```lua
local ICONS = {
    arrow_back = string.char(0xEE, 0x97, 0x84),
    phone = string.char(0xEE, 0xA4, 0x93),
    coffee = string.char(0xEE, 0x95, 0x81),
}
```

GUI-нода `hotspot_icon_*` в `main/gui/components_v2/hotspots_v2.gui` использует font `material_icons`. Скрипт `hotspots_v2.gui_script` делает примерно так:

```lua
icon = resolve_icon(icon)
gui.set_text(icon_node, icon)
```

То есть иконка работает как текст, но в `scenes.lua` ты пишешь короткое имя.

Доступные имена:

| Назначение | Код |
|---|---|
| Стрелка влево | `icon = "arrow_back"` |
| Стрелка вправо | `icon = "arrow_forward"` |
| Стрелка вверх | `icon = "arrow_up"` |
| Стрелка вниз | `icon = "arrow_down"` |
| Клик / тап | `icon = "left_click"` |
| Телефон | `icon = "phone"` или `icon = "smartphone"` |
| Кофе | `icon = "coffee"` |
| Кружка | `icon = "mug"` |
| Заметка | `icon = "note"` |

Старые способы тоже работают, если вдруг понадобится:

```lua
icon = string.char(0xEE, 0x97, 0x84)
icon = ""
```

Но для новых хотспотов лучше использовать имена. Это проще читать и безопаснее для кодировки.

### Как добавить новое имя иконки

1. Найди Material Icon и его Unicode-код, например `U+E8B6`.
2. Переведи `U+E8B6` в UTF-8 байты.
3. Добавь запись в таблицу `ICONS` в `main/gui/components_v2/hotspots_v2.gui_script`:

```lua
local ICONS = {
    search = string.char(0xEE, 0xA2, 0xB6),
}
```

4. Используй в `scenes.lua`:

```lua
icon = "search"
```

Если имя не найдено в `ICONS`, скрипт считает, что ты передал готовый символ, и попробует нарисовать его как есть.

## 3. Откуда берётся круг

Круг и кольцо - это PNG из атласа:

```text
main/images/hotspot_circle.png
main/images/hotspot_ring.png
main/images/hotspot_dot.png
```

Они подключены в `main/images/hotspots.atlas`:

```text
images {
  image: "/main/images/hotspot_circle.png"
}
images {
  image: "/main/images/hotspot_ring.png"
}
images {
  image: "/main/images/hotspot_dot.png"
}
```

В `hotspots_v2.gui` есть ноды:

```text
hotspot_circle_1 ... hotspot_circle_6
hotspot_ring_1   ... hotspot_ring_6
hotspot_icon_1   ... hotspot_icon_6
```

Скрипт берёт свободный слот и ставит эти ноды в центр `rect`.

## 4. Как сделать разные цвета кругов

Теперь каждый хотспот может иметь свои цвета:

```lua
{
    id = "phone_on_bedside",
    rect = { x = 565, y = 230, w = 180, h = 135 },
    label = "Телефон",
    icon = "phone",
    circle_color = { r = 0.03, g = 0.10, b = 0.18 },
    ring_color = { r = 0.40, g = 0.90, b = 1.00 },
    icon_color = { r = 0.85, g = 0.98, b = 1.00 },
    action = { type = "ink_knot", knot = "take_phone" },
}
```

Цвета задаются числами от `0.0` до `1.0`.

Примеры палитр:

| Тип | `circle_color` | `ring_color` | `icon_color` |
|---|---|---|---|
| Нейтральный переход | `{ r = 0.06, g = 0.06, b = 0.10 }` | `{ r = 1.00, g = 1.00, b = 1.00 }` | `{ r = 1.00, g = 1.00, b = 1.00 }` |
| Телефон / техно | `{ r = 0.03, g = 0.10, b = 0.18 }` | `{ r = 0.40, g = 0.90, b = 1.00 }` | `{ r = 0.85, g = 0.98, b = 1.00 }` |
| Кофе / кухня | `{ r = 0.18, g = 0.10, b = 0.04 }` | `{ r = 1.00, g = 0.68, b = 0.28 }` | `{ r = 1.00, g = 0.90, b = 0.68 }` |
| Опасность / запрет | `{ r = 0.20, g = 0.02, b = 0.04 }` | `{ r = 1.00, g = 0.18, b = 0.28 }` | `{ r = 1.00, g = 0.75, b = 0.78 }` |

## 5. Как менять прозрачность

```lua
circle_alpha = 0.78
ring_alpha = 0.90
icon_alpha = 1.00
```

Полный пример:

```lua
{
    id = "locked_door",
    rect = { x = 900, y = 120, w = 180, h = 360 },
    label = "Закрыто",
    icon = "lock",
    circle_color = { r = 0.20, g = 0.02, b = 0.04 },
    ring_color = { r = 1.00, g = 0.18, b = 0.28 },
    icon_color = { r = 1.00, g = 0.75, b = 0.78 },
    circle_alpha = 0.65,
    ring_alpha = 0.85,
    icon_alpha = 1.00,
    action = { type = "ink_knot", knot = "door_locked" },
}
```

Если у хотспота есть `locked = true`, скрипт сам делает круг, кольцо и иконку более тусклыми. Явные `circle_alpha`, `ring_alpha`, `icon_alpha` переопределяют это поведение.

## 6. Как менять размер

Изменить всё сразу:

```lua
hotspot_scale = 1.10
```

Изменить отдельно:

```lua
circle_scale = 1.05
ring_scale = 1.15
icon_scale = 0.95
```

Пример:

```lua
{
    id = "important_exit",
    rect = { x = 0, y = 95, w = 235, h = 515 },
    label = "В коридор",
    icon = "arrow_back",
    hotspot_scale = 1.12,
    ring_alpha = 1.0,
    action = { type = "goto_scene", scene = "apartment_hub" },
}
```

## 6.1. Как подвинуть иконку внутри круга

Иконка рисуется текстом из шрифта Material Icons. У разных символов центр внутри шрифта может быть не идеально по центру картинки, поэтому стрелка, телефон или кружка иногда выглядят чуть смещёнными.

Для точной ручной настройки используй поля:

```lua
icon_offset_x = 0
icon_offset_y = 4
```

`icon_offset_x` двигает иконку влево/вправо:

```text
меньше 0  -- левее
больше 0  -- правее
```

`icon_offset_y` двигает иконку вниз/вверх:

```text
меньше 4  -- ниже
больше 4  -- выше
```

Почему по умолчанию `4`, а не `0`: в `hotspots_v2.gui_script` есть базовая компенсация шрифта, потому что текстовая baseline у Material Icons визуально чуть уводит значок. Если иконка кажется слишком низко, попробуй `icon_offset_y = 0` или `icon_offset_y = -2`.

Практическое правило текущих сцен:

- для стрелок в квартире часто используется `icon_offset_x = -4`, `icon_offset_y = 0`;
- если копируешь существующий стиль из `scenes.lua`, сохраняй offset'ы;
- если делаешь новый hotspot с нуля, начни с `0, 0` и подгони через F1/debug.

Пример для стрелки вниз:

```lua
{
    id = "go_down",
    rect = { x = 500, y = 250, w = 160, h = 160 },
    label = "Вниз",
    icon = "arrow_down",
    icon_offset_x = 0,
    icon_offset_y = 0,
    action = { type = "goto_scene", scene = "some_scene" },
}
```

Пример, если хочешь хранить сдвиг внутри общего стиля:

```lua
hotspot_style = {
    icon_offset_x = 0,
    icon_offset_y = 0,
    circle_color = { r = 0.06, g = 0.06, b = 0.10 },
    ring_color = { r = 1.00, g = 1.00, b = 1.00 },
}
```

## 7. Как не повторять стиль в каждом хотспоте

Можно завернуть стиль в таблицу `hotspot_style`:

```lua
hotspot_style = {
    circle_color = { r = 0.06, g = 0.06, b = 0.10 },
    ring_color = { r = 1.00, g = 1.00, b = 1.00 },
    icon_color = { r = 1.00, g = 1.00, b = 1.00 },
    circle_alpha = 0.78,
    ring_alpha = 0.90,
    scale = 1.00,
}
```

Полный пример:

```lua
{
    id = "back_to_hall_from_bedroom",
    rect = { x = 1035, y = 70, w = 170, h = 220 },
    label = "В коридор",
    icon = "arrow_back",
    hotspot_style = {
        circle_color = { r = 0.06, g = 0.06, b = 0.10 },
        ring_color = { r = 1.00, g = 1.00, b = 1.00 },
        icon_color = { r = 1.00, g = 1.00, b = 1.00 },
        circle_alpha = 0.78,
        ring_alpha = 0.90,
    },
    action = { type = "goto_scene", scene = "apartment_hub" },
}
```

Можно смешивать:

```lua
hotspot_style = {
    circle_color = { r = 0.06, g = 0.06, b = 0.10 },
    ring_color = { r = 1.00, g = 1.00, b = 1.00 },
}
icon_color = { r = 1.00, g = 0.80, b = 0.40 }
```

Поле, указанное напрямую в хотспоте, важнее поля внутри `hotspot_style`.

## 8. Как добавить новый PNG-круг

Если цвета недостаточно и нужна другая форма круга:

1. Положи PNG в `main/images/`, например:

```text
main/images/hotspot_circle_danger.png
main/images/hotspot_ring_danger.png
```

2. Добавь их в `main/images/hotspots.atlas`:

```text
images {
  image: "/main/images/hotspot_circle_danger.png"
}
images {
  image: "/main/images/hotspot_ring_danger.png"
}
```

3. В хотспоте укажи имя анимации из атласа без `.png`:

```lua
{
    id = "danger_hotspot",
    rect = { x = 600, y = 200, w = 160, h = 160 },
    label = "Опасно",
    icon = "warning",
    circle_texture = "hotspot_circle_danger",
    ring_texture = "hotspot_ring_danger",
    action = { type = "ink_knot", knot = "danger_hint" },
}
```

Важно: если текстура не найдена в атласе, Defold оставит старую/default-текстуру, а в консоли может появиться ошибка. Проверь имя файла и запись в `hotspots.atlas`.

## 9. Что происходит в коде

Файл `main/gui/components_v2/hotspots_v2.gui_script`.

Упрощённо:

```lua
local icon = data.icon
if icon and icon ~= "" then
    local icon_node = M.hotspot_icons[i]
    local circle_node = M.hotspot_circles[i]
    local ring_node = M.hotspot_rings[i]

    gui.set_position(circle_node, vmath.vector3(cx, cy, 0.068))
    gui.set_position(ring_node, vmath.vector3(cx, cy, 0.067))
    gui.set_position(icon_node, vmath.vector3(cx, cy + 4, 0.07))

    gui.set_text(icon_node, icon)
    gui.set_color(circle_node, ...)
    gui.set_color(ring_node, ...)
    gui.set_color(icon_node, ...)

    gui.set_enabled(circle_node, true)
    gui.set_enabled(ring_node, true)
    gui.set_enabled(icon_node, true)
end
```

Если `icon = ""`, визуальный круг не показывается. При этом прямоугольник `rect` всё равно может быть кликабельным, если хотспот видим.

## 10. Как добавить новый хотспот

1. Найди нужную сцену в `main/scripts/scenes.lua`.
2. Внутри `hotspots = { ... }` добавь объект:

```lua
{
    id = "my_new_hotspot",
    rect = { x = 500, y = 250, w = 180, h = 140 },
    label = "Осмотреть",
    icon = "note",
    circle_color = { r = 0.08, g = 0.08, b = 0.14 },
    ring_color = { r = 0.70, g = 0.80, b = 1.00 },
    action = { type = "ink_knot", knot = "my_new_knot" },
    visible_when = function(gs)
        return gs.get_flag("some_flag")
    end,
}
```

3. Если `action.type = "ink_knot"`, убедись, что такой knot есть в Ink.
4. Если `action.type = "goto_scene"`, убедись, что такая сцена есть в `M.scenes`.
5. Перезапусти Defold build.

## 11. Когда нужно компилировать Ink

Нужно запускать:

```bat
tools\compile_ink.bat
```

Если менял:

- `.ink`;
- текст сюжета;
- новые Ink knots;
- Ink-переходы.

Не нужно компилировать Ink, если менял только:

- `scenes.lua`;
- цвета хотспотов;
- координаты `rect`;
- PNG;
- atlas;
- GUI scripts.

Но после Lua/GUI/PNG изменений всё равно нужно пересобрать проект в Defold.

## 12. Быстрый чеклист отладки

Если хотспот не виден:

- Проверь, что `icon` не пустой, если ты ждёшь круг и значок.
- Проверь `visible_when`: возможно, нужный флаг ещё `false`.
- Проверь, что в сцене не больше 6 видимых хотспотов одновременно. Сейчас GUI подготовлен под 6 слотов.
- Проверь `rect`: круг ставится в центр прямоугольника.
- Проверь, что ты запускаешь свежую сборку, а не старую папку `build`.

Если круг не того цвета:

- Проверь диапазон цвета: значения должны быть от `0.0` до `1.0`, не `0..255`.
- Проверь, не переопределяет ли прямое поле `circle_color` значение внутри `hotspot_style`.
- Проверь, что хотспот не `locked = true`, либо явно задай `circle_alpha`, `ring_alpha`, `icon_alpha`.

Если новая PNG-текстура не появилась:

- Проверь, что PNG лежит в `main/images/`.
- Провь, что PNG добавлен в `main/images/hotspots.atlas`.
- В `circle_texture` и `ring_texture` пиши имя без `.png`.
- Пересобери проект.

## 13. Как теперь устроен `hotspots_v2.gui`

`main/gui/components_v2/hotspots_v2.gui` теперь специально сделан простым и повторяемым. В нём нет логики сцены, координат конкретных предметов или условий видимости. Это только набор заранее подготовленных GUI-нод, которые скрипт двигает и включает/выключает во время игры.

Главная идея: есть 6 одинаковых слотов хотспотов. Каждый слот состоит из 5 нод:

```text
hotspot_1          -- невидимый прямоугольник клика
hotspot_label_1    -- подпись хотспота, дочерняя нода hotspot_1
hotspot_ring_1     -- внешнее PNG-кольцо
hotspot_circle_1   -- PNG-круг-подложка
hotspot_icon_1     -- иконка из шрифта Material Icons
```

То же самое повторяется для `hotspot_2`, `hotspot_3`, `hotspot_4`, `hotspot_5`, `hotspot_6`.

Если нужно увеличить количество одновременно видимых хотспотов:

1. В `hotspots_v2.gui` скопируй полный набор нод последнего слота.
2. Переименуй их, например, в `hotspot_7`, `hotspot_label_7`, `hotspot_ring_7`, `hotspot_circle_7`, `hotspot_icon_7`.
3. В `main/gui/components_v2/hotspots_v2.gui_script` поменяй:

```lua
M.HOTSPOT_COUNT = 7
```

Без этого скрипт всё равно будет брать только первые 6 слотов.

4. В `main/gui/modules/ui_manager_v2/scene_flow.lua` поменяй лимит:

```lua
max_hotspots = function() return 7 end
```

Иначе `scene_controller` всё равно будет отдавать максимум 6 хотспотов в GUI.

### Что можно менять в GUI руками

Обычно руками в `hotspots_v2.gui` трогать почти ничего не надо. Большинство настроек лучше задавать в `main/scripts/scenes.lua` прямо в хотспоте:

```lua
icon = "phone"
circle_color = { r = 0.03, g = 0.10, b = 0.18 }
ring_color = { r = 0.40, g = 0.90, b = 1.00 }
icon_color = { r = 0.85, g = 0.98, b = 1.00 }
hotspot_scale = 1.10
```

В GUI имеет смысл менять только базовую форму слота:

```text
hotspot_ring_*      -- стартовый размер внешнего кольца
hotspot_circle_*    -- стартовый размер круга
hotspot_icon_*      -- стартовый размер текстовой ноды иконки
hotspot_label_*     -- положение подписи относительно прямоугольника клика
```

Но важно помнить: во время игры `hotspots_v2.gui_script` сам ставит позицию, размер hitbox-а, текст и цвета. Поэтому если ты вручную подвинешь `hotspot_circle_1` в GUI-редакторе, в игре он всё равно окажется в центре `rect` из `scenes.lua`.

### Что было удалено из старого GUI

Раньше в `hotspots_v2.gui` были ещё:

```text
hotspot_orbit_1 ... hotspot_orbit_6
hotspot_dot_1_1 ... hotspot_dot_6_6
```

Это были ноды для орбиты с точками вокруг хотспота. Сейчас визуальный стиль использует только `ring + circle + icon`, а скрипт всё равно всегда выключал orbit/dots. Поэтому эти ноды удалены из GUI и из `hotspots_v2.gui_script`, чтобы файл не выглядел как склад забытых деталей от велосипеда.

Если когда-нибудь захочется вернуть орбитальные точки, лучше сделать это заново отдельной понятной системой, а не тащить старые выключенные ноды обратно.
