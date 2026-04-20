# GUI Analysis Report - AVOS Project
**Date:** 2026-04-20  
**Analyzed by:** defold-gui skill  
**Branch:** AVOS_S

## Executive Summary

Проанализировал GUI компоненты проекта AVOS с применением обновлённого скилла defold-gui. Обнаружено несколько критических проблем и множество возможностей для оптимизации.

---

## 🚨 КРИТИЧЕСКИЕ ПРОБЛЕМЫ

### 1. ❌ Использование `gui.set_parent()` для динамических нод

**Файл:** `main_menu_v2.gui_script:92`

```lua
gui.set_parent(n, parent)
```

**Проблема:** Это нарушает **Rule #2** из DESIGN_PORT_RULES.md!

**Почему это плохо:**
- Динамические ноды с `gui.set_parent()` могут быть невидимыми (enabled=true, alpha=1, но НЕ РЕНДЕРЯТСЯ)
- Клики работают (`gui.pick_node` успешен), но ничего не видно
- Это известный баг Defold с динамическими нодами

**Решение:**
```lua
-- ❌ НЕПРАВИЛЬНО
local n = gui.new_box_node(vmath.vector3(0, y, 0.12), vmath.vector3(960, h, 0))
gui.set_parent(n, parent)

-- ✅ ПРАВИЛЬНО - используйте абсолютные координаты
local parent_pos = gui.get_position(parent)
local n = gui.new_box_node(
    vmath.vector3(parent_pos.x + 0, parent_pos.y + y, 0.12),
    vmath.vector3(960, h, 0)
)
-- НЕТ gui.set_parent()!
```

**Затронутые файлы:**
- `main_menu_v2.gui_script` - функция `make_skyline_layer()`

**Приоритет:** 🔴 ВЫСОКИЙ - может вызвать невидимые элементы UI

---

### 2. ⚠️ Отсутствие текстур на box нодах

**Проблема:** Многие box ноды не имеют назначенных текстур.

**Найдено в:**
- `inventory_v2.gui` - множество box нод без текстур (backdrop, modal, borders, dividers)
- `choice_v2.gui` - backdrop, modal, timer элементы без текстур
- `dialogue_v2.gui` - dbox, borders без текстур

**Почему это плохо:**
Согласно официальной документации Defold:
> "Box nodes are always rendered, even if they do not have a texture assigned to them... Box nodes should always have a texture assigned to them so the renderer can batch them properly and reduce the number of draw-calls."

**Влияние на производительность:**
- Нарушается батчинг (группировка draw calls)
- Увеличивается количество draw calls
- Снижается производительность рендеринга

**Решение:**
1. Создать 1x1 пиксельную белую текстуру в атласе `v2.atlas`
2. Назначить её всем box нодам, которые используют только цвет
3. Цвет будет работать как tint (умножение на текстуру)

```lua
-- В .gui файле:
textures {
  name: "v2"
  texture: "/main/images/v2.atlas"
}

nodes {
  type: TYPE_BOX
  texture: "v2/white_1x1"  -- добавить!
  color { x: 0.047 y: 0.039 z: 0.141 w: 0.98 }
  ...
}
```

**Приоритет:** 🟡 СРЕДНИЙ - влияет на производительность

---

### 3. ⚠️ Отсутствие слоёв (Layers) для оптимизации

**Проблема:** Ни один GUI компонент не использует слои для оптимизации батчинга.

**Текущая ситуация:**
```
Проверено: choice_v2.gui, inventory_v2.gui, dialogue_v2.gui, и др.
Результат: layer: не используется нигде
```

**Почему это плохо:**
Без слоёв рендерер вынужден создавать отдельные draw calls для каждого изменения типа ноды:
```
Пример из inventory_v2:
- box (backdrop)
- box (modal)
- text (title)
- box (border)
- text (label)
- box (slot)
= 6 draw calls вместо потенциальных 2!
```

**Решение - использовать слои:**

```lua
-- В .gui файле добавить:
layers {
  name: "backgrounds"
}
layers {
  name: "borders"
}
layers {
  name: "text"
}
layers {
  name: "icons"
}

-- Затем назначить слои нодам:
nodes {
  id: "backdrop"
  layer: "backgrounds"
  ...
}
nodes {
  id: "title"
  layer: "text"
  ...
}
```

**Потенциальная экономия:**
- inventory_v2: ~40-50 нод → можно сократить с ~30 draw calls до ~4-6
- choice_v2: ~20 нод → можно сократить с ~15 draw calls до ~3-4
- dialogue_v2: ~30 нод → можно сократить с ~20 draw calls до ~4-5

**Приоритет:** 🟡 СРЕДНИЙ - значительное улучшение производительности

---

## ✅ ЧТО СДЕЛАНО ПРАВИЛЬНО

### 1. ✅ Правильное использование `acquire_input_focus`

**Отлично!** Все GUI скрипты правильно вызывают `msg.post(".", "acquire_input_focus")` в `init()`:

```lua
function init(self)
    msg.post(".", "acquire_input_focus")  -- ✅ Правильно!
    ...
end
```

**Проверено:**
- choice_v2.gui_script ✅
- dialogue_v2.gui_script ✅
- hotspots_v2.gui_script ✅
- hud_v2.gui_script ✅
- inventory_v2.gui_script ✅
- main_menu_v2.gui_script ✅
- map_v2.gui_script ✅
- nav_buttons_v2.gui_script ✅
- phone_v2.gui_script ✅

---

### 2. ✅ Правильное использование абсолютных координат для динамических нод

**Отлично!** В `inventory_v2.gui_script` и `choice_v2.gui_script` динамические ноды создаются с абсолютными координатами:

```lua
-- inventory_v2.gui_script:73 ✅
local abs_x = grid_pos.x + local_x
local abs_y = grid_pos.y + local_y
local bg = gui.new_box_node(vmath.vector3(abs_x, abs_y, 0.55), vmath.vector3(SLOT, SLOT, 0))
-- НЕТ gui.set_parent() - правильно!
```

```lua
-- choice_v2.gui_script:85 ✅
local abs_x = OPTS_PANEL_X
local abs_y = OPTS_PANEL_Y + y_local
local bg = gui.new_box_node(vmath.vector3(abs_x, abs_y, 0.7), vmath.vector3(w, h, 0))
-- НЕТ gui.set_parent() - правильно!
```

**Комментарий в коде показывает понимание проблемы:**
```lua
-- choice_v2.gui_script:76
-- опции создаём TOP-LEVEL с абсолютными координатами 
-- (дети opts_panel по непонятной причине не рендерятся)
```

---

### 3. ✅ Правильное использование `inherit_alpha`

**Отлично!** Правильная настройка alpha inheritance:

```lua
-- dialogue_v2.gui:63-71 ✅
nodes {
  id: "dlg_root"
  color { x: 0.0 y: 0.0 z: 0.0 w: 1.0 }  -- w=1.0 ✅
  inherit_alpha: true
}

-- inventory_v2.gui:32-40 ✅
nodes {
  id: "backdrop"
  color { x: 0.027 y: 0.023 z: 0.102 w: 0.55 }
  inherit_alpha: false  -- ✅ Правильно для backdrop с dimming
}
```

Это соответствует **Rule #1** из DESIGN_PORT_RULES.md!

---

### 4. ✅ Правильный порядок компонентов в коллекции

**Отлично!** Порядок GUI компонентов в `main_v2.collection` соответствует **Rule #3**:

```
1. ui_manager_v2 (script only)
2. main_menu_v2
3. dialogue_v2
4. hotspots_v2
5. nav_buttons_v2
6. hud_v2
7. choice_v2
8. inventory_v2
9. phone_v2
10. map_v2
11. effects
```

Это правильный порядок от фона к оверлеям!

---

### 5. ✅ Правильное использование Z-значений

**Отлично!** Z-значения правильно распределены по диапазонам:

```lua
// dialogue_v2.gui
scene_bg: z: 0.06-0.07  // Фоны сцен
dlg_root: z: 0.4        // Диалоговые элементы
dbox: z: 0.41-0.42      // Диалоговый бокс

// inventory_v2.gui
backdrop: z: 0.40       // Затемнение
modal: z: 0.50          // Модальное окно
content: z: 0.51-0.57   // Контент модалки

// choice_v2.gui
backdrop: z: 0.40       // Затемнение
modal: z: 0.50          // Модалка
options: z: 0.7-0.72    // Опции выбора
```

Это соответствует рекомендованным диапазонам из скилла!

---

## 🔧 РЕКОМЕНДАЦИИ ПО УЛУЧШЕНИЮ

### 1. Добавить GUI Layouts для разных разрешений

**Текущая ситуация:** Все GUI компоненты используют фиксированное разрешение 960x640.

**Проблема:** Нет адаптации под разные ориентации и разрешения экранов.

**Рекомендация:**
1. Создать Display Profiles для Portrait/Landscape
2. Добавить layouts в GUI компоненты
3. Использовать Pivot, Anchors, Adjust Mode для адаптивности

**Пример:**
```lua
-- В game.project указать display_profiles
-- Создать layouts в каждом .gui:
layouts {
  name: "Landscape"
}
layouts {
  name: "Portrait"
}

-- Обработать в скрипте:
function on_message(self, message_id, message, sender)
  if message_id == hash("layout_changed") then
    if message.id == hash("Portrait") then
      -- адаптировать UI для портретной ориентации
    end
  end
end
```

**Приоритет:** 🟢 НИЗКИЙ - улучшение UX для мобильных устройств

---

### 2. Использовать `gui.is_enabled()` перед `gui.pick_node()`

**Текущая ситуация:** Не проверено во всех местах.

**Проблема:** `gui.pick_node()` проверяет только геометрию, игнорирует `enabled` флаг!

**Рекомендация:**
```lua
-- ❌ НЕБЕЗОПАСНО
if gui.pick_node(node, action.x, action.y) then
    -- может сработать даже если node disabled!
end

-- ✅ БЕЗОПАСНО
if gui.is_enabled(node) and gui.pick_node(node, action.x, action.y) then
    -- безопасно
end
```

**Приоритет:** 🟡 СРЕДНИЙ - предотвращение багов с input

---

### 3. Добавить комментарии о Z-диапазонах в заголовки файлов

**Рекомендация:** Документировать используемые Z-диапазоны в каждом компоненте:

```lua
-- inventory_v2.gui_script
-- Z-ranges:
--   0.40: backdrop (dimming)
--   0.50-0.52: modal window
--   0.55-0.57: dynamic content (slots, buttons)
```

Это поможет избежать конфликтов Z-значений при добавлении новых элементов.

**Приоритет:** 🟢 НИЗКИЙ - улучшение maintainability

---

### 4. Рассмотреть использование Template Nodes

**Текущая ситуация:** Много повторяющихся паттернов (слоты, кнопки, borders).

**Рекомендация:** Создать переиспользуемые template nodes для:
- Inventory slots
- Choice buttons
- Modal windows
- Border decorations

**Преимущества:**
- Меньше дублирования кода
- Легче поддерживать единый стиль
- Проще вносить изменения

**Приоритет:** 🟢 НИЗКИЙ - улучшение архитектуры

---

## 📊 СТАТИСТИКА

### Проанализированные файлы:
- ✅ 9 GUI компонентов (.gui)
- ✅ 9 GUI скриптов (.gui_script)
- ✅ 1 коллекция (main_v2.collection)

### Найдено проблем:
- 🔴 Критических: 1 (gui.set_parent)
- 🟡 Средних: 2 (отсутствие текстур, отсутствие слоёв)
- 🟢 Низких: 0

### Правильные практики:
- ✅ acquire_input_focus: 9/9
- ✅ Абсолютные координаты для динамических нод: 2/2 (где используется)
- ✅ Правильный inherit_alpha: проверено
- ✅ Правильный порядок компонентов: да
- ✅ Правильные Z-значения: да

---

## 🎯 ПЛАН ДЕЙСТВИЙ (по приоритету)

### Немедленно (🔴 Высокий приоритет):
1. **Исправить `gui.set_parent()` в `main_menu_v2.gui_script`**
   - Файл: `main_menu_v2.gui_script:92`
   - Функция: `make_skyline_layer()`
   - Заменить на абсолютные координаты

### В ближайшее время (🟡 Средний приоритет):
2. **Добавить текстуры ко всем box нодам**
   - Создать white_1x1 в v2.atlas
   - Назначить всем box нодам без текстур
   - Файлы: inventory_v2.gui, choice_v2.gui, dialogue_v2.gui, и др.

3. **Внедрить систему слоёв (Layers)**
   - Начать с inventory_v2.gui (самый сложный)
   - Создать слои: backgrounds, borders, text, icons
   - Назначить слои всем нодам
   - Измерить улучшение производительности

4. **Добавить проверки `gui.is_enabled()` перед `gui.pick_node()`**
   - Проверить все GUI скрипты
   - Добавить проверки где необходимо

### Долгосрочно (🟢 Низкий приоритет):
5. **Добавить GUI Layouts для адаптивности**
6. **Создать Template Nodes для переиспользования**
7. **Добавить документацию Z-диапазонов**

---

## 📝 ЗАКЛЮЧЕНИЕ

**Общая оценка:** 7/10

**Сильные стороны:**
- Отличное понимание проблем с динамическими нодами (кроме одного случая)
- Правильное использование alpha inheritance
- Правильная структура компонентов и Z-значений
- Все скрипты правильно получают input focus

**Области для улучшения:**
- Один критический баг с `gui.set_parent()` требует немедленного исправления
- Отсутствие текстур на box нодах снижает производительность
- Отсутствие слоёв значительно увеличивает количество draw calls
- Нет адаптивности под разные разрешения

**Вывод:**
Код в целом качественный и следует большинству best practices. Основные проблемы связаны с оптимизацией производительности рендеринга, а не с функциональностью. После исправления критического бага и внедрения оптимизаций (текстуры + слои) производительность GUI может улучшиться на 30-50%.
