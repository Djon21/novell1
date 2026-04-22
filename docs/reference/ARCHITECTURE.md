# Архитектура AVOS_S

Актуально на `2026-04-22`.

## Точка входа

- `game.project` запускает `/main/main_v2.collectionc`
- `main/main_v2.collection` содержит:
  - `ui_manager_v2`
  - `main_menu_v2`
  - `dialogue_v2`
  - `hotspots_v2`
  - `nav_buttons_v2`
  - `hud_v2`
  - `choice_v2`
  - `inventory_v2`
  - `phone_v2`
  - `map_v2`
  - `effects`
  - `music_player`
  - `sfx_player`

## Основной runtime-поток

### 1. Меню / старт игры

- `ui_manager_v2.script` ловит `start_game` или `continue_game`
- загружает `/main/story/chapter_01.json`
- передаёт байты в `dialogue_manager_ink.lua`

### 2. Диалоговый режим

- `dialogue_manager_ink.lua` хранит текущее состояние Ink
- возвращает `current_node`, `background`, `commands`, `effects`
- `ui_manager_v2.script` решает, что показать:
  - `dialogue_v2` для обычной реплики
  - `choice_v2` для вариантов
  - `main_menu_v2` при возврате в меню

### 3. Exploration-режим

- Ink-теги `# explore:scene_id` / `# goto_scene:scene_id` дают команду `scene_controller.lua`
- `scene_controller.lua` читает описание сцены из `main/scripts/scenes.lua`
- `scene_controller` через `set_ui()` прокидывает в GUI:
  - фон сцены
  - hotspot'ы
  - scene objects
- рендеринг выполняет `hotspots_v2.gui_script`

### 4. Состояние игры

- `main/scripts/game_state.lua` — единый source of truth для:
  - flags
  - inventory
  - quests
  - current_scene
  - sms / unread counters
  - notes / mail / clues / call log
- UI обновляется через `gs.subscribe(...)`

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
- синхронизирует `mc_gender`, `mc_name`, `npc_name` с `save_manager.lua`

### `main/scripts/scene_controller.lua`

- активирует / завершает exploration-сцены
- применяет `condition()` и `visible_when()`
- умеет:
  - `enter(scene_id)`
  - `exit()`
  - `return_to_last_scene()`
  - `on_hotspot_click(index)`
  - `serialize()` / `deserialize()`

### `main/scripts/scenes.lua`

- описывает сцены как данные, не как код
- текущее описание сцены может включать:
  - `bg`
  - `label` / `name`
  - `on_enter`
  - `objects`
  - `hotspots`
  - `exits`

### `main/scripts/game_state.lua`

- хранит runtime-state
- умеет:
  - `get_flag()` / `set_flag()`
  - `has_item()` / `add_item()` / `remove_item()`
  - `set_quest()` / `get_quests()`
  - `add_sms()` / `get_sms_contacts()` / `get_sms_unread_total()`
  - `add_note()` / `get_notes()`
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
  - `components_v2/*`

## V2 GUI-компоненты

- `main_menu_v2` — стартовое меню
- `dialogue_v2` — фон, диалоговая панель, портрет, typewriter
- `hotspots_v2` — интерактивные зоны и scene objects
- `nav_buttons_v2` — направленная навигация по `exits`
- `hud_v2` — локация, inventory badge, phone badge
- `choice_v2` — экран выбора
- `inventory_v2` — модальный инвентарь
- `phone_v2` — приложения телефона, SMS, quests, notes и др.
- `map_v2` — карта и dossier-панель
- `effects` — визуальные оверлеи grain/scan/vignette

## Контент и данные

### Сценарий

- исходник: `main/story/chapter_01.ink`
- runtime-ресурс: `main/story/chapter_01.json`
- story-loader в текущем виде жёстко читает именно `chapter_01.json`

### Графика

- `main/images/backgrounds/*.atlas` — по одному dedicated atlas на каждый fullscreen фон.
  Все нормализованы к animation id `scene_bg`. Регистрируются в `ui_manager_v2.script`
  через `go.property` + `DEDICATED_BG_ATLAS_PROPS`.
- `main/images/hotspots.atlas` — иконки hotspot'ов (`hotspot_circle/ring/dot`)
- `main/images/scene_objects.atlas` — overlay-спрайты (`mobile` и т.д.)
- `main/images/v2.atlas` — v2-портреты и часть v2-ассетов
- `main/images/ui_common.atlas` — общие декоративные элементы UI
- `main/images/backgrounds.atlas` — **legacy**, используется только v1 GUI
  (`main/gui/components/`). V2 на него не ссылается
- `main/images/characters.atlas` — legacy portrait atlas

Архитектура фон-атласов задокументирована в
`docs/reference/BACKGROUND_SYSTEM_MIGRATION_PLAN.md`.

### Каталоги контента

- `main/scripts/items_catalog.lua` — инвентарь
- `main/scripts/quests.lua` — квесты
- `main/scripts/scenes.lua` — exploration-сцены

## Ink-теги, которые поддерживает runtime

- `# bg:name`
- `# color:r,g,b`
- `# speaker:name|mc|npc|none`
- `# sfx:name`
- `# shake:intensity,duration`
- `# pulse:duration,r,g,b`
- `# flag:name=value`
- `# item:add:id`
- `# item:remove:id`
- `# quest:start:id`
- `# quest:done:id`
- `# quest:fail:id`
- `# sms:add:contact:text`
- `# note:add:title:body`
- `# phone:close`
- `# goto_scene:scene_id`
- `# explore:scene_id`
- `# return_to_scene`

## Сохранения

- `save_manager.lua` пишет состояние через `sys.save()`
- в сейве лежат:
  - `mc_gender`
  - `chapter`
  - `ink_state`
  - `game_state`
- `dialogue_manager_ink.lua` отдельно сохраняет индекс текущего параграфа внутри пачки Ink, чтобы `Continue` возвращал игрока в точную позицию

## Актуальные ограничения

- `ui_manager_v2` сейчас отдаёт `scene_controller` лимиты:
  - максимум `6` hotspot'ов на сцену
  - максимум `4` scene objects на сцену
- `dialogue_manager_ink` собирает очередь эффектов (`# sfx`, `# shake`, `# pulse`), но активный `v2`-UI пока их не потребляет
- legacy stack остаётся в проекте и может использоваться как reference, но его документация должна считаться архивной
