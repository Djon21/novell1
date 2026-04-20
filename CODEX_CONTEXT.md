# CODEX_CONTEXT

Актуально на `2026-04-20`, коммит `ab82f63`, ветка `AVOS_S`.

Этот файл нужен для новых сессий Codex, чтобы не переизучать проект с нуля каждый раз.

## Как использовать в новой сессии

Стартовая команда:

```text
Прочитай CODEX_CONTEXT.md. Если я пишу "изучи этот проект", не делай полный разбор заново:
опирайся на этот файл, потом быстро проверь, что изменилось и что могло устареть.
```

## Правило для команды "изучи этот проект"

Под "изучи этот проект" понимать:

1. Взять этот файл как базовую карту проекта.
2. Проверить, что изменилось с момента последнего обновления файла.
3. Дочитать только изменённые, связанные или подозрительно устаревшие части.
4. Не делать полный повторный обзор всего репозитория без отдельной просьбы.

Важно: данные в этом файле могут устаревать. Это не immutable-спецификация, а стартовая карта проекта.

Если нужен полный повторный разбор, пользователь должен явно написать:

```text
изучи проект с нуля
```

## Текущая карта проекта

### Точка входа

- Текущий bootstrap: `game.project` -> `main_v2.collectionc`
- Активная главная коллекция: `main/main_v2.collection`
- Старый UI-стек всё ещё лежит в проекте (`main/main.collection`), но текущий запуск идёт через v2

### Основное runtime-ядро

- `main/scripts/dialogue_manager_ink.lua`
  - главный сюжетный движок поверх `defold-ink`
  - загружает `chapter_01.json`
  - превращает Ink в унифицированные UI-узлы: `dialogue`, `choice`, `end`
  - парсит Ink-теги в:
    - одноразовые эффекты (`sfx`, `shake`, `pulse`)
    - команды (`set_flag`, `add_item`, `remove_item`, `set_quest`, `add_sms`, `add_note`, `enter_scene`, `return_to_scene`, `phone_close`)

- `main/scripts/game_state.lua`
  - единый runtime-state для point-and-click слоя
  - хранит:
    - flags
    - inventory
    - quests
    - current_scene
    - sms / sms_unread
    - notes
  - поддерживает подписки через `subscribe(cb)`

- `main/scripts/scene_controller.lua`
  - управление exploration-сценами
  - рендерит фон, hotspot'ы и scene objects через UI-интерфейс
  - умеет:
    - `enter(scene_id)`
    - `exit()`
    - `return_to_last_scene()`
    - `on_hotspot_click(index)`

- `main/scripts/scenes.lua`
  - каталог сцен как данные, а не как логика
  - использует:
    - `hotspots`
    - `objects`
    - `on_enter`
    - `condition(gs)`
    - `visible_when(gs)`

- `main/scripts/save_manager.lua`
  - сохранение через `sys.save()`
  - хранит:
    - `mc_gender`
    - `chapter`
    - `ink_state`
    - `game_state`

### UI v2

- `main/gui/ui_manager_v2.script`
  - текущий оркестратор интерфейса
  - базовые режимы:
    - `menu`
    - `exploration`
    - `dialogue`
  - поверх них модалки:
    - `choice`
    - `inventory`
    - `phone`
    - `map`

- `main/gui/components_v2/*`
  - `main_menu_v2`
  - `hud_v2`
  - `dialogue_v2`
  - `choice_v2`
  - `inventory_v2`
  - `phone_v2`
  - `map_v2`
  - `hotspots_v2`
  - `nav_buttons_v2`
  - `effects`

### Legacy UI

- Старый стек ещё существует:
  - `main/main.collection`
  - `main/gui/ui_manager.script`
  - `main/gui/components/*`
- Он полезен как референс и как fallback-контекст, но не является текущей точкой входа.

## Поток управления

Обычный сценарный путь:

1. `ui_manager_v2` загружает `main/story/chapter_01.json`
2. `dialogue_manager_ink` отдаёт текущий узел UI
3. `ui_manager_v2` решает, что показывать:
   - диалог
   - выбор
   - конец
   - или exploration-сцену

Exploration-путь:

1. Ink-команда `enter_scene` переводит управление в `scene_controller`
2. `scene_controller` рендерит scene background / hotspots / objects
3. hotspot может:
   - перейти в другую сцену
   - поставить флаг
   - добавить/убрать предмет
   - открыть ink-knot и вернуть игрока в dialogue-режим

## Контент

- Сценарий:
  - `main/story/chapter_01.ink`
  - `main/story/chapter_01.json`
- Предметы:
  - `main/scripts/items_catalog.lua`
- Квесты:
  - `main/scripts/quests.lua`
- Графика:
  - `main/images/*`
  - `main/images/v2/*`
- Звуки:
  - `main/sounds/*`

## Что уже было замечено

### Документация местами устарела

На момент обновления файла некоторые документы всё ещё ссылаются на старый UI:

- `README.md`
- `main/story/README.md`

Там встречаются упоминания `novel_ui.gui_script`, хотя текущий bootstrap уже идёт через `main_v2.collection` и `ui_manager_v2.script`.

### Миграция на v2 завершена, модалки работают

Все 20 шагов v2-интеграции выполнены. Bootstrap переключён на `main_v2.collection`. Hotspots реализованы и подключены.

**Статус модалок (исправлено 2026-04-20)**: `inventory_v2`, `phone_v2`, `map_v2` работают корректно. Проблемы с отображением динамического контента решены через:
1. Исправление alpha inheritance у контейнеров (`color.w=1.0`, `size=0×0`)
2. Использование абсолютных координат вместо `gui.set_parent` для динамических нод
3. Корректировка z-index (backdrop=0.4, динамика=0.55-0.57, статика=0.51-0.53)

Ink-команды `set_quest`, `add_sms`, `add_note`, `phone_close` обрабатываются в `ui_manager_v2.script` (коммит 987e900).

**Важное правило для динамических GUI-нод**: В Defold, если родительская нода имеет `size=0×0`, дочерние ноды могут не рендериться. Для динамически создаваемых элементов (через `gui.new_box_node`, `gui.new_text_node`) использовать абсолютные экранные координаты без `gui.set_parent`. См. реализацию в `inventory_v2.gui_script`, `phone_v2.gui_script`, `map_v2.gui_script`.

### Навигация v2 подготовлена под `exits`

`nav_buttons_v2.gui_script` уже рассчитан на данные `exits`, но в `scenes.lua` эта модель используется не везде. Если задача касается навигации между комнатами, сначала проверять, насколько `scenes.lua` действительно заполнен под новую nav-схему.

## Что проверять в первую очередь при актуализации

Если проект менялся, сначала проверять:

1. `game.project`
2. `main/main_v2.collection`
3. `main/gui/ui_manager_v2.script`
4. `main/scripts/dialogue_manager_ink.lua`
5. `main/scripts/scene_controller.lua`
6. `main/scripts/scenes.lua`
7. затронутые `components_v2/*`

## Разработка в нескольких ветках

Проект разрабатывается параллельно в 4 ветках:
- `AVOS_C` — начало миграции на v2
- `AVOS_G` — отлов части багов
- `AVOS_Q` — мерджи и интеграция
- `AVOS_S` — текущая рабочая ветка (продолжение работы над v2)

Изменения из разных веток периодически мерджатся. При работе в `AVOS_S` учитывать, что часть фиксов могла прийти из других веток.

## Если обновляешь этот файл

Желательно обновлять:

- дату
- commit hash
- точку входа
- изменения в архитектуре
- список известных устареваний
