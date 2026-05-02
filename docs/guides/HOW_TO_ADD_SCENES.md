# Как добавить новую сцену и фон

> Один файл-инструкция: добавление fullscreen-фонов, point-and-click сцен,
> hotspot'ов, scene objects. Поглотил `HOW_TO_ADD_BACKGROUNDS.md` и
> `BACKGROUND_SYSTEM_MIGRATION_PLAN.md`.

---

## Содержание

1. [Архитектура — что где лежит и почему](#1-архитектура--что-где-лежит-и-почему)
2. [Добавить fullscreen-фон](#2-добавить-fullscreen-фон)
3. [Добавить point-and-click сцену](#3-добавить-point-and-click-сцену)
4. [Hotspots — справочник полей и actions](#4-hotspots--справочник-полей-и-actions)
5. [Scene objects (overlay-спрайты)](#5-scene-objects-overlay-спрайты)
6. [Координаты и F1-редактор](#6-координаты-и-f1-редактор)
7. [Привязка сцены к Ink](#7-привязка-сцены-к-ink)
8. [Чеклист перед коммитом](#8-чеклист-перед-коммитом)

---

## 1. Архитектура — что где лежит и почему

### Структура ассетов

```
main/images/
├── bg_apartment_bedroom_morning.jpg    ← исходные .jpg
├── bg_kitchen.jpg
├── ...
├── backgrounds/                        ← по одному atlas на фон
│   ├── bg_apartment_bedroom_morning.atlas
│   ├── bg_kitchen.atlas
│   └── ...
├── hotspots.atlas                      ← hotspot_circle, hotspot_ring, hotspot_dot
├── scene_objects.atlas                 ← mobile и другие overlay-спрайты
└── v2.atlas                            ← UI-ассеты dialogue_v2 (портреты, рамки)
```

**Правило:** `1 fullscreen background = 1 atlas`. Никаких сборных «backgrounds.atlas».

### Почему так

Старый общий `backgrounds.atlas` плохо масштабировался для `1920x1080`-картинок:
- атлас рос до больших power-of-two размеров
- память на платформах расходовалась хуже, чем на наборе отдельных
- мелкие UI-ассеты были связаны с тяжёлым набором сцен

Сейчас фоны переключаются runtime'ом — `ui_manager_v2` через `go.set` подменяет нужный atlas в текущем texture slot dialogue_v2.

### Runtime-flow смены фона

```
Ink-тег # bg:bg_kitchen  /  scenes.lua bg = "bg_kitchen"
        │
        ▼
ui_manager_v2.post_dialogue_background(bg_name)
        │  msg.post сам себе
        ▼
ui_manager_v2.apply_dialogue_bg(bg_name)
        │  go.set(dialogue, "textures", atlas, { key = "backgrounds" })
        │  msg.post(dialogue, "set_background", { name, animation = "scene_bg" })
        ▼
dialogue_v2.gui_script
        │  gui.play_flipbook(scene_bg_node, "scene_bg")
        ▼
[фон на экране]
```

### Критичный инвариант: `go.set` только из `.script` контекста

`scene_controller.set_background()` зовётся из `hotspots_v2.gui_script`
(callback на клик хотспота) — это **gui_script** контекст, и `go.*` API оттуда
недоступно.

Поэтому `post_dialogue_background` НЕ вызывает `go.set` напрямую — он шлёт
`msg.post(self.self_url, "apply_dialogue_bg", {...})`. Хендлер исполняется
уже в `.script` контексте и безопасно дёргает `go.set`.

**Любые изменения swap-логики атласа должны сохранять разделение:**
`callback из gui_script → msg.post → script on_message → go.set`.

### Почему `scene_bg` — общий animation id

Каждый dedicated atlas внутри переименовывает свою картинку в общий
animation id `scene_bg` через `rename_patterns`. Это позволяет
`dialogue_v2` не знать имена конкретных фонов — всегда играет
`gui.play_flipbook(node, "scene_bg")`. Подмена atlas происходит на
уровне ui_manager.

---

## 2. Добавить fullscreen-фон

### Шаг 1: положить картинку

```
main/images/bg_my_scene.jpg
```

Требования:
- формат `JPG` или `PNG`
- рекомендуемое разрешение `1920x1080`
- имя файла `bg_<name>.jpg` (префикс `bg_` обязателен)

### Шаг 2: создать dedicated atlas

`main/images/backgrounds/bg_my_scene.atlas`:

```text
images {
  image: "/main/images/bg_my_scene.jpg"
}
rename_patterns: "bg_my_scene=scene_bg"
extrude_borders: 2
```

**Обязательно:**
- один atlas = один fullscreen background
- `rename_patterns: "bg_my_scene=scene_bg"` — runtime animation id всегда `scene_bg`
- НЕ добавлять в `archive/legacy_runtime/main/images/backgrounds.atlas` (он архивный)

### Шаг 3: зарегистрировать в `ui_manager_v2.script`

В верхней части файла (там где `go.property`):

```lua
go.property("bg_my_scene_atlas", resource.atlas("/main/images/backgrounds/bg_my_scene.atlas"))
```

И в таблицу `DEDICATED_BG_ATLAS_PROPS`:

```lua
local DEDICATED_BG_ATLAS_PROPS = {
    ...
    bg_my_scene = "bg_my_scene_atlas",
}
```

Без этого:
- `go.property` не объявлен → ресурс не попадёт в bundle на HTML5
- Записи в `DEDICATED_BG_ATLAS_PROPS` нет → runtime-switch не найдёт атлас → фон чёрный + warning в консоли

### Шаг 4: использовать

В Ink:
```ink
# bg:bg_my_scene
```

В сцене:
```lua
my_scene = {
    bg = "bg_my_scene",
    hotspots = { ... },
}
```

### Правило именования

Логическое имя проходит через всю цепочку без изменений:

| Где | Значение |
|---|---|
| Файл картинки | `bg_my_scene.jpg` |
| Atlas | `bg_my_scene.atlas` |
| `rename_patterns` | `"bg_my_scene=scene_bg"` |
| `go.property` | `"bg_my_scene_atlas"` |
| `DEDICATED_BG_ATLAS_PROPS` | `bg_my_scene = "bg_my_scene_atlas"` |
| Ink-тег | `# bg:bg_my_scene` |
| `scenes.lua` | `bg = "bg_my_scene"` |

---

## 3. Добавить point-and-click сцену

Сцены описываются в `main/scripts/scenes.lua`, исполняются `scene_controller.lua`,
рендерятся через `ui_manager_v2.script` + `hotspots_v2.gui_script`.

### Лимиты текущего runtime

- **6** hotspot'ов на сцену максимум
- **4** scene objects на сцену максимум
- координатная система: `1280x720`, origin — **левый нижний угол**

Лишние элементы тихо отбрасываются на стороне UI, пока лимиты не расширены в `ui_manager_v2.script`.

### Базовая структура сцены

```lua
my_room = {
    bg = "bg_my_room",         -- имя фона из §2
    label = "Комната",         -- опционально (для nav/exits)
    on_enter = { ... },        -- опционально, см. §3.2
    objects = { ... },         -- опционально, см. §5
    hotspots = { ... },        -- обычно обязательно
    exits = { ... },           -- опционально
}
```

### 3.1 Минимальный пример

```lua
my_room = {
    bg = "bg_my_room",
    label = "Комната",
    hotspots = {
        {
            id = "back_to_corridor",
            rect = { x = 30, y = 30, w = 140, h = 80 },
            label = "Назад",
            icon = "",
            action = { type = "goto_scene", scene = "apartment_hub" },
        },
    },
}
```

### 3.2 Автотриггер при входе (`on_enter`)

```lua
on_enter = {
    knot = "enter_kitchen_morning_first",
    condition = function(gs)
        return not gs.get_flag("kitchen_morning_seen")
    end,
}
```

> **Важно:** соответствующий ink-knot обязан выставить флаг, который проверяет `condition` — иначе вечный цикл. См. §10 в `HOW_TO_WRITE_INK.md`.

### 3.3 Переходы между сценами

Игра — point-and-click, переходы через hotspots с `goto_scene`:

```lua
{
    id = "to_kitchen",
    rect = { x = 95, y = 0, w = 225, h = 680 },
    label = "На кухню",
    icon = "",
    action = { type = "goto_scene", scene = "kitchen" },
},
```

Возврат — такой же hotspot с обратной сценой.

---

## 4. Hotspots — справочник полей и actions

### Поля

| Поле | Тип | Описание |
|---|---|---|
| `id` | string | Уникальный идентификатор внутри сцены |
| `rect` | `{ x, y, w, h }` | Прямоугольник в `1280x720`, origin — левый-нижний |
| `label` | string | Подпись (показывается над hotspot) |
| `icon` | string | Material Icon glyph (UTF-8) или `""` |
| `action` | table | Действие по клику, см. ниже |
| `condition(gs)` | function?→bool | Если `false` — hotspot **виден, но locked** |
| `visible_when(gs)` | function?→bool | Если `false` — hotspot **полностью скрыт** |

`condition` vs `visible_when`: первый показывает «нельзя пока» (полезно когда у игрока должна быть инфа что тут что-то есть), второй — для «этого вообще нет до выполнения условия».

### Поддерживаемые `action.type`

#### Переход в другую сцену

```lua
action = { type = "goto_scene", scene = "kitchen" }
```

#### Установка флага

```lua
action = { type = "set_flag", flag = "door_opened", value = true }
```

#### Инвентарь

```lua
action = { type = "add_item",    item = "key" }
action = { type = "remove_item", item = "key" }
```

#### Запуск Ink-knot'а

```lua
action = { type = "ink_knot", knot = "take_phone" }
```

Используется для коротких монологов и осмотров. Knot должен заканчиваться `# return_to_scene`, иначе игрок застрянет в диалоге.

#### Закрытие телефона

```lua
action = { type = "phone_close" }
```

> **Важно:** телефон **не является сценой**. Не используйте телефон как navigation target. Открывается через UI (`phone_v2`) или Ink-теги телефона (`# phone:map`, `# phone:app:NAME`).

### Пример с `condition`

```lua
{
    id = "exit_door",
    rect = { x = 390, y = 130, w = 175, h = 365 },
    label = "Выйти",
    icon = "",
    action = { type = "ink_knot", knot = "leave_apartment" },
    condition = function(gs)
        return gs.has_item("phone") and gs.get_flag("coffee_drunk")
    end,
}
```

---

## 5. Scene objects (overlay-спрайты)

Это отдельные спрайты поверх фона: телефон на тумбочке, кружка на столе и т.п.

### Описание в `scenes.lua`

```lua
objects = {
    {
        id = "phone_obj",
        image = "mobile",                    -- имя flipbook'а из scene_objects.atlas
        pos = { x = 385, y = 260 },          -- левый-нижний угол
        size = { w = 52, h = 22 },
        visible_when = function(gs)
            return gs.get_flag("coffee_drunk") and not gs.has_item("phone")
        end,
    },
}
```

### Добавить новый scene object спрайт

1. Положи `.png` в `main/images/`
2. В `main/images/scene_objects.atlas` добавь:
   ```text
   images { image: "/main/images/<name>.png" }
   ```
3. В `scenes.lua` укажи `image = "<name>"`

`hotspots_v2.gui` уже подключает `scene_objects.atlas` как texture slot — отдельная регистрация в `ui_manager_v2.script` **не нужна** (это не fullscreen background).

### Хитпоинты для спрайтов

- НЕ называем `bg_*` (этот префикс зарезервирован для fullscreen)
- НЕ оформляем как отдельный fullscreen atlas
- НЕ кладём в `archive/legacy_runtime/main/images/backgrounds.atlas`

---

## 6. Координаты и F1-редактор

Все координаты hotspot'ов и scene objects — в системе `1280x720`, origin **левый-нижний угол**.

Для подгонки координат на лету используйте F1-редактор:

1. Запустить игру
2. Войти в нужную exploration-сцену
3. Нажать `F1`
4. Управление:
   - `Tab` — следующий элемент
   - `←` `→` `↑` `↓` — двигать
   - `[` / `]` — менять ширину
   - `;` / `'` — менять высоту
   - `P` — напечатать координаты в консоль (готовая Lua-строка для вставки в `scenes.lua`)

Полный гайд: `docs/guides/F1_HOTSPOT_EDITOR.md`.

---

## 7. Привязка сцены к Ink

Сцена попадает на экран либо через ink-тег `# explore:`, либо через `# goto_scene:`:

```ink
=== apartment_hub ===
# bg:bg_apartment_bedroom_morning # explore:apartment_hub # speaker:none
Коридор. Тихо.
-> DONE
```

`# explore:apartment_hub` отдаёт управление `scene_controller`. Ink-сторона переходит в режим «ждёт».

Подробности про теги, on_enter и `# return_to_scene` — в `docs/guides/HOW_TO_WRITE_INK.md`.

---

## 8. Чеклист перед коммитом

### Если добавлял фон

- [ ] Картинка лежит в `main/images/bg_<name>.jpg`
- [ ] Создан atlas `main/images/backgrounds/bg_<name>.atlas` с `rename_patterns: "bg_<name>=scene_bg"`
- [ ] В `ui_manager_v2.script` добавлен `go.property("bg_<name>_atlas", resource.atlas(...))`
- [ ] В `DEDICATED_BG_ATLAS_PROPS` добавлена запись `bg_<name> = "bg_<name>_atlas"`
- [ ] Имя `bg_<name>` совпадает в atlas, Ink и `scenes.lua`
- [ ] Фон проверен в игре (не чёрный, без WARN в консоли)

### Если добавлял сцену

- [ ] Фон оформлен (см. выше) или используется существующий
- [ ] `scene_id` добавлен в `scenes.lua`, имя уникально
- [ ] У всех hotspot'ов уникальные `id` внутри сцены
- [ ] Сцена укладывается в лимиты `6` hotspot'ов / `4` objects
- [ ] Все knot'ы из `action.ink_knot` реально существуют в Ink
- [ ] `condition` / `visible_when` проверены в игре
- [ ] Координаты подогнаны через F1-редактор
- [ ] Если есть `on_enter.condition` — соответствующий knot выставляет нужный флаг (иначе цикл)

### Если добавлял scene object

- [ ] `.png` лежит в `main/images/`
- [ ] `images { image: ... }` добавлен в `main/images/scene_objects.atlas`
- [ ] В `scenes.lua` `image = "<name>"` совпадает с именем в atlas
- [ ] `pos` и `size` в координатах `1280x720`

---

## Связанные документы

- `docs/guides/HOW_TO_WRITE_INK.md` — теги, knot'ы, флаги, on_enter, return_to_scene
- `docs/guides/F1_HOTSPOT_EDITOR.md` — горячие клавиши редактора
- `docs/guides/GRAPHICS_GUIDE.md` — общие правила по графике
