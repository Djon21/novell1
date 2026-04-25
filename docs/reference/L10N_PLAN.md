# АВОСЬ — План локализации (RU / EN / TR)

Актуально на `2026-04-25`. Игра на стадии прототипа.  
Платформа: Яндекс Игры. Языки: русский (основной), английский, турецкий.

---

## 1. Контекст

- Яндекс Игры предоставляют текущий язык пользователя через  
  `ysdk.environment.i18n.lang` → строка `"ru"`, `"en"`, `"tr"` и т.д.
- SDK **не** делает перевод сам — только сообщает язык. Систему переключения строим мы.
- Турецкий алфавит — латиница с расширениями (ş ğ ı ö ü ç). Отдельный шрифт с кириллицей для RU, один латинский шрифт покрывает EN + TR.
- Игра на прототипной стадии: Ink-тексты меняются, UI ещё дорабатывается. Поэтому план рассчитан на постепенное подключение, а не на полный перевод сразу.

---

## 2. Что нужно локализовать (объём)

### Слой 1 — UI-строки в Lua (мало, высокий приоритет)

Хардкод в `.gui_script` и `.script` файлах:

| Файл | Примеры строк |
|---|---|
| `main_menu_v2.gui_script` | «НОВАЯ ИТЕРАЦИЯ», «ПРОДОЛЖИТЬ», «СБРОСИТЬ ИТЕРАЦИЮ», «ДОСТИЖЕНИЯ», eyebrow/stamp/dossier тексты |
| `phone_v2.gui_script` | «ЗАДАЧИ», «сообщений:», заголовки вкладок |
| `hud_v2.gui_script` | подписи кнопок HUD |
| `ui_manager_v2.script` | лейблы пинов карты (`MAP_PIN_LABELS`) |
| `hotspots_v2.gui_script` | лейблы hotspot'ов (идут из `scenes.lua`) |
| `scenes.lua` | поле `label` у каждого hotspot'а и сцены |

### Слой 2 — Ink-диалоги (много, низкий приоритет сейчас)

Весь нарратив: `chapters/New/01_apartment.ink`, `02_metro.ink`, `03_office.ink`, `04_rooftop.ink`.  
Объём — тысячи строк. Переводить только после контентного freeze.

### Слой 3 — Ink-переменные и теги (не переводятся)

`# bg:`, `# sfx:`, `# flag:`, `# loop:end:*` — технические, языконезависимые.  
`# sms:add:`, `# note:add:` — содержат текст, переводить вместе со Слоем 2.

### Не входит в локализацию

- Имена персонажей (Мила/Mila/Mila — останутся как есть, различие только в падежах RU)
- ID сцен, флагов, предметов — технические, без перевода
- Звуки, шрифты кода в терминале — оставить en-only

---

## 3. Приоритеты

| Приоритет | Задача | Когда |
|---|---|---|
| **P1** | Детект языка из Яндекс SDK при старте | До первого публичного теста |
| **P1** | Таблица строк для UI (`l10n.lua`) + переключение | До первого публичного теста |
| **P2** | Перевод UI-строк на EN | После стабилизации UI |
| **P2** | Перевод UI-строк на TR | После EN |
| **P3** | Перевод Ink-диалогов на EN | После контентного freeze |
| **P3** | Перевод Ink-диалогов на TR | После EN-диалогов |
| **P4** | Шрифт с поддержкой TR (ş ğ ı ö ü ç) | До TR-диалогов |

---

## 4. Техническая архитектура

### 4.1 Детект языка (Яндекс SDK)

В `ui_manager_v2.script`, в `init`, до показа меню:

```lua
-- Определяем язык из Яндекс SDK (или fallback на "ru")
local function detect_lang()
    local ok, ysdk_env = pcall(function()
        return ysdk.environment  -- только в браузерном билде
    end)
    if ok and ysdk_env and ysdk_env.i18n and ysdk_env.i18n.lang then
        local lang = ysdk_env.i18n.lang
        if lang == "en" or lang == "tr" then return lang end
    end
    return "ru"
end

M.lang = detect_lang()
```

`M.lang` хранится в ui_manager_v2 на время сессии. Смена языка mid-session не нужна.

### 4.2 Таблица строк — `main/scripts/l10n.lua`

```lua
local L = {}

L.strings = {
    ru = {
        menu_new        = "НОВАЯ ИТЕРАЦИЯ",
        menu_continue   = "ПРОДОЛЖИТЬ",
        menu_reset      = "СБРОСИТЬ ИТЕРАЦИЮ",
        menu_achievements = "ДОСТИЖЕНИЯ",
        phone_quests    = "ЗАДАЧИ",
        phone_messages  = "сообщений: ",
        map_home        = "Дом",
        map_work        = "Офис",
        map_metro       = "М. Ул. 1905 года",
        -- ... и т.д.
    },
    en = {
        menu_new        = "NEW ITERATION",
        menu_continue   = "CONTINUE",
        menu_reset      = "RESET ITERATION",
        menu_achievements = "ACHIEVEMENTS",
        phone_quests    = "TASKS",
        phone_messages  = "messages: ",
        map_home        = "Home",
        map_work        = "Office",
        map_metro       = "Metro · 1905 St.",
        -- ...
    },
    tr = {
        menu_new        = "YENİ İTERASYON",
        menu_continue   = "DEVAM ET",
        menu_reset      = "İTERASYONU SIFIRLA",
        menu_achievements = "BAŞARIMLAR",
        phone_quests    = "GÖREVLER",
        phone_messages  = "mesaj: ",
        map_home        = "Ev",
        map_work        = "Ofis",
        map_metro       = "Metro · 1905 Cd.",
        -- ...
    },
}

function L.get(lang, key)
    local t = L.strings[lang] or L.strings["ru"]
    return t[key] or L.strings["ru"][key] or ("?" .. key)
end

return L
```

Использование в `main_menu_v2.gui_script`:
```lua
local l10n = require "main.scripts.l10n"
-- ...
set_text("mi_new", l10n.get(M.lang, "menu_new"))
```

### 4.3 Ink-диалоги — отдельные JSON-билды (P3)

Два варианта, выбрать при переходе к P3:

**Вариант A — Отдельный .ink на каждый язык**
- `chapter_01_en.ink`, `chapter_01_tr.ink` — полные копии, переведённый текст
- При старте грузим нужный JSON: `"/main/story/chapter_01_" .. lang .. ".json"`
- Плюсы: чистый Ink, нет условной логики  
- Минусы: тройное дублирование файлов, сложно синхронизировать при правках сюжета

**Вариант B — Внешние JSON-таблицы строк для Ink**
- Ink-параграфы содержат ключи вместо текста: `{L("wake_line_01")}`
- Отдельный `strings_en.json` / `strings_tr.json`  
- Плюсы: один .ink, переводчику нужен только JSON  
- Минусы: нестандартный Ink, сложнее редактировать нарратив

**Рекомендация для прототипа → P3:** начать с Варианта A.  
Прототипный сюжет ещё не заморожен, синхронизация трёх копий терпима на малом объёме.

### 4.4 scenes.lua — лейблы hotspot'ов

Hotspot `label` и `icon` — статические строки в `scenes.lua`. После внедрения `l10n.lua`:

```lua
local l10n = require "main.scripts.l10n"
local LANG = "ru"  -- выставляется при старте из ui_manager

-- hotspot
{
    label = l10n.get(LANG, "hs_to_kitchen"),
    ...
}
```

Либо передавать `lang` через game_state и читать в `scene_controller`.

---

## 5. Шрифты

| Язык | Необходимо |
|---|---|
| RU | Кириллица — уже есть (`unbounded_bold_54.font` и др.) |
| EN | Латиница — уже покрыта теми же шрифтами |
| TR | Латиница + ş ğ ı ö ü ç — проверить покрытие в текущих шрифтах. Если нет — добавить TTF с полным Latin Extended-A |

Действие (P2/P3): открыть `main/fonts/` и проверить glyphs через Defold font editor.  
Если Turkish Extended отсутствует — подключить шрифт с `unicode_range` Latin + Latin Extended-A.

---

## 6. Что НЕ делаем сейчас

- Полный перевод Ink-текстов — только после контентного freeze
- RTL-поддержка (Arabic/Hebrew) — не нужна
- Детект по геолокации (только по `ysdk.environment.i18n.lang`)
- In-game переключатель языка — Яндекс SDK сам определяет, игрок не выбирает

---

## 7. Чеклист готовности к EN/TR

- [ ] `l10n.lua` создан, подключён к `ui_manager_v2` и `main_menu_v2`
- [ ] Детект `ysdk.environment.i18n.lang` работает в браузерном билде
- [ ] Все UI-строки переведены на EN
- [ ] Все UI-строки переведены на TR
- [ ] Шрифт покрывает Turkish Extended символы (ş ğ ı ö ü ç)
- [ ] `scenes.lua` hotspot-лейблы вынесены в `l10n.lua`
- [ ] `MAP_PIN_LABELS` в `ui_manager_v2` вынесены в `l10n.lua`
- [ ] Ink-диалоги EN: отдельный `chapter_01_en.json` загружается при `lang == "en"`
- [ ] Ink-диалоги TR: аналогично для `"tr"`
- [ ] Smoke-тест: запуск с `?lang=en` в URL Яндекс Игр показывает EN интерфейс
