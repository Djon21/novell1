# План локализации (RU / EN / TR)

Актуально на `2026-05-01`. Игра на стадии прототипа.
Платформа: Яндекс Игры. Языки: русский (основной), английский, турецкий.

> История: 2026-04-25 был написан детальный план, потом перезаписан коротким резюме.
> Этот файл — восстановленный детальный план, сверенный с актуальным состоянием кода.

---

## 1. Контекст

- Яндекс Игры передают язык через `ysdk.environment.i18n.lang` → `"ru" | "en" | "tr"` и т.д.
- SDK **не** делает перевод сам — только сообщает язык. Систему переключения строим мы.
- Турецкий алфавит — латиница + Latin Extended-A (`ş ğ ı ö ü ç İ Ğ Ş`). Один латинский шрифт покрывает EN + TR.
- Игра на прототипной стадии: Ink-тексты меняются, UI ещё дорабатывается. План рассчитан на постепенное подключение.
- **Перевод делается через нейронку (LLM).** Все размеры файлов и формат хранения подобраны так, чтобы LLM могла перевести один файл целиком за один заход без потери контекста (см. §4.2.1, §4.3.1, §4.3.2).

### Что уже есть в коде (на 2026-05-01)

- `main/engine_template.html` уже читает `ysdk.environment.i18n.lang` и кладёт в `window.__gameLang` ДО старта Defold (требование Яндекс модерации 2.14)
- yagames присутствует как зависимость в `game.project`, но в активном Lua-runtime НЕ подключается — для L10n это и не нужно: язык достаётся через `html5.run("window.__gameLang")`, минуя SDK-обёртку
- В `main/scripts/` нет `l10n.lua`
- Хардкод-строки разбросаны по `*.gui_script` и `scripts/scenes.lua`

---

## 2. Что нужно локализовать (объём)

### Слой 1 — UI-строки в Lua (мало, высокий приоритет)

| Файл | Примеры строк |
|---|---|
| `main/gui/components_v2/main_menu_v2.gui_script` | «НОВАЯ ИТЕРАЦИЯ», «ПРОДОЛЖИТЬ», «СБРОСИТЬ ИТЕРАЦИЮ», «ДОСТИЖЕНИЯ» |
| `main/gui/components_v2/hud_v2.gui_script` | подписи кнопок HUD |
| `main/gui/components_v2/phone_v2_root.gui_script` | заголовки приложений в лаунчере |
| `main/gui/components_v2/phone_sms.gui_script` | «Сообщения», «Сообщение отправлено» (если есть) |
| `main/gui/components_v2/phone_quests.gui_script` | «ЗАДАЧИ» |
| `main/gui/components_v2/phone_notes.gui_script`, `phone_mail`, `phone_call`, `phone_messenger`, `phone_term` | заголовки и пустые состояния |
| `main/gui/components_v2/inventory_v2.gui_script` | подписи verbs (use/inspect/read) |
| `main/gui/modules/ui_manager_v2/map_flow.lua` + `main/scripts/l10n.lua` | ключи подписей пинов карты (`map_home`, `map_work`, …) |
| `main/scripts/scenes.lua` | поле `label` у каждого hotspot'а |
| `main/scripts/quests.lua` | названия и описания квестов (`name`, `description`, `text` шагов) |
| `main/scripts/items_catalog.lua` | названия и описания предметов |

### Слой 2 — Ink-диалоги (много, низкий приоритет)

Весь нарратив в `main/story/chapter_01.ink` + `main/story/chapters/*.ink`:
- `00_bootstrap.ink` (VAR-объявления, переводить не нужно)
- `10_apartment.ink`, `02_sunday_date.ink`, `02_metro.ink`, `03_office.ink`, `04_rooftop.ink`
- `91_inventory_actions.ink`

Объём — тысячи строк. Переводить только после контентного freeze.

### Слой 3 — Ink-теги (НЕ переводятся)

`# bg:`, `# sfx:`, `# set_flag:`, `# loop:end:*`, `# quest:start:*`, `# add_item:*` — технические, языконезависимые.

### Содержат текст (переводить вместе со Слоем 2):

- `# sms:add:contact:текст`
- `# sms:reply:contact:текст`
- `# note:add:title:body`
- `# mail:add:from:subject[:body]`

### Не локализуем

- Имена персонажей в Ink (`mc`, `npc`, `mila`) — в RU нужны падежи, в EN/TR нет; имя «Mila» одинаковое во всех языках
- ID сцен, флагов, предметов, квестов — технические
- Терминальные строки `# term:` — оставить en-only
- Звуки, шейдеры

---

## 3. Приоритеты

| Приоритет | Задача | Когда |
|---|---|---|
| **P1** | Lua читает `window.__gameLang` через `html5.run` → `l10n.lang` | До первого публичного теста |
| **P1** | Создать `main/scripts/l10n.lua` со скелетом и RU-строками | До первого публичного теста |
| **P1** | Перенести в `l10n` строки карты + меню | Сразу |
| **P2** | Перенести остальные UI-строки (phone, inventory, quests, items) | По мере касания |
| **P2** | EN-перевод UI | После заморозки UI-словаря |
| **P2** | TR-перевод UI | После EN |
| **P2** | Шрифт с Latin Extended-A для TR (ş ğ ı ö ü ç) | До TR |
| **P3** | Перевод Ink на EN | После контентного freeze |
| **P3** | Перевод Ink на TR | После EN-Ink |

---

## 4. Техническая архитектура

### 4.1 Детект языка

Хитрый трюк: язык забирается **через JS-переменную `window.__gameLang`**, которую engine_template.html выставляет до старта Defold. Lua-стороне yagames не нужен.

**JS-сторона (уже работает)** — `main/engine_template.html`:

```js
window.__gameLang = ysdk.environment.i18n.lang;
```

**Lua-сторона (новое)** — `main/scripts/l10n.lua`:

```lua
local M = { lang = "ru" }

local SUPPORTED = { ru = true, en = true, tr = true }

function M.detect()
    -- В нативной сборке html5 модуля нет → сразу fallback на ru.
    if html5 and html5.run then
        local ok, lang = pcall(html5.run, "window.__gameLang || ''")
        if ok and lang and SUPPORTED[lang] then
            M.lang = lang
            return lang
        end
    end
    -- Дев-сборка / неподдерживаемый язык → ru.
    M.lang = "ru"
    return M.lang
end
```

`l10n.detect()` зовём один раз в `ui_manager_v2.init()` ДО показа меню. Смена языка mid-session не нужна (Яндекс UI смены не предоставляет).

**Почему без yagames:** инициализация `yagames.init()` асинхронная и срабатывает позже init'а UI. Если ждать SDK — меню успеет нарисоваться на дефолтном языке. JS-шаблон же выставляет `window.__gameLang` синхронно в момент `YaGames.init().then(...)`, ДО загрузки Defold-движка → к моменту `init` всех скриптов значение уже на месте.

### 4.2 Таблица строк — JSON-файлы на язык

**Формат хранения:** один JSON на язык в `main/data/strings/`:
- `main/data/strings/ru.json` — мастер (правится разработчиком при добавлении фич)
- `main/data/strings/en.json` — перевод (генерируется через LLM из ru.json)
- `main/data/strings/tr.json` — перевод (генерируется через LLM из ru.json)

**Почему JSON, а не Lua-таблица:**
- Перевод делается через нейронку. Нейронка отдаёт JSON чисто, без риска сломать Lua-синтаксис (запятая, кавычка, escape).
- Размер ru.json даже на 200+ ключах ~10KB — нейронка съест в один заход, переведёт в en/tr целиком.
- Можно запустить валидатор «все ли ключи из ru.json присутствуют в en.json/tr.json» обычным diff'ом.

**Пример `ru.json`:**

```json
{
  "menu_new": "НОВАЯ ИТЕРАЦИЯ",
  "menu_continue": "ПРОДОЛЖИТЬ",
  "menu_reset": "СБРОСИТЬ ИТЕРАЦИЮ",
  "menu_achievements": "ДОСТИЖЕНИЯ",

  "phone_sms": "СООБЩЕНИЯ",
  "phone_quests": "ЗАДАЧИ",
  "phone_notes": "ЗАМЕТКИ",

  "map_home": "Дом",
  "map_work": "Офис",
  "map_metro": "М. Ул. 1905 года"
}
```

**Загрузчик `main/scripts/l10n.lua`:**

```lua
local M = { lang = "ru", strings = {} }

local SUPPORTED = { ru = true, en = true, tr = true }

local function load_lang(lang)
    local path = "main/data/strings/" .. lang .. ".json"
    local data = sys.load_resource("/" .. path)
    if not data then return nil end
    local ok, parsed = pcall(json.decode, data)
    return ok and parsed or nil
end

function M.init()
    -- Грузим RU всегда (fallback) + текущий язык
    M.strings.ru = load_lang("ru") or {}
    if M.lang ~= "ru" then
        M.strings[M.lang] = load_lang(M.lang) or {}
    end
end

function M.t(key)
    local cur = M.strings[M.lang]
    if cur and cur[key] then return cur[key] end
    return M.strings.ru[key] or ("?" .. tostring(key))
end
```

> **Важно:** все JSON-файлы должны быть указаны в `[project] custom_resources` в `game.project`, чтобы Defold их забандлил, а `sys.load_resource` смог прочитать.

Использование:
```lua
local l10n = require "main.scripts.l10n"
gui.set_text(node, l10n.t("menu_new"))
```

### 4.2.1 Промпт нейронке для перевода UI

```
Переведи значения JSON-файла с русского на английский (или турецкий).
Ключи (левая часть) НЕ трогай.
Сохрани форматирование (capslock, регистр) — если в RU "НОВАЯ ИТЕРАЦИЯ"
капсом, то и в EN "NEW ITERATION" капсом.
Верни валидный JSON.

[вставка содержимого ru.json]
```

### 4.3 Ink-диалоги — Вариант A (P3)

**Вариант A — отдельный JSON на язык**
- `main/story/chapter_01.ink` (RU, основной)
- `main/story/chapter_01_en.ink`, `main/story/chapter_01_tr.ink` — копии с переводом
- Компилируем `tools/compile_ink.bat chapter_01_en` → `chapter_01_en.json`
- `ui_manager_v2.init()` грузит `chapter_01_<lang>.json`, fallback на RU

**Плюсы:** чистый Ink, нет лишней логики в нарративе.
**Минусы:** тройное дублирование, сложно синхронизировать правки сюжета.

**Вариант B — внешние таблицы строк**
- В Ink ключи: `{L_wake_01}`
- `strings_<lang>.json` с переводами

**Минусы:** нестандартный Ink, ломает читаемость нарратива → отказались.

**Решение:** Вариант A. Откладываем до контентного freeze.

### 4.3.1 Размеры глав и нейронный workflow

Замеры на 2026-05-01 (`wc -w`):

| Файл | Слов | ≈ токенов | В один заход в LLM |
|---|---:|---:|:---:|
| `00_bootstrap.ink` | 213 | ~430 | ✅ (только VAR) |
| `10_apartment.ink` | 2048 | ~4100 | ✅ |
| `02_metro.ink` | 1316 | ~2630 | ✅ |
| `03_office.ink` | 2341 | ~4680 | ✅ |
| `04_rooftop.ink` | 1260 | ~2520 | ✅ |
| `91_inventory_actions.ink` | 266 | ~530 | ✅ |

> Числа на 2026-05-01. Перепроверяй `wc -w main/story/chapters/*.ink` перед заходом в LLM, если контент изменился.

Каждая глава влезает в любую современную LLM (~5k токенов). **Перевод делаем по одной главе за раз**, не отправлять всё разом.

### 4.3.2 Промпт нейронке для перевода Ink-главы

⚠️ Главная опасность: LLM может «исправить» теги, имена knot'ов или Ink-переменные. Промпт должен явно их защитить.

```
Переведи русский текст внутри ink-файла на английский (или турецкий).

ЧТО НЕ ТРОГАТЬ ВООБЩЕ:
1. Имена knot'ов: === имя_knota === — оставлять как есть
2. Имена stitch'ей: = имя_stitch — оставлять как есть
3. ВСЕ строки, начинающиеся с `#` (теги): # bg:..., # set_flag:..., # sms:add:..., # quest:..., # return_to_scene
   ВКЛЮЧАЯ значения тегов: # set_flag:bedroom_seen=true остаётся буквально
4. Имена ink-переменных: coffee_drunk, iteration_number, INSIGHT и т.п.
5. Ink-управляющие конструкции: -> DONE, -> knot_name, ~ переменная = ...
6. Условия в фигурных скобках: {iteration_number > 1: ...} — само условие не трогать,
   но текст внутри блока перевести
7. Комментарии // ... — переводить их не нужно
8. ID контактов в SMS: # sms:add:mila:текст — "mila" не трогать,
   переводить только текст после второго двоеточия

ЧТО ПЕРЕВОДИТЬ:
- Текст реплик и нарратива (между тегами)
- Текст в квадратных скобках выбора: * [Текст выбора] → переводим
- Текст SMS после второго двоеточия в # sms:add:contact:ТЕКСТ
- Текст заметок после второго двоеточия в # note:add:title:body

Верни весь файл целиком — структура должна быть идентична оригиналу.

[вставка содержимого 10_apartment.ink]
```

После перевода **обязательно**:
1. Прогнать `tools/compile_ink.bat chapter_01_en` — должна быть `[OK]` без ошибок
2. Сверить число knot'ов: `grep -c '^=== ' 10_apartment.ink` в RU и `_en` версии = одинаковое
3. Сверить число хотспот-выборов: `grep -c '^\*' 10_apartment.ink` = одинаковое
4. Smoke-тест в игре с `?lang=en` — пройти главу, проверить что выборы и SMS видны

### 4.4 Динамические данные (`scenes.lua`, `quests.lua`, `items_catalog.lua`)

Вместо хардкод-строк в этих модулях:
```lua
-- было
{ label = "Спальня", id = "to_bedroom" }
-- станет
{ label_key = "hs_to_bedroom", id = "to_bedroom" }
```

`scene_controller` / `phone_quests.gui_script` / `inventory_v2.gui_script` сами зовут `l10n.t(label_key)` при отрисовке.

---

## 5. Шрифты

### Текущие шрифты (`main/fonts/`)

- `Unbounded-Bold.ttf`, `Unbounded-Black.ttf` — основные заголовки
- `Manrope-Regular.ttf` — body
- `JetBrainsMono-*.ttf` — терминал, технический шрифт
- `Caveat-Regular.ttf` — рукопись
- `MaterialIcons-Regular.ttf` — иконки

### Покрытие Turkish Extended (ş ğ ı ö ü ç İ Ğ Ş)

**Действие (P2):** проверить через Defold font editor для каждого `.font`-файла, что в `extra_characters` или unicode_range есть Latin Extended-A.

Если нет — либо добавить нужные глифы в `extra_characters`, либо подключить шрифт-аналог с полным покрытием.

`Unbounded` и `Manrope` — современные шрифты, у них Latin Extended должен быть. `Caveat` — рукописный, может не иметь, нужно проверить.

---

## 6. Что НЕ делаем сейчас

- Полный перевод Ink — только после контентного freeze
- RTL (Arabic/Hebrew) — не нужны
- In-game переключатель языка — Яндекс не предоставляет UI смены
- Локализация графики (надписи на фоне) — не критично для прототипа

---

## 7. Чеклист готовности к EN/TR

### Этап P1 — фундамент

- [ ] Создан `main/scripts/l10n.lua` с `detect()`, `t(key)`, таблицами `ru/en/tr`
- [ ] `ui_manager_v2.init()` зовёт `l10n.detect()` до показа меню (читает `window.__gameLang` через `html5.run`)
- [x] подписи пинов карты вынесены из `ui_manager_v2` в `map_flow.lua` + `l10n.t(...)`
- [ ] Главное меню (`main_menu_v2.gui_script`) использует `l10n.t()` вместо хардкод-строк

### Этап P2 — расширение

- [ ] HUD-кнопки используют `l10n.t()`
- [ ] Все приложения телефона (sms, quests, notes, mail, call, cam, term, map) используют `l10n.t()`
- [ ] `inventory_v2` verbs через `l10n.t()`
- [ ] `scenes.lua` hotspot-лейблы через `label_key` + `l10n.t()`
- [ ] `quests.lua` через `name_key`/`description_key` + `l10n.t()`
- [ ] `items_catalog.lua` через `name_key`/`description_key` + `l10n.t()`
- [ ] Все строки переведены на EN
- [ ] Все строки переведены на TR
- [ ] Шрифты проверены на покрытие Latin Extended-A; при необходимости расширены `extra_characters`

### Этап P3 — Ink

- [ ] Контентный freeze RU-нарратива (текст не меняется)
- [ ] `chapter_01_en.ink` создан, переведён, компилируется
- [ ] `chapter_01_tr.ink` создан, переведён, компилируется
- [ ] `ui_manager_v2` грузит `chapter_01_<lang>.json` по `l10n.lang`, fallback на RU

### Smoke-тест

- [ ] Запуск Яндекс Игр с `?lang=en` — UI на английском
- [ ] Запуск с `?lang=tr` — UI на турецком, турецкие символы видны
- [ ] Запуск с `?lang=ru` или без параметра — RU как раньше
- [ ] Continue после смены языка не падает (replay через game_state, текст подменяется на лету)

---

## 8. Риски и заметки

- **defold-ink replay чувствителен к структуре JSON.** При смене JSON между сессиями `Continue` может ломаться. Решение: при детекте смены языка между загрузкой save и текущей сессией — start fresh, без `Continue`.
- **Длина строк.** Английский на 20–30% длиннее RU в среднем; турецкий ещё длиннее. Проверить, что лейблы не переполняют поля в `.gui`.
- **Падежи в RU.** Сейчас есть токены `{MC|м|ж}` и `{NPC|м|ж}` для гендерных падежей. В EN/TR падежей нет — токены нужно резолвить заранее в L10n-логике или просто игнорировать.
- **Yagames в Lua не нужен для L10n.** Язык приходит через `window.__gameLang`. Если в будущем понадобится подключать SDK для рекламы или других фич — делать `local yagames = require "yagames.yagames"` ТОЛЬКО top-level, не через `pcall(require, ...)` (см. `memory/defold_vn_setup.md`: pcall ломает статический анализ бандла, модуль не попадает в HTML5 build).

---

## 9. Порядок реализации (рекомендуемый)

1. **`l10n.lua` базовый** (detect + t + RU-словарь с ключами карты `map_home`, `map_work`, …) → `main_menu_v2` подключает → smoke-тест что меню всё ещё видно
2. **EN-перевод словаря** (только то что в `l10n.lua` есть)
3. **HTML5 smoke-тест**: собрать билд, проверить что `l10n.detect()` действительно даёт `en` при `?lang=en` в URL
4. **Расширение словаря** (HUD, телефон, инвентарь) — постепенно, без блокеров
5. **TR-перевод словаря** + проверка шрифтов на турецкие глифы
6. **Динамические данные** (`scenes`, `quests`, `items_catalog`) → переход на `*_key`
7. **(после freeze)** Ink на EN
8. **(после freeze)** Ink на TR
