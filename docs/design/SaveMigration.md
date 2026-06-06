# Save Migration — Refactor Plan (Option C)

## Current State

`save_manager.lua:44-88` — version ladder:

```lua
local function migrate_save(loaded)
    if v < 1 then loaded.version = 1 end
    if v < 2 then loaded.save_time = loaded.save_time or 0 end
    -- будущие миграции — сюда ещё ladder'ы
end
```

`game_state.deserialize` — nil-check на каждое поле:

```lua
_flags  = data.flags  or {}
_quests = data.quests or {}
```

## Problem

- Каждое новое поле в save = новый `if v < N` в ladder
- Каждый новый channel в game_state = его вызов в deserialize
- Сложные миграции (ink_state) и примитивы (save_time) в одном месте

## Target (Option C)

Гибрид: `ipairs`-defaults для примитивов + version ladder только для сложных миграций.

### 1. Defaults для примитивов

```lua
local SAVE_KEYS = {"save_time", "mc_gender", "chapter", "ink_state", "game_state"}
local SAVE_DEFAULTS = {save_time = 0, chapter = 1}

local function apply_defaults(loaded)
    for _, k in ipairs(SAVE_KEYS) do
        if loaded[k] == nil then
            loaded[k] = SAVE_DEFAULTS[k]  -- nil если нет в DEFAULTS
        end
    end
end
```

- `ipairs` по списку ключей гарантирует что ВСЕ поля проверены
- Поля без дефолта (`mc_gender`, `ink_state`, `game_state`) получают nil
- Никаких sentinel, никаких `pairs` с nil-пропуском

### 2. Version ladder только для complex-миграций

```lua
local COMPLEX_MIGRATIONS = {
    [1] = function(loaded)
        -- v0 -> v1: ink_state формат изменился
        -- loaded.ink_state уже не nil (apply_defaults поставил),
        -- но может быть старого формата
    end,
    [2] = function(loaded)
        -- v1 -> v2: добавлен save_time (НО теперь это в apply_defaults)
        -- Этот ladder пуст — save_time уже проставлен defaults
    end,
}
```

### 3. migrate_save

```lua
local function migrate_save(loaded)
    if type(loaded) ~= "table" then return nil end
    local v = tonumber(loaded.version) or 0

    apply_defaults(loaded)

    for target_v, fn in ipairs(COMPLEX_MIGRATIONS) do
        if v < target_v then fn(loaded) end
    end

    loaded.version = CURRENT_VERSION
    return loaded
end
```

### 4. game_state serialization (low priority)

Сейчас каждый channel явно вызывается:

```lua
sms_state.deserialize(data)
messenger_state.deserialize(data)
bank_state.deserialize(data)
```

Можно заменить на автоматическую итерацию:

```lua
local CHANNELS = { sms_state, messenger_state, bank_state, mail_state, calls_state, clues_state, notes_state }

function M.deserialize(data)
    -- общие поля
    _flags  = data.flags  or {}
    _quests = data.quests or {}
    -- каналы
    for _, ch in ipairs(CHANNELS) do ch.deserialize(data) end
end
```

Это уже частично сделано в serialize (строки 496-500). Для deserialize — тот же паттерн.

## Compatibility

- Старые сейвы (v0, v1, v2) проходят `apply_defaults` — все nil-получают дефолт
- `ink_state` может быть старого формата — это ловится в `COMPLEX_MIGRATIONS[1]`
- Yandex Games ограничение на 1MB не затрагивается (миграция не добавляет данных)

## Why Not

- `ipairs` = явный список ключей. При добавлении нового поля нужно не забыть добавить в список. Но то же самое сейчас — нужно не забыть добавить `if v < N`.
- `COMPLEX_MIGRATIONS[1]` может быть пустым, если `ink_state` никогда не менял формат.
- Выигрыш — код чище, не надо писать очередной `if v < 3 then loaded.xxx = nil end`.
