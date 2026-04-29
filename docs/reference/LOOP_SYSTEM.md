# Loop System

Актуально на `2026-04-29`.

Система временных петель разделяет run-state текущего прохождения и persistent meta-state между итерациями.

## State

### Run-state

Хранится через `main/scripts/save_manager.lua` в `save.dat`.

Нужен для `Continue`:

- Ink replay state
- `game_state`
- выбранный персонаж
- текущая exploration-сцена

При старте новой итерации run-state очищается.

### Meta-state

Хранится через `main/scripts/meta_state.lua` в `meta_state.dat`.

Живёт между итерациями:

- `iteration_number`
- `completed_iterations`
- `loop_awareness`
- `false_endings_seen`
- `false_endings_count`
- сохранённый выбор персонажа

## Flow

### Start Game

1. меню отправляет `start_game`
2. `ui_manager_v2` очищает run-state
3. `meta_state` сохраняется
4. загружается `/main/story/chapter_01.json`
5. `dialogue_manager_ink.init(bytes)` стартует Ink

### Continue

1. меню отправляет `continue_game`
2. `save_manager` восстанавливает run-state
3. `game_state` и `scene_controller` десериализуются
4. `dialogue_manager_ink.load_saved(bytes)` replay'ит Ink

`Continue` корректен только для совместимого compiled JSON. После крупных правок `.ink` обязательно проверять загрузку.

### Reset Iteration

1. меню отправляет `reset_iteration`
2. `meta.reset_all()`
3. run-state очищается
4. игра стартует с `Итерации 001`

## False Endings / True Ending

Новая схема:

- `# loop:end:false:id` — ложная концовка
- `# loop:end:true` — истинная концовка

Ложная концовка:

- вызывает `meta.record_false_ending(id)`
- повышает `loop_awareness` только если такой `id` ещё не встречался
- очищает run-state
- перезапускает текущую итерацию без увеличения `iteration_number`

Истинная концовка:

- доступна, когда `false_endings_count >= 2`
- завершает главу через `meta.complete_iteration()`
- очищает список ложных концовок
- переводит игрока в следующую итерацию

## Ink Vars

Lua прокидывает в Ink:

- `iteration_number`
- `iteration_label`
- `loop_awareness`
- `completed_iterations`
- `false_endings_count`

Эти значения пишутся через `story.assign_value(...)`, чтобы `defold-ink` сохранял их в replay history.

## Авторинг

Пример loop-aware текста:

```ink
{loop_awareness >= 2:
    Ты уже знаешь, чем закончится этот разговор.
}
```

Пример ложной концовки:

```ink
# loop:end:false:system_trust
-> DONE
```

Пример истинной концовки:

```ink
{false_endings_count >= 2:
    # loop:end:true
    -> DONE
}
```

## Caveats

- `chapter_01.json` остаётся единственным runtime story-файлом.
- source-level story уже модульный через `INCLUDE`.
- `chapters/New/` больше не считается рабочей веткой.
- если правка меняет Ink structure, проверяйте `Continue`.
