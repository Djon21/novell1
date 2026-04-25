# Сюжет на Ink (AVOS_S)

Эта папка хранит сценарий `AVOS_S` в формате [Ink](https://www.inklestudios.com/ink/).

> Этот файл — обзор и навигация. Каноничные правила написания Ink находятся в `INK_STYLE.md`.
> При любом конфликте приоритет у `INK_STYLE.md`.

---

## Что реально грузится в игре

- composition root: `main/story/chapter_01.ink`
- chapter-модули: `main/story/chapters/*.ink`
- runtime-ресурс: `main/story/chapter_01.json`
- активный loader в `main/gui/ui_manager_v2.script` жёстко читает именно `/main/story/chapter_01.json`

`chapter_01_old.ink` считается архивным исходником. Он не участвует в runtime и по умолчанию пропускается bulk-компиляцией.

Важно: runtime всё ещё использует один compiled story, но исходники разбиты на include-файлы. Это сохраняет совместимость с текущими `Continue`, replay history и loop-state.

---

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

---

## Как устроено разбиение на главы

- `chapter_01.ink` больше не хранит весь сюжет целиком: это root-файл со списком `INCLUDE`.
- `chapters/00_bootstrap.ink` хранит общие `VAR` и стартовый `-> wake_intro`.
- `chapters/01_apartment.ink` содержит пробуждение, квартиру и переход к карте города.
- `chapters/02_metro.ink` содержит метро и переход к офису.
- `chapters/03_office.ink` содержит утро в офисе, рабочие выборы и переход на крышу.
- `chapters/04_rooftop.ink` содержит rooftop-разговор и финалы итерации.
- `chapters/90_phone_apps.ink` содержит только пустые compatibility-knot'ы. Новый контент телефона туда добавлять запрещено.
- `chapters/91_inventory_actions.ink` хранит действия предметов инвентаря и fallback-knot'ы.

Такой порядок даёт два плюса:

- сюжет проще читать и редактировать по локациям;
- runtime остаётся единым, поэтому внутренние Ink VAR не нужно отдельно переносить между независимыми story-файлами.

---

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

---

## Как runtime использует JSON

- `game.project` подтягивает `main/story` через `custom_resources = /main/story`.
- `ui_manager_v2.script` делает `sys.load_resource("/main/story/chapter_01.json")`.
- Байты уходят в `dialogue_manager_ink.lua`.
- Дальше Ink-история работает через `dialogue`, `choice`, `exploration` и `chapter_finished`.

---

## Как добавить новую главу

1. Создайте новый include-файл в `main/story/chapters/`, например `05_laboratory.ink`.
2. Перенесите туда knot'ы новой главы и оставьте понятный комментарий-секцию в начале файла.
3. Добавьте строку `INCLUDE chapters/05_laboratory.ink` в `main/story/chapter_01.ink`.
4. Из предыдущей главы переведите сюжет в первый knot новой главы через `-> your_new_knot`.
5. Перекомпилируйте `chapter_01.json`.

Если новая глава должна переиспользовать общие телефонные или сервисные knot'ы, не дублируйте их — оставляйте такие вспомогательные узлы в отдельных include-файлах.

---

## Loop-система и story vars

`dialogue_manager_ink.lua` перед началом истории прокидывает в Ink две группы переменных.

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

- если меняете структуру `.ink`, проверяйте `Continue`, а не только старт новой игры;
- если правка ломает replay history, текущая интеграция предпочитает честный fallback на новый старт главы, а не тихое частичное восстановление.

---

## Поддерживаемые Ink-теги

Полный и каноничный контракт тегов находится в `INK_STYLE.md`. Этот раздел — краткая навигация по тому, что runtime уже понимает.

| Тег | Что делает |
| --- | --- |
| `# bg:NAME` | меняет фон |
| `# bg:none` | скрывает фоновую картинку |
| `# color:R,G,B` | задаёт цвет под фоном |
| `# speaker:mc\|npc\|none\|Имя` | переключает говорящего |
| `# sfx:NAME` | одноразовый SFX |
| `# shake:INT,DUR` | тряска экрана |
| `# pulse:DUR,R,G,B` | цветовая вспышка |
| `# flag:NAME=VALUE` | ставит флаг в `game_state` |
| `# item:add:ID` | добавляет предмет |
| `# item:remove:ID` | убирает предмет |
| `# quest:start:ID` | стартует квест |
| `# quest:done:ID` | закрывает квест |
| `# quest:fail:ID` | проваливает квест |
| `# sms:add:contact:text` | добавляет SMS |
| `# sms:read:contact` | помечает чат прочитанным и гасит unread |
| `# note:add:title:body` | добавляет заметку |
| `# mail:add:from:subject` | добавляет письмо (unread=true) |
| `# mail:add:from:subject:body` | то же, с отдельным телом письма |
| `# mail:read` | помечает все письма прочитанными |
| `# mail:read:N` | помечает N-е письмо (1 = самое свежее) |
| `# call:in:who` | входящий звонок в журнал |
| `# call:out:who` | исходящий звонок в журнал |
| `# call:missed:who` | пропущенный звонок (подсвечивает журнал) |
| `# call:seen` | гасит счётчик пропущенных |
| `# clue:add:id:label` | добавляет улику (дубли по id игнорируются) |
| `# camera:offline:MSG` / `# camera:online:MSG` / `# camera:error:MSG` | обновляет вьюху «камера» (статус и основной текст) |
| `# camera:offline:MSG:META` | то же + нижняя мета-строка |
| `# camera:reset` | сбрасывает камеру к дефолтному offline |
| `# term:LEVEL:text` | добавляет строку в терминал (LEVEL ∈ ok, warn, err, info, prompt, plain) |
| `# term:clear` | очищает терминал |
| `# term:defaults` | перезаливает дефолтный стартовый лог |
| `# meta:add:loop_awareness:1` | повышает loop-awareness внутри текущей итерации |
| `# meta:set:loop_awareness:2` | жёстко выставляет значение meta-поля |
| `# phone:close` | закрывает телефон |
| `# map:hub:KNOT` | открывает карту в hub-режиме; «МАРШРУТ» пина с `route_knot=KNOT` уводит в этот ink-узел |
| `# loop:end:false:ending_a` | ложная концовка — `meta.record_false_ending("ending_a")` (+1 awareness если впервые), перезапускает ту же итерацию |
| `# loop:end:true` | истинная концовка — доступна когда `false_endings_count >= 2`; при успехе переходит в следующую итерацию |
| `# explore:SCENE_ID` | переводит игру в exploration-сцену |
| `# goto_scene:SCENE_ID` | alias для `# explore:SCENE_ID` |
| `# return_to_scene` | возвращает управление в предыдущую exploration-сцену |

### Квесты

Runtime поддерживает только:

```ink
# quest:start:ID
# quest:done:ID
# quest:fail:ID
```

`quest:complete` и любые другие статусы не поддерживаются и приведут к silent fail.

---

## VAR против `# flag:`

В проекте есть две параллельные системы состояния.

| Механизм | Где работает |
| --- | --- |
| `VAR` / `~ присваивание` | внутри Ink: условия, выражения, выборы |
| `# flag:X=Y` | в Lua `game_state`, `scenes.lua`, hotspot'ы |

Если состояние нужно и для Ink-ветвления, и для scene/hotspot-логики, его нужно дублировать:

```ink
~ coffee_drunk = true
# flag:coffee_drunk=true
```

Это обязательное правило. Движок не синхронизирует `VAR` и `flag` автоматически.

---

## Действия инвентаря

- `inventory_v2` показывает ids из `game_state`, а метаданные берёт из `main/scripts/items_catalog.lua`.
- Текущий MVP поддерживает только `use`, `inspect`, `read`.
- `combine` и `give` пока не входят в рабочий flow и скрыты из активного footer до отдельного этапа реализации.
- `ui_manager_v2` ищет Ink-knot для действия предмета в таком порядке:
  - `inv_<scene_id>_<verb>_<item_id>`
  - `inv_<verb>_<item_id>`
  - `inv_<verb>_fallback`
  - `inv_fallback`
- Перед прыжком в knot runtime выставляет в Ink:
  - `inventory_item_id`
  - `inventory_item_name`
  - `inventory_item_verb`
  - `inventory_scene_id`
- Особый случай: `phone` с verb `use` или `read` не уходит в Ink, а открывает `phone_v2` напрямую.

### Как добавить новое действие предмета

1. Добавьте или обновите `item_id` в `main/scripts/items_catalog.lua`.
2. Создайте knot в `main/story/chapters/91_inventory_actions.ink`.
3. Если действие сцено-зависимое, используйте имя `inv_<scene_id>_<verb>_<item_id>`.
4. Если после монолога нужно вернуться в exploration, заканчивайте knot через `# return_to_scene`.
5. Перекомпилируйте `chapter_01.json`.

---

## Телефон и итерации

- `phone_v2` — data-driven UI над `game_state`, а не отдельный сюжетный экран в Ink.
- Новые SMS добавляйте из Ink через `# sms:add:contact:text`.
- Прочтение чата можно фиксировать через `# sms:read:contact`.
- Новые quest-state переходы задавайте из Ink через `# quest:*`.
- Если вводите новый `quest_id`, добавьте ему название и описание в `main/scripts/quests.lua`, иначе телефон покажет только сырой id.
- Для роста осознания петли внутри главы используйте `# meta:add:loop_awareness:N`.
- `game_state.add_sms()` сам проставляет fallback `time`, поэтому превью чата в `phone_v2` не требует отдельного Ink-поля времени.
- Compatibility-knot'ы в `chapters/90_phone_apps.ink` больше не должны хранить статичный текст приложений. Они оставлены только как безопасные точки входа для старых переходов.
- Разрешены только уже существующие legacy compatibility-knot'ы из `chapters/90_phone_apps.ink`. Создавать новые `phone_*` knot'ы запрещено.
- `phone_home` больше не существует как scene в `main/scripts/scenes.lua`; старые `# goto_scene:phone_home` работают только потому, что `ui_manager_v2` перехватывает их как alias на `phone_v2`.
- Если новое значение meta-поля должно влиять на ветвление сразу в этом же knot, дублируйте его обычным Ink-присваиванием и рядом оставляйте `# meta:add:*` для сохранения в `meta_state`.

---

## Телефон как сюжетный канал: каноническое правило

Телефон (`phone_v2`) — это data-driven overlay, а не Ink-сцена.

### Запрещено

- писать сюжетный текст телефона в Ink-knot'ах;
- создавать новые `phone_*` knot'ы или отдельные `phone_*` сцены;
- использовать телефон как `goto_scene`.

### Исключение для legacy

`chapters/90_phone_apps.ink` может содержать только уже существующие compatibility-knot'ы для старых переходов. Это не место для нового phone-контента и не разрешение создавать новые `phone_*` knot'ы.

### Правильная модель

Ink только добавляет данные в runtime:

```ink
# sms:add:anya:"Сообщение"
# note:add:Заметка:"текст"
# quest:start:check_phone
# quest:fail:check_phone
# sms:read:anya
```

---

## Важный caveat по эффектам

`dialogue_manager_ink.lua` парсит `# sfx`, `# shake`, `# pulse`, а `ui_manager_v2.script` забирает `dm.get_effects()` и роутит их в `sfx_player` и `effects`.

Для нового `# sfx:name` мало добавить `.sound` в `sfx_player`. Тот же id нужно ещё прописать в `M.SFX_URLS` в `main/gui/ui_manager_v2.script`, иначе runtime выведет warning про неизвестный SFX.

Для нового SFX нужны:

1. `.ogg` в `main/sounds/`;
2. `.sound` descriptor;
3. component в `sfx_player` внутри `main/main_v2.collection`;
4. запись id в `M.SFX_URLS` в `main/gui/ui_manager_v2.script`.

---

## Loader и ограничения

- Активный story-loader пока жёстко читает только `main/story/chapter_01.json`.
- Source-level story уже разбит на include-главы, но runtime остаётся единым compiled story.
- Отдельный multi-json chapter routing пока не выделен.
- Include-файлы в `main/story/chapters/` не компилируются отдельно.

---

## AI-friendly workflow

1. Меняете `.ink`.
2. Перекомпилируете `.json`.
3. Запускаете игру в Defold.
4. Если меняли теги, loop vars, инвентарь или телефон, сверяетесь с:
   - `INK_STYLE.md`
   - `docs/reference/LOOP_SYSTEM.md`
   - `docs/reference/ARCHITECTURE.md`
   - `docs/reference/INVENTORY_SYSTEM.md`
   - `main/scripts/dialogue_manager_ink.lua`
   - `main/gui/ui_manager_v2.script`

---

## Связанные документы

- `INK_STYLE.md` — главный runtime-контракт Ink.
- `docs/reference/ARCHITECTURE.md` — архитектура активного v2 runtime.
- `docs/reference/LOOP_SYSTEM.md` — временная петля и meta-state.
- `docs/reference/INVENTORY_SYSTEM.md` — инвентарь и item actions.
- `docs/guides/HOW_TO_ADD_SCENES.md` — exploration-сцены.
- `docs/guides/HOW_TO_ADD_BACKGROUNDS.md` — фоны.
- `docs/guides/HOW_TO_ADD_SOUNDS.md` — звуки.
- `docs/guides/HOW_TO_ADD_PORTRAITS.md` — портреты.

---

## Коротко

- `INK_STYLE.md` — главный источник истины по Ink-правилам.
- `README_INK.md` — обзор, навигация и рабочий pipeline.
- Runtime грузит только `chapter_01.json`.
- `.ink` разбит на include-файлы, но compiled story один.
- Телефон — data-driven overlay, не Ink-сцена.
- Инвентарь — state в `game_state`, UI в `inventory_v2`, реакция в Ink.
- `VAR` и `# flag:` не синхронизируются автоматически.
- После любой правки `.ink` нужен compile.
