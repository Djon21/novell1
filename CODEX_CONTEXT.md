# CODEX_CONTEXT

Актуально на `2026-04-22`, commit `9a3d819`, ветка `AVOS_S`.

Этот файл нужен как короткая стартовая карта проекта для новых Codex-сессий.

## Как использовать в новой сессии

Стартовая команда:

```text
Прочитай CODEX_CONTEXT.md, README.md и ARCHITECTURE.md. Не делай полный повторный обзор репозитория без необходимости: сначала опирайся на эти файлы, потом дочитывай только то, что относится к задаче.
```

## Что считать текущим source of truth

1. `README.md`
2. `ARCHITECTURE.md`
3. `TODO.md`
4. `main/story/README.md`
5. затем уже код конкретного модуля

Исторические файлы про миграцию (`GUI_*`, `MIGRATION_*`, `NODE_MAP.md`, `AVOS_V2_PROGRESS.md`) полезны как архив, но не как основной ориентир для текущего runtime.

## Точка входа

- Активный bootstrap: `game.project` -> `/main/main_v2.collectionc`
- Активная главная коллекция: `main/main_v2.collection`
- Legacy-стек (`main/main.collection`, `main/gui/ui_manager.script`, `main/gui/components/`) всё ещё лежит в проекте, но не является боевым входом

## Текущая карта runtime

- `main/scripts/dialogue_manager_ink.lua`
  - Ink runtime
  - возвращает `current_node`, `commands`, `effects`
  - синхронизирует `mc_gender` / `mc_name` / `npc_name`

- `main/scripts/game_state.lua`
  - единый state для exploration/UI
  - flags, inventory, quests, sms, notes, current_scene

- `main/scripts/scene_controller.lua`
  - управление exploration-сценами
  - читает `main/scripts/scenes.lua`
  - через `set_ui()` прокидывает данные в GUI

- `main/gui/ui_manager_v2.script`
  - оркестратор активного UI
  - загружает `/main/story/chapter_01.json`
  - управляет режимами `menu`, `exploration`, `dialogue`
  - открывает overlays `choice`, `inventory`, `phone`, `map`

- `main/gui/components_v2/*`
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

## Где лежит контент

- сценарий: `main/story/chapter_01.ink`, `main/story/chapter_01.json`
- сцены: `main/scripts/scenes.lua`
- предметы: `main/scripts/items_catalog.lua`
- квесты: `main/scripts/quests.lua`
- фоны: `main/images/backgrounds.atlas`
- v2-портреты: `main/images/v2.atlas`

## Важные caveats перед работой

- `chapter_01.json` сейчас зашит напрямую в `ui_manager_v2.script`; мульти-главный loader ещё не выделен
- `dialogue_manager_ink.lua` уже поддерживает `# sfx`, `# shake`, `# pulse`, но `ui_manager_v2` пока не вызывает `dm.get_effects()`
- `nav_buttons_v2` готов к `exits`, но `scenes.lua` пока в основном использует hotspot-переходы
- рабочее дерево может быть грязным: не трогать чужие изменения вне текущей задачи

## Если задача звучит «изучи этот проект»

Под этим понимать:

1. Сначала прочитать этот файл, `README.md` и `ARCHITECTURE.md`
2. Проверить, что изменилось с момента их обновления
3. Дочитать только затронутые или потенциально устаревшие части кода
4. Не делать полный обзор всего репозитория без отдельной просьбы

Если нужен именно полный re-audit, пользователь должен явно попросить:

```text
изучи проект с нуля
```

## Если обновляешь этот файл

Желательно обновить:

- дату
- commit hash
- активную точку входа
- ключевые caveats
- список документов, которые стоит читать первыми
