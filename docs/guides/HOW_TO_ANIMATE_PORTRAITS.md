# Анимированные портреты (layered)

Расширение системы портретов: персонажи **моргают в простое** и **шевелят ртом** во время typewriter. Подход — классические visual novel layered sprites: статичный base + overlay-ноды с прозрачными feature-PNG поверх (глаза + рот, независимо).

Для статичных портретов (один кадр без анимации) см. [`HOW_TO_ADD_PORTRAITS.md`](HOW_TO_ADD_PORTRAITS.md).

---

## Архитектура

### GUI-структура

В `main/gui/components_v2/dialogue_v2.gui` под stencil-родителем `portrait_bg_fon`:

```
portrait_bg_fon (stencil clip, 220×290)
├── portrait_bg              — base-портрет (статика)
├── portrait_overlay         — РОТ (mila_talk loop)
└── portrait_overlay_eyes    — ГЛАЗА (mila_blink по таймеру)
```

Два overlay-нода чтобы blink и talk играли **независимо одновременно**. Раньше делили один нод и перебивали друг друга.

### Tight-кадры в атласе

Старая версия использовала overlay'и 512×512 (как base) с прозрачным фоном вокруг feature-зоны. Это раздувало атлас — большая часть кадра была пустотой.

Сейчас overlay-PNG обрезаны до **bbox** feature-зоны:
- Глаза: ~142×50 пикс
- Рот: ~74×58 пикс

В `dialogue_v2.gui_script` есть таблица `OVERLAY_GEOMETRY`:

```lua
local OVERLAY_GEOMETRY = {
    mila_blink = { x = 208, y = 157, w = 142, h = 50 },
    mila_talk  = { x = 231, y = 234, w = 74,  h = 58 },
}
```

При старте анимации `apply_overlay_geometry()` ресайзит нод и позиционирует его в правильном месте внутри `portrait_bg` (через scale 290/512).

### Анимации в атласе

В `main/images/portraits/<char>/<char>.atlas`:

| Animation ID | Кадры | FPS | Playback |
|---|---|---|---|
| `<char>_idle` | base | 1 | `PLAYBACK_NONE` |
| `<char>_blink` | blink_1, blink_2 | 8 | `PLAYBACK_ONCE_PINGPONG` |
| `<char>_talk` | mouth_1, mouth_2, mouth_3 | 8 | `PLAYBACK_LOOP_PINGPONG` |

PINGPONG для blink даёт «закрыл → открыл» из двух кадров (играет 1→2→1→complete). Для talk — луп с плавным движением рта (1→2→3→2→1→2→3...).

### Logic в скрипте

`dialogue_v2.gui_script`:
- `render()` устанавливает `current_char_meta`, играет idle-кадр на portrait_bg, стартует talk-loop, шедулит blink-таймер
- `start_talk_anim` → играет talk на `portrait_overlay`
- `schedule_blink` → таймер 2–5.5с, играет blink на `portrait_overlay_eyes`, в complete-callback'е шедулит следующий blink
- `portrait_anim_token` — int, защита от stale completion-callback'ов при смене спикера (token-pattern)

---

## Файловая структура

```
main/images/portraits/<char>/
├── <char>.atlas
├── <char>_base.png         (512×512, открытые глаза + закрытый рот)
├── <char>_blink_1.png      (~142×50, средняя фаза моргания)
├── <char>_blink_2.png      (~142×50, полностью закрытые)
├── <char>_mouth_1.png      (~74×58, рот закрыт)
├── <char>_mouth_2.png      (~74×58, чуть открыт)
└── <char>_mouth_3.png      (~74×58, открыт)
```

Веса (пример Милы):
- `mila_base.png` ~430 KB
- `mila_blink_*.png` ~10 KB каждый
- `mila_mouth_*.png` ~6 KB каждый

Атлас Милы упаковывается в страницу 1024×512 (base + мелочи рядом). При `extrude_borders: 0` влезает плотно.

---

## Пайплайн от нуля до atlas

### Шаг 0 — Сгенерировать исходники

**Лучший путь**: [LivePortrait](https://github.com/KwaiVGI/LivePortrait) + ComfyUI-AdvancedLivePortrait. Берёшь один base-портрет, крутишь слайдеры моргания / формы рта (`aaa/eee/ooo`) / улыбки. Голова не движется, кадры идеально align'нуты. Скачиваешь нужные кадры как PNG.

**Альтернатива**: нейронка в режиме image-edit (Nano Banana / GPT-image / Kling). Сгенерируй сет:
- `1.png` — открытые глаза, рот закрыт (это будет base)
- `2.png` — глаза полу-закрыты
- `3.png` — глаза закрыты с ресницами
- (для рта) ещё 2-3 варианта с разными формами рта

Промпт обязательно с magenta-фоном `#FF00FF` чтобы chroma-key'ить:

> Same character, same pose, same lighting, same outfit. **Solid bright magenta background (#FF00FF)**. Only the specified feature changes — eyes / mouth.

Положи в `tools/port_p/raw1/`.

### Шаг 1 — Resize до 512×512

Все исходники должны быть одного размера. Скрипт ресайзит на месте:

```python
from PIL import Image
for n in [1,2,3]:
    p = f'tools/port_p/raw1/{n}.png'
    Image.open(p).resize((512,512), Image.LANCZOS).save(p, 'PNG', optimize=True)
```

Можно засунуть в одноразовый python -c.

### Шаг 2 — Убрать фон (chroma key + despill)

Нейронка генерит magenta слегка разных оттенков каждый раз — нельзя hardcode'ить `#FF00FF`. Сэмплируем реальный цвет из угла:

```python
import numpy as np
import sys
sys.path.insert(0, 'tools')
from extract_portrait_overlays import chroma_key, despill_edges
from PIL import Image

for n in [1,2,3]:
    src = f'tools/port_p/raw1/{n}.png'
    dst = f'tools/port_p/raw1/{n}_nobg.png'
    arr = np.array(Image.open(src).convert('RGB'))
    pts = [(0,0),(0,256),(0,511),(256,0),(256,511),(511,0),(511,511)]
    bg_rgb = tuple(int(c) for c in np.median([arr[y,x] for y,x in pts], axis=0))
    out = chroma_key(Image.open(src), bg_rgb, tolerance=60, feather=1.5)
    out = despill_edges(out, bg_rgb, strength=0.7)
    out.save(dst, 'PNG', optimize=True)
```

Сохраняется отдельным файлом `<N>_nobg.png` — исходник не трогается.

### Шаг 3 — Разметить feature-зоны (интерактивно)

```bash
python tools/mark_eyes.py tools/port_p/raw1/2_nobg.png
```

Откроется окно. Управление:
| Клавиша | Действие |
|---|---|
| ЛКМ-drag | Нарисовать |
| **r** | Режим прямоугольника |
| **e** | Режим эллипса |
| **c** | Режим круга (зажатый аспект) |
| ПКМ | Удалить фигуру под курсором |
| Backspace / Del | Удалить последнюю |
| **s** | Сохранить в `<image>.rects.json` |
| q / Esc | Выход |

Обведи **каждый глаз отдельным прямоугольником** (две фигуры, не одну общую — иначе захватишь волосы/брови между ними).

Для рта — аналогично новый запуск с другой картинкой (тот же скрипт):
```bash
python tools/mark_eyes.py tools/port_p/raw1/3_nobg.png
```

Обведи рот одной фигурой (эллипс лучше всего).

Координаты сохраняются в `2_nobg.rects.json` / `3_nobg.rects.json`.

### Шаг 4 — Вырезать feature-области

```bash
# Глаза из вариантов 2 и 3 (закрытые/полузакрытые)
python tools/crop_rects.py tools/port_p/raw1/2_nobg.png --prefix eye
python tools/crop_rects.py tools/port_p/raw1/3_nobg.png --prefix eye \
    --rects tools/port_p/raw1/2_nobg.rects.json

# Рот из 3 вариантов (одна разметка из 1.rects.json)
python tools/crop_rects.py tools/port_p/rawl/2.png --prefix mouth \
    --rects tools/port_p/rawl/1.rects.json
python tools/crop_rects.py tools/port_p/rawl/3.png --prefix mouth \
    --rects tools/port_p/rawl/1.rects.json
python tools/crop_rects.py tools/port_p/rawl/4.png --prefix mouth \
    --rects tools/port_p/rawl/1.rects.json
```

Создаст файлы вида `2_nobg_eye_1.png`, `2_nobg_eye_2.png`, `3_mouth_1.png` и т.д.

Опции:
- `--rects PATH` — использовать одну разметку для нескольких картинок с тем же ракурсом
- `--feather N` — мягкие края у формы (для ellipse/circle обычно 1.5–3)

### Шаг 5 — Собрать tight-overlay'и

```bash
# Глаза: union bbox обоих rect'ов → один маленький PNG + offset.json
python tools/compose_overlay.py tools/port_p/raw1/2_nobg.png --prefix eye --tight
python tools/compose_overlay.py tools/port_p/raw1/3_nobg.png --prefix eye --tight \
    --rects tools/port_p/raw1/2_nobg.rects.json

# Рот: одна rect → bbox = тот же rect
python tools/compose_overlay.py tools/port_p/rawl/2.png --prefix mouth --tight \
    --rects tools/port_p/rawl/1.rects.json
python tools/compose_overlay.py tools/port_p/rawl/3.png --prefix mouth --tight \
    --rects tools/port_p/rawl/1.rects.json
python tools/compose_overlay.py tools/port_p/rawl/4.png --prefix mouth --tight \
    --rects tools/port_p/rawl/1.rects.json
```

На выходе:
- `2_nobg_eye_overlay.png` (например 142×50, ~10 KB) + `.offset.json` с bbox-координатами
- `3_nobg_eye_overlay.png`
- `2_mouth_overlay.png`, `3_mouth_overlay.png`, `4_mouth_overlay.png`

`offset.json` нужен чтобы знать **куда в 512×512 base-портрете эту мелочь класть**. Используем при ручной правке `OVERLAY_GEOMETRY` в скрипте.

### Шаг 6 — Положить в `portraits/<char>/`

```bash
cp <base> main/images/portraits/<char>/<char>_base.png
cp <eye_overlay_1> main/images/portraits/<char>/<char>_blink_1.png
cp <eye_overlay_2> main/images/portraits/<char>/<char>_blink_2.png
cp <mouth_overlay_1> main/images/portraits/<char>/<char>_mouth_1.png
cp <mouth_overlay_2> main/images/portraits/<char>/<char>_mouth_2.png
cp <mouth_overlay_3> main/images/portraits/<char>/<char>_mouth_3.png
```

### Шаг 7 — Создать атлас `<char>.atlas`

```
main/images/portraits/<char>/<char>.atlas
```

Содержимое (используй mila.atlas как образец):

```
images {
  image: "/main/images/portraits/<char>/<char>_base.png"
}
images {
  image: "/main/images/portraits/<char>/<char>_blink_1.png"
}
images {
  image: "/main/images/portraits/<char>/<char>_blink_2.png"
}
images {
  image: "/main/images/portraits/<char>/<char>_mouth_1.png"
}
images {
  image: "/main/images/portraits/<char>/<char>_mouth_2.png"
}
images {
  image: "/main/images/portraits/<char>/<char>_mouth_3.png"
}
animations {
  id: "<char>_idle"
  images { image: "/main/images/portraits/<char>/<char>_base.png" }
  playback: PLAYBACK_NONE
  fps: 1
}
animations {
  id: "<char>_blink"
  images { image: "/main/images/portraits/<char>/<char>_blink_1.png" }
  images { image: "/main/images/portraits/<char>/<char>_blink_2.png" }
  playback: PLAYBACK_ONCE_PINGPONG
  fps: 8
}
animations {
  id: "<char>_talk"
  images { image: "/main/images/portraits/<char>/<char>_mouth_1.png" }
  images { image: "/main/images/portraits/<char>/<char>_mouth_2.png" }
  images { image: "/main/images/portraits/<char>/<char>_mouth_3.png" }
  playback: PLAYBACK_LOOP_PINGPONG
  fps: 8
}
extrude_borders: 2
```

`extrude_borders: 2` обязательно для атласов с анимациями — иначе соседние
кадры в текстуре будут «протекать» в края overlay'я и появится видимая
полоса при проигрывании.

### Шаг 8 — Зарегистрировать texture в `dialogue_v2.gui`

В секции `textures {}`:

```
textures {
  name: "<char>"
  texture: "/main/images/portraits/<char>/<char>.atlas"
}
```

### Шаг 9 — Добавить запись в `CHARS`

В `dialogue_v2.gui_script` рядом с `mila` блоком:

```lua
["<имя_кириллицей>"] = {
    color = vmath.vector4(<R>, <G>, <B>, 1.0),
    icon = string.char(0xEE, 0x9F, 0xBB),
    atlas = "<char>",
    portrait = "<char>_idle",
    portrait_idle  = "<char>_idle",
    portrait_blink = "<char>_blink",
    portrait_talk  = "<char>_talk",
},
```

### Шаг 10 — Добавить `OVERLAY_GEOMETRY`

В `dialogue_v2.gui_script` найди таблицу `OVERLAY_GEOMETRY` и добавь bbox'ы из `.offset.json`:

```lua
local OVERLAY_GEOMETRY = {
    mila_blink = { x = 208, y = 157, w = 142, h = 50 },
    mila_talk  = { x = 231, y = 234, w = 74,  h = 58 },
    -- новый персонаж:
    <char>_blink = { x = <из eye_overlay.offset.json>, y = ..., w = ..., h = ... },
    <char>_talk  = { x = <из mouth_overlay.offset.json>, y = ..., w = ..., h = ... },
}
```

Значения берутся из `<file>.offset.json` который выдал `compose_overlay.py --tight`.

### Шаг 11 — Сборка и проверка

В Defold Editor **Ctrl+B** → запуск → диалог с новым персонажем. Должно:
- Видишь base-портрет
- Раз в 2–5 секунд глаза моргают (blink-анимация на `portrait_overlay_eyes`)
- Во время typewriter рот шевелится (talk-loop на `portrait_overlay`)
- При смене спикера всё сбрасывается, новый персонаж получает свои анимации

---

## Параметры тонкой настройки

В `dialogue_v2.gui_script`:

```lua
local BLINK_MIN_DELAY = 2.0   -- мин секунд между морганиями
local BLINK_MAX_DELAY = 5.5   -- макс
```

В атласе:
- `_blink` FPS=8 → blink цикл ~0.4с
- `_talk` FPS=8 + 3 кадра PINGPONG → ~0.7с на цикл рта

---

## Размер атласа и `extrude_borders`

Defold пакует спрайты в power-of-2 текстуру. Размер зависит от:
- Самого большого спрайта (если base 512×512, страница ≥ 512×512)
- `extrude_borders: N` — добавляет N пикселей бордюра вокруг каждого спрайта в текстуре → 512+2*2 = 516, что округляется до 1024.

### Правило по `extrude_borders`

| Тип атласа | Значение | Почему |
|---|---|---|
| Один статичный спрайт (narrator) | `0` | Не масштабируется, край не bleed'ит, экономим место (512×512 вместо 1024×1024). |
| Атлас с анимациями (mila, artem) | `2` | **Обязательно**. Без бордюра при проигрывании flipbook'а соседние кадры в текстуре «протекают» друг в друга — видна резкая полоса/артефакт по краю overlay'я во время анимации. |

Если ставить `0` на анимированный атлас и видишь полосы во время анимации — это оно. Поднимай до `2`.

### Текущие размеры

- `narrator.atlas`: 1 sprite 512×512, extrude 0 → **512×512** ✓
- `artem.atlas`: 4 sprites (base + 3 blink), extrude 2 → **1024×1024**
- `mila.atlas`: 6 sprites (base + 2 blink + 3 mouth), extrude 2 → **1024×1024**

Для уменьшения mila/artem можно:
1. Уменьшить base до 256×256 (в GUI отображается в 290×290, разница минимальна, но качество слегка просядет)
2. Разделить атлас на base + anim (отдельные texture binding'и, усложняет код — нужно только если упрётся в бюджет)

---

## Test mode notes

В коде есть две метки `TEST MODE` / `TODO`:

1. `typewriter_finish` — закомментирован `stop_talk_anim(self)`. Когда раскоментируешь, рот остановится по окончании печати реплики (нормальное поведение).
2. `render()` — есть явный вызов `start_talk_anim(self)` + `schedule_blink(self)` для теста. Когда уберёшь — talk будет стартовать только из `typewriter_start`, blink — только из `stop_talk_anim`.

Сейчас оба активны для проверки анимаций. Перед релизом раскомментируй обратно.

---

## Подводные камни

| Симптом | Причина | Решение |
|---|---|---|
| Overlay не на месте | Координаты `OVERLAY_GEOMETRY` не совпадают с реальной разметкой | Проверь `.offset.json` от compose_overlay.py — там точные числа |
| Атлас 1024×1024 для одного 512×512 PNG | `extrude_borders: 2` пушит спрайт до 516×516 | Поставь `extrude_borders: 0` (только для статичных атласов!) |
| Резкая полоса по краю overlay'я во время анимации | `extrude_borders: 0` на анимированном атласе → соседние кадры в текстуре протекают | Поставь `extrude_borders: 2` для атласов с animations |
| Только один глаз моргает (винк) | В variant'е нейронка асимметрично нарисовала глаза | Перегенерить вариант или подправить разметку, чтобы оба rect'а попадали в глаза точно |
| Magenta-кайма по контуру персонажа | `chroma_key` уловил только центр цвета, края (антиалиас) остались | `despill_edges` уже применён в скрипте — это лечит. Если всё равно есть, увеличь `bg_tolerance` |
| Прядь волос закрывает половину глаза | В исходнике AI нарисовал волосы поверх глаза | Перегенерить variant без пряди (попросить нейронку убрать), или жить с этим |
| Blink перебивает talk | Раньше делили один overlay-нод | Должно быть исправлено: blink на `portrait_overlay_eyes`, talk на `portrait_overlay`, разные ноды |
| `[WARN] overlay anim not found` | Animation ID в `OVERLAY_NODE_FOR_ANIM` не совпадает с атласом | Проверь точное написание |

---

## Чеклист добавления анимированного персонажа

- [ ] Исходники в `tools/port_p/<folder>/` сгенерированы и приведены к 512×512
- [ ] `_nobg.png` версии созданы (chroma key + despill)
- [ ] `mark_eyes.py` использован, координаты сохранены в `.rects.json`
- [ ] `crop_rects.py` нарезал features
- [ ] `compose_overlay.py --tight` собрал tight-overlay'и
- [ ] PNG'и скопированы в `main/images/portraits/<char>/`
- [ ] `<char>.atlas` создан с idle / blink / talk animations
- [ ] `dialogue_v2.gui` имеет texture-binding `<char>`
- [ ] `dialogue_v2.gui_script` CHARS содержит запись с `atlas`, `portrait_idle`, `portrait_blink`, `portrait_talk`
- [ ] `OVERLAY_GEOMETRY` содержит bbox'ы для `<char>_blink` и `<char>_talk`
- [ ] Defold rebuild + проверка в игре

---

## Инструменты в `tools/`

| Скрипт | Назначение |
|---|---|
| `mark_eyes.py` | Интерактивная разметка прямоугольников/эллипсов/кругов на картинке. Сохраняет `.rects.json`. |
| `crop_rects.py` | Вырезает фигуры по разметке. Опциональный feather, поддерживает формы. |
| `compose_overlay.py` | Собирает crop'ы в overlay. Флаг `--tight` обрезает до bbox + сохраняет offset. |
| `extract_portrait_overlays.py` | Старый all-in-one скрипт (chroma key + alignment + diff). Сейчас используется только для chroma_key и despill_edges как библиотека. Полный pipeline через него — fallback на случай если нет времени на ручную разметку. |

Каждый принимает `--help`.
