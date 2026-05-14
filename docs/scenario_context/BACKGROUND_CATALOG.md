# Background Catalog

Этот каталог нужен, чтобы GPT понимал, какие локации уже есть, и не придумывал новые background id без необходимости.

## Квартира

- `bg_apartment_bedroom_morning` - спальня утром.
- `bg_apartment_hall_morning` - коридор/холл утром.
- `bg_apartment_kitchen_morning` - кухня утром.
- `bg_apartment_bathroom_morning` - ванная утром.

Квартира может иметь дневные/ночные варианты через функции и scene data. Перед добавлением нового времени суток проверь `main/data/scenes/apartment*.lua`.

## Офис

- Офисный хаб.
- Рабочее место.
- Переговорная.

У офиса могут быть дневные/ночные состояния. Смотри `main/data/scenes/office.lua`.

## Внешние локации

- `bg_cafe_morning` - кафе.
- `bg_shop_day` - магазин.
- `bg_observation_day` - смотровая/видовая точка.
- `bg_bar_maybe_night` - бар.
- `bg_archive_day` - архив.

## Парк

- `bg_park_riverside_entrance_morning` - вход/начало парковой зоны у реки.
- `bg_park_riverside_bench_morning` - скамейка у реки.
- `bg_park_riverside_path_morning` - дорожка/тропа у реки.

## Финальные/особые локации

- `bg_rooftop` - крыша.

## Как добавлять новый фон

Обычно нужны шаги:

1. Добавить изображение в папку проекта.
2. Добавить его в нужный atlas/material pipeline, если фон используется через atlas.
3. Добавить/проверить background id в scene data.
4. Если фон должен использоваться в диалоговом режиме, проверить привязки background properties в `ui_manager_v2.script` и связанных модулях.
5. Добавить `scene_id` или расширить существующую сцену.
6. Обновить этот каталог.

Не надо просить GPT просто "подключить фон", если ему не дали структуру atlas/scene data. Для корректной правки нужны текущие файлы `main/data/scenes/*.lua` и, если фон новый, файлы графического пайплайна проекта.

