# game_state архитектура

Единый источник правды для runtime-state игры. Раньше — монолит на 1249
строк. Теперь — фасад + channel-модули.

## Структура

```
main/scripts/
├── game_state.lua              ← фасад (~532 строки):
│                                  flags, inventory, quests, scene,
│                                  terminal, map_pois,
│                                  subscribe/_notify,
│                                  serialize/deserialize composition,
│                                  делегаты в channel-модули.
└── state/
    ├── _helpers.lua            ← clone_value/array, format_clock,
    │                             make_default_time, make_seq.
    ├── bank.lua                ← Баланс карты (bank:*)
    ├── sms.lua                 ← SMS-канал
    ├── messenger.lua           ← Messenger (msg:*)
    ├── mail.lua                ← Почта
    ├── calls.lua               ← Журнал звонков
    ├── clues.lua               ← Улики (уникальные по id)
    └── notes.lua               ← Заметки
```

## Public API (`game_state.lua`)

Внешний код видит **только** `gs.foo(...)`. Откуда логика — неважно.

### Flags
```lua
gs.set_flag(name, value)
gs.get_flag(name)
```

### Inventory
```lua
gs.has_item(id)
gs.add_item(id)        -- false если уже есть или max
gs.remove_item(id)
gs.get_inventory()     -- клон массива
```

### Quests
```lua
gs.set_quest(id, status)   -- "active" | "done" | "failed"
gs.get_quest(id)
gs.get_quests()            -- развёрнутый список с progress из catalog
```

### Scene
```lua
gs.set_scene(id)
gs.get_scene()
```

### SMS — делегаты в `state/sms.lua`
```lua
gs.add_sms(contact_id, text)        -- входящее
gs.reply_sms(contact_id, text)      -- исходящее (auto-flag sms_<contact>_replied)
gs.mark_sms_read(contact_id)        -- auto-flag sms_<contact>_read
gs.mark_all_sms_read()
gs.get_sms(contact_id)              -- клон списка сообщений
gs.get_sms_contacts()               -- newest-first
gs.get_sms_unread_total()
gs.get_sms_unread(contact_id)
```

### Messenger — делегаты в `state/messenger.lua`
Параллельно SMS, префикс `msg_` для авто-флагов:
```lua
gs.add_msg(chat_id, text)
gs.reply_msg(chat_id, text)
gs.mark_msg_read(chat_id)
gs.mark_all_msg_read()
gs.get_msg(chat_id)
gs.get_msg_chats()
gs.get_msg_unread_total()
gs.get_msg_unread(chat_id)
```

### Mail
```lua
gs.add_mail(from, subject, body)
gs.mark_mail_read(index)         -- index из get_mails() (newest-first)
gs.mark_all_mail_read()
gs.get_mails()                   -- newest-first
gs.get_mail_unread_total()
```

### Calls
```lua
gs.add_call(who, kind)           -- kind: "in" | "out" | "missed"
gs.mark_all_calls_seen()
gs.get_call_log()                -- newest-first
gs.get_call_missed_total()
```

### Clues
```lua
gs.add_clue(id, label)           -- повтор с тем же id = no-op
gs.has_clue(id)
gs.get_clues()                   -- newest-first
```

### Notes
```lua
gs.add_note(title, body)
gs.get_notes()
```

### Terminal / Map POIs
Эти небольшие домены живут прямо в `game_state.lua` (не вынесены).

```lua
gs.add_terminal_line(level, text)   -- level: ok|warn|err|info|prompt|plain
gs.clear_terminal()
gs.reset_terminal_to_defaults()
gs.get_terminal_lines()

gs.map_allow(poi_id)              -- добавить POI в whitelist
gs.map_allow_reset()              -- очистить (вернуть default = все разрешены)
gs.map_lock_to(poi_id)            -- clear + добавить (только этот)
gs.map_lock_all()                 -- заблокировать все
gs.map_is_poi_allowed(poi_id)
gs.get_map_allowed_pois()
gs.is_map_all_pois_locked()
```

### Прочее
```lua
gs.subscribe(callback)            -- подписаться на _notify
gs.get_phone_unread_total()       -- суммарный бейдж телефона
gs.get_messages()                 -- SMS в формате для phone_v2.gui_script
gs.serialize()                    -- snapshot для save_manager
gs.deserialize(snapshot)          -- восстановить
gs.reset()                        -- полный сброс (новый run)
```

## Контракт channel-модуля

Каждый channel в `state/<name>.lua` следует одному паттерну:

```lua
local M = {}
local notify_cb = function() end
local set_flag_cb = function(_n, _v) end

-- DI: game_state вызывает в init.
function M.set_deps(deps)
    if deps.notify   then notify_cb   = deps.notify   end
    if deps.set_flag then set_flag_cb = deps.set_flag end
end

local _state = {}      -- внутреннее состояние, не торчит наружу
local next_seq, _, _ = H.make_seq()
local default_time = H.make_default_time(BASE_MINUTES)

local function normalize() ... end  -- приведение state к канону

function M.reset() ... end          -- обнулить всё
function M.add(...) ... end         -- добавить запись (notify_cb)
function M.get(...) ... end         -- клон, не мутирует
function M.serialize() ... end      -- → таблица для save
function M.deserialize(data) ...    -- ← таблица из save + normalize

return M
```

## Зависимости

`game_state.lua` подключает channel-модули и делает `set_deps`:

```lua
sms_state.set_deps      ({ notify = M._notify, set_flag = set_flag_internal })
messenger_state.set_deps({ notify = M._notify, set_flag = set_flag_internal })
mail_state.set_deps     ({ notify = M._notify })
-- ...
```

`set_flag_internal` — внутренний setter (НЕ нотифицирует), чтобы каналы
которые ставят auto-флаги (`sms_<contact>_replied`, `msg_<chat>_read`)
не дублировали `_notify` после собственного.

## Сериализация

`gs.serialize()` собирает snapshot:
```lua
{
    flags         = ...,
    inventory     = [...],
    quests        = ...,
    terminal_lines = [...],
    map_allowed_pois = ...,
    map_all_pois_locked = bool,
    current_scene = id,

    -- channel ключи (мерджатся из каждого M.serialize()):
    sms = ..., sms_unread = ...,
    msg = ..., msg_unread = ...,
    mails = ..., mails_unread = N,
    call_log = ..., call_missed = N,
    clues = ...,
    notes = ...,
}
```

`gs.deserialize(snap)`:
1. Разбирает локальные домены (flags, inventory, ...).
2. Каждому каналу зовёт `channel.deserialize(snap)` — он сам читает
   нужные ключи (`data.sms` и т.п.) и нормализует.

**Backwards compat:** старые сейвы (до рефакторинга) хранили те же
top-level ключи, поэтому загружаются без миграции.

## Куда добавлять что

| Хочу | Куда |
|------|------|
| Новый канал телефона (sms-like) | новый файл `main/scripts/state/<name>.lua` + делегаты в `game_state.lua` |
| Новый флаг / single-value домен | прямо в `game_state.lua` (как `_current_scene`) |
| Helper для каналов (clone, format) | `main/scripts/state/_helpers.lua` |
| Изменение поведения SMS (например replied-флаг) | `state/sms.lua`, не трогать `game_state.lua` |

## Что НЕ вынесено

- `flags` / `inventory` / `quests` — атомарные, малая поверхность,
  делать модуль ради 4 функций нет смысла.
- `scene` — 2 функции.
- `terminal` — небольшой, частично специфичный. Можно вынести если будет расти.
- `map_pois` — 7 функций, но все коротенькие.

## Миграция тестов / новых вызовов

Внешний код **не трогаем** — все `gs.add_sms(...)`, `gs.get_msg(...)` и
т.п. работают как раньше. Внутренние модули — через delegation в
`game_state.lua`.

Если понадобится тестировать channel в изоляции:
```lua
local sms = require "main.scripts.state.sms"
sms.set_deps({ notify = function() end, set_flag = function() end })
sms.add("alice", "hi")
assert(sms.get_unread_total() == 1)
```

## См. также

- `docs/guides/HOW_TO_WRITE_INK.md` — все ink-теги и какие домены они вызывают.
- `docs/guides/PHONE_SYSTEM.md` — архитектура phone-overlay и его apps.
- `main/gui/modules/ui_manager_v2/dm_commands.lua` — где ink-команды
  превращаются в `gs.add_sms()` / `gs.add_msg()` / т.п.
