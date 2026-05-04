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
- активные verbs: `use`, `inspect`, `read`, `give`, `combine`
- если `item_id` отсутствует в `items_catalog.lua`, инвентарь всё равно покажет fallback-карточку вместо пустого слота

## Verb flow по типам

### `inspect` / `read`

Простые verbs — закрывают инвентарь и сразу прыгают в ink-knot:
- `inv_<scene>_<verb>_<item>` → `inv_<verb>_<item>` → `inv_<verb>_fallback` → `inv_fallback`

### `use` — armed-режим (use-on-target)

1. Игрок жмёт `USE` на предмете
2. Инвентарь закрывается, предмет «в руках» (`ui_state.armed_inventory` = `{item_id, verb="use"}`)
3. Следующий клик по hotspot'у запускает knot:
   - `inv_<scene>_use_<item>_on_<hotspot_id>`
   - `inv_use_<item>_on_<hotspot_id>`
   - `inv_use_<item>_on_fallback`
   - `inv_use_on_<hotspot_id>` (любой предмет на этом хотспоте)
   - `inv_use_fallback`
   - `inv_fallback`
4. Клик мимо хотспотов = отмена armed (без эффекта)
5. Повторное открытие инвентаря тоже снимает armed

В ink-knot доступны переменные `inventory_item_id`, `inventory_target_id` (= hotspot_id), `inventory_target_kind` = `"hotspot"`.

### `combine` — соединить два предмета

Двухкликовая операция **внутри инвентаря** (без выхода в сцену):

1. Игрок выделяет item A → жмёт `СОЕДИНИТЬ`
2. Details panel перерисовывается: «Соединить с …» + инструкция; кнопка `СОЕДИНИТЬ` превращается в `ОТМЕНА`
3. Клик на другой item B → запускает knot:
   - **Имена knot'ов канонизированы лексикографической сортировкой** — для пары `(matchbox, lighter)` всегда ищется `inv_combine_lighter_with_matchbox` (потому что `l < m`). Автору не нужно писать оба порядка
   - Цепочка: `inv_combine_<low>_with_<high>` → `inv_combine_fallback` → `inv_fallback`
4. Отмена: повторный клик на `ОТМЕНА`, клик на тот же item A, закрытие инвентаря

В ink-knot: `inventory_item_id` = A (первый, который был выделен при клике COMBINE), `inventory_target_id` = B (второй), `inventory_target_kind` = `"item"`.

> **Совет:** результат combine реализуется обычными тегами:
> ```ink
> === inv_combine_lighter_with_matchbox ===
> # speaker:mc
> Зажигалка прикуривает от спички. Удобно.
> # remove_item:matchbox
> # add_item:lit_match
> # return_to_scene
> -> DONE
> ```

### `give` — передать NPC текущей сцены

1. В `scenes.lua` сцена объявляет NPC: `npc = "npc"` (или конкретное имя)
2. Игрок жмёт `GIVE` на предмете
3. Инвентарь закрывается, ui_manager берёт `scene.npc` и стреляет:
   - `inv_<scene>_give_<item>_on_<npc>`
   - `inv_give_<item>_on_<npc>`
   - `inv_give_<item>_on_fallback`
   - `inv_give_on_<npc>`
   - `inv_give_fallback` → `inv_fallback`
4. Если у сцены НЕТ поля `npc` — сразу `inv_give_<item>` → `inv_give_fallback`

В ink-knot: `inventory_target_id` = npc_id, `inventory_target_kind` = `"npc"`.

> Convention: для воскресных сцен (cafe_hub/park_hub) target = `"npc"` (не конкретное имя), потому что NPC меняется по гендеру MC. Внутри knot можно делать `{mc_gender == "female": Артём - else: Мила}`.

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
- `inventory_target_id` — для use-on-target = hotspot id, для give = npc id, иначе `""`
- `inventory_target_kind` — `"hotspot"` / `"npc"` / `""`

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
