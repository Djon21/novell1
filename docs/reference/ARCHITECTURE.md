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
- пункт `ДОСТИЖЕНИЯ` временно скрыт из активного меню, пока под него нет отдельного рабочего экрана
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
- при `render_dialogue` прокидывает в `dialogue_v2` текущие `iteration_number` / `iteration_label`, чтобы dossier-плашка и loop-counter не жили на старом `#017`
- runtime-метки текущей петли больше не захардкожены и в смежном UI: `items_catalog.get_runtime()` подставляет актуальный `iteration_label` для инвентаря, а `map_v2` нормализует только текущие dossier-штампы, не трогая намеренные ссылки на прошлые петли вроде `#015/#016`
- `AUTO` и `SKIP` в `dialogue_v2` больше не декоративные: `ui_manager_v2` ведёт их как взаимоисключающие режимы автолистания и останавливает на `choice` / `end`

### 3. Exploration-режим

- Ink-теги `# explore:scene_id` и `# goto_scene:scene_id` приводят к входу в `scene_controller.lua`
- `main/scripts/scene_controller.lua` читает описания сцен из `main/scripts/scenes.lua`
- `scene_controller` через `set_ui()` прокидывает в GUI:
  - фон сцены
  - hotspot'ы
  - scene objects
- `hotspots_v2.gui_script` рендерит интерактив поверх фона
- legacy `phone_home` больше не зарегистрирован в `scenes.lua`; телефон теперь overlay-only и открывается через `ui_manager_v2`

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

Для текущего MVP инвентарь хранится как список уникальных `item_id` с лимитом `12` слотов. `get_inventory()` возвращает копию массива, чтобы GUI не мутировал state напрямую.
SMS и заметки в `game_state` теперь тоже читаются через безопасные копии, а не через живые внутренние таблицы. Для новых SMS runtime сам назначает fallback `time` и монотонный `seq`, чтобы `phone_v2` мог стабильно рендерить превью и порядок чатов даже после загрузки старых сейвов.
Названия, описания и шаги квестов телефон берёт из `main/scripts/quests.lua`; chapter bootstrap квесты вроде `make_coffee` и `find_phone` тоже должны быть зарегистрированы там, а не только стартовать из Ink.
Для phone-квестов `game_state.get_quests()` сейчас отдаёт список с приоритетом `active -> failed -> done`; `phone_v2` показывает первые две карточки и помечает в заголовке, если задач больше, чем видно на экране.

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
- держит registry top-level knot'ов compiled story и умеет принимать inventory-context (`inventory_item_*`) перед side-knot прыжком

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
- применяет Ink-команды для data-driven телефона:
  - `# sms:add:*`
  - `# sms:read:*`
  - `# quest:*`
  - `# note:add:*`
  - `# meta:add:*`
- двусторонне синхронизирует legacy-derived предметы инвентаря: `has_mug/has_phone` не только добавляют `mug/phone`, но и убирают их обратно, если старый флаг уже снят
- потребляет one-shot очередь эффектов из `dm.get_effects()`:
  - `# sfx:*` -> `sfx_player`
  - `# shake:*` -> `effects`
  - `# pulse:*` -> `effects`
- держит реальные режимы `dialogue_auto` / `dialogue_skip`: `skip` мгновенно раскрывает typewriter и быстро листает реплики, `auto` ждёт завершения печати и переключает их по таймеру
- обрабатывает MVP-действия инвентаря через Ink-knot contract:
  - `inv_<scene_id>_<verb>_<item_id>`
  - `inv_<verb>_<item_id>`
  - `inv_<verb>_fallback`
  - `inv_fallback`
- special-case: `phone + use/read` открывает `phone_v2` напрямую, без side-knot
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

- `main_menu_v2` — стартовое меню и карточка текущей итерации; в активном списке оставлены только рабочие действия
- `dialogue_v2` — фон, диалоговая панель, портрет, typewriter
- `hotspots_v2` — интерактивные зоны и scene objects
- `nav_buttons_v2` — направленная навигация по `exits`
- `hud_v2` — локация, inventory badge, phone badge
- `choice_v2` — экран выбора
- `inventory_v2` — модальный инвентарь; в footer видны только рабочие verbs MVP: `use`, `inspect`, `read`
- `phone_v2` — data-driven телефон поверх `game_state`; app tiles больше не ведут в статичные Ink-экраны
- `map_v2` — карта и dossier-панель; принимает runtime `set_points`, умеет динамически обновлять pin'ы и шлёт `map_verb` в `ui_manager_v2`
- `effects` — визуальные оверлеи grain/scan/vignette
- старые Ink compatibility-переходы `goto_scene:phone_home` всё ещё допустимы, но `ui_manager_v2` перехватывает их как alias на `open_phone()`, а не как вход в отдельную сцену

## Ограничения и открытые хвосты

- `ui_manager_v2` сейчас отдаёт `scene_controller` лимиты:
  - максимум `6` hotspot'ов на сцену
  - максимум `4` scene objects на сцену
- one-shot эффекты (`# sfx`, `# shake`, `# pulse`) уже подключены к активному `v2`; для новых SFX нужно держать в sync и `sfx_player`, и `M.SFX_URLS` в `ui_manager_v2.script`
- `ui_manager_v2` больше не оставляет `map_verb` пустым: `route/save/share` теперь синхронизируют карту с runtime-флагами и пишут следы в заметки через `game_state`
- runtime-loader всё ещё однофайловый: `chapter_01.json` зашит напрямую, но source-level story уже разбит на include-главы в `main/story/chapters/`; отдельный multi-json chapter routing пока не выделен

## Где читать дальше

- `docs/reference/LOOP_SYSTEM.md`
- `docs/reference/INVENTORY_SYSTEM.md`
- `docs/reference/CODEX_CONTEXT.md`
- `main/story/README_INK.md`
