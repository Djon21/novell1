# GUI AUDIT - Анализ novel_ui.gui_script

Дата: 2026-04-19
Файл: novel_ui.gui_script (1670 строк)

## ОСНОВНЫЕ СИСТЕМЫ

### 1. MAIN MENU (Главное меню)
**Переменные состояния:**
- S.menu_panel
- S.menu_btn_new, S.menu_btn_continue, S.menu_btn_gallery, S.menu_btn_awards
- S.menu_btn_*_text (текстовые ноды кнопок)
- S.menu_hint_node
- S.menu_toast_until
- S.menu_title_glitch_r, S.menu_title_glitch_b
- S.in_menu (флаг)
- S.glitch_active (флаг)

**Функции:**
- start_glitch() - эффект глитча на заголовке
- show_menu() - показ меню
- Обработка кликов по кнопкам в on_input()

**Зависимости:**
- save_manager (проверка наличия сохранений)
- dialogue_manager_ink (запуск истории)
- yagames (Яндекс SDK)

---

### 2. DIALOGUE SYSTEM (Система диалогов)
**Переменные состояния:**
- S.dialogue_panel
- S.name_panel, S.name_label
- S.dialogue_text
- S.continue_hint
- S.choice_panel
- S.choice_question_node
- S.choice_btns[], S.choice_texts[]
- S.choice_btn_tops[], S.choice_btn_lefts[]
- S.narrator_panel, S.narrator_clock, S.narrator_prompt, S.narrator_cursor
- S.narrator_visible
- S.cursor_blink_t

**Функции:**
- show_dialogue_mode() - отображение диалога
- show_choice_mode() - отображение выборов
- show_end_mode() - конец истории
- hide_dialogue_ui() - скрытие диалогового UI
- render() - основной рендеринг

**Зависимости:**
- dialogue_manager_ink (получение текста, выборов)
- scene_controller (проверка активности сцен)

---

### 3. PORTRAITS (Портреты персонажей)
**Переменные состояния:**
- S.portraits = {} (таблица нод портретов)
- S.current_portrait
- S.PORTRAIT_X, S.PORTRAIT_Y, S.PORTRAIT_Z
- S.PORTRAIT_SLIDE_FROM
- S.PORTRAIT_ANIM_DUR = 0.25
- S.TEXT_X_NORMAL, S.TEXT_X_PORTRAIT
- S.TEXT_W_NORMAL, S.TEXT_W_PORTRAIT
- S.NAME_X_NORMAL, S.NAME_X_PORTRAIT

**Функции:**
- Логика показа/скрытия портретов в show_dialogue_mode()
- Анимация появления портрета (slide from left)
- Сдвиг текста при показе портрета

**Зависимости:**
- dialogue_manager_ink (получение speaker)

---

### 4. BACKGROUNDS (Фоны)
**Переменные состояния:**
- S.bg_node (цветная подложка)
- S.bg_sprite (основной фон)
- S.bg_sprite_next (для crossfade)
- S.bg_menu_node (фон меню)
- S.current_bg_image
- S.BG_FADE_DUR = 0.35

**Функции:**
- set_background() - смена фона с crossfade
- normalize_bg() - нормализация имени фона

**Зависимости:**
- dialogue_manager_ink (получение bg, bg_image)

---

### 5. HOTSPOTS (Интерактивные точки)
**Переменные состояния:**
- S.hotspot_boxes[] (6 слотов)
- S.hotspot_labels[]
- S.hotspot_icons[]
- S.hotspot_circles[]
- S.hotspot_rings[]
- S.hotspot_orbits[]
- S.hotspot_dots[][] (6 точек на орбите)
- S.HOTSPOT_COUNT = 6
- S.ORBIT_DOTS = 6
- S.scene_obj_nodes[] (4 объекта)
- S.SCENE_OBJECT_COUNT = 4

**Функции:**
- Управление через scene_controller
- Обработка кликов в on_input()
- Анимация орбит в update()

**Зависимости:**
- scene_controller (управление hotspot'ами)
- hotspot_editor (режим редактирования)

---

### 6. INVENTORY (Инвентарь)
**Переменные состояния:**
- S.inv_modal = { visible, slots[], COUNT = 12 }
- S.item_modal = { visible, item_id }
- S.hud.backpack = { circle, ring, icon, hit }

**Функции:**
- Показ/скрытие инвентаря
- Управление слотами
- Модалка описания предмета

**Зависимости:**
- game_state (получение инвентаря)
- items_catalog (данные о предметах)

---

### 7. PHONE (Телефон)
**Переменные состояния:**
- S.hud.phone = { circle, ring, icon, hit }
- Ноды телефонного интерфейса (не детализированы в начале файла)

**Функции:**
- Открытие/закрытие телефона
- Навигация по приложениям

**Зависимости:**
- game_state (флаг has_phone)
- scene_controller (сцена phone_home)

---

### 8. EFFECTS (Эффекты)
**Переменные состояния:**
- S.pulse_overlay (вспышка)
- S.shake_state (тряска экрана)
- S.SFX_URLS (звуковые эффекты)

**Функции:**
- play_sfx() - воспроизведение звука
- start_shake() - тряска экрана
- pulse_flash() - вспышка
- dispatch_effect() - диспетчер эффектов

**Зависимости:**
- dialogue_manager_ink (теги sfx, shake, pulse)

---

### 9. HUD (Постоянный интерфейс)
**Переменные состояния:**
- S.hud.backpack (рюкзак - всегда виден)
- S.hud.phone (телефон - виден при has_phone=true)

**Функции:**
- Управление видимостью HUD
- Обработка кликов по иконкам

**Зависимости:**
- game_state (флаги)

---

## ЗАВИСИМОСТИ МЕЖДУ СИСТЕМАМИ

### Высокая связность:
1. **Dialogue System ↔ Portraits** - диалоги управляют портретами
2. **Dialogue System ↔ Backgrounds** - диалоги управляют фонами
3. **Dialogue System ↔ Effects** - диалоги запускают эффекты
4. **Hotspots ↔ Scene Controller** - hotspot'ы управляются scene_controller
5. **Inventory ↔ Game State** - инвентарь читает/пишет в game_state
6. **Phone ↔ Game State** - телефон читает/пишет в game_state

### Низкая связность:
1. **Main Menu** - относительно независим
2. **HUD** - независим, только читает флаги

---

## ОБЩИЕ МОДУЛИ (для извлечения)

### gui_utils.lua
- Функции работы с нодами
- Проверки видимости
- Базовые операции

### gui_animations.lua
- fade_in / fade_out
- slide_in / slide_out
- pulse_flash
- shake

### gui_colors.lua
- COLOR_INK, COLOR_PAPER, COLOR_ACCENT и т.д.
- Палитра цветов

---

## РЕКОМЕНДАЦИИ ПО РАЗДЕЛЕНИЮ

### Приоритет 1 (легко отделить):
1. **Main Menu** - минимум зависимостей
2. **Portraits** - четкая граница, управляется через сообщения

### Приоритет 2 (средняя сложность):
3. **Inventory** - нужно выделить HUD иконку
4. **Phone** - нужно выделить HUD иконку
5. **Hotspots** - связан с scene_controller

### Приоритет 3 (сложно):
6. **Dialogue System** - центральная система, много связей
7. **Backgrounds** - используется всеми системами
8. **Effects** - используется диалогами

---

## РАЗМЕР СИСТЕМ (примерная оценка строк кода)

1. Main Menu: ~200-300 строк
2. Dialogue System: ~500-700 строк
3. Portraits: ~150-200 строк
4. Backgrounds: ~100-150 строк
5. Hotspots: ~300-400 строк
6. Inventory: ~400-500 строк
7. Phone: ~200-300 строк
8. Effects: ~150-200 строк
9. HUD: ~100-150 строк

**Итого:** ~2100-2900 строк логики (остальное - init, update, on_input)

---

Конец аудита.
