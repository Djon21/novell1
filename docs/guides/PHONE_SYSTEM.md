# Телефон — архитектура split-системы

Актуально на `2026-05`.  
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
| `phone_sms.gui` | `phone_sms.gui_script` | `gs.get_messages()` (per-contact thread через `gs.get_sms()`) |
| `phone_messenger.gui` | `phone_messenger.gui_script` | `gs.get_msg_chats()` / `gs.get_msg(chat_id)`, metadata из `CHAT_META` |
| `phone_call.gui` | `phone_call.gui_script` | `gs.get_call_log()` |
| `phone_notes.gui` | `phone_notes.gui_script` | `gs.get_clues()` |
| `phone_quests.gui` | `phone_quests.gui_script` | `gs.get_quests()` |
| `phone_mail.gui` | `phone_mail.gui_script` | `gs.get_mails()` |
| `phone_term.gui` | `phone_term.gui_script` | `gs.get_terminal_lines()` |
| `phone_map.gui` | `phone_map.gui_script` | POI-кружки крутятся для разрешённых; runtime allow-set из `gs.map_is_poi_allowed()` |

### GUI Templates (clone_tree подход)

Большие phone-приложения вынесены в **GUI templates** — отдельные `.gui` файлы
с прототипом строки/чата, которые подключаются как ноды-`type: TEMPLATE`:

| Хост (.gui) | Templates | Что внутри |
|---|---|---|
| `phone_sms.gui` | `phone_sms_list_template.gui` + `phone_sms_thread_template.gui` | список тредов + thread-сообщения |
| `phone_messenger.gui` | `phone_messenger_list_template.gui` + `phone_messenger_chat_template.gui` | список чатов + bubble-treads |

В .gui редакторе каждый template даёт ОДИН прототип (`chat1_*`, `bub1_*`,
`msg1_*`). Дополнительные слоты (chat2..chat7, bub2..bub8) создаются в
скрипте через `gui.clone_tree(prototype_root)` в `init`, и удаляются в `final`
через `gui.delete_node`. Идентификаторы клонов лежат в локальной таблице,
обращение к ним идёт через wrapper `get_node()` который разрешает виртуальные id
вида `chat3_name` → реальную ноду клона #3.

То же самое для `phone_quests` — он использует `clone_tree` для динамического
рендера карточек квестов.

Преимущество: GUI редактор остаётся простым (один прототип строки), а runtime
вы можете показывать столько слотов сколько влезает в видимую область.

### Архив (не в коллекции)

- `phone_v2.gui` + `phone_v2.gui_script` — старый монолит, остался на диске для справки,
  в коллекцию не подключён. Можно удалить после стабилизации сплита.
- `phone_map_beautiful.gui` — заготовка нового дизайна карты, пока не используется.

Удалены в мае 2026: `phone_cam.gui`/`.gui_script` и весь camera-channel
в game_state (set/get/reset_camera_feed), парсинг `# camera:` ink-тега,
обработчик в dm_commands. Заменены полноценно на `phone_messenger`.

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
    "components { id: \"phone_messenger\" component: \"/main/gui/components_v2/phone_messenger.gui\" }\n"
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

ui_manager_v2.script -> message_flow.lua -> phone_flow.lua
  └─ проверяет has_phone_access()
  └─ overlays.phone = true
  └─ msg.post("#phone_v2", "open_phone")

phone_v2_root.gui_script.on_message("open_phone")
  ├─ self.visible = true
  ├─ set_nodes_enabled(CHROME_NODES, true)   -- показать корпус/лаунчер
  ├─ update_notif()                           -- бейджи + статус-бар
  └─ msg.post("#phone_sms", "open_app")       -- открыть SMS по умолчанию
     self.active_app = "sms"

phone_sms.gui_script.on_message("open_app")
  ├─ self.visible = true
  ├─ set_nodes_enabled(true)                  -- показать ноды SMS
  ├─ refresh()                                -- pull из game_state
  └─ msg.post("#ui_manager_v2", "phone_sms_viewed")  -- сбросить unread
```

### Бейджи на иконках приложений

`update_notif` в `phone_v2_root.gui_script` различает источники:

| Что показывает | Источник |
|---|---|
| `stats_msg` («сообщений: N» в статус-баре) | `gs.get_phone_unread_total()` — sum sms+msg |
| `app1_badge` (иконка SMS) | `gs.get_sms_unread_total()` — только SMS |
| `app7_badge` (иконка Messenger) | `gs.get_msg_unread_total()` — только Messenger |

Раньше бейдж на SMS-иконке мог показывать общий total. Сейчас SMS и Messenger разделены.

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

Важно:

Вкладка Quests показывает только runtime-задачи текущей итерации из `game_state`.
Она не является persistent loop journal.

Если в дизайне нужен журнал гипотез, переживающий итерации, его нельзя брать из `gs.get_quests()`.
Для него нужен отдельный источник данных: `meta_state` или отдельный persistent journal module.

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

message_flow.lua handles "sms_open_contact"
  ├─ gs.mark_sms_read(contact_id)   -- ставит sms_<contact>_read=true
  ├─ close_phone(self)              -- закрывает телефон
  └─ run_side_dialogue_knot("sms_thread_mila")   -- прыгает в Ink
       -- knot должен лежать в chapters/*.ink
       -- завершается через # return_to_scene -> вернуться в текущую сцену
```

**Ink-knot для переписки** (`sms_thread_<contact_id>`) показывает сообщения,
предлагает варианты ответа через choices и выполняет `# sms:reply:contact:text`.

Пример: `sms_thread_mila` в `main/story/chapters/10_apartment.ink`:

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

### Messenger — параллельный канал

Messenger-приложение (`phone_messenger`) работает зеркально к SMS, но через
отдельный storage в `game_state` (`_msg` / `_msg_unread`). Это не camera-app и
не старый mock-мессенджер: source of truth для сообщений — только `game_state`.

| SMS | Messenger |
|---|---|
| `# sms:add:mila:текст` | `# msg:add:mila:текст` |
| `# sms:reply:mila:текст` | `# msg:reply:mila:текст` |
| `# sms:read:mila` | `# msg:read:mila` |
| auto-flag `sms_<contact>_read` | auto-flag `msg_<chat>_read` |
| auto-flag `sms_<contact>_replied` | auto-flag `msg_<chat>_replied` |
| ink-thread `sms_thread_<contact>` | ink-thread `msg_thread_<chat>` |

Поток при тапе на строку Messenger-чата:

```text
phone_messenger.gui_script.open_chat
  ├─ открывает inline bubble-view (без автоматического прыжка в ink)
  ├─ gs.mark_msg_read(chat_id)       -- читает только конкретный чат
  └─ если can_reply(chat_id):
       поле «написать сообщение» и кнопка «отправить» начинают пульсировать

Тап игрока на th_input_bg / th_send_bg в открытом thread-вью:
  └─ msg.post("#ui_manager_v2", "messenger_open_chat", { chat_id })

message_flow.handle_messenger_open_chat
  ├─ msg_<chat>_replied != true
  ├─ dm.has_knot("msg_thread_<chat>") = true
  │    └─ close_phone + run_side_dialogue_knot("msg_thread_<chat>")
  └─ иначе игнорируется (тап не делает ничего)
```

`can_reply(chat_id)` возвращает true только если выполнены все условия:

1. Есть ink-knot `msg_thread_<chat>`.
2. Игрок ещё не отвечал в этом чате (`msg_<chat>_replied != true`).

Для чатов без интерактивного ответа (meme-чаты, боты-нотификации, каналы) пульса не будет — input/send выглядят статичными. Тап тоже игнорируется.

`open_app` Messenger не вызывает автоматически `gs.mark_all_msg_read()`.
Непрочитанные сбрасываются точечно при открытии конкретного чата через
`gs.mark_msg_read(chat_id)`. Так игрок может открыть приложение и всё ещё видеть,
какие диалоги остались непрочитанными.

Локальная таблица `CHAT_META` внутри `phone_messenger.gui_script` допустима только
как presentation metadata: имя, аватар, тон, статус, служебные бейджи. Она не
является источником сообщений. Если автор присылает `# msg:add:newchar:...` для
chat_id, которого нет в `CHAT_META`, чат всё равно должен появиться в списке через
`gs.get_msg_chats()`, но с fallback-именем/аватаром.

> **Как добавить Messenger-переписку с новым chat_id:**
> 1. `# msg:add:<chat_id>:<текст>` — прислать входящее сообщение.
> 2. При необходимости написать knot `msg_thread_<chat_id>` в `.ink`-файле.
> 3. Если knot есть — тап по input/SEND в открытом чате может открыть side-dialogue выбора ответа.
> 4. Если knot нет — чат остаётся обычным inline bubble-view внутри телефона.

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

Он открывает телефон и сразу переключает его на приложение карты (`phone_map.gui`). Игрок выбирает POI, `phone_map.gui_script` отправляет `map_travel`, после чего `message_flow.lua` закрывает телефон и открывает выбранный hub через `scene_controller.enter(scene_id)`.

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
| Карта открывается как внешний оверлей | `map` в `EXTERNAL_APPS` / обработчик в `message_flow.lua` | Убрать `map` из `EXTERNAL_APPS`; не открывать внешний `map_v2` из `phone_app_clicked` |
| Меню не реагирует на клики | `acquire_input_focus` убран из `init` root-скрипта | Восстановить, не добавлять `release` при закрытии |
| При закрытии телефона меню не работает | `release_input_focus` вызывается в `close_phone` | Убрать `release_input_focus` |
| Данные в вкладке не обновляются | Нет вызова `refresh(self)` в `open_app` | Добавить `refresh(self)` в хэндлер `open_app` |
| `refresh_phone` не обновляет данные | Активная вкладка не совпадает с той что на экране | `refresh_phone` обновляет только `active_app` — открой нужную вкладку |
| `gui.get_node` крашится | Нода с таким id нет в этом GUI-файле | Используй `pcall(gui.get_node, id)` — обёртка `get_node()` уже есть в каждом скрипте |
