# Ink Сценарий

Активный runtime загружает один compiled story:

- root: `main/story/chapter_01.ink`
- modules: `main/story/chapters/*.ink`
- runtime JSON: `main/story/chapter_01.json`
- loader: `main/gui/ui_manager_v2.script`

`main/story/chapters/New/` больше не считается отдельной тестовой веткой. Новый сюжет должен попадать в активные `chapters/*.ink`, затем компилироваться в `chapter_01.json`.

## Структура

```text
main/story/
├── chapter_01.ink
├── chapter_01.json
├── INK_STYLE.md
├── README_INK.md
└── chapters/
    ├── 00_bootstrap.ink
    ├── 01_apartment.ink
    ├── 02_metro.ink
    ├── 03_office.ink
    ├── 04_rooftop.ink
    ├── 90_phone_apps.ink
    ├── 91_inventory_actions.ink
    └── README_INK_modul.md
```

## Компиляция

```bash
tools\compile_ink.bat
tools\compile_ink.bat chapter_01
```

Git Bash / Linux:

```bash
./tools/compile_ink.sh
./tools/compile_ink.sh chapter_01
```

После любой правки `.ink` нужен новый compile, иначе Defold продолжит играть старый `.json`.

## Базовые Правила

- `chapter_01.ink` хранит только `INCLUDE`.
- Общие `VAR` лежат в `chapters/00_bootstrap.ink`.
- Локационные главы лежат в `01_apartment`, `02_metro`, `03_office`, `04_rooftop`.
- Служебные compatibility-knot'ы телефона лежат в `90_phone_apps`.
- Действия предметов лежат в `91_inventory_actions`.
- Не создавайте новые `phone_*` сюжетные экраны: телефон data-driven и рендерится GUI.
- Если меняете структуру Ink, проверяйте и новый старт, и `Continue`.

## Lua -> Ink Vars

Lua до начала истории прокидывает:

| VAR | Источник |
| --- | --- |
| `mc_gender` | `save_manager` / выбор игрока |
| `mc_name` | `save_manager` |
| `npc_name` | `save_manager` |
| `iteration_number` | `meta_state` |
| `iteration_label` | `meta_state` |
| `loop_awareness` | `meta_state` |
| `completed_iterations` | `meta_state` |
| `false_endings_count` | `meta_state` |

Внешние значения пишутся через `story.assign_value(...)`, чтобы `defold-ink` корректно replay'ил их на `Continue`.

## Поддерживаемые Теги

| Тег | Что Делает |
| --- | --- |
| `# bg:NAME` | меняет фон |
| `# bg:none` | скрывает фон |
| `# color:R,G,B` | задаёт цвет под фоном |
| `# speaker:mc|npc|none|Имя` | переключает говорящего |
| `# sfx:NAME` | одноразовый звук |
| `# shake:INT,DUR` | тряска экрана |
| `# pulse:DUR,R,G,B` | цветовая вспышка |
| `# flag:NAME=VALUE` | пишет flag в `game_state` |
| `# item:add:ID` | добавляет предмет |
| `# item:remove:ID` | убирает предмет |
| `# quest:start:ID` | стартует квест |
| `# quest:done:ID` | завершает квест |
| `# quest:fail:ID` | проваливает квест |
| `# sms:add:contact:text` | добавляет SMS |
| `# sms:read:contact` | гасит unread чата |
| `# note:add:title:body` | добавляет заметку |
| `# mail:add:from:subject` | добавляет письмо |
| `# mail:add:from:subject:body` | добавляет письмо с телом |
| `# mail:read` | помечает всю почту прочитанной |
| `# mail:read:INDEX` | помечает одно письмо прочитанным |
| `# call:add:who:kind` | добавляет звонок (`in`, `out`, `missed`) |
| `# call:read` | помечает звонки просмотренными |
| `# clue:add:id:label` | добавляет улику |
| `# camera:offline:message:meta` | обновляет камеру |
| `# camera:online:message:meta` | обновляет камеру |
| `# camera:error:message:meta` | обновляет камеру |
| `# camera:reset` | сбрасывает камеру |
| `# term:LEVEL:text` | добавляет строку терминала |
| `# term:clear` | очищает терминал |
| `# term:defaults` | возвращает дефолтные строки терминала |
| `# meta:add:loop_awareness:1` | увеличивает meta-поле |
| `# meta:set:loop_awareness:2` | задаёт meta-поле |
| `# loop:end:false:id` | ложная концовка, restart текущей итерации |
| `# loop:end:true` | истинная концовка, переход дальше |
| `# map:hub:KNOT` | открыть `map_v2` в hub-режиме |
| `# goto_scene:SCENE_ID` | перейти в exploration-сцену |
| `# explore:SCENE_ID` | перейти в exploration-сцену |
| `# return_to_scene` | вернуться в предыдущую exploration-сцену |
| `# phone:close` | закрыть телефон |

## Карта Из Ink

Для выбора маршрута используйте:

```ink
# map:hub:metro
-> DONE
```

`map_v2` откроется как hub. Если игрок выбирает пин с `route_knot`, `ui_manager_v2` прыгнет в этот knot. Если карту закрыли без выбора, используется primary knot из тега.

## Действия Инвентаря

Контракт поиска knot'а:

- `inv_<scene_id>_<verb>_<item_id>`
- `inv_<verb>_<item_id>`
- `inv_<verb>_fallback`
- `inv_fallback`

Рабочие verbs: `use`, `inspect`, `read`.

`phone + use/read` открывает `phone_v2` напрямую.

## Телефон И Итерации

Телефон не хранит сюжет в отдельных Ink-экранах. Ink только добавляет данные в `game_state`, а GUI показывает текущее состояние.

Для loop-aware контента используйте условия по `iteration_number`, `loop_awareness`, `false_endings_count` и добавляйте данные тегами:

```ink
{iteration_number >= 2:
    # sms:add:anya:Ты тоже это помнишь?
    # clue:add:repeat_signal:Повторяющийся сигнал
}
```

Если тег может сработать повторно внутри одной итерации, защищайте его Ink-флагом.

## После Правки Сюжета

1. Скомпилировать `chapter_01.json`.
2. Запустить игру.
3. Проверить старт новой игры.
4. Проверить `Continue`, если правка могла затронуть replay history.
5. Проверить телефон, карту и инвентарь, если добавлялись соответствующие теги.
