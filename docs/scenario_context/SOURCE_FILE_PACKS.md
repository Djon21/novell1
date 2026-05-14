# Source File Packs For GPT

Эта папка с документацией не должна заменять реальные исходники. Она нужна, чтобы GPT быстрее понял проект и не держал в контексте всё подряд.

Если задача требует точной правки кода, координат, тегов или условий, GPT нужно дать не только документы, но и актуальные source files ниже.

## Минимальный базовый пакет

Давать почти всегда:

- `docs/scenario_context/README.md`
- `docs/scenario_context/ACTIVE_TASK.md`
- `docs/scenario_context/STORY_BIBLE_SHORT.md`
- `docs/scenario_context/WRITING_RULES.md`
- `docs/scenario_context/INK_TAG_REFERENCE.md`
- `docs/scenario_context/INK_STRUCTURE.md`
- `docs/scenario_context/CURRENT_STATE_AND_FLAGS.md`

Если GPT помогает с локациями:

- `docs/scenario_context/HUB_AND_HOTSPOT_WORKFLOW.md`
- `docs/scenario_context/BACKGROUND_CATALOG.md`

## Ink-сцена без новых тегов

Если надо написать или отредактировать обычную сцену:

- нужный файл из `main/story/chapters/`;
- соседний файл по дню, если сцена стоит на переходе между днями;
- `docs/scenario_context/SCENE_SUMMARIES.md`.

Пример для парка как чистой Ink-сцены:

- `main/story/chapters/02_sunday_date.ink`
- `docs/scenario_context/SCENE_SUMMARIES.md`
- `docs/scenario_context/STORY_BIBLE_SHORT.md`
- `docs/scenario_context/WRITING_RULES.md`


## Имя, пол, обращение и склонения

Если задача касается выбранного персонажа, имён, местоимений, формы обращения или грамматики фраз с именами, дополнительно загрузи:

- `main/story/chapters/00_bootstrap.ink`
- `main/story/chapters/01_apartment.ink`
- текущий Ink-файл сцены, где используется имя

Почему это нужно:

- `00_bootstrap.ink` содержит стартовые `mc_name`, `npc_name` и падежные формы `mc_name_*`, `npc_name_*`.
- `01_apartment.ink` задаёт реальные значения после выбора персонажа.
- Сценарный файл нужен, чтобы заменить прямые `{mc_name}` / `{npc_name}` на правильные падежные формы только там, где это действительно требуется.

`dialogue_manager_ink.lua` нужен только если меняется синхронизация этих переменных со старыми сохранениями или save_manager. Для обычной правки текста достаточно Ink-файлов.

## Ink-сцена с тегами

Если сцена открывает карту, телефон, рекламу, exploration mode, фон, инвентарь или другой runtime-эффект, обычно достаточно добавить:

- `docs/scenario_context/INK_TAG_REFERENCE.md`
- `docs/guides/HOW_TO_WRITE_INK.md`

`main/scripts/dialogue_manager_ink.lua` нужен только если:

- добавляется новый тег;
- меняется поведение существующего тега;
- есть подозрение, что `INK_TAG_REFERENCE.md` устарел;
- нужно отладить баг парсинга или порядка выполнения тегов.

Если задача связана с рекламой:

- `docs/guides/YANDEX_SDK_AND_ADS.md`
- файлы, где подключён Yandex SDK и message flow рекламы.

## Exploration hub или хотспоты

Если парк, квартира, офис или другая локация правится как exploration hub, а не только как текстовая Ink-сцена, обязательно дать:

- нужный файл из `main/data/scenes/`;
- `main/data/scenes/_shared.lua`;
- `main/scripts/scenes.lua`;
- `docs/scenario_context/HUB_AND_HOTSPOT_WORKFLOW.md`;
- `docs/scenario_context/BACKGROUND_CATALOG.md`.

Пример для парка:

- `main/data/scenes/locations.lua`
- `main/data/scenes/_shared.lua`
- `main/scripts/scenes.lua`
- `main/story/chapters/02_sunday_date.ink`, если хотспоты вызывают Ink-knot из свидания
- скрин или фон парка, если нужно подобрать `rect`

Почему GPT попросит именно эти файлы:

- `locations.lua` содержит реальные сцены парка и хотспоты.
- `_shared.lua` содержит реальные стили, иконки и helper-функции.
- `scenes.lua` показывает, как сцены собираются и какие action types поддерживаются.
- Ink-файл нужен, чтобы проверить, существуют ли knot names для `action = { type = "ink_knot", knot = "..." }`.

## Новый фон или новая локация

Если нужно не просто расставить хотспоты, а добавить новую локацию:

- нужный `main/data/scenes/*.lua`;
- `main/data/scenes/_shared.lua`;
- `main/scripts/scenes.lua`;
- файлы atlas/collection/gui, если фон ещё не подключён;
- `docs/guides/HOW_TO_ADD_SCENES.md`;
- `docs/scenario_context/BACKGROUND_CATALOG.md`.

Если фон уже подключён и имеет background id, atlas-файлы можно не давать.

## Телефон, карта, SMS

Если задача связана с телефоном или картой:

- `docs/guides/PHONE_SYSTEM.md`
- `docs/guides/HUB_SYSTEM.md`, если есть переходы в exploration hub
- `docs/scenario_context/INK_TAG_REFERENCE.md`, если карта вызывается из Ink
- соответствующие GUI/script файлы телефона, если меняется поведение приложения
- `92_phone_sms.ink` или `93_phone_messenger.ink`, если меняется текст переписки

Для карты важно проверять реальные `poi_id`, а не брать их из памяти.

## Инвентарь и применение предметов

Если задача связана с предметами:

- `docs/reference/INVENTORY_SYSTEM.md`
- `main/story/chapters/91_inventory_actions.ink`
- scene Lua-файл с хотспотом, на который применяется предмет
- файлы inventory/state, если меняется логика предметов

## UI/GUI поведение

Если задача про кнопки HUD, лог, телефон, модалки, перекрытия слоёв или клики:

- нужный `.gui`;
- его `.gui_script`;
- `main/gui/ui_manager_v2.script`;
- соответствующий модуль из `main/gui/modules/ui_manager_v2/`;
- `main/gui/modules/messages.lua`, если есть новые `msg`.

Документация может объяснить архитектуру, но не заменяет текущую структуру нод в `.gui`.

## Быстрая формула

Если GPT должен писать художественный текст, ему достаточно документов и 1-2 Ink-файлов.

Если GPT должен править игру как систему, ему нужны документы плюс живые исходники того слоя, который меняется.

Если GPT просто спрашивает "какие теги доступны", не давай ему `dialogue_manager_ink.lua`; давай `INK_TAG_REFERENCE.md`.
