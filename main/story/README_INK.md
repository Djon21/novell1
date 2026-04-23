# Сюжет на Ink

Эта папка хранит сценарий `AVOS_S` в формате [Ink](https://www.inklestudios.com/ink/).

## Что реально грузится в игре

- composition root: `main/story/chapter_01.ink`
- chapter-модули: `main/story/chapters/*.ink`
- runtime-ресурс: `main/story/chapter_01.json`
- активный loader в `main/gui/ui_manager_v2.script` жёстко читает именно `/main/story/chapter_01.json`

`chapter_01_old.ink` считается архивным исходником. Он не участвует в runtime и по умолчанию пропускается bulk-компиляцией.

Важно: рантайм всё ещё использует один compiled story, но исходники теперь разбиты на include-файлы. Это сохраняет совместимость с текущими `Continue`, replay history и loop-state.

## Структура папки

```text
main/story/
├── chapter_01.ink
├── chapter_01.json
├── chapters/
│   ├── 00_bootstrap.ink
│   ├── 01_apartment.ink
│   ├── 02_metro.ink
│   ├── 03_office.ink
│   ├── 04_rooftop.ink
│   ├── 90_phone_apps.ink
│   ├── 91_inventory_actions.ink
│   └── README.md
├── chapter_01_old.ink
├── INK_STYLE.md
└── README.md
```

## Как устроено разбиение на главы

- `chapter_01.ink` больше не хранит весь сюжет целиком: это root-файл со списком `INCLUDE`
- `chapters/00_bootstrap.ink` хранит общие `VAR` и стартовый `-> wake_intro`
- `chapters/01_apartment.ink` содержит пробуждение, квартиру и переход к карте города
- `chapters/02_metro.ink` содержит метро и переход к офису
- `chapters/03_office.ink` содержит утро в офисе, рабочие выборы и переход на крышу
- `chapters/04_rooftop.ink` содержит rooftop-разговор и финалы итерации
- `chapters/90_phone_apps.ink` хранит compatibility-knot'ы телефона; реальный контент телефона живёт в `phone_v2` + `game_state`
- `chapters/91_inventory_actions.ink` хранит действия предметов инвентаря и fallback-knot'ы

Такой порядок даёт два плюса:

- сюжет проще читать и редактировать по локациям
- runtime остаётся единым, поэтому внутренние Ink VAR не нужно отдельно переносить между независимыми story-файлами

## Компиляция `.ink -> .json`

Ink компилируется через `inklecate`, который лежит в `tools/`.

### Компилировать активные главы

```bash
# Linux/macOS/Git Bash
./tools/compile_ink.sh

# Windows CMD
tools\compile_ink.bat
```

### Компилировать один файл

```bash
./tools/compile_ink.sh chapter_01
tools\compile_ink.bat chapter_01
```

После каждого изменения `.ink` нужно перекомпилировать `.json`, иначе Defold продолжит играть старый compiled story.

`tools/compile_ink.*` компилируют только top-level `.ink` из `main/story/`. Файлы внутри `main/story/chapters/` подтягиваются автоматически через `INCLUDE` и не должны компилироваться как отдельные runtime-json.

## Как runtime использует JSON

- `game.project` подтягивает `main/story` через `custom_resources = /main/story`
- `ui_manager_v2.script` делает `sys.load_resource("/main/story/chapter_01.json")`
- байты уходят в `dialogue_manager_ink.lua`
- дальше Ink-история работает через `dialogue`, `choice`, `exploration` и `chapter_finished`

## Как добавить новую главу

1. Создайте новый include-файл в `main/story/chapters/`, например `05_laboratory.ink`.
2. Перенесите туда knot'ы новой главы и оставьте понятный комментарий-секцию в начале файла.
3. Добавьте строку `INCLUDE chapters/05_laboratory.ink` в `main/story/chapter_01.ink`.
4. Из предыдущей главы переведите сюжет в первый knot новой главы через `-> your_new_knot`.
5. Перекомпилируйте `chapter_01.json`.

Если новая глава должна переиспользовать общие телефонные или сервисные knot'ы, не дублируйте их — оставляйте такие вспомогательные узлы в отдельных include-файлах.

## Loop-система и story vars

`dialogue_manager_ink.lua` перед началом истории прокидывает в Ink две группы переменных:

### Run-state

| VAR | Что значит |
| --- | --- |
| `mc_gender` | `"male"` или `"female"` |
| `mc_name` | имя главного героя |
| `npc_name` | имя второго главного персонажа |
| `TRUST` | счётчик доверия |
| `INSIGHT` | счётчик догадок |
| `SYNC` | счётчик синхронности |

### Meta-state

| VAR | Источник | Что значит |
| --- | --- | --- |
| `iteration_number` | `meta_state.lua` | номер текущей итерации |
| `iteration_label` | `meta_state.lua` | строка вида `001`, `002`, `003` |
| `loop_awareness` | `meta_state.lua` | уровень осознания петли |
| `completed_iterations` | `meta_state.lua` | сколько циклов уже завершено |

Если добавляете новые loop-aware реплики, меняйте `.ink` и обязательно перекомпилируйте `chapter_01.json`.

### Как это связано с `defold-ink` save/load

`defold-ink` сохраняет историю через replay choices/input, а не через полный снимок всех globals.

Поэтому в `AVOS_S` внешние vars, которые задаются Lua-стороной до начала истории, пишутся через `story.assign_value(...)`. Иначе они могут потеряться на `Continue` после `story.restore(...)`.

Старые сейвы, созданные до этого фикса, при restore дополнительно получают текущие external vars перед replay.

### Что это значит для разработки

- если меняете структуру `.ink`, проверяйте `Continue`, а не только старт новой игры
- если правка ломает replay history, текущая интеграция предпочитает честный fallback на новый старт главы, а не тихое частичное восстановление

## Поддерживаемые Ink-теги

Текущий runtime понимает следующие теги:

| Тег | Что делает |
| --- | --- |
| `# bg:NAME` | меняет фон |
| `# bg:none` | скрывает фоновую картинку |
| `# color:R,G,B` | задаёт цвет под фоном |
| `# speaker:mc|npc|none|Имя` | переключает говорящего |
| `# sfx:NAME` | одноразовый SFX |
| `# shake:INT,DUR` | тряска экрана |
| `# pulse:DUR,R,G,B` | цветовая вспышка |
| `# flag:NAME=VALUE` | ставит флаг в `game_state` |
| `# item:add:ID` | добавляет предмет |
| `# item:remove:ID` | убирает предмет |
| `# quest:start:ID` / `done` / `fail` | меняет статус квеста |
| `# sms:add:contact:text` | добавляет SMS |
| `# sms:read:contact` | помечает чат прочитанным и гасит unread |
| `# note:add:title:body` | добавляет заметку |
| `# meta:add:loop_awareness:1` | повышает loop-awareness внутри текущей итерации |
| `# meta:set:loop_awareness:2` | жёстко выставляет значение meta-поля |
| `# phone:close` | закрывает телефон |
| `# goto_scene:SCENE_ID` / `# explore:SCENE_ID` | переводит игру в exploration-сцену |
| `# return_to_scene` | возвращает управление в предыдущую exploration-сцену |

## Действия инвентаря

- `inventory_v2` показывает ids из `game_state`, а метаданные берёт из `main/scripts/items_catalog.lua`
- текущий MVP поддерживает только `use`, `inspect`, `read`
- `combine` и `give` пока не входят в рабочий flow и должны оставаться выключенными как verbs второго этапа
- `ui_manager_v2` ищет Ink-knot для действия предмета в таком порядке:
  - `inv_<scene_id>_<verb>_<item_id>`
  - `inv_<verb>_<item_id>`
  - `inv_<verb>_fallback`
  - `inv_fallback`
- перед прыжком в knot runtime выставляет в Ink:
  - `inventory_item_id`
  - `inventory_item_name`
  - `inventory_item_verb`
  - `inventory_scene_id`
- особый случай: `phone` с verb `use` или `read` не уходит в Ink, а открывает `phone_v2` напрямую

### Как добавить новое действие предмета

1. Добавьте или обновите `item_id` в `main/scripts/items_catalog.lua`.
2. Создайте knot в `main/story/chapters/91_inventory_actions.ink`.
3. Если действие сцено-зависимое, используйте имя `inv_<scene_id>_<verb>_<item_id>`.
4. Если после монолога нужно вернуться в exploration, заканчивайте knot через `# return_to_scene`.
5. Перекомпилируйте `chapter_01.json`.

## Телефон и итерации

- `phone_v2` — data-driven UI над `game_state`, а не отдельный сюжетный экран в Ink
- новые SMS добавляйте из Ink через `# sms:add:contact:text`
- прочтение чата можно фиксировать через `# sms:read:contact`
- новые quest-state переходы задавайте из Ink через `# quest:*`
- если вводите новый `quest_id`, добавьте ему название и описание в `main/scripts/quests.lua`, иначе телефон покажет только сырой id
- для роста осознания петли внутри главы используйте `# meta:add:loop_awareness:N`
- compatibility-knot'ы в `chapters/90_phone_apps.ink` больше не должны хранить статичный текст приложений; они оставлены только как безопасные точки входа для старых переходов
- если новое значение meta-поля должно влиять на ветвление сразу в этом же knot, дублируйте его обычным Ink-присваиванием (`~ loop_awareness = loop_awareness + 1`) и рядом оставляйте `# meta:add:loop_awareness:1` для сохранения в `meta_state`

## Важный caveat по эффектам

`dialogue_manager_ink.lua` уже парсит `# sfx`, `# shake`, `# pulse`, но активный `v2` UI пока не потребляет `dm.get_effects()`. То есть формат уже живой, а bridge для визуальных и звуковых one-shot эффектов ещё нужно подключать отдельно.

## AI-friendly workflow

1. Меняете `.ink`
2. Перекомпилируете `.json`
3. Запускаете игру в Defold
4. Если меняли теги или loop vars, сверяетесь с:
   - `docs/reference/LOOP_SYSTEM.md`
   - `docs/reference/ARCHITECTURE.md`
   - `main/scripts/dialogue_manager_ink.lua`
