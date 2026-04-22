# Loop System

Актуально на `2026-04-23`.

Это описание минимальной рабочей системы временных петель в `AVOS_S`.

## Что уже делает система

- после конца главы игра возвращается в меню
- меню показывает следующую итерацию: `001`, `002`, `003` ...
- кнопка старта запускает новую итерацию с начала главы
- meta-state сохраняется между циклами
- run-state текущего прохождения сбрасывается
- Ink получает номер итерации и уровень осознания петли
- в `chapter_01.ink` уже можно писать условные loop-aware реплики

## Разделение состояний

### Persistent meta-state

Файл: `main/scripts/meta_state.lua`

Хранит долгую память петли:

- `iteration_number`
- `completed_iterations`
- `loop_awareness`

Это состояние живёт между запусками новых итераций.

### Persisted run-state

Файл: `main/scripts/save_manager.lua`

Хранит только текущее прохождение:

- `mc_gender`
- `chapter`
- `ink_state`
- `game_state`

Это состояние нужно кнопке `Continue`. При переходе на новую итерацию оно очищается.

### Runtime-state

Файл: `main/scripts/game_state.lua`

Содержит живое состояние текущего запуска:

- flags
- inventory
- quests
- sms / notes / phone data
- current_scene

Оно сериализуется в `save_manager.lua`, но само по себе не является meta-state.

## Поток работы

### Старт новой итерации

1. `main_menu_v2` шлёт `start_game`
2. `ui_manager_v2.script` делает:
   - `sm.new_game()`
   - `gs.reset()`
   - `scene_controller.reset()`
3. загружается `chapter_01.json`
4. `dialogue_manager_ink.lua` поднимает Ink и прокидывает meta vars

### Continue

1. меню шлёт `continue_game`
2. `ui_manager_v2.script` проверяет `sm.has_save()`
3. если save есть:
   - восстанавливает `game_state`
   - восстанавливает `scene_controller`
   - вызывает `dm.load_saved(bytes)`

### Конец главы

1. Ink доходит до `END`
2. `dialogue_manager_ink.lua` шлёт `chapter_finished`
3. `ui_manager_v2.script` вызывает `meta.complete_iteration(1)`
4. затем:
   - `sm.clear_run()`
   - `gs.reset()`
   - `scene_controller.reset()`
   - `show_menu()`

Итог: следующая попытка стартует как новая итерация, но meta-state не теряется.

## Ink-интеграция

Перед стартом истории `dialogue_manager_ink.lua` прокидывает в Ink:

| VAR | Значение |
| --- | --- |
| `iteration_number` | номер текущей итерации |
| `iteration_label` | строка `001`, `002`, `003` |
| `loop_awareness` | уровень осознания петли |
| `completed_iterations` | число завершённых циклов |

Эти переменные уже объявлены в `main/story/chapter_01.ink` и попадают в `chapter_01.json` после компиляции.

## Что считается минимальной рабочей версией

- глава полностью проходима
- повторный запуск через меню работает
- `Continue` работает только для незавершённого прохождения
- у игрока появляется базовое ощущение повторения
- конец главы отражает актуальный `iteration_label`

## Как расширять дальше

- добавлять больше условных сцен по `iteration_number` и `loop_awareness`
- делать нелинейный рост `loop_awareness`, а не только `+1` за финал главы
- добавлять meta unlocks в меню, телефон, предметы и exploration
- выносить multi-chapter routing из жёсткого `chapter_01.json`

## Обязательный pipeline при изменении Ink

```bash
tools\compile_ink.bat chapter_01
./tools/compile_ink.sh chapter_01
```

Без перекомпиляции `chapter_01.json` новые loop-aware реплики в игре не появятся.
