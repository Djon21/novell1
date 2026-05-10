# Рекомендованная цветовая система AVOS_S

Документ фиксирует текущую цветовую систему интерфейса игры и рекомендации по её дальнейшему использованию.

Это **не обязательный стандарт**, а рабочий color guide. Его задача — сохранить единый визуальный язык между телефоном, картой, терминалом, HUD, диалогом, выбором, инвентарём, почтой, SMS и exploration-hotspot'ами. Отступать от схемы можно, если этого требует читаемость фона, драматургия сцены, состояние персонажа или отдельный UI-режим.

---

## 1. Главный принцип

Цвет в AVOS_S лучше использовать как **семантический сигнал**, а не как декор.

Игрок должен постепенно привыкнуть:

- cyan = системный интерфейс, навигация, рамки, координаты;
- magenta / hot pink = новое, важное, уведомление, loop/alert;
- amber = активная операция, действие, подтверждение, карта/терминал;
- violet = анализ, осмотр, архивность, secondary intel;
- green = валидная цель, успешное состояние, доступность;
- cream = основной читаемый текст;
- muted beige = вторичный текст;
- navy / purple = базовая тёмная поверхность.

---

## 2. Базовые цвета UI

Значения ниже даны в Defold/Lua-диапазоне `0.0..1.0`.

| Имя | Lua RGB | HEX approx | Где уже встречается | Роль |
|---|---:|---:|---|---|
| `UI_BG_DEEP` | `{ r=0.020, g=0.012, b=0.102 }` | `#05031A` | phone root, dialogue, choice, menu | самый глубокий фон |
| `UI_BG_PANEL` | `{ r=0.031, g=0.024, b=0.094 }` | `#080618` | HUD, dialogue panel, inventory, mail, sms | основной тёмный panel/bg |
| `UI_BG_CARD` | `{ r=0.047, g=0.039, b=0.141 }` | `#0C0A24` | inventory, menu dossier, mail head | карточки и вложенные панели |
| `UI_BG_TILE` | `{ r=0.078, g=0.071, b=0.204 }` | `#141234` | SMS/message rows, mail rows | интерактивные строки/тайлы |
| `UI_TEXT_MAIN` | `{ r=0.953, g=0.925, b=0.851 }` | `#F3ECD9` | заголовки, labels, body text | основной текст |
| `UI_TEXT_MUTED` | `{ r=0.788, g=0.753, b=0.659 }` | `#C9C0A8` | meta, time, secondary labels | вторичный текст |
| `UI_CYAN` | `{ r=0.490, g=0.976, b=1.000 }` | `#7DFAFF` | phone, map coords, HUD, dialogue borders, inventory | системный primary accent |
| `UI_CYAN_SOFT` | `{ r=0.282, g=0.961, b=1.000 }` | `#48F5FF` | map/work POI, camera/phone app | bright cyan variant |
| `UI_MAGENTA` | `{ r=1.000, g=0.239, b=0.498 }` | `#FF3D7F` | phone SMS/mail, badges, logo hot, mail tags | уведомление/новое/важное |
| `UI_ALERT_DARK` | `{ r=0.784, g=0.078, b=0.165 }` | `#C8142A` | dialogue loop mark, choice loop, badge dark | тревога/loop/критичное состояние |
| `UI_AMBER` | `{ r=1.000, g=0.702, b=0.278 }` | `#FFB347` | map cafe/view, terminal app, inventory qty/star | действие/операция/подтверждение |
| `UI_VIOLET` | `{ r=0.714, g=0.361, b=1.000 }` | `#B65CFF` | map home/archive | secondary intel / archive / inspect |
| `UI_PURPLE` | `{ r=0.478, g=0.361, b=1.000 }` | `#7A5CFF` | quests app | quest/secondary state |
| `UI_GREEN` | `{ r=0.412, g=0.961, b=0.529 }` | `#69F587` | map park | valid/safe/available target |

---

## 3. Семантическое назначение цветов

### Cyan / teal

Использовать для:

- системных рамок;
- координат;
- HUD eyebrow;
- navigation / route;
- generic active UI affordance;
- hotspot `NAV`.

Не использовать для: ошибок, критических сюжетных действий, предупреждений.

### Magenta / hot pink

Использовать для:

- уведомлений;
- новых сообщений;
- badges;
- важных pickup-событий;
- mail/SMS tags;
- hotspot `PICKUP`;
- редких story gates, если нужно привлечь внимание.

Не использовать как универсальный “красивый акцент” в каждой сцене: быстро станет шумом.

### Amber

Использовать для:

- активных операций;
- подтверждения;
- действий с объектом;
- терминальных/картографических состояний;
- hotspot `USE`;
- важной числовой/статусной информации.

### Violet / purple

Использовать для:

- осмотра;
- вторичной аналитической информации;
- архивных/домашних/quest-like состояний;
- hotspot `INSPECT`.

Violet лучше держать чуть менее агрессивным, чем cyan/magenta/amber, особенно на светлых фонах.

### Green

Использовать для:

- валидной цели;
- разрешённого состояния;
- успешного состояния;
- hotspot `ITEM_TARGET`, когда игрок держит предмет или выбирает verb `use/give/combine`.

---

## 4. Hotspot palette

Hotspot'ы используют цвет как код **игрового глагола**, а не конкретного предмета.

| Стиль | Смысл | Цветовая роль |
|---|---|---|
| `STYLE_NAV` | перейти / переместиться | cyan |
| `STYLE_INSPECT` | осмотреть / изучить | violet |
| `STYLE_PICKUP` | подобрать / получить | magenta |
| `STYLE_USE` | выполнить действие | amber |
| `STYLE_ITEM_TARGET` | цель для предмета | green |
| `STYLE_STORY` | важный сюжетный gate | hot magenta / alert |

Текущие рекомендуемые значения после теста на сценах квартиры:

```lua
local STYLE_NAV = {
    circle_color = { r = 0.020, g = 0.045, b = 0.105 },
    ring_color   = { r = 0.300, g = 0.950, b = 1.000 },
    icon_color   = { r = 0.680, g = 0.985, b = 1.000 },
    circle_alpha = 0.52,
    ring_alpha   = 0.66,
    icon_alpha   = 0.96,
    scale = 0.90,
}

local STYLE_INSPECT = {
    circle_color = { r = 0.055, g = 0.035, b = 0.135 },
    ring_color   = { r = 0.660, g = 0.360, b = 1.000 },
    icon_color   = { r = 0.880, g = 0.760, b = 1.000 },
    circle_alpha = 0.46,
    ring_alpha   = 0.56,
    icon_alpha   = 0.90,
    scale = 0.84,
}

local STYLE_PICKUP = {
    circle_color = { r = 0.120, g = 0.020, b = 0.080 },
    ring_color   = { r = 1.000, g = 0.200, b = 0.560 },
    icon_color   = { r = 1.000, g = 0.620, b = 0.820 },
    circle_alpha = 0.56,
    ring_alpha   = 0.72,
    icon_alpha   = 0.98,
    scale = 0.92,
}

local STYLE_USE = {
    circle_color = { r = 0.115, g = 0.065, b = 0.015 },
    ring_color   = { r = 1.000, g = 0.640, b = 0.180 },
    icon_color   = { r = 1.000, g = 0.820, b = 0.430 },
    circle_alpha = 0.56,
    ring_alpha   = 0.72,
    icon_alpha   = 0.98,
    scale = 0.92,
}

local STYLE_ITEM_TARGET = {
    circle_color = { r = 0.025, g = 0.100, b = 0.055 },
    ring_color   = { r = 0.410, g = 0.960, b = 0.530 },
    icon_color   = { r = 0.760, g = 1.000, b = 0.820 },
    circle_alpha = 0.56,
    ring_alpha   = 0.74,
    icon_alpha   = 0.98,
    scale = 0.94,
}

local STYLE_STORY = {
    circle_color = { r = 0.135, g = 0.018, b = 0.070 },
    ring_color   = { r = 1.000, g = 0.120, b = 0.470 },
    icon_color   = { r = 1.000, g = 0.520, b = 0.760 },
    circle_alpha = 0.62,
    ring_alpha   = 0.82,
    icon_alpha   = 1.00,
    scale = 0.96,
}
```

Практические правила:

- обычные `goto_scene` и обычные `leave_*` лучше держать в `STYLE_NAV`;
- `STYLE_STORY` не использовать для каждого выхода, иначе он читается как ошибка/тревога;
- `STYLE_INSPECT` должен быть мягче остальных, потому что таких hotspot'ов обычно больше;
- `PICKUP` не должен зависеть от предмета: телефон, кружка, пропуск, папка — всё `PICKUP`, если результатом является получение.

---

## 5. Текущие UI-области

### Телефон root

Использует:

- `UI_BG_DEEP`, `UI_BG_PANEL`, `UI_BG_CARD` для корпуса/экрана/плиток;
- `UI_TEXT_MAIN`, `UI_TEXT_MUTED` для времени, подписей, статуса;
- cyan/magenta/amber/violet как app accents.

Рекомендация: новые app tiles лучше брать из существующих accent tokens, а не придумывать новые насыщенные цвета.

### Карта

Карта уже работает как цветовая витрина POI:

- home/archive — violet;
- shop/bar — magenta;
- cafe/view — amber;
- work — cyan;
- park — green.

Рекомендация: если POI связан с hotspot-глаголом, не переносить POI-цвет напрямую в hotspot. В карте цвет обозначает **тип места**, в сцене hotspot-цвет обозначает **тип действия**.

### HUD

HUD опирается на:

- cream для scene labels;
- cyan для technical eyebrow;
- dark navy для buttons;
- magenta/dark red для badges;
- amber для phone icon.

Рекомендация: HUD должен оставаться более стабильным и менее разноцветным, чем карта/phone apps.

### Диалог и выборы

Диалог и выбор используют:

- cyan для рамок/активного UI;
- cream для текста;
- muted beige для сервисного текста;
- dark red/magenta для loop/мета-состояний;
- amber для caveat/важной подсказки.

Рекомендация: `UI_ALERT_DARK` лучше оставить для loop/metastate, а bright `UI_MAGENTA` — для уведомлений и pickup/new data.

### Инвентарь

Инвентарь использует:

- cyan для рамок, verbs и активных affordance;
- cream для названий и значений;
- amber для количества/итерации/операционного акцента;
- magenta для clue/loop-ish данных;
- dark card surfaces для verb buttons and details.

Рекомендация: `STYLE_ITEM_TARGET` green хорошо подходит именно как внешний exploration-сигнал, когда предмет из инвентаря можно применить в сцене. Внутри самого inventory UI green лучше использовать осторожно, чтобы не спорить с cyan verbs.

### SMS и Mail

SMS/Mail используют:

- cyan для рамок/скролла/active affordance;
- magenta для dot/tag/new;
- amber для pinned/starred;
- cream/muted для текстов;
- tile purple для rows.

Рекомендация: magenta в hotspot `PICKUP` хорошо поддерживает идею “новый объект/новые данные”, но magenta нельзя использовать для обычной навигации.

---

## 6. Рекомендации по альфам

В проекте много glow-like PNG и полупрозрачных панелей. Поэтому лучше держать alpha умеренной.

Для hotspot'ов после проверки на светлых сценах:

- `circle_alpha`: обычно `0.46..0.56`;
- `ring_alpha`: обычно `0.56..0.74`;
- `icon_alpha`: обычно `0.90..1.00`;
- `STYLE_STORY` может быть ярче, но использовать редко.

Для панелей:

- fullscreen/panel backdrop: `0.65..0.95`;
- borders: `0.15..0.50`, если их много;
- primary text: `0.90..1.00`;
- secondary text: `0.65..0.85`.

---

## 7. Когда можно отступать

Отступать от палитры нормально, если:

- фон сцены слишком светлый или слишком контрастный;
- конкретный hotspot теряется на фоне;
- сцена требует намеренного визуального диссонанса;
- режим UI отличается по fiction-смыслу: glitch, dream, false ending, corrupted phone, terminal breach;
- элемент должен быть deliberately unreadable/disabled.

Но лучше сначала менять `alpha/scale`, а не придумывать новый цвет.

---

## 8. Чеклист для нового UI-элемента

Перед добавлением нового цвета:

- [ ] Можно ли использовать один из существующих tokens?
- [ ] Цвет кодирует состояние/действие, а не просто украшает?
- [ ] Не конфликтует ли он с magenta как уведомлением/важным сигналом?
- [ ] Не конфликтует ли он с amber как действием/операцией?
- [ ] Проверен ли элемент на светлой и тёмной сцене?
- [ ] Сохраняется ли читаемость текста при alpha ниже 1.0?

