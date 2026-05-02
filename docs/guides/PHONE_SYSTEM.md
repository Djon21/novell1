# Телефон — архитектура split-системы

Актуально на `2026-04-25`.  
Телефон разбит на 9 отдельных Defold GUI-компонентов на одном game object-е.

---

## Содержание

1. [Файлы и их роли](#1-файлы-и-их-роли)
2. [Как компоненты подключены к коллекции](#2-как-компоненты-подключены-к-коллекции)
3. [Поток сообщений: открытие](#3-поток-сообщений-открытие)
4. [Поток сообщений: переключение вкладок](#4-поток-сообщений-переключение-вкладок)
5. [Поток сообщений: SMS → открытие переписки](#5-поток-сообщений-sms--открытие-переписки)
6. [Поток сообщений: закрытие](#6-поток-сообщений-закрытие)
7. [Как app-скрипт тянет данные](#7-как-app-скрипт-тянет-данные)
8. [Как обновить данные в реальном времени](#8-как-обновить-данные-в-реальном-времени)
9. [Добавить новое приложение](#9-добавить-новое-приложение)
10. [Добавить ноды в существующую вкладку](#10-добавить-ноды-в-существующую-вкладку)
11. [Важно: acquire_input_focus и порядок инпута](#11-важно-acquire_input_focus-и-порядок-инпута)
12. [Карта — особый случай](#12-карта--особый-случай)
13. [Частые ошибки](#13-частые-ошибки)

---

## 1. Файлы и их роли

### Хром и лаунчер

| Файл | Роль |
|---|---|
| `phone_v2_root.gui` | Корпус телефона, статус-бар, 8 иконок приложений, кнопки X и Home |
| `phone_v2_root.gui_script` | Роутинг: открывает/закрывает app-компоненты, держит фокус инпута |

### Приложения (8 штук)

| GUI-файл | Script-файл | Данные из game_state |
|---|---|---|
| `phone_sms.gui` | `phone_sms.gui_script` | `gs.get_messages()` |
| `phone_call.gui` | `phone_call.gui_script` | `gs.get_call_log()` |
| `phone_notes.gui` | `phone_notes.gui_script` | `gs.get_clues()` |
| `phone_quests.gui` | `phone_quests.gui_script` | `gs.get_quests()` |
| `phone_mail.gui` | `phone_mail.gui_script` | `gs.get_mails()` |
| `phone_cam.gui` | `phone_cam.gui_script` | `gs.get_camera_feed()` |
| `phone_term.gui` | `phone_term.gui_script` | `gs.get_terminal_lines()` |
| `phone_map.gui` | `phone_map.gui_script` | показывает карту внутри телефона (132 ноды под `map_root`) |

### Архив (не в коллекции)

- `phone_v2.gui` + `phone_v2.gui_script` — старый монолит, остался на диске для справки,
  в коллекцию не подключён. Можно удалить после стабилизации сплита.
- `phone_map_beautiful.gui` — заготовка нового дизайна карты, пока не используется.

---

## 2. Как компоненты подключены к коллекции

Все 9 компонентов — дочерние GUI-компоненты одного game object-а `ui_manager_v2`
в `main_v2.collection`:

```
embedded_instances { id: "ui_manager_v2"
  data:
    "components { id: \"phone_v2\"     component: \"/main/gui/components_v2/phone_v2_root.gui\" }\n"
    "components { id: \"phone_sms\"    component: \"/main/gui/components_v2/phone_sms.gui\" }\n"
    "components { id: \"phone_call\"   component: \"/main/gui/components_v2/phone_call.gui\" }\n"
    "components { id: \"phone_map\"    component: \"/main/gui/components_v2/phone_map.gui\" }\n"
    "components { id: \"phone_notes\"  component: \"/main/gui/components_v2/phone_notes.gui\" }\n"
    "components { id: \"phone_quests\" component: \"/main/gui/components_v2/phone_quests.gui\" }\n"
    "components { id: \"phone_mail\"   component: \"/main/gui/components_v2/phone_mail.gui\" }\n"
    "components { id: \"phone_cam\"    component: \"/main/gui/components_v2/phone_cam.gui\" }\n"
    "components { id: \"phone_term\"   component: \"/main/gui/components_v2/phone_term.gui\" }\n"
```

Адресация компонентов с одного game object-а — через `"#component_id"`:

```lua
-- из phone_v2_root.gui_script:
msg.post("#phone_sms",  "open_app")   -- открыть SMS
msg.post("#phone_term", "close_app")  -- закрыть терминал

-- из любого app-скрипта:
msg.post("#ui_manager_v2", "phone_sms_viewed")  -- уведомить ui_manager
```

---

## 3. Поток сообщений: открытие

```
HUD (кнопка телефона)
  └─ msg.post("#ui_manager_v2", "open_phone")

ui_manager_v2.script
  └─ проверяет has_phone_access()
  └─ overlays.phone = true
  └─ msg.post("#phone_v2", "open_phone")

phone_v2_root.gui_script.on_message("open_phone")
  ├─ self.visible = true
  ├─ set_nodes_enabled(CHROME_NODES, true)   -- показать корпус/лаунчер
  ├─ update_notif()                           -- обновить "сообщений: N"
  └─ msg.post("#phone_sms", "open_app")       -- открыть SMS по умолчанию
     self.active_app = "sms"

phone_sms.gui_script.on_message("open_app")
  ├─ self.visible = true
  ├─ set_nodes_enabled(true)                  -- показать ноды SMS
  ├─ refresh()                                -- pull из game_state
  └─ msg.post("#ui_manager_v2", "phone_sms_viewed")  -- сбросить unread
```

---

## 4. Поток сообщений: переключение вкладок

Пользователь тапает иконку приложения (например, Задачи):

```
on_input в phone_v2_root.gui_script
  ├─ обнаружил клик на app5_bg (quests)
  ├─ msg.post("#ui_manager_v2", "phone_app_clicked", {id="quests"})
  │    ui_manager только логирует (для quests ничего не делает)
  └─ switch_app(self, "quests")
       ├─ close_active_app():
       │    msg.post("#phone_sms", "close_app")   -- закрыть текущую
       │    self.active_app = nil
       └─ open_app("quests"):
            msg.post("#phone_quests", "open_app") -- открыть новую
            self.active_app = "quests"

phone_quests.gui_script.on_message("open_app")
  ├─ self.visible = true
  ├─ set_nodes_enabled(true)
  └─ refresh()    -- gs.get_quests() → заполнить ноды
```

**Тап на уже открытое приложение** → возврат в SMS:

```lua
-- в switch_app():
if self.active_app == id then
    -- закрыть текущее, открыть sms
end
```

---

## 5. Поток сообщений: SMS → открытие переписки

Когда игрок тапает на строку переписки в SMS-приложении:

```
phone_sms.gui_script.on_input (тап на msg1_bg..msg4_bg)
  └─ msg.post("#ui_manager_v2", "sms_open_contact", { contact_id = "mila" })

ui_manager_v2.script.on_message("sms_open_contact")
  ├─ gs.mark_sms_read(contact_id)   -- ставит sms_<contact>_read=true
  ├─ close_phone(self)              -- закрывает телефон
  └─ run_side_dialogue_knot("sms_thread_mila")   -- прыгает в Ink
       -- knot должен лежать в chapters/*.ink
       -- завершается через # return_to_scene -> вернуться в текущую сцену
```

**Ink-knot для переписки** (`sms_thread_<contact_id>`) показывает сообщения,
предлагает варианты ответа через choices и выполняет `# sms:reply:contact:text`.

Пример: `sms_thread_mila` в `main/story/chapters/01_apartment.ink`:

```ink
=== sms_thread_mila ===
# speaker:none
Открываешь переписку. Мила написала утром:
«Есть планы на сегодня? Может, увидимся?»

* [«Давай. Напишу, как освобожусь.»]
    Тёплый ответ. Не обещаешь конкретику, но дверь открыта.
    # sms:reply:mila:Давай. Напишу, как освобожусь.
    -> sms_mila_sent
* [«Сейчас занят. Потом.»]
    Коротко. Без объяснений.
    # sms:reply:mila:Сейчас занят. Потом напишу.
    -> sms_mila_sent

= sms_mila_sent
# speaker:none
Сообщение отправлено.
# quest:done:reply_mila
# return_to_scene
-> DONE
```

> **Как добавить переписку с новым контактом:**
> 1. `# sms:add:<contact>:<текст>` — прислать входящее (из любого knot'а)
> 2. Написать knot `sms_thread_<contact>` в нужном `.ink`-файле
> 3. Готово — ui_manager найдёт knot по имени автоматически

---

## 6. Поток сообщений: закрытие


```
Пользователь тапает ✕

on_input в phone_v2_root.gui_script
  └─ msg.post("#ui_manager_v2", "close_phone")
       ui_manager_v2:
         overlays.phone = false
         msg.post("#phone_v2", "close_phone")   ← назад в root

phone_v2_root.gui_script.on_message("close_phone")
  ├─ close_active_app():
  │    msg.post("#phone_sms", "close_app")   -- или какой открыт
  ├─ set_nodes_enabled(CHROME_NODES, false)  -- скрыть корпус
  └─ self.visible = false
     (НЕ постим close_phone обратно в ui_manager — это создаст бесконечный loop)
```

---

## 7. Как app-скрипт тянет данные

Каждый app-скрипт автономен: при `open_app` сам запрашивает `game_state`
и заполняет свои ноды. Пример из `phone_quests.gui_script`:

```lua
local gs = require "main.scripts.game_state"

local function refresh(self)
    local list = gs.get_quests and gs.get_quests() or {}

    -- Заголовок
    if #list == 0 then
        set_text("v_quests_title", "ЗАДАЧИ [0]")
    else
        set_text("v_quests_title", "ЗАДАЧИ")
    end

    -- Слоты q1..q2
    for i = 1, QUEST_SLOTS do
        local prefix = "v_quests_q" .. i
        local has = list[i] ~= nil
        set_node_enabled(prefix .. "_bg",   has)
        set_node_enabled(prefix .. "_name", has)
        set_node_enabled(prefix .. "_desc", has)
        if has then
            local q = list[i]
            set_text(prefix .. "_name", q.title or "—")
            set_text(prefix .. "_desc", q.desc  or "")
        end
    end
end

function on_message(self, message_id, message, sender)
    if message_id == hash("open_app") then
        self.visible = true
        set_nodes_enabled(true)
        refresh(self)                        -- ← pull данных при открытии
    elseif message_id == hash("refresh_app") then
        if self.visible then refresh(self) end  -- ← pull при обновлении
    end
end
```

---

## 8. Как обновить данные в реальном времени

Когда Ink-тег (`# sms:add:`, `# note:add:` и т.д.) изменяет `game_state`,
`ui_manager_v2` посылает `refresh_phone` в root:

```lua
-- в ui_manager_v2 после обработки тегов:
msg.post(M.components.phone, "refresh_phone")
```

Root пересылает активному приложению:

```lua
-- phone_v2_root.gui_script:
elseif message_id == hash("refresh_phone") then
    update_notif(self)                              -- обновить счётчик
    if self.active_app then
        msg.post("#phone_" .. self.active_app, "refresh_app")  -- к активному
    end
```

Также напрямую из любого скрипта:

```lua
msg.post("/ui_manager_v2#phone_v2", "refresh_phone")
```

---

## 9. Добавить новое приложение

### 1. Создать GUI-файл

`phone_newapp.gui` — создать в Defold Editor (File → New → GUI File),  
указать скрипт `phone_newapp.gui_script`.

Структура нод: все ноды top-level (без общего root-а) **или** один root-нод
с детьми (тогда в скрипте скрывать только root).

### 2. Создать скрипт

```lua
-- phone_newapp.gui_script
local gs = require "main.scripts.game_state"

local NODE_IDS = {
    "newapp_title",
    "newapp_item1_bg", "newapp_item1_text",
    -- все ноды файла
}

local function get_node(id)
    local ok, n = pcall(gui.get_node, id)
    if ok then return n end
    return nil
end

local function set_node_enabled(id, enabled)
    local n = get_node(id)
    if n then gui.set_enabled(n, enabled) end
end

local function set_nodes_enabled(enabled)
    for _, id in ipairs(NODE_IDS) do set_node_enabled(id, enabled) end
end

local function set_text(id, s)
    local n = get_node(id)
    if n then gui.set_text(n, s or "") end
end

local function refresh(self)
    -- тянем из game_state
    local data = gs.get_newapp_data and gs.get_newapp_data() or {}
    set_text("newapp_title", "NEW APP")
    -- заполняем ноды...
end

function init(self)
    self.visible = false
    set_nodes_enabled(false)
end

function on_message(self, message_id, message, sender)
    if message_id == hash("open_app") then
        self.visible = true
        set_nodes_enabled(true)
        refresh(self)
    elseif message_id == hash("close_app") then
        self.visible = false
        set_nodes_enabled(false)
    elseif message_id == hash("refresh_app") then
        if self.visible then refresh(self) end
    end
end

function on_input(self, action_id, action)
    if not self.visible then return false end
    return false
end
```

### 3. Добавить компонент в коллекцию

Открыть `main_v2.collection` в Defold Editor, найти `ui_manager_v2`,
добавить GUI Component → выбрать `phone_newapp.gui`, дать id `phone_newapp`.

Или вручную в текстовом виде — добавить строку в `data` поле embedded instance:
```
"components {\n"
"  id: \"phone_newapp\"\n"
"  component: \"/main/gui/components_v2/phone_newapp.gui\"\n"
"}\n"
```

### 4. Добавить иконку в лаунчер

В `phone_v2_root.gui_script` добавить в таблицы:

```lua
local APP_COMPONENT = {
    -- ... существующие ...
    newapp = "#phone_newapp",   -- ← новый
}

local APPS = {
    -- ... существующие ...
    { key = "app9", id = "newapp" },  -- ← новый тайл
}
```

В `phone_v2_root.gui` добавить ноды `app9_bg`, `app9_icon`, `app9_label`
и добавить их в `CHROME_NODES` в скрипте.

---

## 10. Добавить ноды в существующую вкладку

Пример: добавляем третью карточку квеста в `phone_quests.gui`.

1. **Defold Editor**: открыть `phone_quests.gui`, добавить ноды  
   `v_quests_q3_bg`, `v_quests_q3_name`, `v_quests_q3_desc`.

2. **`phone_quests.gui_script`**: добавить в `NODE_IDS`:
   ```lua
   "v_quests_q3_bg", "v_quests_q3_name", "v_quests_q3_desc",
   ```
   Увеличить слоты:
   ```lua
   local QUEST_SLOTS = 3  -- было 2
   ```

Больше ничего менять не нужно — остальная логика уже параметризована по `QUEST_SLOTS`.

> **Правило:** если нода добавлена в `.gui`-файл, она должна быть добавлена  
> в `NODE_IDS` скрипта. Иначе нода останется видимой при старте.

---

## 11. Важно: `acquire_input_focus` и порядок инпута

В Defold `acquire_input_focus` строит **LIFO-стек**: последний взявший фокус
получает инпут **первым**. Если он вернул `false` — инпут идёт дальше по стеку.

`phone_v2_root.gui_script` берёт фокус в `init` **и никогда не отдаёт**:

```lua
function init(self)
    msg.post(".", "acquire_input_focus")  -- всегда первый в стеке
    self.visible = false
    ...
end
```

Когда телефон **закрыт**: `self.visible = false` → `on_input` возвращает `false`
→ инпут проходит дальше → меню и HUD работают нормально.

Когда телефон **открыт**: `self.visible = true` → root обрабатывает инпут
и возвращает `true` (поглощает всё), пока телефон открыт.

**Нельзя:**
- Убирать `acquire_input_focus` из `init` root-скрипта — меню перестанет реагировать.
- Добавлять `acquire_input_focus` в `init` app-скриптов — лишние компоненты в стеке.
- Вызывать `release_input_focus` в root при закрытии телефона — после release
  root выпадает из стека и инпут больше не проходит через него корректно.

---

## 12. Карта — внутри телефона

Иконка карты (app3) в лаунчере **открывает `phone_map.gui` внутри телефонного фрейма**,
как любое другое приложение:

```lua
-- phone_v2_root.gui_script:
local EXTERNAL_APPS = {}   -- map здесь больше нет

-- on_input при клике на app3:
msg.post(UI_MGR, "phone_app_clicked", { id = "map" })   -- ui_manager ничего не делает
switch_app(self, "map")                                  -- → open_app → #phone_map
```

`phone_map.gui` имеет 132 ноды под единым корнем `map_root`.
`phone_map.gui_script` скрывает/показывает только `map_root` —
Defold автоматически распространяет `enabled = false` на все дочерние узлы.

### Вызов карты из Ink

Для сюжетного вызова карты используй тег:

```ink
# phone:map
```

Он открывает телефон и сразу переключает его на приложение карты (`phone_map.gui`). Игрок выбирает POI, `phone_map.gui_script` отправляет `map_travel`, после чего `ui_manager_v2` закрывает телефон и открывает выбранный hub через `scene_controller.enter(scene_id)`.

Универсальная форма для других приложений:

```ink
# phone:app:map
# phone:app:sms
# phone:app:notes
```

Старый прямой сценарный вызов внешней карты не использовать для нового контента: карта должна открываться внутри телефона.

---

## 13. Частые ошибки

| Симптом | Причина | Решение |
|---|---|---|
| Ноды телефона видны поверх меню | Нода добавлена в `.gui` но не в `NODE_IDS` скрипта | Добавить в `NODE_IDS` |
| Карта открывается как внешний оверлей | `map` в `EXTERNAL_APPS` / обработчик в `ui_manager_v2` | Убрать `map` из `EXTERNAL_APPS`; убрать `id=="map"` из `phone_app_clicked` |
| Меню не реагирует на клики | `acquire_input_focus` убран из `init` root-скрипта | Восстановить, не добавлять `release` при закрытии |
| При закрытии телефона меню не работает | `release_input_focus` вызывается в `close_phone` | Убрать `release_input_focus` |
| Данные в вкладке не обновляются | Нет вызова `refresh(self)` в `open_app` | Добавить `refresh(self)` в хэндлер `open_app` |
| `refresh_phone` не обновляет данные | Активная вкладка не совпадает с той что на экране | `refresh_phone` обновляет только `active_app` — открой нужную вкладку |
| `gui.get_node` крашится | Нода с таким id нет в этом GUI-файле | Используй `pcall(gui.get_node, id)` — обёртка `get_node()` уже есть в каждом скрипте |
