# CODEX_CONTEXT

Актуально на `2026-04-23`, ветка `AVOS_S`.

Этот файл нужен как короткая стартовая карта проекта для новых Codex-сессий.

## Что читать первым

1. `README.md`
2. `docs/reference/ARCHITECTURE.md`
3. `docs/reference/LOOP_SYSTEM.md`
4. `docs/reference/TODO.md`
5. `main/story/README_INK.md`

Исторические материалы в `docs/archive/legacy-ui/` полезны только как архив, а не как source of truth для текущего runtime.

## Активная точка входа

- `game.project` -> `/main/main_v2.collectionc`
- активная коллекция: `main/main_v2.collection`
- legacy runtime отключён и архивирован в `archive/legacy_runtime/`

## Текущая карта runtime

- `main/scripts/dialogue_manager_ink.lua`
  - Ink runtime
  - возвращает `current_node`, `commands`, `effects`
  - прокидывает в Ink и run-state, и meta-state

- `main/scripts/game_state.lua`
  - runtime-state текущего прохождения
  - flags, inventory, quests, sms, notes, current_scene
  - phone-квесты сортируются по приоритету `active -> failed -> done`, чтобы завершённые не вытесняли активные из двух видимых карточек
  - SMS-чаты сортируются по свежести последнего сообщения; новые SMS/notes автоматически получают fallback `time`, а `get_sms()` / `get_notes()` возвращают копии, а не живые таблицы state

- `main/scripts/save_manager.lua`
  - persisted run-state текущей попытки
  - нужен для `Continue`

- `main/scripts/meta_state.lua`
  - persisted meta-state между итерациями
  - хранит `iteration_number`, `completed_iterations`, `loop_awareness`

- `main/scripts/scene_controller.lua`
  - управление exploration-сценами
  - читает `main/scripts/scenes.lua`
  - умеет `reset()` для чистого старта новой итерации
  - больше не содержит legacy phone scene: телефон живёт вне `scene_controller`

- `main/gui/ui_manager_v2.script`
  - главный оркестратор UI
  - загружает `/main/story/chapter_01.json`
  - управляет `menu`, `exploration`, `dialogue`
  - на `chapter_finished` переводит игру в следующую итерацию
  - поддерживает `reset_iteration`, который вручную возвращает проект к `Итерации 001`
  - держит compatibility alias `phone_home -> open_phone()`, чтобы старые Ink-knot'ы не ломались после удаления legacy scene
  - прокидывает текущий `loop_label` в `dialogue_v2`, поэтому диалоговая dossier-плашка теперь берёт номер итерации из `meta_state`
  - ведёт рабочие `AUTO/SKIP` режимы диалога, а не только локальную подсветку кнопок
  - синхронизирует `map_v2` через `set_points` и обрабатывает `route/save/share` как реальные runtime-действия
  - двусторонне зеркалит legacy inventory flags `has_mug/has_phone` в реальные предметы `mug/phone`, чтобы derived-инвентарь не зависал в устаревшем состоянии

- `main/gui/components_v2/inventory_v2.gui_script`
  - показывает только рабочие MVP verbs `use`, `inspect`, `read`
  - `combine/give` сейчас скрыты из footer целиком, а не висят как фальшивые disabled-кнопки

## Где лежит контент

- сценарий: `main/story/chapter_01.ink` (composition root), `main/story/chapters/*.ink`, `main/story/chapter_01.json`
- архивный story-черновик: `main/story/chapter_01_old.ink`
- сцены: `main/scripts/scenes.lua`
- предметы: `main/scripts/items_catalog.lua`
- квесты: `main/scripts/quests.lua`
- фоны: `main/images/backgrounds/<bg_name>.atlas`
- hotspot sprites: `main/images/hotspots.atlas`
- scene objects: `main/images/scene_objects.atlas`

## Важные caveats перед работой

- после изменения `.ink` нужно перекомпилировать `.json`
- bulk compile теперь пропускает `*_old.ink`, чтобы архивные источники не создавали лишние `.json`
- runtime всё ещё грузит один `chapter_01.json`, но source-level story уже разбит на include-файлы в `main/story/chapters/`
- `chapter_01.json` всё ещё зашит напрямую в `ui_manager_v2.script`; multi-chapter loader ещё не выделен
- `dialogue_manager_ink.lua` уже поддерживает `# sfx`, `# shake`, `# pulse`, а `ui_manager_v2` забирает `dm.get_effects()`; новые SFX требуют записи и в `sfx_player`, и в `M.SFX_URLS`
- в `main_menu_v2` больше нет реального gallery-flow: его место заняла кнопка `СБРОСИТЬ ИТЕРАЦИЮ`
- `map_v2` уже не purely decorative overlay, но большой хвост по world-map всё ещё живёт в Ink-узле `city_map_hub`; полного объединения схемы пока нет

## Если задача звучит как «изучи проект»

Под этим понимать:

1. сначала прочитать этот файл, `README.md` и `docs/reference/ARCHITECTURE.md`
2. затем проверить `docs/reference/LOOP_SYSTEM.md`, если задача касается сюжета, сейвов или итераций
3. только после этого дочитывать конкретные затронутые модули

Полный re-audit всего репозитория без отдельной просьбы не нужен.
