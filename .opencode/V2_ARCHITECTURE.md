# AVOS V2 UI Architecture

**Дата создания:** 2026-04-20  
**Статус:** Активная система (bootstrap переключён на main_v2.collection)

---

## 📋 Обзор

V2 UI система — это **модульная архитектура GUI** для визуальной новеллы AVOS, построенная на принципах:

- **Компонентность**: Каждый экран = отдельный .gui + .gui_script
- **Атомарность**: Переиспользуемые UI-элементы в папке `atoms/`
- **Централизованная тема**: Все цвета/шрифты в `v2_theme.lua`
- **Оркестрация**: `ui_manager_v2.script` управляет всеми компонентами
- **Параллельность**: V2 живёт рядом со старой системой (не заменяет её)

---

## 🗂️ Структура файлов

```
main/
├── gui/
│   ├── components_v2/              # Новая V2 система
│   │   ├── atoms/                  # Переиспользуемые UI-атомы
│   │   │   ├── corner_brackets.gui # 4 угловых скобки (cyan, 22×22)
│   │   │   ├── hud_top.gui         # Верхняя HUD-полоса (960×32)
│   │   │   └── hud_bot.gui         # Нижняя HUD-полоса (960×32)
│   │   │
│   │   ├── main_menu_v2.gui/.gui_script    # Главное меню
│   │   ├── hud_v2.gui/.gui_script          # HUD (локация, BAG/PHN кнопки)
│   │   ├── dialogue_v2.gui/.gui_script     # Диалоги + портреты
│   │   ├── choice_v2.gui/.gui_script       # Выборы с таймером
│   │   ├── nav_buttons_v2.gui/.gui_script  # Навигация (W/N/E/S)
│   │   ├── inventory_v2.gui/.gui_script    # Инвентарь (4×3 grid)
│   │   ├── phone_v2.gui/.gui_script        # Телефон (8 приложений)
│   │   ├── map_v2.gui/.gui_script          # Карта Москвы (7 пинов)
│   │   ├── hotspots_v2.gui/.gui_script     # Интерактивные объекты
│   │   └── effects.gui/.gui_script         # Эффекты (grain/scan/vignette)
│   │
│   ├── modules/
│   │   └── v2_theme.lua            # Централизованная тема
│   │
│   ├── components/                 # Старая система (НЕ ТРОГАТЬ!)
│   │   └── ...                     # Legacy UI
│   │
│   └── ui_manager_v2.script        # Оркестратор V2 компонентов
│
├── main_v2.collection              # V2 коллекция (активная)
└── main.collection                 # Старая коллекция (неактивна)
```

---

## 🧩 Atoms (Атомы) - Переиспользуемые элементы

### Что такое atoms?

**Atoms** — это маленькие, переиспользуемые GUI-компоненты, которые можно встраивать в другие экраны. Это аналог "UI prefabs" или "компонентов дизайн-системы".

### Существующие атомы:

#### 1. `corner_brackets.gui` - Угловые скобки

**Назначение:** Декоративные угловые скобки по периметру экрана (киберпанк-эстетика)

**Структура:**
- 8 нод (4 угла × 2 линии: горизонталь + вертикаль)
- Размер: 22×22 пикселя на угол
- Цвет: cyan (`#7df9ff`) с opacity 40%
- Позиции: отступ 14px от краёв экрана

**Использование:**
```lua
-- Atoms НЕ используются напрямую в коде
-- Они встраиваются в .gui файлы как визуальные элементы
-- Пример: можно скопировать ноды из corner_brackets.gui в свой компонент
```

**Визуально:**
```
┌──                    ──┐
│                        │
│    [ЭКРАН КОНТЕНТ]     │
│                        │
└──                    ──┘
```

---

#### 2. `hud_top.gui` - Верхняя HUD-полоса

**Назначение:** Информационная полоса сверху экрана (локация, время, петля)

**Структура:**
- `hud_top_bg`: Фон (960×32, тёмный ink с alpha 72%)
- `hud_top_border`: Cyan линия снизу (1px, alpha 25%)
- `hud_top_dot`: Пульсирующая точка слева (6×6, cyan)
- `hud_top_left`: Текст слева ("АВОСЬ_// room 04 · 07:12")
- `hud_top_right`: Текст справа ("петля #017 · состояние стабильно")

**Шрифт:** JetBrains Mono 10pt

**Использование в компонентах:**
```lua
-- В hud_v2.gui_script:
gui.set_text(gui.get_node("hud_top_left"), "ПРИХОЖАЯ · 07:12")
gui.set_text(gui.get_node("hud_top_right"), "петля #017")
```

**Визуально:**
```
┌────────────────────────────────────────────────────┐
│ ● АВОСЬ_// room 04 · 07:12    петля #017 · стабильно │
└────────────────────────────────────────────────────┘
```

---

#### 3. `hud_bot.gui` - Нижняя HUD-полоса

**Назначение:** Информационная полоса снизу экрана (действие игрока, метаинфо)

**Структура:**
- `hud_bot_bg`: Фон (960×32, тёмный ink с alpha 72%)
- `hud_bot_border`: Cyan линия сверху (1px, alpha 25%)
- `hud_bot_left`: Текст слева ("> стою на пороге _")
- `hud_bot_right`: Текст справа ("© 1983 / 2026 · самиздат · v0.1.7")

**Шрифт:** JetBrains Mono 10pt

**Использование:**
```lua
-- Обычно статичен, но можно обновлять:
gui.set_text(gui.get_node("hud_bot_left"), "> " .. player_action)
```

**Визуально:**
```
┌────────────────────────────────────────────────────┐
│ > стою на пороге _        © 1983 / 2026 · v0.1.7   │
└────────────────────────────────────────────────────┘
```

---

## 🎨 V2 Theme System (`v2_theme.lua`)

### Назначение

Централизованное хранилище всех визуальных констант проекта:
- Цветовая палитра (16 цветов + варианты с alpha)
- Шрифты (4 семейства, 12 начертаний)
- Семантические роли (title, body, mono, eyebrow, etc.)
- Layout константы (размеры экрана, отступы, размеры элементов)
- Анимационные пресеты (длительность, easing)

### Основные цвета

```lua
local theme = require "main.gui.modules.v2_theme"

-- Тёмные фоны (ink - чернила)
theme.COLORS.ink_0        -- #07061a (самый тёмный)
theme.COLORS.ink_1        -- #0c0a24
theme.COLORS.ink_2        -- #171232
theme.COLORS.frame        -- #221947

-- Текст (paper - бумага)
theme.COLORS.paper        -- #f3ecd9 (основной текст)
theme.COLORS.paper_soft   -- 70% alpha
theme.COLORS.paper_medium -- 50% alpha
theme.COLORS.paper_dim    -- #c9c0a8 (приглушённый)

-- Акценты
theme.COLORS.accent       -- #7df9ff (cyan - основной акцент)
theme.COLORS.accent_hot   -- #ff3d7f (magenta - опасность)
theme.COLORS.amber        -- #ffb347 (янтарный - предупреждение)
theme.COLORS.violet       -- #7a5cff (фиолетовый - магия)
theme.COLORS.stamp        -- #c8142a (красный - штамп "СЕКРЕТНО")
theme.COLORS.crt_green    -- #5aff7a (зелёный - CRT-режим нарратора)
```

### Шрифты

```lua
-- JetBrains Mono (моноширинный, UI/технический текст)
theme.FONTS.mono_10       -- Мелкий (eyebrow, метки)
theme.FONTS.mono_12       -- Средний (HUD, таймеры)
theme.FONTS.mono_bold_14  -- Жирный (кнопки)

-- Unbounded (заголовки, кнопки меню)
theme.FONTS.title_20      -- Средний заголовок
theme.FONTS.title_32      -- Крупный заголовок
theme.FONTS.title_72      -- Логотип "АВОСЬ"

-- Caveat (рукописный, заметки)
theme.FONTS.caveat_18     -- Мелкий
theme.FONTS.caveat_28     -- Крупный

-- Manrope (основной текст диалогов)
theme.FONTS.body_14       -- Мелкий
theme.FONTS.body_16       -- Средний

-- Material Icons (иконки)
theme.FONTS.icons         -- Глифы (рюкзак, телефон, etc.)
```

### Семантические роли

Вместо прямого указания шрифта/цвета, используй роли:

```lua
-- Применить роль к ноде:
theme.apply(gui.get_node("title"), "title")

-- Доступные роли:
"title"         -- Заголовки экранов (Unbounded 32, paper)
"button"        -- Кнопки меню (Unbounded 20, paper)
"body"          -- Диалоги (Manrope 16, paper)
"mono"          -- HUD/таймеры (JB Mono 12, paper_soft)
"eyebrow"       -- Надтекст (JB Mono 10, accent)
"caveat"        -- Рукописные заметки (Caveat 18, amber)
"hint_hot"      -- Подсказка magenta (JB Mono 10, accent_hot)
```

### Layout константы

```lua
theme.LAYOUT.screen_w = 960        -- Ширина экрана
theme.LAYOUT.screen_h = 640        -- Высота экрана
theme.LAYOUT.hud_strip_h = 32      -- Высота HUD-полос
theme.LAYOUT.corner_size = 22      -- Размер угловых скобок
theme.LAYOUT.portrait_size = 96    -- Размер портрета
theme.LAYOUT.inv_slot_size = 96    -- Размер слота инвентаря
theme.LAYOUT.nav_btn_size = 112    -- Размер кнопки навигации
```

---

## 🎮 Компоненты V2

### 1. main_menu_v2 - Главное меню

**Функции:**
- 4 пункта меню (Новая итерация / Продолжить / Галерея / Достижения)
- Логотип "АВОСЬ" с glitch-эффектом
- Штамп "СЕКРЕТНО · №17"
- Досье-карточка с прогрессом
- Ticker (бегущая строка внизу)
- Parallax skyline (3 слоя, idle-sway анимация)

**Сообщения:**
- `show_menu` / `hide_menu`
- Клики → `start_game` / `continue_game` / `open_gallery` / `open_achievements`

---

### 2. hud_v2 - HUD (Heads-Up Display)

**Функции:**
- Верхняя плашка: локация + время + номер петли
- Правый слот: 2 круглые кнопки (BAG, PHN) с бейджами
- Динамическое скрытие/показ телефона (до получения предмета)

**Сообщения:**
- `set_location {name, time, loop}`
- `set_inventory_count {n}`
- `set_phone_notif {n}`
- `set_phone_enabled {enabled}`
- Клики → `open_inventory` / `open_phone`

---

### 3. dialogue_v2 - Диалоги

**Функции:**
- Портрет персонажа (96×96, из v2.atlas)
- Nameplate (имя + тег)
- Диалоговый бокс с угловыми brackets
- Typewriter эффект (45 символов/сек)
- Кнопки SKIP / AUTO / NEXT
- CRT-режим для нарратора (зелёный текст)

**Сообщения:**
- `render_dialogue {speaker, name, text, tag, portrait}`
- `show_dialogue` / `hide_dialogue`
- Клики → `dialogue_next` / `dialogue_skip` / `dialogue_auto`

**Особенности:**
- UTF-8 aware (поддержка кириллицы)
- Автоматическое определение портрета по имени персонажа
- Пауза после знаков препинания

---

### 4. choice_v2 - Выборы

**Функции:**
- Модалка с 2-4 опциями
- Динамическое создание кнопок
- Таймер countdown (18 сек по умолчанию)
- Цветовая индикация (accent → amber → hot)
- Стили опций: normal / key / danger
- Hint-строки с цветовой кодировкой

**Сообщения:**
- `show_choice {opts, timer_sec, title}`
- `hide_choice`
- Клики → `choice_picked {index}` / `choice_timeout`

---

### 5. nav_buttons_v2 - Навигация

**Функции:**
- 4 круглые кнопки (W/N/E/S) по периметру экрана
- Цветовая кодировка: left=hot, up=cyan, right=amber, down=violet
- Иконки chevron (Material Icons)
- Подписи комнат
- Locked-состояние (серая подпись)

**Сообщения:**
- `show_nav` / `hide_nav`
- `set_exits {W, N, E, S}` (из scenes.lua)
- Клики → `nav_go {dir, scene_id}`

---

### 6. inventory_v2 - Инвентарь

**Функции:**
- Модалка 4×3 grid (12 слотов)
- Динамическое создание слотов
- Details-панель справа (описание + статистика)
- 5 verb-кнопок (Применить / Осмотреть / Комбо / Прочитать / Отдать)
- Координаты слотов (A1, B1, C1, D1, A2, ...)
- Статистика: источник, итерация, тип, улика

**Сообщения:**
- `open_inventory` / `close_inventory`
- `refresh_inventory`
- Клики → `inventory_verb {item_id, verb}`

**Данные:** Читает из `game_state.lua` через `gs.get_inventory()`

---

### 7. phone_v2 - Телефон

**Функции:**
- Модалка 280×560 (вертикальная рамка)
- Status bar (время, 4G, батарея)
- Wallpaper с датой
- 8 app-плиток (4×2 grid): СМС / Звонки / Карта / Улики / День / Почта / Камера / Терминал
- Цветовые акценты (cyan/hot/amber/violet)
- Flash-эффект при клике

**Сообщения:**
- `open_phone` / `close_phone`
- Клики → `phone_app_clicked {id}`

**Примечание:** Приложения пока открывают диалоги на основном экране (не внутри телефона)

---

### 8. map_v2 - Карта

**Функции:**
- Карта Москвы (560×480 слева)
- 7 пинов: home / work / cafe / metro / shop / clue / gov
- Досье-панель справа (310×480)
- Информация о локации: адрес, время пути, метро, статус, улика
- 3 verb-кнопки: route / save / share (пока заглушки)

**Сообщения:**
- `open_map` / `close_map`
- Клики → `map_verb {pin_id, verb}`

**Данные:** Пины с нормализованными координатами (0..1)

---

### 9. hotspots_v2 - Интерактивные объекты

**Функции:**
- 6 hotspot-слотов (круглые кнопки с орбитами)
- 4 scene_object-слота (объекты на сцене)
- Иконки Material Icons
- Анимация орбиты (6 точек вращаются)
- Locked-состояние

**Сообщения:**
- `set_hotspot {index, data}`
- `set_scene_object {index, data}`
- `hide_all`
- Клики → `hotspot_clicked {index}` / `scene_object_clicked {index}`

**Данные:** Получает из `scene_controller` через `ui_manager_v2`

---

### 10. effects - Визуальные эффекты

**Функции:**
- `grain`: Зернистость (белый 7% alpha)
- `scan`: Сканлайны (белый 18% alpha, BLEND_MULT)
- `vignette`: Виньетка (чёрный 55% alpha)

**Сообщения:**
- `set_effects {level}` (0..1)
- `toggle_scan {on}`
- `show_effects` / `hide_effects`

**Примечание:** Пока plain-color box'ы, можно подключить текстуры

---

## 🎛️ ui_manager_v2 - Оркестратор

### Назначение

Центральный контроллер, который:
- Управляет режимами (menu / nav / exploration / dialogue / choice)
- Управляет оверлеями (inventory / phone / map)
- Маршрутизирует сообщения между компонентами
- Интегрируется с `scene_controller`, `dialogue_manager_ink`, `game_state`

### Режимы (base_mode)

```lua
"menu"        -- Главное меню (всё скрыто кроме main_menu_v2)
"nav"         -- Навигация (показаны nav_buttons_v2)
"exploration" -- Исследование (показаны hotspots_v2, hud_v2)
"dialogue"    -- Диалог (показан dialogue_v2, скрыты hotspots)
"choice"      -- Выбор (показан choice_v2 поверх dialogue)
```

### Оверлеи (overlay_mode)

```lua
"inventory"   -- Инвентарь открыт
"phone"       -- Телефон открыт
"map"         -- Карта открыта
nil           -- Нет оверлея
```

### Основные методы

```lua
-- Режимы
show_menu()
show_exploration()
show_dialogue()
show_nav()
hide_nav()

-- Оверлеи
open_inventory()
close_inventory()
open_phone()
close_phone()
open_map()
close_map()

-- Диалоги
render_dialogue(data)
show_choice(data)
hide_choice()
```

---

## 🔄 Порядок рендеринга (Z-Order)

Компоненты в `main_v2.collection` рендерятся в порядке добавления:

```
1. ui_manager_v2 (script)      -- Контроллер
2. main_menu_v2                -- z: 0.5-0.6 (fullscreen)
3. dialogue_v2                 -- z: 0.06-0.42 (scene_bg + dialogue)
4. hotspots_v2                 -- z: 0.08-0.15 (above scene)
5. nav_buttons_v2              -- z: 0.2-0.3 (navigation)
6. hud_v2                      -- z: 0.6-0.65 (HUD badges)
7. choice_v2                   -- z: 0.40-0.65 (modal)
8. inventory_v2                -- z: 0.40-0.57 (modal)
9. phone_v2                    -- z: 0.40-0.57 (modal)
10. map_v2                     -- z: 0.40-0.57 (modal)
11. effects                    -- z: 0.7-0.75 (topmost overlay)
```

**Правило:** Последний в списке = рисуется поверх всех

---

## 📊 Сравнение: Legacy vs V2

| Аспект | Legacy (components/) | V2 (components_v2/) |
|--------|---------------------|---------------------|
| **Архитектура** | Монолитная (novel_ui.gui, 314 нод) | Модульная (10 компонентов) |
| **Размер файлов** | 1 файл 112 KB | 10 файлов по 5-40 KB |
| **Тема** | Hardcoded цвета/шрифты | Централизованная (v2_theme.lua) |
| **Портреты** | 512×512 PNG | 96×96 PNG (оптимизировано) |
| **Atoms** | Нет | Есть (corner_brackets, hud_top/bot) |
| **Typewriter** | Нет | Есть (45 cps, UTF-8 aware) |
| **Модалки** | Простые | С backdrop, анимациями |
| **Статус** | Read-only (не трогать) | Активная разработка |

---

## 🚀 Как добавить новый компонент

1. **Прочитай DESIGN_PORT_RULES.md** (обязательно!)
2. **Используй v2_theme.lua** для всех цветов/шрифтов
3. **Создай .gui файл:**
   - Root container: `size 0×0, color.w=1.0`
   - Backdrop (если модалка): `inherit_alpha: false`
   - Добавь нужные fonts/textures
4. **Создай .gui_script:**
   - `require "main.gui.modules.v2_theme"`
   - `msg.post(".", "acquire_input_focus")` в init (если нужен input)
   - Динамические ноды: абсолютные координаты, явный z
5. **Добавь в main_v2.collection** в правильном порядке
6. **Добавь обработчики в ui_manager_v2.script**
7. **Протестируй в Defold**
8. **Закоммить:** `feat(v2): add xxx_v2 component`

---

## 📚 Полезные ссылки

- `DESIGN_PORT_RULES.md` - Все правила и грабли
- `AVOS_V2_PROGRESS.md` - История миграции
- `GUI_CREATION_GUIDE.md` - Гайд по созданию GUI
- `main/gui/modules/v2_theme.lua` - Исходный код темы
- `.opencode/skills/defold-gui/SKILL.md` - Скилл для OpenCode

---

## ❓ FAQ

**Q: Можно ли использовать atoms в своих компонентах?**  
A: Да, но не через "import" (Defold не поддерживает). Скопируй нужные ноды из atoms/*.gui в свой компонент.

**Q: Почему atoms не имеют .gui_script?**  
A: Atoms — это чисто визуальные элементы без логики. Логика живёт в компонентах, которые их используют.

**Q: Можно ли модифицировать legacy UI?**  
A: НЕТ! Legacy UI (components/) — read-only. Все изменения только в V2.

**Q: Как переключиться обратно на legacy UI?**  
A: В `game.project` измени `bootstrap.main_collection = /main/main.collectionc`

**Q: Почему портреты 96×96, а не 512×512?**  
A: Оптимизация. V2 дизайн использует маленькие портреты, это экономит память.

**Q: Что делать, если нода невидима?**  
A: Читай DESIGN_PORT_RULES.md, Rule #1 (Alpha Inheritance). Это 90% проблем.

---

**Последнее обновление:** 2026-04-20  
**Автор:** OpenCode AI + AVOS Team
