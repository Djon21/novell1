# ИНСТРУКЦИЯ ПО СОЗДАНИЮ GUI ФАЙЛОВ В DEFOLD

**Дата:** 2026-04-19
**Цель:** Создать GUI файлы для готовых компонентов, скопировав ноды из novel_ui.gui

---

## ОБЩИЙ ПРОЦЕСС

1. Открыть Defold редактор
2. Открыть файл `/main/gui/novel_ui.gui` (источник нод)
3. Создать новый GUI файл для компонента
4. Скопировать нужные ноды из novel_ui.gui
5. Прикрепить готовый .gui_script к новому GUI файлу

---

## КОМПОНЕНТ 1: MAIN MENU

### Файл: `/main/gui/components/main_menu.gui`

**Скрипт:** `/main/gui/components/main_menu.gui_script` (уже готов)

**Ноды для копирования из novel_ui.gui:**

```
Всего: 60 нод

Основные элементы:
- bg_menu (фон меню)
- menu_panel (контейнер)
- menu_left_shade
- menu_divider_right
- menu_divider_top
- menu_hud_top_left
- menu_hud_top_right
- menu_hud_bot
- menu_eyebrow

Заголовок:
- menu_title
- menu_title_glitch_r (красный глитч)
- menu_title_glitch_b (синий глитч)

Штамп:
- menu_stamp_box
- menu_stamp_bt, menu_stamp_bb, menu_stamp_bl, menu_stamp_br (границы)
- menu_stamp_text

Подзаголовок:
- menu_subtitle

Кнопки (4 штуки × 5 нод = 20 нод):
Для каждой кнопки (new, continue, gallery, awards):
- menu_btn_NAME (контейнер)
- menu_btn_NAME_bar (боковая полоса)
- menu_btn_NAME_num (номер)
- menu_btn_NAME_text (текст на русском)
- menu_btn_NAME_en (текст на английском)

Досье (статистика):
- menu_dossier_bg
- menu_dossier_bt, menu_dossier_bb, menu_dossier_bl, menu_dossier_br
- menu_dossier_eyebrow
- menu_dossier_label_0..5 (6 меток)
- menu_dossier_value_0..5 (6 значений)
- menu_dossier_hand (иконка руки)

Подсказка:
- menu_hint
```

**Как найти в novel_ui.gui:**
1. Открыть Outline панель
2. Найти ноду `menu_panel` - это корневой контейнер
3. Выделить `menu_panel` и все дочерние ноды
4. Ctrl+C для копирования
5. Открыть main_menu.gui
6. Ctrl+V для вставки

---

## КОМПОНЕНТ 2: PORTRAITS

### Файл: `/main/gui/components/portraits.gui`

**Скрипт:** `/main/gui/components/portraits.gui_script` (уже готов)

**Ноды для копирования из novel_ui.gui:**

```
Всего: 2 ноды

- portrait_mila
- portrait_artem
```

**Как найти в novel_ui.gui:**
1. В Outline найти `portrait_mila`
2. Выделить обе ноды (Ctrl+Click)
3. Ctrl+C для копирования
4. Открыть portraits.gui
5. Ctrl+V для вставки

**ВАЖНО:** Эти ноды используют текстуры из атласа `/main/images/portraits.atlas`

---

## КОМПОНЕНТ 3: INVENTORY

### Файл: `/main/gui/components/inventory.gui`

**Скрипт:** `/main/gui/components/inventory.gui_script` (уже готов)

**Ноды для копирования из novel_ui.gui:**

```
Всего: 143 ноды

Основные элементы:
- inv_modal_dim (затемнение)
- inv_modal_panel (панель)
- inv_modal_title (заголовок)
- inv_modal_close_btn
- inv_modal_close_text
- inv_modal_eyebrow
- inv_modal_stat_slots
- inv_modal_stat_weight
- inv_modal_stat_loop

Слоты инвентаря (12 слотов × 7 нод = 84 ноды):
Для каждого слота (1..12):
- inv_slot_circle_N
- inv_slot_ring_N
- inv_slot_icon_N
- inv_slot_hit_N
- inv_slot_coord_N
- inv_slot_name_N
- inv_slot_qty_N

Детали предмета:
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

Действия (verbs):
- inv_verb_use, inv_verb_use_text
- inv_verb_inspect, inv_verb_inspect_text
- inv_verb_combine, inv_verb_combine_text
- inv_verb_read, inv_verb_read_text
- inv_verb_give, inv_verb_give_text

Модалка предмета:
- item_modal_dim
- item_modal_panel
- item_modal_name
- item_modal_icon
- item_modal_desc
- item_modal_close_btn
- item_modal_close_text
```

**Как найти в novel_ui.gui:**
1. В Outline найти `inv_modal_dim` - это корневой контейнер
2. Выделить `inv_modal_dim` и все дочерние ноды
3. Также выделить `item_modal_dim` и его дочерние ноды
4. Ctrl+C для копирования
5. Открыть inventory.gui
6. Ctrl+V для вставки

---

## КОМПОНЕНТ 4: PHONE

### Файл: `/main/gui/components/phone.gui`

**Скрипт:** `/main/gui/components/phone.gui_script` (уже готов)

**Ноды для копирования из novel_ui.gui:**

```
Всего: 10 нод

HUD иконка телефона:
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
```

**Как найти в novel_ui.gui:**
1. В Outline найти `hud_phone_circle`
2. Выделить все 10 нод с префиксом `hud_phone_`
3. Ctrl+C для копирования
4. Открыть phone.gui
5. Ctrl+V для вставки

**ПРИМЕЧАНИЕ:** Телефон открывает сцену `phone_home` через scene_controller, сам интерфейс телефона - это обычная point-and-click сцена с hotspots.

---

## КОМПОНЕНТ 5: DIALOGUE SYSTEM

### Файл: `/main/gui/components/dialogue_system.gui`

**Скрипт:** `/main/gui/components/dialogue_system.gui_script` (уже готов)

**Ноды для копирования из novel_ui.gui:**

```
Всего: ~27 нод

Нарраторская панель:
- narrator_panel
- narrator_clock
- narrator_prompt
- narrator_cursor

Диалоговая панель:
- dialogue_panel
- name_panel
- name_label
- dialogue_text
- continue_hint

Панель выборов:
- choice_panel
- choice_question
- choice_panel_top_line
- choice_panel_left_line

Кнопки выбора (4 кнопки × 4 ноды = 16 нод):
Для каждой кнопки (1..4):
- choice_btn_N
- choice_text_N
- choice_btn_N_top
- choice_btn_N_left
```

**Как найти в novel_ui.gui:**
1. В Outline найти `narrator_panel` - выделить его и дочерние
2. Найти `dialogue_panel` - выделить его и дочерние
3. Найти `choice_panel` - выделить его и дочерние
4. Ctrl+C для копирования всех выделенных
5. Открыть dialogue_system.gui
6. Ctrl+V для вставки

---

## КОМПОНЕНТ 6: HOTSPOTS

### Файл: `/main/gui/components/hotspots.gui`

**Скрипт:** `/main/gui/components/hotspots.gui_script` (уже готов)

**Ноды для копирования из novel_ui.gui:**

```
Всего: 64 ноды

Hotspots (6 слотов × 10 нод = 60 нод):
Для каждого hotspot (1..6):
- hotspot_N (контейнер/hitbox)
- hotspot_label_N
- hotspot_circle_N
- hotspot_ring_N
- hotspot_orbit_N
- hotspot_icon_N
- hotspot_dot_N_1..6 (6 точек на орбите)

Scene objects (4 слота):
- scene_obj_1
- scene_obj_2
- scene_obj_3
- scene_obj_4
```

**Как найти в novel_ui.gui:**
1. В Outline найти `hotspot_1` - выделить его и все дочерние
2. Повторить для `hotspot_2..6`
3. Также выделить `scene_obj_1..4`
4. Ctrl+C для копирования
5. Открыть hotspots.gui
6. Ctrl+V для вставки

---

## ВАЖНЫЕ ЗАМЕЧАНИЯ

### 1. Текстуры и атласы

После копирования нод нужно убедиться, что GUI файл подключает нужные атласы:

```
В Properties панели GUI файла добавить:
- /main/images/backgrounds.atlas
- /main/images/portraits.atlas (для portraits.gui)
- /main/images/ui_elements.atlas (если используется)
```

### 2. Шрифты

Убедитесь, что все текстовые ноды используют правильные шрифты:
- `/main/fonts/roboto_mono.font` - основной моноширинный шрифт
- `/main/fonts/material_icons.font` - иконки Material Icons

### 3. Скрипты

После создания GUI файла:
1. В Properties панели установить Script: `/main/gui/components/COMPONENT_NAME.gui_script`
2. Сохранить GUI файл

### 4. Проверка

После создания каждого GUI файла:
1. Открыть соответствующий test_*.collection
2. Запустить проект (Project → Build)
3. Проверить, что компонент отображается корректно

---

## ПОРЯДОК СОЗДАНИЯ (РЕКОМЕНДУЕМЫЙ)

1. **Portraits** (самый простой - 2 ноды)
2. **Phone** (простой - 10 нод)
3. **Main Menu** (средний - 60 нод)
4. **Dialogue System** (средний - 27 нод)
5. **Hotspots** (сложный - 64 ноды)
6. **Inventory** (самый сложный - 143 ноды)

---

## АЛЬТЕРНАТИВНЫЙ СПОСОБ: ПОИСК ПО ID

Если сложно найти ноды в Outline:

1. Открыть `/main/gui/novel_ui.gui` в текстовом редакторе
2. Найти строку с нужным ID, например: `id: "menu_panel"`
3. Скопировать весь блок ноды (от `nodes {` до закрывающей `}`)
4. Вставить в новый GUI файл

**ВНИМАНИЕ:** Этот способ требует понимания формата .gui файлов!

---

## ПОМОЩЬ ПРИ ПРОБЛЕМАХ

### Проблема: "Node not found"
**Решение:** Проверьте, что ID ноды в GUI файле совпадает с ID в .gui_script

### Проблема: "Texture not found"
**Решение:** Добавьте нужный атлас в Properties → Textures

### Проблема: "Script error"
**Решение:** Убедитесь, что путь к скрипту правильный в Properties → Script

---

## КОНТРОЛЬНЫЙ СПИСОК

После создания всех GUI файлов:

- [ ] main_menu.gui создан и работает
- [ ] portraits.gui создан и работает
- [ ] inventory.gui создан и работает
- [ ] phone.gui создан и работает
- [ ] dialogue_system.gui создан и работает
- [ ] hotspots.gui создан и работает
- [ ] Все test_*.collection запускаются без ошибок
- [ ] Все компоненты отображаются корректно

---

Удачи с созданием GUI файлов! 🚀
