# Дополнения к defold-gui скиллу из официальной документации Defold

**Дата:** 2026-04-20  
**Источник:** https://defold.com/manuals/

---

## 🎯 Ключевые практики из официальной документации

### 1. GUI Layouts - Адаптация к разным экранам

**Что это:**
Defold поддерживает автоматическую адаптацию GUI к разным ориентациям и разрешениям через Display Profiles и Layouts.

**Как использовать в AVOS:**

#### Display Profiles (game.project)
```ini
[display]
width = 1280
height = 720
display_profiles = /builtins/render/default.display_profiles
dynamic_orientation = 0  # Для десктопа оставить 0
```

**Создание кастомных профилей:**
1. Создать файл `.display_profiles`
2. Добавить профили для разных разрешений:
   - Landscape: 1280×720
   - Portrait: 720×1280 (если нужно)
   - Tablet: 1024×768
3. Указать Device Models (для iOS/Android)

#### GUI Layouts в .gui файлах

**Добавление layout:**
1. Right-click "Layouts" → Add → Layout → "My Landscape"
2. Редактировать ноды для этого layout
3. Overridden properties помечаются синим

**Layout change messages:**
```lua
function on_message(self, message_id, message, sender)
    if message_id == hash("layout_changed") then
        print("New layout:", message.id)
        if message.id == hash("Portrait") then
            -- Адаптировать логику под портрет
        end
    end
end
```

**Manual layout selection:**
```lua
-- Отключить Auto Layout Selection в Display Profiles
-- Затем управлять вручную:
function init(self)
    local ok = gui.set_layout("Portrait")
    if not ok then
        print("Layout not found")
    end
end

-- Получить список доступных layouts:
local layouts = gui.get_layouts()
for id, size in pairs(layouts) do
    print(id, size.x, size.y)
end
```

**Рекомендация для AVOS:**
- Создать layouts для 1280×720 (основной) и 1920×1080 (Full HD)
- Использовать Adjust Mode для адаптации элементов

---

### 2. Adjust Mode - Адаптация нод к растяжению экрана

**Три режима:**

#### Fit (рекомендуется для большинства элементов)
- Масштабирует контент так, чтобы он помещался в растянутый bounding box
- Сохраняет aspect ratio
- **Использовать для:** портретов, иконок, кнопок

#### Zoom
- Масштабирует контент так, чтобы он полностью покрывал bounding box
- Сохраняет aspect ratio, но может обрезать края
- **Использовать для:** фонов, которые должны заполнить экран

#### Stretch
- Растягивает контент по всему bounding box
- НЕ сохраняет aspect ratio
- **Использовать для:** полос, линий, простых фонов

**Пример из AVOS:**
```lua
-- В .gui файле:
-- scene_bg (фон) → Adjust Mode: Zoom (заполнить экран)
-- portrait_bg (портрет) → Adjust Mode: Fit (сохранить пропорции)
-- hud_top_bg (полоса) → Adjust Mode: Stretch (растянуть по ширине)
```

---

### 3. Anchors - Позиционирование относительно краёв

**X Anchor:**
- `None` - позиция от центра родителя
- `Left` - привязка к левому краю
- `Right` - привязка к правому краю

**Y Anchor:**
- `None` - позиция от центра родителя
- `Top` - привязка к верхнему краю
- `Bottom` - привязка к нижнему краю

**Комбинации для AVOS:**
```
HUD элементы (BAG/PHN):
- X Anchor: Right
- Y Anchor: Top
- Pivot: East
→ Всегда в правом верхнем углу

Навигационные кнопки:
- Left button: X Anchor: Left, Y Anchor: None, Pivot: West
- Right button: X Anchor: Right, Y Anchor: None, Pivot: East
- Top button: X Anchor: None, Y Anchor: Top, Pivot: North
- Bottom button: X Anchor: None, Y Anchor: Bottom, Pivot: South
→ Всегда по периметру экрана

Центральная модалка:
- X Anchor: None
- Y Anchor: None
- Pivot: Center
→ Всегда в центре
```

---

### 4. Layers и Draw Calls - Оптимизация рендеринга

**Проблема:**
Смешивание разных типов нод ломает батчинг:
```
button-1 (box)      → draw call 1
button-text-1 (text) → draw call 2
button-2 (box)      → draw call 3
button-text-2 (text) → draw call 4
button-3 (box)      → draw call 5
button-text-3 (text) → draw call 6
= 6 draw calls!
```

**Решение через Layers:**
```
Layer "graphics":
  button-1 (box)
  button-2 (box)
  button-3 (box)
→ draw call 1

Layer "text":
  button-text-1 (text)
  button-text-2 (text)
  button-text-3 (text)
→ draw call 2

= 2 draw calls!
```

**Правила батчинга:**
Ноды батчатся если:
- ✅ Одинаковый тип (box/text/pie)
- ✅ Один atlas/tile source
- ✅ Один blend mode
- ✅ Один font (для текста)

Батч ломается если:
- ❌ Разные типы нод
- ❌ Разные атласы
- ❌ Разные blend modes
- ❌ Clipping nodes
- ❌ Stencil scopes

**Рекомендация для AVOS:**
```
Создать layers:
- "backgrounds" (z: 0.06-0.10) - фоны
- "content" (z: 0.15-0.40) - основной контент
- "ui_graphics" (z: 0.50-0.55) - UI box ноды
- "ui_text" (z: 0.56-0.60) - UI текст
- "overlays" (z: 0.65-0.70) - модалки
- "effects" (z: 0.75-0.80) - эффекты
```

---

### 5. Runtime Manipulation - Динамическое изменение ресурсов

**Fonts:**
```lua
go.property("mybigfont", resource.font("/assets/mybig.font"))

function init(self)
    -- Получить текущий шрифт
    local current = go.get("#gui", "fonts", { key = "default" })
    
    -- Заменить шрифт
    go.set("#gui", "fonts", self.mybigfont, { key = "default" })
end
```

**Materials:**
```lua
go.property("myeffect", resource.material("/assets/myeffect.material"))

function init(self)
    -- Заменить материал
    go.set("#gui", "materials", self.myeffect, { key = "effect" })
end
```

**Textures (Atlases):**
```lua
go.property("mytheme", resource.atlas("/assets/mytheme.atlas"))

function init(self)
    -- Заменить атлас
    go.set("#gui", "textures", self.mytheme, { key = "theme" })
end
```

**Применение в AVOS:**
- Динамическая смена тем (light/dark)
- Локализация шрифтов (кириллица/латиница)
- Сезонные ресурсы (новогодняя тема)

---

### 6. Max Nodes - Лимит нод

**По умолчанию:** 512 нод на GUI компонент

**Как увеличить:**
В .gui файле (Properties → Max Nodes):
```
max_nodes: 1024  # Или больше если нужно
```

**Подсчёт нод в AVOS:**
- Статические ноды (в .gui файле)
- Динамические ноды (создаваемые через `gui.new_box_node()`)
- Дочерние ноды (считаются отдельно)

**Пример:**
```
inventory_v2.gui:
- 12 слотов × 4 ноды (bg, border, icon, label) = 48
- 5 verb кнопок × 3 ноды (bg, border, label) = 15
- Статические элементы (backdrop, modal, details) = ~30
= ~93 ноды (в пределах 512)
```

**Рекомендация:**
- Если компонент создаёт много динамических нод → увеличить max_nodes
- Мониторить через `gui.get_node_count()` (если доступно)

---

### 7. Clipping - Обрезка контента

**Stencil Clipping:**
```lua
-- В .gui файле:
-- Parent node:
--   Clipping Mode: Stencil
--   Clipping Visible: true/false
--   Clipping Inverted: false

-- Child nodes будут обрезаны по границам parent
```

**Применение в AVOS:**
- Scrollable списки (SMS, заметки в телефоне)
- Overflow текста в details панели
- Маски для эффектов

**Важно:**
- Clipping nodes ломают батчинг
- Каждый stencil scope = отдельный draw call
- Использовать экономно

---

### 8. Blend Modes - Режимы смешивания

**Доступные режимы:**

#### Alpha (Normal)
- Стандартное альфа-смешивание
- **Использовать для:** всех обычных UI элементов

#### Add (Linear Dodge)
- Складывает цвета
- **Использовать для:** свечения, эффектов света

#### Multiply
- Умножает цвета (затемняет)
- **Использовать для:** теней, затемнения

#### Screen
- Инверсное умножение (осветляет)
- **Использовать для:** highlights, блики

**Применение в AVOS:**
```lua
-- Эффект свечения для accent элементов:
-- Blend Mode: Add
-- Color: cyan с низкой alpha

-- Затемнение backdrop:
-- Blend Mode: Multiply
-- Color: чёрный с alpha 0.5
```

---

### 9. Pivot Points - Точки вращения/масштабирования

**9 вариантов:**
```
North West    North    North East
   ┌────────────┬────────────┐
   │            │            │
West│          Center        │East
   │            │            │
   └────────────┴────────────┘
South West    South    South East
```

**Правила:**
- Pivot = "центр" ноды для rotation/scale
- Pivot влияет на alignment текста:
  - `West` = left-aligned
  - `Center` = center-aligned
  - `East` = right-aligned

**Комбинация Pivot + Anchor:**
```
Элемент в правом верхнем углу:
- Pivot: North East
- X Anchor: Right
- Y Anchor: Top
→ Угол элемента всегда в углу экрана

Элемент слева по центру:
- Pivot: West
- X Anchor: Left
- Y Anchor: None
→ Левый край элемента всегда у левого края экрана
```

---

### 10. Parent-Child Hierarchies - Иерархии

**Наследование:**
- Child наследует transform родителя (position, rotation, scale)
- Child рисуется ПОСЛЕ родителя
- Child с unset layer наследует layer родителя

**Важно:**
- Родитель рисуется ДО детей
- Используй layers чтобы изменить порядок отрисовки
- Не злоупотребляй иерархиями - они могут ломать батчинг

**Пример из AVOS:**
```
button_bg (box, layer: "ui_graphics")
  └─ button_label (text, layer: "ui_text")

Без layers: box → text → box → text (ломает батч)
С layers: все box → все text (батчится)
```

---

## 📋 Чеклист для добавления в defold-gui скилл

- [ ] Добавить раздел про GUI Layouts и Display Profiles
- [ ] Расширить объяснение Adjust Mode (Fit/Zoom/Stretch)
- [ ] Добавить примеры комбинаций Pivot + Anchor
- [ ] Добавить раздел про Layers и оптимизацию draw calls
- [ ] Добавить Runtime Manipulation (fonts/materials/textures)
- [ ] Добавить информацию про Max Nodes
- [ ] Добавить раздел про Clipping
- [ ] Добавить Blend Modes
- [ ] Добавить лучшие практики для Parent-Child иерархий

---

## 🎯 Ключевые инсайты для AVOS

### 1. Миграция на 1280×720 упростится с Layouts
Вместо ручного пересчёта всех координат, можно:
- Создать новый Layout "1280x720"
- Defold автоматически масштабирует ноды
- Вручную подправить только критичные элементы

### 2. Оптимизация через Layers критична
AVOS имеет много смешанных box/text нод. Правильное использование layers может:
- Сократить draw calls с ~50 до ~10
- Улучшить FPS на слабых устройствах
- Упростить отладку рендеринга

### 3. Anchors решают проблему адаптации
Текущая система с hardcoded координатами хрупкая. Anchors позволят:
- Автоматически адаптироваться к разным разрешениям
- Меньше кода для пересчёта позиций
- Проще поддержка мобильных устройств

### 4. Runtime resource swapping для тем
Возможность менять fonts/materials/textures на лету открывает:
- Тёмная/светлая тема
- Локализация (разные шрифты для языков)
- Сезонные события (новогодняя тема)

---

**Следующий шаг:** Обновить `.opencode/skills/defold-gui/SKILL.md` с этой информацией?
