# Система хабов и POI-карты

Хаб — это point-and-click сцена, в которую игрок попадает через карту телефона. Карта сама не содержит сценарий: она только выбирает `scene_id`, закрывает телефон и передаёт управление `scene_controller`.

Сцены живут в `main/data/scenes/<location>.lua` (apartment, office, locations и т.п.); `main/scripts/scenes.lua` — тонкий фасад который агрегирует location-файлы. См. `HOW_TO_ADD_SCENES.md` для деталей.

---

## 1. Runtime-flow

```text
phone_map.gui_script
  → msg.post(ui_manager, "map_travel", { scene = "cafe_hub" })
  → message_flow.lua closes phone
  → scene_controller.enter("cafe_hub")
  → scenes.lua: M.scenes.cafe_hub
  → фон + hotspots
```

Source of truth:

| Что | Где |
|---|---|
| POI на карте и связанный `scene_id` | `phone_map.gui_script`, таблица `POI_SCENES` |
| Сцена, фон, hotspot'ы, `on_enter`, `npc` | `main/data/scenes/<location>.lua` (через фасад `main/scripts/scenes.lua`) |
| Ink-реакции hotspot'ов | `main/story/chapters/*.ink` |
| Правила добавления фонов | `HOW_TO_ADD_SCENES.md` |
| Внешний вид hotspot'ов | `HOTSPOT_VISUALS.md` |

---

## 2. Добавить или изменить хаб

### Шаг 1. Зарегистрировать фон

Фоны регистрируются не в этом документе. Используй `HOW_TO_ADD_SCENES.md`, раздел «Добавить fullscreen-фон».

Коротко: `bg_*` должен пройти всю цепочку:

```text
main/images/bg_name.jpg или .png
→ main/images/backgrounds/bg_name.atlas
→ rename_patterns: "bg_name=scene_bg"
→ go.property("bg_name_atlas", ...)
→ DEDICATED_BG_ATLAS_PROPS.bg_name
→ scenes.lua: bg = "bg_name"
```

Если хотя бы одного шага нет, фон может стать чёрным.

### Шаг 2. Проверить POI

В `phone_map.gui_script` должен быть POI, который ведёт в нужный `scene_id`:

```lua
poi_cafe = { scene = "cafe_hub", label = "Кафе" }
```

`label` — текст в подтверждении перехода. `scene` — ключ в `M.scenes`.

### Шаг 3. Описать сцену в `scenes.lua`

```lua
cafe_hub = {
    bg = "bg_cafe_morning",
    label = "Кафе",
    npc = "npc", -- если в сцене разрешён inventory verb=give

    on_enter = {
        knot = "sunday_date_cafe_arrival",
        condition = function(gs)
            return gs.get_flag("date_place_cafe")
               and not gs.get_flag("met_npc_sunday")
        end,
    },

    hotspots = {
        {
            id = "cafe_window_table",
            rect = { x = 680, y = 170, w = 300, h = 270 },
            label = "Столик у окна",
            icon = "left_click",
            action = { type = "ink_knot", knot = "cafe_window_table" },
        },
        {
            id = "leave_cafe",
            rect = { x = 0, y = 0, w = 170, h = 220 },
            label = "Выйти",
            icon = "arrow_back",
            action = { type = "ink_knot", knot = "leave_cafe" },
        },
    },
}
```

### Шаг 4. Написать Ink-knot'ы

Каждый `action = { type = "ink_knot", knot = "..." }` обязан иметь `=== ... ===` в подключённом `.ink`.

```ink
=== leave_cafe ===
# speaker:none
Пора идти.
# return_to_scene
-> DONE
```

---

## 3. Поля сцены

| Поле | Тип | Обязательно | Описание |
|---|---|---:|---|
| `bg` | `string` или `function(gs)->string` | да | Имя зарегистрированного фона или функция, возвращающая имя фона. |
| `label` | `string` | нет | Читаемое имя сцены. |
| `hotspots` | `table` | да | Интерактивные зоны. |
| `on_enter` | `table` | нет | Автомонолог при входе. |
| `objects` | `table` | нет | Спрайты поверх фона. |
| `npc` | `string` | нет | Цель для inventory verb `give`. |

---

## 4. Universal hubs

Universal hub используется, когда локация та же, hotspot'ы в основном общие, а меняется только фон по времени суток или сюжетному состоянию.

Пример: квартира.

```lua
local function is_apartment_night(gs)
    return gs.get_flag("sunday_evening_started")
       and not gs.get_flag("sunday_finished")
end

local function apartment_bg(room)
    return function(gs)
        if is_apartment_night(gs) then
            return "bg_apartment_" .. room .. "_night"
        end
        return "bg_apartment_" .. room .. "_morning"
    end
end

apartment_hub = {
    bg = apartment_bg("hall"),
    label = "Коридор",
    hotspots = { ... },
}
```

Правила:

- `bg`-функция должна возвращать только зарегистрированные `bg_*`.
- Если меняется только фон — используй universal hub.
- Если меняется порядок маршрута, набор обязательных действий или флаги дня — используй отдельный `scene_id`.
- Hotspot'ы по состояниям гейтятся через `visible_when` или `condition`.
- `scene_controller.get_current_bg()` возвращает уже разрешённый фон, поэтому side-knot'ы открываются на правильном фоне.

---

## 5. Hotspot: поля и действия

```lua
{
    id = "уникальный_id",
    rect = { x = 400, y = 200, w = 300, h = 400 },
    label = "Подпись",
    icon = "left_click",
    hotspot_style = STYLE_NEUTRAL,
    action = { type = "ink_knot", knot = "talk_to_barista" },

    visible_when = function(gs)
        return not gs.get_flag("item_taken")
    end,

    condition = function(gs)
        return gs.get_flag("door_unlocked")
    end,
}
```

| Поле | Поведение |
|---|---|
| `visible_when=false` | Hotspot полностью скрыт. Используй для взаимоисключающих состояний. |
| `condition=false` | Hotspot виден, но locked/тусклый и не кликается. Используй для обучения и закрытых действий. |

`action.type`:

| type | Поля | Что делает |
|---|---|---|
| `goto_scene` | `scene` | Переход в другую point-and-click сцену. |
| `ink_knot` | `knot` | Короткий Ink-монолог, потом `# return_to_scene`. |
| `set_flag` | `flag`, `value` | Поставить флаг в `game_state`. |
| `add_item` | `item` | Добавить предмет в инвентарь. |

---

## 6. Карта и POI lock

Карта может быть ограничена через Ink-теги:

```ink
# map:lock_to:poi_cafe   // разрешён только cafe
# map:allow:poi_park     // добавить park в allow-set
# map:lock_all           // заблокировать все POI
# map:lock:all           // то же самое, альтернативная запись
# map:allow:reset        // очистить allow-set: снова доступны все POI
```

Важно: если allow-set пустой, runtime считает, что доступны все POI, кроме отдельного режима `map:lock_all`. После `map:lock_all` можно открыть одну точку через `map:allow:POI_ID` или снять все ограничения через `map:allow:reset`. Future-хабы (`bar_hub`, `archive_hub` и т.п.) нельзя открывать игроку, пока у их hotspot'ов нет рабочих Ink-knot'ов. Для линейного маршрута лучше использовать `map:lock_to` или scripted commute без карты.

---

## 7. Текущие POI-хабы

| POI | scene_id | Статус |
|---|---|---|
| Дом | `apartment_hub` | Рабочий universal hub квартиры. |
| Работа | `work_hub` | Рабочий офисный entrypoint. |
| Кафе | `cafe_hub` | Воскресная встреча. |
| Парк | `park_hub` | Альтернативная воскресная встреча. |
| Магазин | `shop_hub` | Future / по маршруту после встречи. |
| Бар | `bar_hub` | Future, не открывать без готовых knot'ов. |
| Смотровая | `view_hub` | Вторник / крыша-слой. |
| Архив | `archive_hub` | Future, не открывать без готовых knot'ов. |

---

## 8. Чеклист хаба

- [ ] `scene_id` есть в `phone_map.gui_script → POI_SCENES`.
- [ ] `scene_id` есть в `scenes.lua → M.scenes`.
- [ ] Все `bg_*`, которые возвращает сцена, зарегистрированы в `ui_manager_v2.script` (`go.property` + `DEDICATED_BG_ATLAS_PROPS`).
- [ ] Все `ink_knot` из hotspot'ов существуют в подключённых `.ink`.
- [ ] Каждый `on_enter.condition` гасится флагом внутри соответствующего knot'а.
- [ ] В `ink_knot` из хаба последним тегом стоит `# return_to_scene`.
- [ ] Future POI закрыты через map allow-set или ещё не доступны игроку.
