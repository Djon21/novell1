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

### Что уже есть в коде (на 2026-05-01)

- `main/engine_template.html` уже читает `ysdk.environment.i18n.lang` и кладёт в `window.__gameLang` ДО старта Defold (требование Яндекс модерации 2.14)
- В Lua-коде yagames/ysdk **не подключен** — Defold-сторона про язык пока не знает
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
| `main/gui/components_v2/phone_notes.gui_script`, `phone_mail`, `phone_call`, `phone_cam`, `phone_term` | заголовки и пустые состояния |
| `main/gui/components_v2/inventory_v2.gui_script` | подписи verbs (use/inspect/read) |
| `main/gui/ui_manager_v2.script` | `MAP_PIN_LABELS` (Дом, Офис, …) |
| `main/scripts/scenes.lua` | поле `label` у каждого hotspot'а |
| `main/scripts/quests.lua` | названия и описания квестов (`name`, `description`, `text` шагов) |
| `main/scripts/items_catalog.lua` | названия и описания предметов |

### Слой 2 — Ink-диалоги (много, низкий приоритет)

Весь нарратив в `main/story/chapter_01.ink` + `main/story/chapters/*.ink`:
- `00_bootstrap.ink` (VAR-объявления, переводить не нужно)
- `01_apartment.ink`, `02_metro.ink`, `03_office.ink`, `04_rooftop.ink`
- `90_phone_apps.ink`, `91_inventory_actions.ink`

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
| **P1** | Lua прокидывает `window.__gameLang` через yagames в `l10n.lang` | До первого публичного теста |
| **P1** | Создать `main/scripts/l10n.lua` со скелетом и RU-строками | До первого публичного теста |
| **P1** | Перенести в `l10n` строки `MAP_PIN_LABELS` + меню | Сразу |
| **P2** | Перенести остальные UI-строки (phone, inventory, quests, items) | По мере касания |
| **P2** | EN-перевод UI | После заморозки UI-словаря |
| **P2** | TR-перевод UI | После EN |
| **P2** | Шрифт с Latin Extended-A для TR (ş ğ ı ö ü ç) | До TR |
| **P3** | Перевод Ink на EN | После контентного freeze |
| **P3** | Перевод Ink на TR | После EN-Ink |

---

## 4. Техническая архитектура

### 4.1 Детект языка

**JS-сторона (уже работает)** — `main/engine_template.html`:

```js
window.__gameLang = ysdk.environment.i18n.lang;
```

**Lua-сторона (предстоит)** — `main/scripts/l10n.lua`:

```lua
local M = { lang = "ru" }

-- 1) Читаем из html5.run("window.__gameLang") — выставлен в engine_template.html
-- 2) Fallback через yagames.environment().i18n.lang (если SDK инициализирован)
-- 3) Окончательный fallback — "ru"

local SUPPORTED = { ru = true, en = true, tr = true }

function M.detect()
    if html5 and html5.run then
        local ok, lang = pcall(html5.run, "window.__gameLang || ''")
        if ok and SUPPORTED[lang] then
            M.lang = lang
            return lang
        end
    end
    -- Yagames fallback (на случай если __gameLang не выставился)
    local yagames = package.loaded["yagames.yagames"]
    if yagames and yagames.environment then
        local ok, env = pcall(yagames.environment)
        if ok and env and env.i18n and SUPPORTED[env.i18n.lang] then
            M.lang = env.i18n.lang
            return M.lang
        end
    end
    return "ru"
end
```

`l10n.detect()` зовём один раз в `ui_manager_v2.init()` ДО показа меню. Смена языка mid-session не нужна (Яндекс не предоставляет UI смены).

### 4.2 Таблица строк — `main/scripts/l10n.lua`

```lua
M.strings = {
    ru = {
        menu_new          = "НОВАЯ ИТЕРАЦИЯ",
        menu_continue     = "ПРОДОЛЖИТЬ",
        menu_reset        = "СБРОСИТЬ ИТЕРАЦИЮ",
        menu_achievements = "ДОСТИЖЕНИЯ",
        phone_sms         = "СООБЩЕНИЯ",
        phone_quests      = "ЗАДАЧИ",
        phone_notes       = "ЗАМЕТКИ",
        map_home          = "Дом",
        map_work          = "Офис",
        map_metro         = "М. Ул. 1905 года",
        -- ...
    },
    en = {
        menu_new          = "NEW ITERATION",
        menu_continue     = "CONTINUE",
        menu_reset        = "RESET ITERATION",
        menu_achievements = "ACHIEVEMENTS",
        phone_sms         = "MESSAGES",
        phone_quests      = "TASKS",
        phone_notes       = "NOTES",
        map_home          = "Home",
        map_work          = "Office",
        map_metro         = "Metro · 1905 St.",
    },
    tr = {
        menu_new          = "YENİ İTERASYON",
        menu_continue     = "DEVAM ET",
        menu_reset        = "İTERASYONU SIFIRLA",
        menu_achievements = "BAŞARIMLAR",
        phone_sms         = "MESAJLAR",
        phone_quests      = "GÖREVLER",
        phone_notes       = "NOTLAR",
        map_home          = "Ev",
        map_work          = "Ofis",
        map_metro         = "Metro · 1905 Cd.",
    },
}

function M.t(key)
    local table_for_lang = M.strings[M.lang] or M.strings.ru
    return table_for_lang[key] or M.strings.ru[key] or ("?" .. tostring(key))
end
```

Использование:
```lua
local l10n = require "main.scripts.l10n"
gui.set_text(node, l10n.t("menu_new"))
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
- [ ] yagames подключен в Lua (`local yagames = require "yagames.yagames"`)
- [ ] `ui_manager_v2.init()` зовёт `l10n.detect()` до показа меню
- [ ] `MAP_PIN_LABELS` в `ui_manager_v2` вынесен в `l10n.strings`
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
- **Yagames в Lua.** Сейчас не подключен; добавить `require "yagames.yagames"` потребует проверки бандла (см. memory: НЕ через `pcall(require, ...)`).

---

## 9. Порядок реализации (рекомендуемый)

1. **`l10n.lua` базовый** (detect + t + RU-словарь с MAP_PIN_LABELS) → `main_menu_v2` подключает → smoke-тест что меню всё ещё видно
2. **EN-перевод словаря** (только то что в `l10n.lua` есть)
3. **Подключить yagames в Lua** + проверить что `l10n.detect()` действительно даёт `en` при `?lang=en`
4. **Расширение словаря** (HUD, телефон, инвентарь) — постепенно, без блокеров
5. **TR-перевод словаря** + проверка шрифтов на турецкие глифы
6. **Динамические данные** (`scenes`, `quests`, `items_catalog`) → переход на `*_key`
7. **(после freeze)** Ink на EN
8. **(после freeze)** Ink на TR
