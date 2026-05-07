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

## 4. Портреты для активного v2 UI

### Где лежат

- файлы: `main/images/v2/`
- atlas: `main/images/v2.atlas`
- runtime-логика: `main/gui/components_v2/dialogue_v2.gui_script`

### Правила

- формат: `PNG`
- прозрачный фон
- рекомендуемый размер: `512x512`
- atlas frame name должен совпадать с полем `portrait` в таблице `CHARS`

## 5. Legacy ресурсы (НЕ для новых ассетов)

- `archive/legacy_runtime/main/images/characters.atlas` — архивный portrait atlas старого GUI
- `archive/legacy_runtime/main/images/backgrounds.atlas` — archive-only atlas старого v1 GUI.
Старая схема смены фонов отключена; этот atlas не используется v2 и не считается fallback. Сейчас содержит только то, что осталось от legacy сцены (`bg_bedroom_01`, `mobile`,
  `hotspot_*`). Новые ресурсы сюда не добавляем — `dialogue_v2`, `hotspots_v2`
  и `main_menu_v2` его не используют.

## 6. Координатная система для scenes

- hotspot'ы и scene objects в `scenes.lua` описываются в системе `1280x720`
- origin — левый нижний угол
- подгонка делается через `docs/guides/F1_HOTSPOT_EDITOR.md`

## 7. Практические правила

- fullscreen фон → `main/images/backgrounds/<bg_name>.atlas` + регистрация `go.property`/`DEDICATED_BG_ATLAS_PROPS` в `ui_manager_v2.script`
- мелкий overlay-спрайт сцены → `main/images/scene_objects.atlas`
- портрет персонажа → `main/images/v2.atlas`
- иконка/декор UI → `main/images/ui_common.atlas` (или новый dedicated atlas)
- если сомневаетесь, проверьте, какой texture slot использует нужный `.gui` файл

## 8. Быстрые ссылки

- сцены, фоны, scene objects, архитектура atlas-ов: `docs/guides/HOW_TO_ADD_SCENES.md`
- портреты: `docs/guides/HOW_TO_ADD_PORTRAITS.md`
