# Система итераций — что сохраняется между петлями

Итерация — один полный прогон истории. После концовки счётчик растёт,
игрок возвращается в главное меню и начинает следующую петлю.

---

## Два хранилища состояния

| Хранилище | Файл | Когда сбрасывается |
|-----------|------|--------------------|
| **save_manager** | `save.dat` | При `sm.new_game()` — каждая новая итерация |
| **meta_state** | `meta_state.dat` | Только при `meta.reset_all()` — кнопка «СБРОСИТЬ ИТЕРАЦИЮ» |

### Что живёт в `save_manager` (сбрасывается каждую итерацию)

- `ink_state` — текущее состояние ink-истории
- `game_state` — флаги, инвентарь, квесты, СМС, заметки
- `chapter` — текущая глава
- `mc_gender` — пол персонажа (НЕ сбрасывается — восстанавливается из meta_state)

### Что живёт в `meta_state` (переживает итерации)

- `iteration_number` — номер текущей итерации (1, 2, 3...)
- `completed_iterations` — сколько итераций пройдено до конца
- `loop_awareness` — сколько ложных концовок найдено (разблокирует истинную)
- `false_endings_seen` — таблица найденных ложных концовок
- `mc_gender` — выбор персонажа (сохраняется навсегда до полного сброса)

---

## Выбор персонажа между итерациями

### Проблема

При старте новой итерации `sm.new_game()` очищает save.dat, включая `mc_gender`.
Ink-история запускается заново и всегда доходит до узла `choose_character`.

### Решение (реализовано)

Выбор персонажа сохраняется в `meta_state` и автоматически применяется на следующих итерациях.

**Поток при первой итерации:**
1. `choose_character` показывается игроку
2. Игрок выбирает «Артём» или «Мила»
3. `pull_gender_from_ink()` → `sm.set_gender()` + `meta.set("mc_gender", gender)`

**Поток при итерации 2+:**
1. `start_new_run` → `sm.new_game()` (mc_gender = nil) → восстановить из `meta.get("mc_gender")`
2. `push_vars_to_ink` ставит корректный `mc_gender` в ink до первого continue
3. История доходит до `choose_character` — `handle_dialogue_update` перехватывает
4. Видит выбор из двух вариантов «Артём»/«Мила» + знает сохранённый пол
5. Вызывает `dm.choose(i)` автоматически — игрок ничего не видит
6. История идёт дальше с `wake_after_choice`

**Полный сброс (кнопка «СБРОСИТЬ ИТЕРАЦИЮ»):**
1. `meta.reset_all()` — сбрасывает `mc_gender = nil` в meta_state
2. На следующем старте `meta.get("mc_gender")` = nil → пол не восстанавливается
3. Игрок снова видит `choose_character`

---

## Как добавить новое поле в meta_state

Если нужно что-то ещё сохранять между итерациями (например, найденные секреты):

```lua
-- meta_state.lua → DEFAULT
local DEFAULT = {
    -- ... существующие поля ...
    my_field = nil,   -- или 0, или false — начальное значение
}
```

Читать:
```lua
local meta = require "main.scripts.meta_state"
local value = meta.get("my_field", default_value)
```

Записать:
```lua
meta.set("my_field", new_value)   -- автосохранение в файл
```

Сбросить при полном сбросе: поле сбросится автоматически через `clone_defaults()` в `reset_all()`.

---

## Нумерация и метки итераций

Текущий номер доступен из любого скрипта:

```lua
local meta = require "main.scripts.meta_state"

local n      = meta.get("iteration_number", 1)   -- 1, 2, 3...
local label  = meta.get_iteration_label()          -- "001", "002", "003"...
local aware  = meta.get("loop_awareness", 0)       -- количество найденных ложных концовок
```

В ink переменные выставляются автоматически перед стартом:
```ink
VAR iteration_number = 1      // подставляет Lua
VAR loop_awareness   = 0      // подставляет Lua

// Пример использования в тексте:
{iteration_number > 1:
    На секунду возникает странное чувство — это утро уже было.
}
```

---

## Концовки и переход итераций

| Тег в ink | Что происходит |
|-----------|----------------|
| `# chapter_finished` | Обычный конец → `meta.complete_iteration()` → меню |
| `# false_ending:id` | Ложная концовка → `meta.record_false_ending(id)` → меню |
| `# true_ending` | Истинная концовка (нужно 2 ложных) → `meta.complete_iteration()` → меню |

`meta.complete_iteration()` делает:
- `iteration_number += 1`
- `completed_iterations += 1`
- Сбрасывает `false_endings_seen` и `false_endings_count`
- **НЕ трогает `mc_gender`**, `loop_awareness`

Истинная концовка разблокируется когда `loop_awareness >= 2`.

---

## Файлы системы

| Файл | Роль |
|------|------|
| `main/scripts/meta_state.lua` | Хранилище между итерациями, автосохранение |
| `main/scripts/save_manager.lua` | Состояние текущей итерации |
| `main/scripts/dialogue_manager_ink.lua` | `pull_gender_from_ink()` — синхронизация пола |
| `main/gui/ui_manager_v2.script` | `start_new_run` — восстановление пола; `handle_dialogue_update` — автовыбор |
