# CODEX_CONTEXT

Актуально на `2026-05-11`, ветка `AVOS_S`.

Быстрый вход в проект для новой AI-сессии. Поглотил `CONTINUE_HERE.md` и
`DOCUMENTATION_AUDIT.md` — был дубль на дубле.

## Читать Первым

1. `README.md`
2. `docs/reference/ARCHITECTURE.md`
3. `docs/guides/HOW_TO_WRITE_INK.md`
4. `docs/reference/LOOP_SYSTEM.md`
5. `docs/reference/TODO.md`

## Активный Runtime

- `game.project → /main/main_v2.collectionc`
- главный UI: `main/gui/ui_manager_v2.script` (~730 строк, остальное в flow-модулях)
- GUI: `main/gui/components_v2/`
- сценарий: `main/story/chapter_01.ink` + `main/story/chapters/*.ink`
- compiled story: `main/story/chapter_01.json`
- legacy runtime: `archive/legacy_runtime/` — НЕ участвует в игре

## Основные Модули

### Scripts (`main/scripts/`)

- `dialogue_manager_ink.lua` — `defold-ink` wrapper, команды из тегов, one-shot
  эффекты, jump в knot'ы.
- `game_state.lua` — фасад state-системы. Реальная логика в `main/scripts/state/`.
- `scene_controller.lua` — exploration-сцены, hotspots и scene objects.
- `save_manager.lua` — run-save для `Continue`: Ink history + `game_state`.
- `meta_state.lua` — долгий meta-state петли: iteration, awareness, false endings,
  выбор персонажа.
- `log.lua` — единый logger с уровнями (error/warn/info/debug/trace) +
  фильтрация по системам.
- `items_catalog.lua`, `quests.lua`, `phone_contacts.lua` — каталоги.
- `hotspot_editor.lua` — F1-редактор для координат hotspot'ов.

### State channels (`main/scripts/state/`)

Каналы phone-данных, выделенные из game_state.lua:

- `sms.lua` / `messenger.lua` / `mail.lua` / `calls.lua` / `clues.lua` /
  `notes.lua` — каждый держит свой state, normalize, serialize/deserialize.
- `_helpers.lua` — общие clone, format_clock, make_seq, make_default_time.

### Scenes (`main/data/scenes/`)

`scenes.lua` стал фасадом ~60 строк. Реальные сцены:

- `_shared.lua` — STYLE_* + apartment_bg/office_bg helper'ы.
- `apartment.lua`, `apartment_monday.lua`, `apartment_tuesday.lua` — квартира.
- `office.lua`, `locations.lua` — офис, кафе/парк/магазин/бар/обзор/архив.

### UI orchestrator (`main/gui/ui_manager_v2.script` + `main/gui/modules/ui_manager_v2/`)

- `message_flow.lua` — маршрутизация `on_message`
- `overlay_flow.lua` — menu/exploration/dialogue/choice/inventory/map overlays
- `dialogue_flow.lua` — AUTO/SKIP/backlog
- `dialogue_orchestrator.lua` — `handle_dialogue_update` (рендер по типу ноды)
- `dm_commands.lua` — выполнение команд из Ink-тегов
- `lifecycle.lua` — start_new_run / reset_iteration / refresh_menu
- `inventory_flow.lua` — verbs предметов и armed-use
- `phone_flow.lua` — открыть/закрыть телефон и приложения
- `map_flow.lua` — map pins, route/save/share, hub-mode
- `scene_flow.lua` — адаптер `scene_controller -> hotspots_v2`
- `background_flow.lua` — fullscreen backgrounds и location label
- `effects_flow.lua` — one-shot effects
- `run_state.lua` — persist/restore/reset run-state

Подробная карта: `docs/reference/UI_MANAGER_V2_ARCHITECTURE.md` и `UI_MANAGER_V2_MODULES.md`.

### Shared GUI utilities (`main/gui/modules/`)

- `messages.lua` — реестр всех msg.post сообщений (MSG.dialogue_next и т.п.).
- `drag_scroll.lua` — общий drag-to-scroll для phone-app'ов.
- `gui_utils.lua` — общие GUI-хелперы (get_node, set_text, set_color, clamp_text,
  flash_node).
- `gui_animations.lua` — pulsing/bobbing/easing.
- `v2_theme.lua` — централизованные цвета и шрифты.

## Что Важно Помнить

- После правок `.ink` запускать `tools\compile_ink.bat`.
- Runtime грузит один `/main/story/chapter_01.json`.
- `main/story/chapters/New/` больше НЕ рабочая ветка.
- `Continue` чувствителен к структуре compiled Ink JSON. После крупных правок
  сценария проверять и новый старт, и загрузку.
- Телефон data-driven: контент через Ink-теги, хранится в `game_state` / `state/*`.
- Карта для нового контента вызывается из Ink через `# phone:map`.
- `nav_buttons_v2` удалён — навигация через hotspots и карту.
- `open_achievements` — скрытый пункт будущего этапа.
- Папку `skills/` не трогаем.
- Если нужно менять обработку `msg.post("#ui_manager_v2", "...")`, сначала
  смотри `main/gui/modules/ui_manager_v2/message_flow.lua`.
- Если нужно понять «где теперь лежит логика foo» — смотри
  `docs/reference/UI_MANAGER_V2_ARCHITECTURE.md` (таблица «Хочу понять X → смотри Y»).

## Свежие Архитектурные Изменения (май 2026)

- **logger module** — единый `main/scripts/log.lua` заменил 78 разрозненных
  `print("[X]")` + 5 локальных DEBUG_LOG-флагов.
- **messages.lua** — реестр сообщений, демо-миграция в `message_flow.lua`.
- **gui_utils.lua** — общие GUI-хелперы, мигрировано 5 phone-apps.
- **drag_scroll.lua** — извлечён в общий модуль из 6 phone-apps (~330 строк
  дубликата убрано).
- **ui_manager_v2.script**: 875 → 730 строк. Lifecycle и dialogue_orchestrator
  вынесены в flow-модули.
- **scenes.lua**: 1263 → 60 строк (фасад), сцены разбиты по локациям в
  `main/data/scenes/`.
- **game_state.lua**: 1249 → 580 строк (фасад). Channel-домены (sms/messenger/
  mail/calls/clues/notes) вынесены в `main/scripts/state/`.
- **phone_messenger.gui**: 5259 → 1470 строк через Defold templates (по образцу
  phone_sms).

## Texture Profiles + BASIS Universal

`main/textures.texture_profiles` подключён в `game.project`. Backgrounds и
phone-UI идут через BASIS Universal — компрессия в десятки раз для HTML5 build.

## Где Лежит Контент

- Ink: `main/story/chapter_01.ink`, `main/story/chapters/*.ink`
- сцены: `main/data/scenes/*.lua` (фасад: `main/scripts/scenes.lua`)
- предметы: `main/scripts/items_catalog.lua`
- квесты: `main/scripts/quests.lua`
- фоны: `main/images/backgrounds/*.atlas`
- телефонные GUI: `main/gui/components_v2/phone_*.gui`
- телефонные ассеты: `main/images/phone/`
- локализация (заготовлена): `main/data/strings/{ru,en,tr}.json`

## Архив

`docs/archive/` удалена в мае 2026 — миграционные доки больше не нужны,
история в git.

Не использовать как рабочие инструкции:

- `archive/legacy_runtime/` (корень проекта)
