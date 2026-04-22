# Архитектура AVOS_S

Актуально на `2026-04-23`.

## Точка входа

- `game.project` запускает `/main/main_v2.collectionc`
- активная главная коллекция: `main/main_v2.collection`
- legacy GUI больше не участвует в runtime и хранится отдельно в `archive/legacy_runtime/`

## Основной runtime-поток

### 1. Меню и запуск итерации

- `main/gui/ui_manager_v2.script` показывает `main_menu_v2`
- меню получает loop-state через сообщение `set_loop_state`
- `start_game` сбрасывает только run-state и стартует текущую итерацию заново
- `reset_iteration` сбрасывает и run-state, и meta-state, затем запускает новую игру с `Итерации 001`
- кнопка `СБРОСИТЬ ИТЕРАЦИЮ` в меню заменила старую `Галерею`
- `continue_game` доступен только если есть активный run-state save

### 2. Диалоговый режим

- `ui_manager_v2.script` загружает `/main/story/chapter_01.json`
- байты передаются в `main/scripts/dialogue_manager_ink.lua`
- `dialogue_manager_ink.lua` оборачивает `defold-ink` и возвращает:
  - `current_node`
  - `background`
  - `commands`
  - `effects`
- `ui_manager_v2.script` решает, что показать:
  - `dialogue_v2` для реплик
  - `choice_v2` для выборов
  - `main_menu_v2` при возврате в меню после конца главы

### 3. Exploration-режим

- Ink-теги `# explore:scene_id` и `# goto_scene:scene_id` приводят к входу в `scene_controller.lua`
- `main/scripts/scene_controller.lua` читает описания сцен из `main/scripts/scenes.lua`
- `scene_controller` через `set_ui()` прокидывает в GUI:
  - фон сцены
  - hotspot'ы
  - scene objects
- `hotspots_v2.gui_script` рендерит интерактив поверх фона

### 4. Завершение главы и переход на новую итерацию

- когда Ink доходит до `END`, `dialogue_manager_ink.lua` шлёт `chapter_finished`
- `ui_manager_v2.script` вызывает `meta.complete_iteration(1)`
- после этого:
  - очищается run-state через `save_manager.clear_run()`
  - сбрасываются `game_state` и `scene_controller`
  - открывается меню с уже увеличенным `iteration_label`

## Модель состояний

### `main/scripts/game_state.lua`

Runtime-state текущего прохождения:

- flags
- inventory
- quests
- current_scene
- sms / unread counters
- notes / mail / clues / call log

Именно это состояние живёт во время игры и синхронизируется с UI через `gs.subscribe(...)`.

### `main/scripts/save_manager.lua`

Persisted run-state только для текущего прохождения:

- `mc_gender`
- `chapter`
- `ink_state`
- `game_state`

Это сейв для кнопки `Continue`, а не для долгой прогрессии между циклами.

### `main/scripts/meta_state.lua`

Persisted meta-state между итерациями:

- `iteration_number`
- `iteration_label` через helper `get_iteration_label()`
- `completed_iterations`
- `loop_awareness`

`meta_state.lua` не сбрасывается при старте новой итерации. Его задача — хранить память петли.

Исключение: ручной `reset_iteration` из меню намеренно вызывает `meta.reset_all()`, чтобы полностью вернуть игру к `Итерации 001`.

## Ключевые runtime-модули

### `main/scripts/dialogue_manager_ink.lua`

- обёртка над `defold-ink`
- поддерживает:
  - `init()`
  - `load_saved()`
  - `get_current_node()`
  - `advance()`
  - `choose()`
  - `jump_to_knot()`
  - `get_commands()`
  - `get_effects()`
- синхронизирует с Ink:
  - `mc_gender`
  - `mc_name`
  - `npc_name`
  - `iteration_number`
  - `iteration_label`
  - `loop_awareness`
  - `completed_iterations`
- для новой игры пишет внешние vars через `story.assign_value(...)`, чтобы они попадали в replay history `defold-ink`
- при `load_saved()` восстанавливает историю через строгий `story.restore(state, with_externals)` без silent ignore mode
- для старых сейвов дополнительно подмешивает текущие external vars в replay перед restore, чтобы loop-state не терялся на `Continue`

### `main/scripts/scene_controller.lua`

- активирует и завершает exploration-сцены
- применяет `condition()` и `visible_when()`
- умеет:
  - `enter(scene_id)`
  - `exit()`
  - `return_to_last_scene()`
  - `reset()`
  - `on_hotspot_click(index)`
  - `serialize()` / `deserialize()`

### `main/gui/ui_manager_v2.script`

- оркестрирует базовые режимы:
  - `menu`
  - `exploration`
  - `dialogue`
- управляет overlay-экранами:
  - `choice`
  - `inventory`
  - `phone`
  - `map`
- связывает между собой:
  - `dialogue_manager_ink`
  - `scene_controller`
  - `game_state`
  - `save_manager`
  - `meta_state`
  - `components_v2/*`
- держит единый helper старта новой игры:
  - `start_game` -> перезапуск текущей итерации без сброса loop-памяти
  - `reset_iteration` -> полный сброс meta-state и запуск с `001`

## Ink и compile pipeline

- composition root story: `main/story/chapter_01.ink`
- chapter-source модули: `main/story/chapters/*.ink`
- активный compiled runtime-файл: `main/story/chapter_01.json`
- story-loader пока жёстко читает именно `chapter_01.json`
- после изменения `.ink` нужно перекомпилировать `.json`
- runtime намеренно остаётся единым compiled story, чтобы не ломать `Continue`, replay history и loop-state

Команды:

```bash
tools\compile_ink.bat chapter_01
./tools/compile_ink.sh chapter_01
```

Bulk-компиляция по умолчанию пропускает `*_old.ink`, чтобы архивные story-черновики не засоряли рабочее дерево лишними `.json`. Include-файлы в `main/story/chapters/` не компилируются отдельно и попадают в runtime через `chapter_01.ink`.

## V2 GUI-компоненты

- `main_menu_v2` — стартовое меню и карточка текущей итерации
- `dialogue_v2` — фон, диалоговая панель, портрет, typewriter
- `hotspots_v2` — интерактивные зоны и scene objects
- `nav_buttons_v2` — направленная навигация по `exits`
- `hud_v2` — локация, inventory badge, phone badge
- `choice_v2` — экран выбора
- `inventory_v2` — модальный инвентарь
- `phone_v2` — приложения телефона, SMS, quests, notes
- `map_v2` — карта и dossier-панель
- `effects` — визуальные оверлеи grain/scan/vignette

## Ограничения и открытые хвосты

- `ui_manager_v2` сейчас отдаёт `scene_controller` лимиты:
  - максимум `6` hotspot'ов на сцену
  - максимум `4` scene objects на сцену
- `dialogue_manager_ink.lua` уже собирает очередь эффектов (`# sfx`, `# shake`, `# pulse`), но активный `v2` UI пока их не потребляет
- runtime-loader всё ещё однофайловый: `chapter_01.json` зашит напрямую, но source-level story уже разбит на include-главы в `main/story/chapters/`; отдельный multi-json chapter routing пока не выделен

## Где читать дальше

- `docs/reference/LOOP_SYSTEM.md`
- `docs/reference/CODEX_CONTEXT.md`
- `main/story/README.md`
