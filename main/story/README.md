# Сюжет на Ink

Эта папка хранит сценарий `AVOS_S` в формате [Ink](https://www.inklestudios.com/ink/).

## Что реально грузится в игре

- исходник: `main/story/chapter_01.ink`
- runtime-ресурс: `main/story/chapter_01.json`
- активный loader в `main/gui/ui_manager_v2.script` жёстко читает именно `/main/story/chapter_01.json`

`chapter_01_old.ink` считается архивным исходником. Он не участвует в runtime и по умолчанию пропускается bulk-компиляцией.

## Структура папки

```text
main/story/
├── chapter_01.ink
├── chapter_01.json
├── chapter_01_old.ink
├── INK_STYLE.md
└── README.md
```

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

## Как runtime использует JSON

- `game.project` подтягивает `main/story` через `custom_resources = /main/story`
- `ui_manager_v2.script` делает `sys.load_resource("/main/story/chapter_01.json")`
- байты уходят в `dialogue_manager_ink.lua`
- дальше Ink-история работает через `dialogue`, `choice`, `exploration` и `chapter_finished`

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
| `# note:add:title:body` | добавляет заметку |
| `# phone:close` | закрывает телефон |
| `# goto_scene:SCENE_ID` / `# explore:SCENE_ID` | переводит игру в exploration-сцену |
| `# return_to_scene` | возвращает управление в предыдущую exploration-сцену |

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
