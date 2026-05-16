# Templates

Готовые copy-paste блоки для типовых задач. AI должен **брать паттерн отсюда**, а не выдумывать структуру из памяти.

Все имена в шаблонах — заглушки (`<PLACEHOLDER>`). Реальные значения подбирай по контексту, проверяя существующие ID в `PROJECT_INVENTORY.md`.

---

## 1. Новый ink-knot

### Минимальный knot

```ink
=== <knot_name> ===
# bg:<bg_name> # speaker:none
Описание сцены / нарратив в speaker:none.

# speaker:mc
Реплика главного героя.

# speaker:npc
Реплика NPC.

# return_to_scene
-> DONE
```

### Knot с условиями и выбором

```ink
=== <knot_name> ===
# bg:<bg_name> # speaker:none
{<flag_name>:
    Текст если флаг есть.
- else:
    Текст если флага нет.
}

* [Вариант 1]
    # speaker:mc
    Текст выбора 1.
    ~ TRUST = TRUST + 1
    -> <knot_continuation>

* [Вариант 2]
    # speaker:mc
    Текст выбора 2.
    -> <knot_continuation>

=== <knot_continuation> ===
# set_flag:<flag_name>=true
~ <flag_name> = true
# return_to_scene
-> DONE
```

### Knot который выдаёт предмет

```ink
=== take_<item> ===
# bg:<bg_name> # speaker:none
Описание взятия предмета.

# add_item:<item_id>
# set_flag:<item>_taken=true
~ <item>_taken = true
# return_to_scene
-> DONE
```

---

## 2. Новый hotspot

```lua
{
    id = "<hotspot_id>",
    rect = { x = 100, y = 200, w = 150, h = 150 },
    label = "<Подпись>",
    icon = "<icon_name>",        -- из icons table в _shared.lua
    hotspot_style = STYLE_INSPECT,  -- или STYLE_NAV / STYLE_PICKUP / STYLE_USE / STYLE_STORY
    action = { type = "ink_knot", knot = "<knot_name>" },

    -- Опциональные поля:
    icon_offset_x = 0,
    icon_offset_y = -4,
    visible_when = function(gs)
        return gs.get_flag("<prereq_flag>")
           and not gs.get_flag("<done_flag>")
    end,
    condition = function(gs)
        return not gs.get_flag("<temporary_lock_flag>")
    end,
},
```

### Action variants

```lua
-- Переход в другую сцену
action = { type = "goto_scene", scene = "<scene_id>" },

-- Установка флага без диалога
action = { type = "set_flag", flag = "<flag_name>", value = true },

-- Выдача предмета без диалога
action = { type = "add_item", item = "<item_id>" },
```

---

## 3. Новая exploration-сцена (в `main/data/scenes/<file>.lua`)

```lua
<scene_id> = {
    bg = "<bg_atlas_name>",     -- например "bg_park_riverside_bench_morning"
    label = "<Подпись локации>",
    on_enter = {                 -- опционально — авто-knot при входе
        knot = "<intro_knot>",
        condition = function(gs)
            return not gs.get_flag("<scene_intro_seen>")
        end,
    },
    hotspots = {
        {
            id = "<hotspot1_id>",
            rect = { x = ..., y = ..., w = ..., h = ... },
            label = "...",
            icon = "...",
            hotspot_style = STYLE_INSPECT,
            action = { type = "ink_knot", knot = "..." },
        },
        -- ещё хотспоты ...
    },
    objects = {                  -- опционально — overlay-спрайты на фоне
        {
            id = "<object_id>",
            image = "<sprite_id>",
            pos = { x = ..., y = ... },
            size = { w = ..., h = ... },
            visible_when = function(gs) return ... end,
        },
    },
},
```

Зарегистрировать в `main/scripts/scenes.lua` если файл новый.

---

## 4. Новая CHARS-запись (диалоговый портрет)

В `main/gui/components_v2/dialogue_v2.gui_script` таблица `CHARS`:

```lua
<char_id> = {
    color = vmath.vector4(<R>, <G>, <B>, 1.0),    -- 0..1, акцент nameplate
    icon = string.char(0xEE, 0x9F, 0xBB),         -- fallback Material Icon
    atlas = "<char_id>",                            -- texture binding из .gui
    portrait = "<char_id>_idle",                    -- default static frame
    portrait_idle  = "<char_id>_idle",              -- если анимированный
    portrait_blink = "<char_id>_blink",
    portrait_talk  = "<char_id>_talk",
},

-- Кириллический алиас для использования в # speaker:Имя
["<имя_кириллицей>"] = {
    color = vmath.vector4(<R>, <G>, <B>, 1.0),
    icon = string.char(0xEE, 0x9F, 0xBB),
    atlas = "<char_id>",
    portrait = "<char_id>_idle",
    portrait_idle  = "<char_id>_idle",
    portrait_blink = "<char_id>_blink",
    portrait_talk  = "<char_id>_talk",
},
```

Плюс — texture binding в `dialogue_v2.gui` (это GUI-редактор, не код):
```
textures {
  name: "<char_id>"
  texture: "/main/images/portraits/<char_id>/<char_id>.atlas"
}
```

Полный pipeline (генерация спрайтов, атлас, нейронка) — `HOW_TO_ADD_PORTRAITS.md` / `HOW_TO_ANIMATE_PORTRAITS.md`.

---

## 5. Scene character (full-figure на фоне)

В `main/scripts/scene_characters.lua`:

```lua
-- В SCENE_GROUPS (если новая локация-группа):
SCENE_GROUPS = {
    <scene_id> = "<group>",
    -- если в группе несколько sub-сцен:
    <scene_id_2> = "<group>",
}

-- В SCENES:
SCENES = {
    <group> = {
        <char>_<pose> = {
            atlas  = "char_<char>",
            sprite = "<pose>",                 -- image id в атласе
            x = 820, y = 340, w = 95, h = 340, -- top-left + size в game coords 1280×720
            -- Опционально — клик запускает knot:
            action = { type = "ink_knot", knot = "<knot_name>" },
            -- Опционально — после события клик отключается:
            clickable_when = function(gs)
                return not gs.get_flag("<event_done_flag>")
            end,
        },
    },
}
```

В ink:
```ink
# scene_char:show:<group>:<char>_<pose>
# scene_char:hide:<group>:<char>_<pose>
# scene_char:hide_all
```

Auto-hide при выходе из группы — встроенное поведение, явный hide не нужен при travel'е.

Полный pipeline — `HOW_TO_ADD_SCENE_CHARACTERS.md`.

---

## 6. SMS / Messenger переписка

### Простое SMS

```ink
# sms:add:<contact_id>:Текст входящего SMS
```

### Игрок отвечает (ставит auto-flag `sms_<contact>_replied`)

```ink
# sms:reply:<contact_id>:Текст ответа от игрока
```

### Полный thread c условием

```ink
=== sms_thread_<contact> ===
{<contact>_replied:
    Здесь обработка ПОСЛЕ ответа.
    -> DONE
}

# sms:add:<contact>:Первое сообщение от NPC.
# sms:add:<contact>:Второе сообщение.

* [Ответ 1]
    # sms:reply:<contact>:Текст ответа 1
    # sms:add:<contact>:Реакция NPC на ответ 1.
* [Ответ 2]
    # sms:reply:<contact>:Текст ответа 2
    # sms:add:<contact>:Реакция NPC на ответ 2.

# return_to_scene
-> DONE
```

Messenger аналогично через `# msg:add:...` / `# msg:reply:...`.

---

## 7. Открыть карту телефона + выбор POI

Карта — это приложение внутри телефона. Открывается через `# phone:map`
(или само, если игрок тапнул иконку карты). После выбора POI игрок попадает
в нужную сцену через POI_SCENES mapping (см. блок 9). Управление доступностью
POI — через `# map:allow:` / `# map:lock_to:` / `# map:lock_all`:

```ink
=== <knot_offering_choice> ===
# bg:<current_bg> # speaker:none
Описание момента, когда нужно выбрать куда идти.

# map:allow:reset
# map:allow:poi_cafe
# map:allow:poi_park
# phone:map
-> DONE
```

Чтобы ограничить карту одной точкой (например, форсировать переход домой):
```ink
# map:lock_to:poi_home
# phone:map
```

`# map:hub:KNOT` (standalone-карта с fallback-knot) **больше не поддерживается** —
старая отдельная карта удалена. Если нужен общий «после-travel» knot для нескольких
POI, заведи его как обычный narrative-knot, в который игрок попадёт через
`on_enter` следующей сцены.

---

## 8. Использование предмета на хотспоте (`use X on Y`)

В `91_inventory_actions.ink`:

```ink
=== inv_use_<item>_on_<hotspot_id> ===
# bg:<current_bg> # speaker:none
Описание реакции.

# remove_item:<item>           -- если предмет одноразовый
# set_flag:<combo_done>=true
~ <combo_done> = true
# return_to_scene
-> DONE
```

Имя knot'а: **`inv_use_<item>_on_<hotspot_id>`** — это convention, по нему движок ищет реакцию автоматически когда игрок armed-with-item кликает на hotspot.

---

## 9. Phone Map POI (`POI_SCENES` в phone_map.gui_script)

```lua
POI_SCENES = {
    -- ...существующие...
    poi_<new_location> = { scene = "<scene_id>", label = "Подпись на карте" },
}
```

Затем разрешать в ink:
```ink
# map:allow:poi_<new_location>
```

Если POI должен быть доступен только при условии — управлять через `map:allow:` / `map:lock_to:` в ink.

---

## Memo

- **Всегда** проверяй существующие имена в `PROJECT_INVENTORY.md` перед добавлением нового
- **Не** создавай новый tag type / action type без согласования (это код, не сценарий)
- **Не** меняй структуру файлов сцены / CHARS наугад — есть конвенции, см. WRITING_RULES
- Если нужна новая фича (новый tag, новый shape хотспота, etc.) — это **отдельная задача** на код, а не часть сценарной правки
