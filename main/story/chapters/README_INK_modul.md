# Главы Ink

Эта папка хранит модульные include-файлы сюжета.

## Правила

- `chapter_01.ink` в родительской папке — это composition root, а не место для всего текста главы
- каждый файл в `chapters/` отвечает за отдельный смысловой блок
- порядок подключения задаётся строками `INCLUDE ...` в `main/story/chapter_01.ink`
- runtime по-прежнему собирается в один `chapter_01.json`

## Текущая разбивка

- `00_bootstrap.ink` — общие `VAR` и стартовый переход
- `01_apartment.ink` — квартира и карта города
- `02_metro.ink` — метро
- `03_office.ink` — офис
- `04_rooftop.ink` — крыша и финалы
- `90_phone_apps.ink` — общие телефонные knot'ы
- `91_inventory_actions.ink` — действия предметов инвентаря и fallback-knot'ы

## Как добавлять новые главы

1. Создайте новый файл с порядковым префиксом, например `05_laboratory.ink`.
2. Подключите его через `INCLUDE` в `main/story/chapter_01.ink`.
3. Передайте поток сюжета в новый knot из предыдущей главы.
4. Перекомпилируйте `chapter_01.json`.

## Контракт для действий инвентаря

`inventory_v2` не хранит тексты действий сам. Он шлёт `item_id + verb` в `ui_manager_v2`, а тот ищет Ink-knot в таком порядке:

1. `inv_<scene_id>_<verb>_<item_id>`
2. `inv_<verb>_<item_id>`
3. `inv_<verb>_fallback`
4. `inv_fallback`

Для MVP сейчас поддерживаются только `use`, `inspect`, `read`.

Особый случай:

- `phone + use/read` не прыгает в Ink, а открывает `phone_v2` напрямую
