# Inventory System

Актуально на `2026-04-23`.

## Что считается source of truth

- runtime-state предметов хранится в `main/scripts/game_state.lua`
- UI-метаданные предметов живут в `main/scripts/items_catalog.lua`
- `inventory_v2` только рендерит состояние и шлёт verbs наружу
- `ui_manager_v2` решает, что делать с verb

Это значит:

- `game_state` отвечает за наличие предмета у игрока
- `items_catalog` отвечает за имя, иконку, описание и доступные verbs
- Ink отвечает за сюжетную реакцию на действие предмета
- `mug` и `phone` — единственный источник правды по этим предметам: hotspots проверяют через `gs.has_item("mug")`/`gs.has_item("phone")`, ink добавляет через `# add_item:mug`/`# add_item:phone`. Старых флагов `has_mug`/`has_phone` больше нет (после рефакторинга 2026-05).

## Ограничения MVP

- максимум `12` уникальных предметов
- текущие рабочие verbs: `use`, `inspect`, `read`
- `combine` и `give` пока не входят в рабочий flow и скрыты из footer, чтобы UI не обещал несуществующую механику
- если `item_id` отсутствует в `items_catalog.lua`, инвентарь всё равно покажет fallback-карточку вместо пустого слота

## Flow действия предмета

1. Игрок открывает `inventory_v2`.
2. GUI берёт список ids из `game_state.get_inventory()`.
3. По клику на verb `inventory_v2` шлёт `inventory_verb` в `ui_manager_v2`.
4. `ui_manager_v2` подготавливает context и ищет Ink-knot.
5. Если найден knot, игра временно выходит из exploration в короткий side-dialogue.
6. После `# return_to_scene` управление возвращается в исходную сцену.

## Порядок поиска Ink-knot

`ui_manager_v2` ищет knot в таком порядке:

1. `inv_<scene_id>_<verb>_<item_id>`
2. `inv_<verb>_<item_id>`
3. `inv_<verb>_fallback`
4. `inv_fallback`

Примеры:

- `inv_apartment_hub_inspect_note`
- `inv_read_note`
- `inv_inspect_fallback`

## Какие переменные runtime кладёт в Ink

Перед side-knot прыжком `dialogue_manager_ink` выставляет:

- `inventory_item_id`
- `inventory_item_name`
- `inventory_item_verb`
- `inventory_scene_id`

Их можно использовать внутри fallback-реплик или scene-specific действий.

## Особый случай: телефон

`phone` не ведёт себя как обычный предмет:

- `phone + use`
- `phone + read`

Эти два verbs не прыгают в Ink, а открывают `phone_v2` напрямую. Это сделано специально, чтобы не ломать возврат из exploration и не дублировать data-driven телефон статичными Ink-экранами.

Если нужен короткий текст про телефон, используйте `inspect` и knot `inv_inspect_phone`.

## Как добавить новый предмет

1. Добавьте `item_id` в `main/scripts/items_catalog.lua`.
2. Убедитесь, что предмет попадает в `game_state` через scene action или Ink tag `# item:add:ID`.
3. Если нужно уникальное действие, добавьте knot в `main/story/chapters/91_inventory_actions.ink`.
4. Перекомпилируйте `main/story/chapter_01.json`.

## Как добавить новое действие предмета

1. Решите, действие глобальное или сцено-зависимое.
2. Для глобального используйте `inv_<verb>_<item_id>`.
3. Для сцено-зависимого используйте `inv_<scene_id>_<verb>_<item_id>`.
4. Если действие должно вернуть игрока в exploration, завершайте knot через `# return_to_scene`.
5. Если действие меняет состояние мира, используйте обычные Ink tags:
   `# flag:*`, `# item:*`, `# quest:*`, `# sms:*`, `# note:*`, `# meta:*`

## Проверка после изменений

- открыть инвентарь
- проверить выбор предмета и details panel
- прожать нужный verb
- убедиться, что side-dialogue открылся на фоне текущей сцены
- убедиться, что после `# return_to_scene` игра вернулась в exploration
- после правки `.ink` всегда перекомпилировать `chapter_01.json`
