# Инструкция по добавлению новых сцен

Текущие point-and-click сцены описываются в `main/scripts/scenes.lua`, исполняются `scene_controller.lua` и рендерятся через `ui_manager_v2.script` + `hotspots_v2.gui_script`.

## Важные ограничения текущего v2 runtime

- максимум `6` hotspot'ов на сцену
- максимум `4` scene objects на сцену
- координатная система hotspot'ов: `1280x720`, origin — левый нижний угол

Если добавить больше элементов, лишние просто не доедут до UI, пока лимиты в `ui_manager_v2.script` не расширены.

## Базовая структура сцены

```lua
my_scene = {
    bg = "bg_my_scene",
    label = "Моя сцена", -- опционально, пригодится для nav/exits
    on_enter = { ... },  -- опционально
    objects = { ... },   -- опционально
    hotspots = { ... },  -- обычно обязательно
    exits = { ... },     -- опционально
}
```

## Шаг 1: Добавить сцену в `main/scripts/scenes.lua`

```lua
my_room = {
    bg = "bg_my_room",
    label = "Комната",
    hotspots = {
        {
            id = "back_to_corridor",
            rect = { x = 30, y = 30, w = 140, h = 80 },
            label = "Назад",
            icon = string.char(0xEE, 0x97, 0x84),
            action = { type = "goto_scene", scene = "apartment_hub" },
        },
    },
}
```

## Поля hotspot'а

- `id` — уникальный идентификатор
- `rect` — `{ x, y, w, h }` в координатах `1280x720`
- `label` — подпись
- `icon` — Material Icon или пустая строка
- `action` — действие по клику
- `condition(gs)` — если `false`, hotspot виден, но заблокирован
- `visible_when(gs)` — если `false`, hotspot полностью скрыт

## Поддерживаемые `action.type`

### Переход в сцену

```lua
action = { type = "goto_scene", scene = "kitchen" }
```

### Установка флага

```lua
action = { type = "set_flag", flag = "door_opened", value = true }
```

### Инвентарь

```lua
action = { type = "add_item", item = "key" }
action = { type = "remove_item", item = "key" }
```

### Ink knot

```lua
action = { type = "ink_knot", knot = "take_phone" }
```

Используйте это для коротких монологов, осмотров и событий. Если knot должен вернуть игрока обратно в exploration, заканчивайте Ink на `# return_to_scene`.

### Закрытие телефона

```lua
action = { type = "phone_close" }
```
❗ Телефон не является сценой.

Не используйте телефон как navigation target.

Телефон открывается через UI (`phone_v2`) или через Ink-теги телефона, например `# phone:map`.

## `condition` и `visible_when`

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

Разница:

- `condition = false` -> hotspot виден, но locked
- `visible_when = false` -> hotspot полностью скрыт

## Scene objects

Это отдельные спрайты поверх фона, которые тоже описываются в `scenes.lua`.

```lua
objects = {
    {
        id = "phone_obj",
        image = "mobile",
        pos = { x = 385, y = 260 },
        size = { w = 52, h = 22 },
        visible_when = function(gs)
            return gs.get_flag("coffee_drunk") and not gs.get_flag("has_phone")
        end,
    },
}
```

Поле `image` должно указывать на имя flipbook'а из `main/images/scene_objects.atlas`.
По умолчанию там лежит `mobile`. Чтобы добавить новый scene-object спрайт, см.
`docs/guides/HOW_TO_ADD_BACKGROUNDS.md` → раздел «Если Нужен Не Fullscreen Background».

## Автотриггер при входе

```lua
on_enter = {
    knot = "enter_kitchen",
    condition = function(gs)
        return not gs.get_flag("kitchen_intro_seen")
    end,
}
```

## Переходы между сценами

Игра — point-and-click, поэтому переходы делаются через hotspots, а не через отдельные direction-кнопки. Достаточно добавить hotspot с действием `goto_scene`:

```lua
{
    id = "to_kitchen",
    rect = { x = 95, y = 0, w = 225, h = 680 },
    label = "На кухню",
    icon = "",
    action = { type = "goto_scene", scene = "kitchen" },
},
```

Для возврата используется такой же hotspot с `scene = "apartment_hub"`.

## Координаты и F1-редактор

Для подгонки coordinates используйте `F1 Hotspot Editor`:

1. Запустите игру
2. Войдите в нужную exploration-сцену
3. Нажмите `F1`
4. Используйте:
   - `Tab` — следующий элемент
   - стрелки — двигать
   - `[` / `]` — менять ширину
   - `;` / `'` — менять высоту
   - `P` — печатать координаты в консоль

См. также `docs/guides/F1_HOTSPOT_EDITOR.md`.

## Ink-привязка к сцене

```ink
=== apartment_hub
# bg:bg_apartment_bedroom_morning # explore:apartment_hub # speaker:none
Коридор. Тихо.
-> DONE
```

## Чеклист

- [ ] фон оформлен по `HOW_TO_ADD_BACKGROUNDS.md` (отдельный atlas + регистрация в `ui_manager_v2.script`)
- [ ] scene id добавлен в `scenes.lua`
- [ ] у hotspot'ов уникальные `id`
- [ ] сцена укладывается в лимиты `6` hotspot'ов / `4` objects
- [ ] все knot'ы реально существуют в Ink
- [ ] `condition` / `visible_when` проверены в игре
- [ ] при необходимости добавлены `exits`
