# NODE MAP - Карта нод novel_ui.gui

Дата: 2026-04-19
> Архивная карта нод legacy `novel_ui.gui`.
> Полезна только при разборе старого UI или исторических багов; текущий интерфейс живёт в `main/gui/components_v2/`.

Всего нод: 314

## ГРУППИРОВКА ПО СИСТЕМАМ

### 1. BACKGROUNDS (Фоны) - 4 ноды
- background (цветная подложка)
- bg_image (основной фон)
- bg_image_next (для crossfade)
- pulse_overlay (вспышка)

**Целевой GUI:** backgrounds можно оставить в dialogue_system.gui или вынести отдельно

---

### 2. SCENE OBJECTS (Объекты сцены) - 4 ноды
- scene_obj_1
- scene_obj_2
- scene_obj_3
- scene_obj_4

**Целевой GUI:** hotspots.gui (связаны с интерактивными сценами)

---

### 3. HOTSPOTS (Интерактивные точки) - 60 нод (6 слотов × 10 нод)
Каждый hotspot содержит:
- hotspot_N (контейнер)
- hotspot_label_N
- hotspot_circle_N
- hotspot_ring_N
- hotspot_orbit_N
- hotspot_dot_N_1..6 (6 точек на орбите)
- hotspot_icon_N

**Слоты:** hotspot_1, hotspot_2, hotspot_3, hotspot_4, hotspot_5, hotspot_6

**Целевой GUI:** hotspots.gui

---

### 4. NARRATOR PANEL (Нарраторская плашка) - 4 ноды
- narrator_panel
- narrator_clock
- narrator_prompt
- narrator_cursor

**Целевой GUI:** dialogue_system.gui

---

### 5. PORTRAITS (Портреты) - 2 ноды
- portrait_mila
- portrait_artem

**Целевой GUI:** portraits.gui

---

### 6. DIALOGUE SYSTEM (Диалоги) - 7 нод
- dialogue_panel
- name_panel
- name_label
- dialogue_text
- continue_hint
- choice_panel
- choice_panel_top_line
- choice_panel_left_line

**Целевой GUI:** dialogue_system.gui

---

### 7. CHOICE BUTTONS (Кнопки выбора) - 16 нод (4 кнопки × 4 ноды)
Каждая кнопка содержит:
- choice_btn_N
- choice_text_N
- choice_btn_N_top
- choice_btn_N_left

**Кнопки:** choice_btn_1, choice_btn_2, choice_btn_3, choice_btn_4
**Вопрос:** choice_question

**Целевой GUI:** dialogue_system.gui (или создать template dialogue_choice.gui)

---

### 8. MAIN MENU (Главное меню) - 60 нод
**Основные элементы:**
- bg_menu (фон меню)
- menu_panel (контейнер)
- menu_left_shade, menu_divider_right, menu_divider_top
- menu_hud_top_left, menu_hud_top_right, menu_hud_bot
- menu_eyebrow

**Заголовок:**
- menu_title
- menu_title_glitch_r (красный глитч)
- menu_title_glitch_b (синий глитч)

**Штамп:**
- menu_stamp_box
- menu_stamp_bt, menu_stamp_bb, menu_stamp_bl, menu_stamp_br (границы)
- menu_stamp_text

**Подзаголовок:**
- menu_subtitle

**Кнопки (4 штуки):**
Каждая кнопка содержит:
- menu_btn_NAME (контейнер)
- menu_btn_NAME_bar (боковая полоса)
- menu_btn_NAME_num (номер)
- menu_btn_NAME_text (текст на русском)
- menu_btn_NAME_en (текст на английском)

Кнопки: new, continue, gallery, awards

**Досье (статистика):**
- menu_dossier_bg
- menu_dossier_bt, menu_dossier_bb, menu_dossier_bl, menu_dossier_br
- menu_dossier_eyebrow
- menu_dossier_label_0..5 (6 меток)
- menu_dossier_value_0..5 (6 значений)
- menu_dossier_hand (иконка руки)

**Подсказка:**
- menu_hint

**Целевой GUI:** main_menu.gui

---

### 9. HUD (Постоянный интерфейс) - 20 нод

**Рюкзак (backpack):**
- hud_backpack_circle
- hud_backpack_ring
- hud_backpack_icon
- hud_backpack_hit
- hud_backpack_decal
- hud_backpack_decal_text
- hud_backpack_badge
- hud_backpack_badge_text
- hud_backpack_tag
- hud_backpack_caption

**Телефон (phone):**
- hud_phone_circle
- hud_phone_ring
- hud_phone_icon
- hud_phone_hit
- hud_phone_decal
- hud_phone_decal_text
- hud_phone_badge
- hud_phone_badge_text
- hud_phone_tag
- hud_phone_caption

**Целевой GUI:** Можно оставить в dialogue_system.gui или создать отдельный hud.gui

---

### 10. INVENTORY MODAL (Инвентарь) - 143 ноды

**Основные элементы:**
- inv_modal_dim (затемнение)
- inv_modal_panel (панель)
- inv_modal_title (заголовок)
- inv_modal_close_btn, inv_modal_close_text (кнопка закрытия)
- inv_modal_eyebrow
- inv_modal_stat_slots, inv_modal_stat_weight, inv_modal_stat_loop (статистика)

**Слоты инвентаря (12 слотов × 7 нод = 84 ноды):**
Каждый слот содержит:
- inv_slot_circle_N
- inv_slot_ring_N
- inv_slot_icon_N
- inv_slot_hit_N
- inv_slot_coord_N
- inv_slot_name_N
- inv_slot_qty_N

**Слоты:** 1..12

**Детали предмета:**
- inv_details_cap
- inv_details_name
- inv_details_preview_bg
- inv_details_preview_icon
- inv_details_stamp
- inv_details_desc
- inv_details_stat_source_key/value
- inv_details_stat_iter_key/value
- inv_details_stat_type_key/value
- inv_details_stat_clue_key/value

**Действия (verbs):**
- inv_verb_use, inv_verb_use_text
- inv_verb_inspect, inv_verb_inspect_text
- inv_verb_combine, inv_verb_combine_text
- inv_verb_read, inv_verb_read_text
- inv_verb_give, inv_verb_give_text

**Целевой GUI:** inventory.gui

---

### 11. ITEM MODAL (Модалка предмета) - 7 нод
- item_modal_dim
- item_modal_panel
- item_modal_name
- item_modal_icon
- item_modal_desc
- item_modal_close_btn
- item_modal_close_text

**Целевой GUI:** inventory.gui

---

## ИТОГОВАЯ СТАТИСТИКА

| Система | Количество нод | Целевой GUI |
|---------|----------------|-------------|
| Backgrounds | 4 | dialogue_system.gui |
| Scene Objects | 4 | hotspots.gui |
| Hotspots | 60 | hotspots.gui |
| Narrator Panel | 4 | dialogue_system.gui |
| Portraits | 2 | portraits.gui |
| Dialogue System | 7 | dialogue_system.gui |
| Choice Buttons | 16 | dialogue_system.gui |
| Main Menu | 60 | main_menu.gui |
| HUD | 20 | dialogue_system.gui или hud.gui |
| Inventory Modal | 143 | inventory.gui |
| Item Modal | 7 | inventory.gui |
| **ИТОГО** | **314** | **6 GUI файлов** |

---

## РЕКОМЕНДАЦИИ ПО TEMPLATES

### Template 1: inventory_slot.gui
Структура слота инвентаря (повторяется 12 раз):
- circle
- ring
- icon
- hit
- coord
- name
- qty

### Template 2: dialogue_choice.gui
Структура кнопки выбора (повторяется 4 раза):
- btn (контейнер)
- text
- top (линия сверху)
- left (линия слева)

### Template 3: hud_icon.gui (опционально)
Структура HUD иконки (повторяется 2 раза):
- circle
- ring
- icon
- hit
- decal + decal_text
- badge + badge_text
- tag
- caption

---

## PHONE SYSTEM (не найдено в NODE_MAP)

**Примечание:** Ноды телефонного интерфейса не найдены в списке ID. Возможно:
1. Телефон использует существующие ноды (например, scene_obj_*)
2. Телефон создается динамически через gui.new_*
3. Телефон находится в отдельном GUI файле (маловероятно)

**Действие:** Проверить код novel_ui.gui_script на наличие phone-related нод.

---

Конец карты нод.
