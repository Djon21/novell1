# Source File Packs

Документация в `scenario_context/` — навигация и контекст. Когда задача требует **точной правки кода/координат/тегов**, AI понадобятся реальные source files. Этот документ — рецепты «какие файлы давать под какой тип задачи».

> Перед началом сессии запусти `python tools/generate_scenario_inventory.py` —
> обновит `PROJECT_INVENTORY.md`. С актуальным INVENTORY часто source-файлы
> не нужны вообще (для большинства сценарных задач).

---

## Базовый пакет

Уже описан в `README.md` — 10 документов из `scenario_context/`, включая `PROJECT_INVENTORY.md`. Дальше — добавки под конкретные задачи.

Важно: если GPT/file search находит старую копию того же source-файла, она не
заменяет файл из текущей сессии. Для точной правки загружай свежий файл как
`/mnt/data/<file>` и проси AI опираться только на него. Старые одноимённые
chunks из поиска считать ненадёжными, пока пользователь явно не подтвердил, что
это текущая версия.

---

## Чистый сценарный текст (ink без новых тегов)

Достаточно базового пакета **+ нужный ink-файл**:

- `main/story/chapters/<нужный>.ink`

Структура: квартира (все дни) — в `10_apartment.ink`. Сцены в локациях — в `chapters/locations/<location>_<day>.ink` (например `park_sunday.ink`, `cafe_monday.ink`). Если задача про конкретную локацию в конкретный день — давай именно этот файл.

**Не нужно**: `dialogue_manager_ink.lua`, lua-файлы сцен.

---

## Ink-сцена с тегами: authoring vs runtime/debug

Есть два разных режима. Их нельзя смешивать.

### A. Authoring: написать сцену с уже известными тегами

Подходит, если задача звучит как:

- "напиши сцену, где после текста открывается карта";
- "добавь SMS в конце сцены";
- "после реплики выдай предмет";
- "поставь флаг после выбора";
- "вставь рекламу перед переходом".

Достаточно:

- базовый пакет;
- текущий ink-файл сцены;
- `docs/guides/HOW_TO_WRITE_INK.md`;
- `docs/scenario_context/INK_TAG_REFERENCE.md`.

Для рекламы дополнительно:

- `docs/guides/YANDEX_SDK_AND_ADS.md`.

В этом режиме `dialogue_manager_ink.lua` **не нужен**, если GPT не меняет
поведение тегов и не расследует баг.

### B. Runtime/debug: почему тег работает не так

Подходит, если задача звучит как:

- "карта открывается не та";
- "phone:map не срабатывает";
- "после тега выкидывает в меню";
- "инвентарь/предмет не меняется";
- "реклама ломает переход";
- "после return_to_scene сцена не возвращается";
- "после continue/load/save поведение другое";
- "проверь, почему этот тег не исполняется";
- "раньше работало, теперь нет".

Обязательно дать:

- `main/scripts/dialogue_manager_ink.lua`;
- `main/gui/modules/ui_manager_v2/dm_commands.lua`;
- `main/gui/modules/ui_manager_v2/message_flow.lua`, если участвуют msg/overlay переходы;
- `main/gui/ui_manager_v2.script`, если меняется общий orchestration;
- текущий ink-файл сцены;
- профильный документ/код подсистемы ниже.

Профильные добавки:

- Карта/телефон: `docs/guides/PHONE_SYSTEM.md`, `docs/guides/HUB_SYSTEM.md`, `main/gui/components_v2/phone_map.gui_script`, нужный `phone_*.gui_script`.
- Exploration переходы: `main/scripts/scene_controller.lua`, `main/scripts/scenes.lua`, нужный `main/data/scenes/<location>.lua`.
- Инвентарь: `docs/reference/INVENTORY_SYSTEM.md`, `main/story/chapters/91_inventory_actions.ink`, `main/gui/modules/ui_manager_v2/inventory_flow.lua`, scene Lua-файл цели.
- Реклама: `docs/guides/YANDEX_SDK_AND_ADS.md` и модули, где обрабатывается `show_ad`.

Если задача содержит слово "баг", "не работает", "выкидывает", "не открывается",
"не возвращается", "не сохраняется", "после Continue", "после загрузки" —
считать это Runtime/debug, а не Authoring.

---

## Имя / пол / обращение / падежи

Базовый пакет + 3 ink-файла:

- `main/story/chapters/00_bootstrap.ink` (стартовые VAR + падежные формы)
- `main/story/chapters/10_apartment.ink` (выбор персонажа, реальная инициализация)
- Текущий ink-файл сцены где используется имя

**Не нужно**: `dialogue_manager_ink.lua`. Нужен только если меняется синхронизация форм со старыми сохранениями.

---

## Любая правка VAR / падежных форм / стартового состояния

**Это отдельный триггер**, даже если задача выглядит как обычный narrative. AI должен **обязательно** запросить:

- `main/story/chapters/00_bootstrap.ink` — список существующих `VAR`, падежные формы по умолчанию

Без этого файла AI пытается изобрести новые `VAR` (часто дублирующие существующие) или придумать формы, которые ломают бутстрап.

Сигналы что задача требует bootstrap:
- предлагает `VAR new_thing = ...`
- упоминает `mc_name_*` / `npc_name_*` падежи
- хочет сменить пол/имя по ходу сцены
- добавляет «счётчик» / «уровень» / «статус» на весь сюжет
- меняет логику `choose_character`

---

## Exploration hub / хотспоты

Базовый пакет + lua-файлы сцен:

- `main/data/scenes/<location>.lua` (один файл на локацию: `park.lua`, `cafe.lua`, `shop.lua`, `bar.lua`, `viewpoint.lua`, `archive.lua`, `office_monday.lua`, `office_tuesday.lua`, `apartment.lua` + day-варианты)
- `main/data/scenes/_shared.lua` (STYLE_*, icons, helpers, рецепты)
- `main/scripts/scenes.lua` (для проверки сборки и поддерживаемых action types)
- связанный ink-файл если хотспоты вызывают `ink_knot`

Зачем именно эти:
- `<scene>.lua` содержит реальные `rect`, `id`, `action`, `visible_when`, `condition` хотспотов
- `_shared.lua` содержит реальные стили / иконки / bg-helpers / рецепты
- `scenes.lua` показывает как сцены собираются и какие action types поддерживаются
- ink-файл нужен чтобы проверить существуют ли knot names для `action_knot`

### Когда задача про **условия видимости** хотспотов

**Всегда** давай `.lua`-файл сцены — `PROJECT_INVENTORY.md` показывает маркеры 👁/🔒
(«у хотспота есть условие»), но не сами Lua-функции. Условия часто многострочные
и могут ссылаться на shared-хелперы вроде `not_chosen_or_met`, `can_offer_place`.
Триггеры этой задачи: «когда виден хотспот X», «почему не появляется», «при каких
флагах», «после какого события доступен», «локед — почему».

---

## Новый фон / новая локация

Базовый пакет +:

- нужный `main/data/scenes/<file>.lua`
- `main/data/scenes/_shared.lua`
- `main/scripts/scenes.lua`
- `docs/guides/HOW_TO_ADD_SCENES.md`

Если фон новый (нужно подключить):
- атлас/коллекция файлы графического пайплайна
- `main/gui/ui_manager_v2.script` (для `DEDICATED_BG_ATLAS_PROPS`)

Если фон уже подключён (есть в `PROJECT_INVENTORY.md` секция Backgrounds) — атлас-файлы не нужны.

---

## Диалоговый портрет персонажа

Базовый пакет +:

- `main/gui/components_v2/dialogue_v2.gui_script` (CHARS table)
- `docs/guides/HOW_TO_ADD_PORTRAITS.md` (для статичных)
- `docs/guides/HOW_TO_ANIMATE_PORTRAITS.md` (для анимированных — blink/talk)
- если меняются ассеты — описание pipeline rembg/character_for_scene.py

---

## Scene character (full-figure)

Базовый пакет +:

- `main/scripts/scene_characters.lua` (SCENE_GROUPS + SCENES конфиг)
- `docs/guides/HOW_TO_ADD_SCENE_CHARACTERS.md`

Ink-тег `# scene_char:show:GROUP:KEY` — описан в `INK_TAG_REFERENCE.md` и `TEMPLATES.md`.

---

## Телефон / карта / SMS / Messenger

Для авторинга текста/сообщений:

- `docs/guides/PHONE_SYSTEM.md`
- `docs/guides/HUB_SYSTEM.md` (если затронуты переходы exploration ↔ phone)
- `92_phone_sms.ink` или `93_phone_messenger.ink` (если меняется текст)

Канон авторинга: сценовые `.ink` файлы вызывают телефонные события через tunnel (`-> phone_sms_* ->`, `-> phone_msg_* ->`), а сами тексты сообщений хранятся централизованно:

- `92_phone_sms.ink` — все `sms:*` и `bank:*`
- `93_phone_messenger.ink` — все `msg:*`

Если задача просит добавить SMS/Messenger-текст в конкретной сцене, всё равно нужен соответствующий телефонный файл. Сценовый файл нужен только чтобы вставить или проверить вызов event-knot'а.

Если меняется логика или есть баг поведения, дополнительно:

- `main/scripts/dialogue_manager_ink.lua`, если вход идёт через Ink-теги;
- `main/gui/modules/ui_manager_v2/dm_commands.lua`;
- GUI/script нужного приложения, например `phone_sms.gui_script`, `phone_map.gui_script`;
- `main/gui/ui_manager_v2.script`, если проблема на уровне overlay/open/close.

---

## Инвентарь / применение предметов

Базовый пакет +:

- `docs/reference/INVENTORY_SYSTEM.md`
- `main/story/chapters/91_inventory_actions.ink`
- scene Lua-файл с хотспотом-целью (если меняется `inv_use_<item>_on_<hotspot>`)

---

## UI / GUI поведение (кнопки, лог, модалки, layout)

Базовый пакет +:

- нужный `.gui` + его `.gui_script`
- `main/gui/ui_manager_v2.script`
- соответствующий модуль из `main/gui/modules/ui_manager_v2/`
- `main/gui/modules/messages.lua` если новые msg-имена
- `docs/reference/UI_MANAGER_V2_ARCHITECTURE.md`

---

## Быстрая формула

| Тип задачи | Что добавлять к базе |
|---|---|
| Художественный текст в существующих knot'ах | 1-2 ink-файла |
| Новый knot без новых тегов | 1 ink-файл |
| Новый knot с известным тегом | + `HOW_TO_WRITE_INK.md`, `INK_TAG_REFERENCE.md` |
| Тег работает не так / runtime-баг | + `dialogue_manager_ink.lua`, `dm_commands.lua`, профильные flow/gui_script |
| Новый hotspot в существующей сцене | + `<scene>.lua`, `_shared.lua` |
| Новая локация | + `<scene>.lua`, `_shared.lua`, `scenes.lua`, `HOW_TO_ADD_SCENES.md` |
| Новый портрет / scene character | + соответствующий HOW_TO |
| Баг рантайма | + конкретный lua/gui_script где косяк |

**Если AI спрашивает «какие теги доступны»** — давать `INK_TAG_REFERENCE.md`, **не** `dialogue_manager_ink.lua`.

**Если AI спрашивает «существует ли scene_id X»** — давать `PROJECT_INVENTORY.md`, **не** scene Lua-файлы (если только не нужно править).
