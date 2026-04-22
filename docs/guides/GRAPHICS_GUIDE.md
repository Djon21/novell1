# Инструкция по графическим ресурсам

## 1. Фоны и exploration sprites

### Где лежат

- файлы: `main/images/`
- atlas: `main/images/backgrounds.atlas`

### Что сюда относится

- полноэкранные фоны `bg_*.jpg`
- scene objects вроде `mobile.png`
- hotspot-related sprites

### Рекомендации

- фон: `JPG`, желательно `1920x1080`
- object sprite: `PNG`
- имена фонов: `bg_name.jpg`
- имена scene objects: по смыслу, без `bg_`

## 2. Портреты для активного v2 UI

### Где лежат

- файлы: `main/images/v2/`
- atlas: `main/images/v2.atlas`
- runtime-логика: `main/gui/components_v2/dialogue_v2.gui_script`

### Правила

- формат: `PNG`
- прозрачный фон
- рекомендуемый размер: `512x512`
- atlas frame name должен совпадать с полем `portrait` в таблице `CHARS`

## 3. Legacy portrait atlas

- `main/images/characters.atlas` — это legacy-ресурс
- он полезен как reference, но новые портреты для текущего UI нужно добавлять в `v2.atlas`

## 4. Координатная система для scenes

- hotspot'ы и scene objects в `scenes.lua` описываются в системе `960x640`
- origin — левый нижний угол
- подгонка делается через `docs/guides/F1_HOTSPOT_EDITOR.md`

## 5. Практические правила

- если asset нужен для exploration-слоя, сначала думайте про `backgrounds.atlas`
- если asset нужен для portrait slot в диалоге, сначала думайте про `v2.atlas`
- если сомневаетесь, проверьте, какой atlas использует нужный `.gui` файл

## 6. Быстрые ссылки

- фоны: `docs/guides/HOW_TO_ADD_BACKGROUNDS.md`
- портреты: `docs/guides/HOW_TO_ADD_PORTRAITS.md`
- сцены и scene objects: `docs/guides/HOW_TO_ADD_SCENES.md`
