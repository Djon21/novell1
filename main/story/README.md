# Сюжет на Ink

Эта папка содержит сценарий АВОСЬ в формате [Ink](https://www.inklestudios.com/ink/).

## Что сейчас реально загружается

- исходник: `main/story/chapter_01.ink`
- runtime-ресурс: `main/story/chapter_01.json`
- текущий loader в `main/gui/ui_manager_v2.script` жёстко читает именно `/main/story/chapter_01.json`

Если добавляете `chapter_02.ink`, мало просто создать файл: нужно ещё расширить loader или роутинг глав.

## Структура папки

```text
main/story/
├── chapter_01.ink
├── chapter_01.json
├── INK_STYLE.md
└── README.md
```

## Компиляция `.ink -> .json`

Ink-файлы компилируются через `inklecate`, который лежит в `tools/`.

### Компилировать всё

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

После каждого изменения `.ink` нужно перекомпилировать `.json`.

## Как runtime использует JSON

- `game.project` подтягивает `main/story` через `custom_resources = /main/story`
- `ui_manager_v2.script` делает `sys.load_resource("/main/story/chapter_01.json")`
- дальше байты уходят в `dialogue_manager_ink.lua`

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

`dialogue_manager_ink.lua` уже парсит `# sfx`, `# shake`, `# pulse`, но активный `v2`-UI пока не забирает `dm.get_effects()`. То есть теги уже являются частью формата, но их bridge в `ui_manager_v2` ещё не доделан.

## Переменные истории

Глобальные Ink-переменные, которые runtime синхронизирует с `save_manager.lua`:

| VAR | Что значит |
| --- | --- |
| `mc_gender` | `"male"` или `"female"` |
| `mc_name` | имя главного героя |
| `npc_name` | имя второго главного персонажа |
| `TRUST` | счётчик доверия |
| `INSIGHT` | счётчик догадок |
| `SYNC` | счётчик синхронности |

## Пример exploration-перехода

```ink
=== apartment_hub_intro
# bg:bg_apartment # speaker:none # explore:apartment_hub
Коридор. Тихо.
-> DONE
```

## AI-friendly workflow

1. Пишете или редактируете `.ink`
2. Перекомпилируете `.json`
3. Запускаете игру в Defold
4. Если меняли теги/команды, проверяете их по `dialogue_manager_ink.lua` и `../../docs/reference/ARCHITECTURE.md`
