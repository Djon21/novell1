# Инструкция по графическим ресурсам

## 1. Фоны (fullscreen backgrounds)

### Где лежат

- исходные файлы: `main/images/bg_*.jpg`
- по одному dedicated atlas на каждый фон в `main/images/backgrounds/`
- регистрация `go.property` в `main/gui/ui_manager_v2.script` и запись в `DEDICATED_BG_ATLAS_PROPS`
- общий runtime animation id внутри dedicated atlas: `scene_bg`

### Правила

- формат: `JPG`, желательно `1920x1080`
- имена фонов: `bg_name.jpg`
- atlas: `main/images/backgrounds/bg_name.atlas` с `rename_patterns: "bg_name=scene_bg"`
- внешнее имя `bg_name` должно совпадать в Ink, `scenes.lua` и регистрации
- подробности и архитектура — `docs/guides/HOW_TO_ADD_SCENES.md`

## 2. Hotspot sprites

### Где лежат

- файлы: `main/images/hotspot_*.png`
- atlas: `main/images/hotspots.atlas`
- texture slot в `hotspots_v2.gui`: `hotspots`

Изменять руками этот atlas нужно редко — `hotspot_circle`/`hotspot_ring`/`hotspot_dot`
покрывают весь визуальный стек.

## 3. Scene objects (overlay-спрайты на фоне)

### Где лежат

- файлы: `main/images/<name>.png`
- atlas: `main/images/scene_objects.atlas`
- texture slot в `hotspots_v2.gui`: `scene_objects`
- в `scenes.lua` ссылка: `image = "<name>"` внутри `objects = { ... }`

### Правила

- формат: `PNG`, прозрачный фон
- имя без префикса `bg_`
- размеры — оригинальные пиксели (масштабирование задаётся `size = { w, h }` в сцене)

## 4. Диалоговые портреты (бюст в окне диалога)

### Где лежат

- per-character папка: `main/images/portraits/<name>/`
- per-character atlas: `main/images/portraits/<name>/<name>.atlas`
- texture binding в `dialogue_v2.gui` (по одному на персонажа: `mila`, `artem`, `narrator`)
- runtime-логика: `main/gui/components_v2/dialogue_v2.gui_script`

### Правила

- формат: `PNG`, прозрачный фон
- размер base'а `512×512`; overlay'и (blink/talk) — tight-bbox (~150×50 для глаз, ~80×60 для рта)
- atlas animations: `<char>_idle`, `<char>_blink`, `<char>_talk`
- запись в `CHARS` (`dialogue_v2.gui_script`) с полями `atlas`, `portrait_idle/blink/talk`
- `extrude_borders: 2` обязательно для атласов с animations (иначе видны полосы между кадрами)

Подробно: `HOW_TO_ADD_PORTRAITS.md`, `HOW_TO_ANIMATE_PORTRAITS.md`.

## 4b. Сценические персонажи (full-figure на фоне)

### Где лежат

- per-character папка: `main/images/characters/<name>/`
- per-character atlas: `main/images/characters/<name>/<name>.atlas`
- texture binding в `dialogue_v2.gui` с префиксом `char_` (`char_mila`, `char_artem`)
- config: `main/scripts/scene_characters.lua` (SCENE_GROUPS + SCENES таблицы)

### Правила

- формат: `PNG`, прозрачный фон (вырезать через `tools/remove_background.py`)
- одна поза = один PNG (`idle.png`, `sitting.png`, etc.), переиспользуется в разных сценах с разной позицией/размером
- координаты `x, y, w, h` в SCENES — game coords `1280×720` с pivot top-left
- опциональные поля: `action = { type="ink_knot", knot=... }`, `clickable_when(gs)` для hover/click

Подробно: `HOW_TO_ADD_SCENE_CHARACTERS.md`.

## 5. Legacy ресурсы (НЕ для новых ассетов)

- `archive/legacy_runtime/main/images/characters.atlas` — архивный portrait atlas старого GUI
- `archive/legacy_runtime/main/images/backgrounds.atlas` — archive-only atlas старого v1 GUI.
Старая схема смены фонов отключена; этот atlas не используется v2 и не считается fallback. Сейчас содержит только то, что осталось от legacy сцены (`bg_bedroom_01`, `mobile`,
  `hotspot_*`). Новые ресурсы сюда не добавляем — `dialogue_v2`, `hotspots_v2`
  и `main_menu_v2` его не используют.

## 6. Координатная система для scenes

- hotspot'ы и scene objects в `scenes.lua` описываются в системе `1280x720`
- origin — левый нижний угол
- подгонка делается через `docs/guides/HOTSPOTS.md`

## 7. Практические правила

- fullscreen фон → `main/images/backgrounds/<bg_name>.atlas` + регистрация `go.property`/`DEDICATED_BG_ATLAS_PROPS` в `ui_manager_v2.script`
- мелкий overlay-спрайт сцены → `main/images/scene_objects.atlas`
- диалоговый портрет → `main/images/portraits/<name>/<name>.atlas`
- сценический персонаж → `main/images/characters/<name>/<name>.atlas`
- иконка/декор UI → `main/images/ui_common.atlas` (или новый dedicated atlas)
- если сомневаетесь, проверьте, какой texture slot использует нужный `.gui` файл

## 8. Быстрые ссылки

- сцены, фоны, scene objects, архитектура atlas-ов: `docs/guides/HOW_TO_ADD_SCENES.md`
- портреты: `docs/guides/HOW_TO_ADD_PORTRAITS.md`
