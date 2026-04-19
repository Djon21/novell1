# Инструкция по добавлению новых сцен (Point-and-Click)

## Что такое сцена?

**Сцена** — это point-and-click локация, где игрок может кликать по hotspot'ам (интерактивным зонам). Примеры: кухня, ванная, коридор квартиры.

Сцены описываются в файле: `main/scripts/scenes.lua`

---

## Структура сцены

```lua
scene_id = {
    bg = "bg_название",           -- Фон из backgrounds.atlas
    on_enter = { ... },            -- Автотриггер при входе (опционально)
    objects = { ... },             -- Спрайты поверх фона (опционально)
    hotspots = { ... },            -- Кликабельные зоны (обязательно)
}
```

---

## Шаг 1: Создание базовой сцены

Откройте `main/scripts/scenes.lua` и добавьте новую сцену в таблицу `M.scenes`:

```lua
M.scenes = {
    -- ... существующие сцены ...
    
    my_room = {
        bg = "bg_my_room",
        hotspots = {
            {
                id = "back_to_corridor",
                rect = { x = 30, y = 30, w = 140, h = 80 },
                label = "Назад",
                icon = string.char(0xEE, 0x97, 0x84),  -- U+E5C4 arrow_back
                action = { type = "goto_scene", scene = "apartment_hub" },
            },
        },
    },
}
```

### Параметры:
- **id** - уникальный идентификатор hotspot'а (латиница, snake_case)
- **rect** - прямоугольник `{ x, y, w, h }` в координатах 960×640 (origin левый-нижний)
- **label** - текст подсказки при наведении
- **icon** - иконка Material Icons (опционально, может быть пустой строкой `""`)
- **action** - действие при клике (см. ниже)

---

## Шаг 2: Типы действий (action)

### goto_scene - переход в другую сцену
```lua
action = { type = "goto_scene", scene = "kitchen" }
```

### set_flag - установить флаг
```lua
action = { type = "set_flag", flag = "door_opened", value = true }
```

### add_item - добавить предмет в инвентарь
```lua
action = { type = "add_item", item = "key" }
```

### remove_item - убрать предмет
```lua
action = { type = "remove_item", item = "key" }
```

### ink_knot - запустить Ink-сценарий
```lua
action = { type = "ink_knot", knot = "take_phone" }
```
После выполнения knot'а с тегом `# return_to_scene` игрок вернется в эту сцену.

### phone_close - закрыть телефон
```lua
action = { type = "phone_close" }
```
Используется только в сцене `phone_home`.

---

## Шаг 3: Условия (condition)

Hotspot может быть **заблокирован** (тусклый, некликабельный) если условие не выполнено:

```lua
{
    id = "exit_door",
    rect = { x = 390, y = 130, w = 175, h = 365 },
    label = "Выйти",
    icon = "",
    action = { type = "ink_knot", knot = "leave_apartment" },
    condition = function(gs)
        return gs.get_flag("has_phone") and gs.get_flag("coffee_drunk")
    end,
}
```

**Параметр `gs`** - это `game_state`, доступные методы:
- `gs.get_flag("name")` - получить флаг
- `gs.has_item("id")` - проверить наличие предмета

---

## Шаг 4: Видимость (visible_when)

Hotspot может быть **полностью скрыт** если условие не выполнено:

```lua
{
    id = "phone_on_desk",
    rect = { x = 400, y = 300, w = 180, h = 160 },
    label = "Телефон",
    icon = string.char(0xEE, 0xA4, 0x93),  -- U+E913 smartphone
    action = { type = "ink_knot", knot = "take_phone" },
    visible_when = function(gs)
        return gs.get_flag("coffee_drunk") and not gs.get_flag("has_phone")
    end,
}
```

**Разница между condition и visible_when:**
- `condition = false` → hotspot виден, но тусклый и некликабельный
- `visible_when = false` → hotspot полностью скрыт

Используйте `visible_when` когда hotspot'ы накладываются друг на друга (например, кофемашина пустая vs с кружкой).

---

## Шаг 5: Объекты сцены (objects)

Спрайты поверх фона (например, телефон на столе):

```lua
my_room = {
    bg = "bg_my_room",
    objects = {
        {
            id = "phone_obj",
            image = "mobile",           -- имя из backgrounds.atlas
            pos = { x = 385, y = 260 }, -- левый-нижний угол спрайта
            size = { w = 52, h = 22 },
            visible_when = function(gs)
                return gs.get_flag("coffee_drunk") and not gs.get_flag("has_phone")
            end,
        },
    },
    hotspots = { ... },
}
```

---

## Шаг 6: Автотриггер при входе (on_enter)

Запустить Ink-knot автоматически при первом входе в сцену:

```lua
kitchen = {
    bg = "bg_kitchen",
    on_enter = {
        knot = "enter_kitchen",
        condition = function(gs) 
            return not gs.get_flag("kitchen_intro_seen") 
        end,
    },
    hotspots = { ... },
}
```

В Ink-файле:
```ink
=== enter_kitchen
# speaker:mc
Кухня. Всё как обычно. Кофемашина, стол, окно.
# flag:kitchen_intro_seen=true
# return_to_scene
-> DONE
```

---

## Шаг 7: Координаты hotspot'ов

### Координатная система:
- **Разрешение:** 960×640 пикселей
- **Origin:** левый-нижний угол (как в OpenGL)
- **rect:** `{ x, y, w, h }` где x,y - левый-нижний угол прямоугольника

### Как определить координаты:

**Вариант 1: F1-редактор (в игре)**
1. Запустите игру в Defold
2. Нажмите F1 в сцене
3. Используйте мышь для настройки hotspot'ов
4. Координаты сохраняются автоматически

**Вариант 2: Вручную**
1. Откройте фон в графическом редакторе
2. Измерьте координаты нужной области
3. Конвертируйте из top-left в bottom-left:
   ```
   y_bottom_left = 640 - y_top_left - height
   ```

### Примеры координат:
```lua
-- Левая стена (узкая полоса для перехода)
{ x = 0, y = 0, w = 220, h = 640 }

-- Центральный объект
{ x = 400, y = 300, w = 180, h = 160 }

-- Кнопка "Назад" в углу
{ x = 30, y = 30, w = 140, h = 80 }
```

---

## Шаг 8: Иконки Material Icons

Используйте Material Icons для hotspot'ов:

```lua
-- Стрелка назад
icon = string.char(0xEE, 0x97, 0x84)  -- U+E5C4 arrow_back

-- Телефон
icon = string.char(0xEE, 0xA4, 0x93)  -- U+E913 smartphone

-- Кофемашина
icon = string.char(0xEE, 0x95, 0x81)  -- U+E541 coffee_maker

-- Инвентарь/ящик
icon = string.char(0xEE, 0x8B, 0x87)  -- U+E2C7 inventory

-- Закрыть
icon = string.char(0xEE, 0x97, 0x8D)  -- U+E5CD close
```

**Как найти код иконки:**
1. Откройте [Material Icons](https://fonts.google.com/icons)
2. Найдите нужную иконку
3. Скопируйте Unicode (например, U+E5C4)
4. Конвертируйте в `string.char(0xEE, 0x97, 0x84)`

---

## Шаг 9: Использование сцены в Ink

```ink
=== apartment_hub
# bg:bg_apartment # explore:apartment_hub # speaker:mc
Коридор. Тихо.
-> DONE
```

Тег `# explore:apartment_hub` передает управление scene_controller на сцену `apartment_hub`.

---

## Полный пример сцены

```lua
kitchen = {
    bg = "bg_kitchen",
    on_enter = {
        knot = "enter_kitchen",
        condition = function(gs) return not gs.get_flag("kitchen_intro_seen") end,
    },
    hotspots = {
        -- Кофемашина без кружки
        {
            id = "coffee_maker_empty",
            rect = { x = 155, y = 250, w = 160, h = 155 },
            label = "Кофемашина",
            icon = string.char(0xEE, 0x95, 0x81),  -- coffee_maker
            action = { type = "ink_knot", knot = "use_coffee_machine_no_cup" },
            visible_when = function(gs)
                return not gs.get_flag("has_mug") and not gs.get_flag("coffee_drunk")
            end,
        },
        -- Кофемашина с кружкой
        {
            id = "coffee_maker_brew",
            rect = { x = 155, y = 250, w = 160, h = 155 },
            label = "Сварить кофе",
            icon = string.char(0xEE, 0x95, 0x81),
            action = { type = "ink_knot", knot = "use_coffee_machine_with_cup" },
            visible_when = function(gs)
                return gs.get_flag("has_mug") and not gs.get_flag("coffee_drunk")
            end,
        },
        -- Ящик с кружкой
        {
            id = "mug_drawer",
            rect = { x = 420, y = 180, w = 160, h = 140 },
            label = "Ящик",
            icon = string.char(0xEE, 0x8B, 0x87),  -- inventory
            action = { type = "ink_knot", knot = "take_mug" },
            visible_when = function(gs) return not gs.get_flag("has_mug") end,
        },
        -- Выход
        {
            id = "back_from_kitchen",
            rect = { x = 0, y = 0, w = 140, h = 640 },
            label = "Назад",
            icon = string.char(0xEE, 0x97, 0x84),  -- arrow_back
            action = { type = "goto_scene", scene = "apartment_hub" },
        },
    },
}
```

---

## Чеклист перед коммитом

- [ ] Фон `bg_название` добавлен в `backgrounds.atlas`
- [ ] Все hotspot'ы имеют уникальные id
- [ ] Координаты rect проверены (не выходят за 960×640)
- [ ] Условия condition/visible_when работают корректно
- [ ] Ink-knot'ы существуют в chapter_01.ink
- [ ] Сцена протестирована в игре
- [ ] Иконки отображаются правильно

---

## Troubleshooting

**Hotspot не кликается:**
- Проверьте condition - возможно он заблокирован
- Проверьте visible_when - возможно он скрыт
- Проверьте координаты rect

**Фон не отображается:**
- Убедитесь что фон добавлен в backgrounds.atlas
- Проверьте имя: в atlas `/main/images/bg_name.jpg`, в сцене `bg_name`

**Ink-knot не запускается:**
- Проверьте имя knot'а (без опечаток)
- Убедитесь что knot существует в chapter_01.ink
- Проверьте что knot заканчивается на `# return_to_scene` и `-> DONE`

**Объект не отображается:**
- Проверьте что image добавлен в backgrounds.atlas
- Проверьте visible_when условие
- Проверьте координаты pos и size
