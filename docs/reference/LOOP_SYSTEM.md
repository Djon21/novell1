# Loop System — итерации, состояние и концовки

Актуально на `2026-05`. Объединил `ITERATION_SYSTEM.md` (детали реализации)
и `LOOP_SYSTEM.md` (концептуальный обзор) в один файл.

Итерация — один полный прогон истории. После концовки игрок возвращается
в главное меню и начинает следующую петлю. Между итерациями переживает
часть состояния (`meta_state`), часть очищается (`save_manager`).

---

## Содержание

1. [Два хранилища состояния](#1-два-хранилища-состояния)
2. [Flow: Start / Continue / Reset](#2-flow-start--continue--reset)
3. [Выбор персонажа между итерациями](#3-выбор-персонажа-между-итерациями)
4. [Концовки и переход итераций](#4-концовки-и-переход-итераций)
5. [Ink Vars от движка](#5-ink-vars-от-движка)
6. [Как добавить поле в meta_state](#6-как-добавить-поле-в-meta_state)
7. [Авторинг loop-aware контента](#7-авторинг-loop-aware-контента)
8. [Caveats](#8-caveats)
9. [Файлы системы](#9-файлы-системы)

---

## 1. Два хранилища состояния

| Хранилище | Файл | Когда сбрасывается |
|---|---|---|
| **save_manager** | `save.dat` | При `sm.new_game()` — каждая новая итерация |
| **meta_state** | `meta_state.dat` | Только при `meta.reset_all()` — кнопка «СБРОСИТЬ ИТЕРАЦИЮ» |

### Что живёт в `save_manager` (run-state, сбрасывается каждую итерацию)

- `ink_state` — текущее состояние ink-истории (для replay)
- `game_state` — флаги, инвентарь, квесты, SMS, заметки, текущая сцена
- `chapter` — текущая глава
- `mc_gender` — пол персонажа (НЕ сбрасывается — восстанавливается из meta_state)

Run-state используется для кнопки «ПРОДОЛЖИТЬ» в меню.

### Что живёт в `meta_state` (переживает итерации)

- `iteration_number` — номер текущей итерации (1, 2, 3...)
- `completed_iterations` — сколько итераций пройдено до конца
- `loop_awareness` — сколько уникальных ложных концовок найдено
- `false_endings_seen` — таблица найденных ложных концовок
- `false_endings_count` — счётчик уникальных ложных
- `mc_gender` — выбор персонажа (сохраняется навсегда до полного сброса)

---

## 2. Flow: Start / Continue / Reset

### Start Game (новая итерация)

1. Меню отправляет `start_game`
2. `ui_manager_v2.start_new_run`:
   - `sm.new_game()` — очищает run-state
   - читает `meta.get("mc_gender")` и восстанавливает пол
3. `meta_state` сохраняется (если что-то изменилось)
4. Загружается `/main/story/chapter_01.json`
5. `dialogue_manager_ink.init(bytes)` стартует Ink с нуля
6. `push_vars_to_ink` ставит `iteration_number`, `loop_awareness`, etc. до первого continue

### Continue

1. Меню отправляет `continue_game`
2. `save_manager` восстанавливает run-state
3. `game_state` и `scene_controller` десериализуются
4. `dialogue_manager_ink.load_saved(bytes)` replay'ит Ink

> `Continue` корректен только для совместимого compiled JSON. После крупных правок `.ink` обязательно тестировать загрузку.

### Reset Iteration

1. Меню отправляет `reset_iteration` (после confirm-модалки)
2. `meta.reset_all()` — сбрасывает всё meta-state, включая `mc_gender`
3. Run-state очищается
4. Игра стартует с `Итерации 001`

---

## 3. Выбор персонажа между итерациями

### Проблема

При старте новой итерации `sm.new_game()` очищает save.dat, включая `mc_gender`.
Ink-история запускается заново и всегда доходит до узла `choose_character`.

### Решение

Выбор персонажа сохраняется в `meta_state` и автоматически применяется на следующих итерациях.

**Поток при первой итерации:**
1. `choose_character` показывается игроку
2. Игрок выбирает «Артём» или «Мила»
3. `pull_gender_from_ink()` → `sm.set_gender(...)` + `meta.set("mc_gender", gender)`

**Поток при итерации 2+:**
1. `start_new_run` → `sm.new_game()` (mc_gender = nil) → восстановить из `meta.get("mc_gender")`
2. `push_vars_to_ink` ставит корректный `mc_gender` в ink до первого continue
3. История доходит до `choose_character` — `handle_dialogue_update` перехватывает
4. Видит выбор из двух вариантов «Артём»/«Мила» + знает сохранённый пол
5. Вызывает `dm.choose(i)` автоматически — игрок ничего не видит
6. История идёт дальше с `wake_after_choice`

**Полный сброс:**
1. `meta.reset_all()` — сбрасывает `mc_gender = nil` в meta_state
2. На следующем старте `meta.get("mc_gender")` = nil → пол не восстанавливается
3. Игрок снова видит `choose_character`

---

## 4. Концовки и переход итераций

### Итерация 001 vs 002+: разная логика

- **Итерация 001** — **линейная**. Петля ещё не запущена, ложных концовок нет, true ending недоступен. Концовка одна — переход в следующую итерацию через `# chapter_finished`.
- **Итерация 002+** — петля активна. Появляются ложные концовки `# loop:end:false:*` и истинная `# loop:end:true` (после двух уникальных ложных).

Runtime-страховка: если на итерации 001 встречается `# loop:end:false:*` или `# loop:end:true` (например, из-за промаха в авторинге), они трактуются как `# chapter_finished` — игрок не «застрянет» в искусственной петле.

### Теги ink

| Тег | Итерация 001 | Итерация 002+ |
|---|---|---|
| `# chapter_finished` | → `meta.complete_iteration()` → меню | то же |
| `# loop:end:false:ID` | трактуется как `chapter_finished` (warn) | `meta.record_false_ending(ID)` → restart той же итерации |
| `# loop:end:true` | трактуется как `chapter_finished` (warn) | требует `loop_awareness >= 2`; иначе fallback `record_false_ending("early_true")` |

### Ложная концовка (`# loop:end:false:ID`)

- Вызывает `meta.record_false_ending(ID)`
- Повышает `loop_awareness` **только если такой ID ещё не встречался**
- Очищает run-state
- **Перезапускает текущую итерацию БЕЗ увеличения** `iteration_number`

### Истинная концовка (`# loop:end:true`)

- Доступна, когда `false_endings_count >= 2` (две уникальные ложные)
- Завершает главу через `meta.complete_iteration()`
- Очищает список ложных концовок
- Переводит игрока в следующую итерацию

### `meta.complete_iteration()` делает:

- `iteration_number += 1`
- `completed_iterations += 1`
- Сбрасывает `false_endings_seen` и `false_endings_count`
- **НЕ трогает** `mc_gender`, `loop_awareness`

---

## 5. Ink Vars от движка

Lua прокидывает в Ink перед стартом каждой итерации:

| VAR | Источник |
|---|---|
| `mc_gender` | `save_manager` / выбор игрока |
| `mc_name` | `save_manager` |
| `npc_name` | `save_manager` |
| `iteration_number` | `meta_state` |
| `iteration_label` | `meta_state` (`"001"`, `"002"`, …) |
| `loop_awareness` | `meta_state` |
| `completed_iterations` | `meta_state` |
| `false_endings_count` | `meta_state` |

Эти значения пишутся через `story.assign_value(...)`, чтобы `defold-ink` сохранял их в replay history. **НЕ объявляй их сам в bootstrap** — они уже есть.

Текущий номер доступен из любого Lua-скрипта:

```lua
local meta = require "main.scripts.meta_state"

local n      = meta.get("iteration_number", 1)   -- 1, 2, 3...
local label  = meta.get_iteration_label()          -- "001", "002", "003"...
local aware  = meta.get("loop_awareness", 0)       -- найденные ложные концовки
```

---

## 6. Как добавить поле в meta_state

Если нужно что-то ещё сохранять между итерациями (например, найденные секреты):

**1. Добавить дефолт в `meta_state.lua`:**

```lua
local DEFAULT = {
    -- ... существующие поля ...
    my_field = nil,   -- или 0, или false — начальное значение
}
```

**2. Читать:**

```lua
local meta = require "main.scripts.meta_state"
local value = meta.get("my_field", default_value)
```

**3. Писать:**

```lua
meta.set("my_field", new_value)   -- автосохранение в файл
```

При полном сбросе (`reset_all()`) поле сбросится автоматически через `clone_defaults()`.

---

## 7. Авторинг loop-aware контента

```ink
{iteration_number > 1:
    На секунду возникает странное чувство — это утро уже было.
}

{loop_awareness >= 2:
    Ты уже знаешь, чем закончится этот разговор.
}
```

### Пример ложной концовки с gate'ом по итерации

Best practice — оборачивать ложные концовки в условие, чтобы итерация 001 шла линейно:

```ink
=== ending_trusted_system ===
# bg:bg_office # speaker:none
...текст концовки...
{iteration_number > 1:
    # loop:end:false:system_trust
- else:
    # chapter_finished
}
-> DONE
```

После показа концовки run-state очистится:
- На итерации 001 → `complete_iteration()` (переход в 002)
- На 002+ → `record_false_ending` (рестарт той же итерации, +1 awareness если ID новый)

### Пример истинной концовки

```ink
=== final_choice ===
{iteration_number > 1 and false_endings_count >= 2:
    # loop:end:true
    -> ending_truth
- else:
    # loop:end:false:partial_truth
    -> DONE
}
```

Истинная концовка должна быть скрыта за условием на `false_endings_count` — иначе игрок попадёт в неё с первой итерации без накопленных ложных. Runtime подстрахует, но лучше гейтить явно.

---

## 8. Caveats

- `chapter_01.json` остаётся единственным runtime story-файлом
- Source-level story уже модульный через `INCLUDE` (`chapter_01.ink` → `chapters/*.ink`)
- Если правка меняет Ink structure — обязательно проверять `Continue`
- При смене языка между сессиями (см. `L10N_PLAN.md`) `Continue` лучше блокировать, иначе replay будет на чужом JSON

---

## 9. Файлы системы

| Файл | Роль |
|---|---|
| `main/scripts/meta_state.lua` | Хранилище между итерациями, автосохранение |
| `main/scripts/save_manager.lua` | Run-state текущей итерации |
| `main/scripts/dialogue_manager_ink.lua` | `pull_gender_from_ink()`, `push_vars_to_ink()` — синхронизация |
| `main/gui/ui_manager_v2.script` | `start_new_run`, `handle_dialogue_update`, обработчики `chapter_finished`, `loop:end:*` |
| `main/gui/components_v2/main_menu_v2.gui_script` | Confirm-модалка для «СБРОСИТЬ ИТЕРАЦИЮ» |
