# Система хабов — локации на карте телефона

Хаб — это point-and-click локация, доступная через карту телефона (phone_map).
Игрок нажимает на POI-маркер → подтверждает переход → телефон закрывается → открывается хаб.

---

## Как это работает (архитектура)

```
Игрок кликает на POI
        ↓
phone_map.gui_script
  показывает диалог "ПЕРЕЙТИ? [ДА] [НЕТ]"
        ↓ ДА
  msg.post(ui_manager, "map_travel", { scene = "cafe_hub" })
        ↓
ui_manager_v2.script
  close_phone()
  scene_controller.enter("cafe_hub")
        ↓
scene_controller.lua
  читает scenes.lua → рендерит фон + hotspot'ы
```

---

## Быстрый старт: добавить новый хаб

### Шаг 1 — Фон

1. Подготовь PNG-картинку фона (1280×720 или любое соотношение, движок растянет)
2. Положи в `main/images/backgrounds/`
3. В Defold: правой кнопкой на папку → **New → Atlas**, назови `bg_НАЗВАНИЕ.atlas`
4. Добавь PNG в атлас (правой кнопкой → **Add Images**)

Имя атласа (без `.atlas`) — это значение поля `bg` в scenes.lua.

---

### Шаг 2 — Сцена в `scenes.lua`

Открой `main/scripts/scenes.lua`, найди нужный хаб-стаб (уже созданы для всех POI) и замени поля:

```lua
cafe_hub = {
    bg = "bg_cafe",          -- имя атласа без .atlas

    -- Необязательно: ink-монолог при первом визите
    on_enter = {
        knot = "enter_cafe_first",
        condition = function(gs)
            return not gs.get_flag("cafe_intro_seen")
        end,
    },

    hotspots = {
        {
            id     = "cafe_barista",
            rect   = { x = 400, y = 200, w = 300, h = 400 },
            label  = "Бариста",
            icon   = "",
            action = { type = "ink_knot", knot = "talk_to_barista" },
        },
        {
            id     = "cafe_exit",
            rect   = { x = 0, y = 0, w = 150, h = 200 },
            label  = "Выйти",
            icon   = "",
            action = { type = "ink_knot", knot = "leave_cafe" },
        },
    },
},
```

---

### Шаг 3 — Проверь POI_SCENES в phone_map.gui_script

Файл `main/gui/components_v2/phone_map.gui_script`, таблица `POI_SCENES` уже содержит все 8 POI:

```lua
local POI_SCENES = {
    poi_home    = { scene = "apartment_hub", label = "Домой"       },
    poi_work    = { scene = "work_hub",      label = "На работу"   },
    poi_cafe    = { scene = "cafe_hub",      label = "Кафе"        },
    poi_park    = { scene = "park_hub",      label = "Парк у реки" },
    poi_shop    = { scene = "shop_hub",      label = "Магазин 24/7"},
    poi_bar     = { scene = "bar_hub",       label = "Бар Maybe"   },
    poi_view    = { scene = "view_hub",      label = "Смотровая"   },
    poi_archive = { scene = "archive_hub",   label = "Архив"       },
}
```

`label` — строка, которая отображается в диалоге подтверждения.
Менять нужно только если хочешь другое имя в диалоге.

---

## Справочник: поля сцены в `scenes.lua`

### Корень сцены

| Поле | Тип | Обязательно | Описание |
|------|-----|-------------|----------|
| `bg` | string или function(gs)->string | ✅ | Имя зарегистрированного фона или функция, возвращающая имя фона. |
| `hotspots` | table | ✅ | Массив интерактивных зон |
| `on_enter` | table | ❌ | Монолог при входе |
| `objects` | table | ❌ | Спрайты поверх фона (предметы) |

Для универсальных хабов утро/день/ночь используй `bg = function(gs) ... end`.
Функция должна возвращать только уже зарегистрированный `bg_*`.

### `on_enter`

```lua
on_enter = {
    knot = "enter_cafe_first",           -- ink-knot для запуска
    condition = function(gs)             -- если false — не запускать
        return not gs.get_flag("cafe_intro_seen")
    end,
},
```

Не забудь в ink-скрипте выставить флаг, иначе монолог будет играть каждый раз:
```ink
=== enter_cafe_first ===
# set_flag:cafe_intro_seen=true
Первый раз здесь. Пахнет кофе.
# return_to_scene
->DONE
```

### Hotspot

```lua
{
    id     = "уникальный_id",
    rect   = { x = 400, y = 200, w = 300, h = 400 },
    label  = "Подпись при наведении",
    icon   = "",          -- иконка (юникод из icons.font) или "" без иконки
    action = { ... },

    -- Необязательные условия:
    condition    = function(gs) return gs.get_flag("door_unlocked") end,
    --   condition = false  → hotspot виден, но некликабельный (тусклый)

    visible_when = function(gs) return not gs.get_flag("item_taken") end,
    --   visible_when = false → hotspot полностью скрыт
}
```

### Типы `action`

| type | дополнительные поля | что делает |
|------|---------------------|-----------|
| `"goto_scene"` | `scene = "kitchen"` | переход в другую сцену без диалога |
| `"ink_knot"` | `knot = "talk_barista"` | запускает ink-монолог, потом возвращает в хаб |
| `"set_flag"` | `flag = "door_open"`, `value = true` | просто ставит флаг |
| `"add_item"` | `item = "key"` | добавить предмет в инвентарь |

---

## Координаты hotspot'ов (`rect`)

Система координат: **1280×720**, начало — **левый-нижний угол** экрана.

```
rect = { x = 400, y = 200, w = 300, h = 400 }
          ^левый-нижний       ^ширина  ^высота
```

### Быстрый способ выставить координаты

1. Запусти игру и перейди в хаб
2. Нажми **F1** — откроется визуальный редактор хотспотов
3. Выбирай хотспоты стрелками, двигай мышкой, меняй размер `[` `]`
4. Когда доволен — нажми **P**: в консоль напечатаются готовые числа для `rect`
5. Скопируй в `scenes.lua`

---

## Ink-интеграция: теги для хабов

После диалога в хабе нужно вернуть игрока обратно в хаб (не на стартовый экран):

```ink
=== talk_to_barista ===
# speaker:mila
Мне капучино, пожалуйста.
# speaker:none
Бариста кивнул. Через минуту — чашка на стойке.
# set_flag:cafe_visited=true
# return_to_scene
->DONE
```

`# return_to_scene` — ключевой тег. Без него игрок застрянет в dialogue-режиме.

### Из хаба в другой хаб

Используй `goto_scene`:
```lua
action = { type = "goto_scene", scene = "apartment_hub" }
```
Переход мгновенный, без диалога.

### Открыть карту телефона из Ink

Телефон не является exploration-сценой. Если после текста нужно открыть карту и дать игроку выбрать, куда идти, используй `# phone:map`.

```ink
=== leave_apartment ===
# speaker:none
Ты выходишь на улицу и достаёшь телефон.
# phone:map
->DONE
```

`# phone:map` открывает телефон сразу на приложении `phone_map.gui`. После выбора POI телефон закрывается, а `ui_manager_v2` открывает нужный hub.

Новый контент не должен открывать телефон как отдельную scene.

---

## Уже готовые хабы

| POI на карте | scene_id | bg (нужно создать) |
|-------------|----------|--------------------|
| 🏠 Дом | `apartment_hub` | `bg_apartment_bedroom_morning` |
| 💼 Работа | `work_hub` | `bg_office_lobby_day` |
| ☕ Кафе | `cafe_hub` | `bg_cafe_morning` |
| 🌿 Парк | `park_hub` | `bg_park_by_the_river_morning` |
| 🛒 Магазин | `shop_hub` | `bg_shop_day` |
| 🍸 Бар | `bar_hub` | `bg_bar_maybe_night` |
| 👁 Смотровая | `view_hub` | `bg_observation_day` |
| 📁 Архив | `archive_hub` | `bg_archive_day` |

Стабы для всех хабов уже есть в `scenes.lua` — осталось только заменить фоны и настроить hotspot'ы.

---

## Диалог подтверждения перехода

При клике на POI появляется панель:

```
┌────────────────────────┐
│      ПЕРЕЙТИ?          │
│      Кафе              │
│   [ ДА ]    [ НЕТ ]   │
└────────────────────────┘
```

- **ДА** — телефон закрывается, открывается хаб
- **НЕТ** или клик мимо кнопок — диалог закрывается, карта остаётся

Текст "Кафе" берётся из поля `label` таблицы `POI_SCENES` в `phone_map.gui_script`.

## Universal hubs

Используются для локаций, где набор hotspot'ов общий, а фон меняется по состоянию.

Примеры:
- квартира: утро / ночь;
- офис: день / ночь.

Паттерн:
bg = function(gs)
    if condition then return "bg_location_night" end
    return "bg_location_day"
end
