# Архитектура AVOS_S

Актуально на `2026-05-07`.

## Entry Point

- `game.project` запускает `/main/main_v2.collectionc`
- активная collection: `main/main_v2.collection`
- legacy runtime хранится в `archive/legacy_runtime/` и не используется как fallback

## Runtime Flow

### Меню

- `main_menu_v2` открывается через `ui_manager_v2.script` → `message_flow.lua`/`overlay_flow.lua`
- `start_game` очищает run-state и стартует текущую итерацию заново
- `continue_game` доступен только при наличии run-save
- `reset_iteration` сбрасывает run-state и meta-state, затем стартует с `Итерации 001`
- achievements скрыты до отдельной реализации экрана

### Ink И Диалог

- `ui_manager_v2.script` грузит `/main/story/chapter_01.json` через `run_state.lua`
- байты передаются в `main/scripts/dialogue_manager_ink.lua`
- `dialogue_manager_ink.lua` оборачивает `defold-ink`, применяет теги и отдаёт UI:
  - текущий node
  - background
  - commands
  - one-shot effects
- `dialogue_v2` показывает реплики, портреты, typewriter и loop-label из `meta_state`
- `AUTO/SKIP` реализованы в `main/gui/modules/ui_manager_v2/dialogue_flow.lua`, останавливаются на `choice`, `end` и exploration
- бэклог реплик и выборов хранится в `main/scripts/dialogue_backlog.lua` (общий
  Lua-модуль через `[script] shared_state = 1`): `dialogue_flow.lua` пишет через
  `backlog.add(entry)`, `dialogue_v2` читает через `backlog.get_all()`. Так
  устранена пересылка большой таблицы через `msg.post`, упиравшаяся в
  `sys.max_message_data_size`.

### Exploration

- Ink-теги `# explore:scene_id` и `# goto_scene:scene_id` переводят игру в `scene_controller`
- `scene_controller.lua` читает сцены из `main/scripts/scenes.lua`
- навигация сейчас живёт на hotspots и карте
- `nav_buttons_v2` удалён из активной схемы
- телефон больше не scene; новый контент открывает телефон через UI/Ink-теги телефона

### Карта

- карта для нового контента открывается внутри телефона через Ink-тег `# phone:map`
- `# phone:map` открывает `phone_v2` и сразу переключает его на `phone_map.gui`
- выбор POI отправляет `map_travel { scene }` обратно в `#ui_manager_v2`
- `message_flow.lua` закрывает телефон и открывает выбранный hub через `scene_controller.enter(scene_id)`

### Телефон

Телефон data-driven и хранит контент в `game_state`, а не в статичных Ink-экранах.

Активные разделы:

- SMS
- quests
- notes
- mail
- call log
- clues
- camera
- terminal
- map entry

Ink добавляет данные через теги `sms`, `quest`, `note`, `mail`, `call`, `clue`, `camera`, `term`.

### Инвентарь

- `game_state` хранит список уникальных `item_id` с лимитом `12`
- metadata берётся из `main/scripts/items_catalog.lua`
- рабочие verbs MVP: `use`, `inspect`, `read`, `give`, `combine`
- `give` работает только в сценах, где задано поле `npc`
- `combine` работает как двухкликовая операция внутри инвентаря:
  выбрать предмет A → нажать `СОЕДИНИТЬ` → выбрать предмет B
- combine-knot ищется по канонической паре:
  `inv_combine_<low>_with_<high>` → `inv_combine_fallback` → `inv_fallback`
- `inventory_flow.lua` ищет Ink-knot в порядке:
  - `inv_<scene_id>_<verb>_<item_id>`
  - `inv_<verb>_<item_id>`
  - `inv_<verb>_fallback`
  - `inv_fallback`
- `phone + use/read` открывает телефон напрямую

## State Model

### `game_state.lua`

Run-state текущего прохождения:

- flags
- inventory
- quests
- current_scene
- SMS / notes
- mail / call log / clues
- camera feed
- terminal lines

Важно:

`quests` здесь — это phone quests текущей итерации.
Они являются частью run-state и очищаются при старте новой итерации вместе с `game_state`.

Не использовать `game_state.quests` как долгосрочный журнал петли.
Если нужна память между итерациями, она должна жить в `meta_state` или отдельном persistent journal-state.

Все getters для списков возвращают копии, чтобы GUI не мутировал state напрямую.

### `save_manager.lua`

Сохраняет только run-state для `Continue`:

- `mc_gender`
- `chapter`
- `ink_state`
- `game_state`

### `meta_state.lua`

Persistent meta-state временной петли:

- `iteration_number`
- `completed_iterations`
- `loop_awareness`
- `false_endings_seen`
- `false_endings_count`
- выбор персонажа между итерациями

Ложные концовки учитываются через `record_false_ending(id)`. Истинная концовка открывается после двух уникальных ложных.

## Ink Pipeline

- root: `main/story/chapter_01.ink`
- include-модули: `main/story/chapters/*.ink`
- runtime JSON: `main/story/chapter_01.json`

Команды:

```bash
tools\compile_ink.bat
tools\compile_ink.bat chapter_01
```

Git Bash / Linux:

```bash
./tools/compile_ink.sh
./tools/compile_ink.sh chapter_01
```

## V2 GUI Components

- `main_menu_v2` — меню и состояние итерации
- `dialogue_v2` — фон, портрет, dialogue panel, typewriter
- `hotspots_v2` — hotspots и scene objects
- `hud_v2` — HUD, badges, быстрые входы в overlays
- `choice_v2` — выборы Ink
- `inventory_v2` — инвентарь
- `phone_v2` / `phone_v2_root` / `phone_*.gui` — телефон и его приложения
- `map_v2` — карта, dossier и hub-mode
- `effects` — screen shake, pulse, scan/vignette overlays

## UI Manager V2 Modules

`main/gui/ui_manager_v2.script` сейчас работает как центральный Defold-адаптер, а не как монолит всей логики.

Основная логика вынесена в `main/gui/modules/ui_manager_v2/`:

- `message_flow.lua` — маршрутизация `on_message`
- `overlay_flow.lua` — menu/exploration/dialogue/choice/inventory/map overlays
- `dialogue_flow.lua` — `AUTO`, `SKIP`, backlog
- `dm_commands.lua` — выполнение команд из Ink-тегов
- `inventory_flow.lua` — verbs предметов и armed-use
- `phone_flow.lua` — открыть/закрыть телефон и приложения
- `map_flow.lua` — map pins, route/save/share, hub-mode
- `scene_flow.lua` — адаптер `scene_controller -> hotspots_v2`
- `background_flow.lua` — fullscreen backgrounds и location label
- `effects_flow.lua` — one-shot effects
- `run_state.lua` — persist/restore/reset run-state

Подробная карта: `docs/reference/UI_MANAGER_V2_MODULES.md`.

## Ограничения

- story-loader пока однофайловый: `/main/story/chapter_01.json`
- каждый новый fullscreen background должен иметь dedicated atlas в `main/images/backgrounds/`
- новые SFX требуют регистрацию и в `sfx_player`, и в `M.SFX_URLS` внутри `ui_manager_v2.script`; воспроизведение идёт через `effects_flow.lua`
- legacy GUI и legacy atlas-ы не считаются supported fallback

## Читать Дальше

- `docs/reference/LOOP_SYSTEM.md`
- `docs/reference/INVENTORY_SYSTEM.md`
- `docs/guides/HOW_TO_WRITE_INK.md`
- `docs/reference/TODO.md`
