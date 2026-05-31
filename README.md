# АВОСЬ

`AVOS_S` — narrative point-and-click / visual novel на Defold.

Активный runtime работает через `v2`-стек:

- `game.project -> /main/main_v2.collectionc`
- `main/gui/ui_manager_v2.script` — главный оркестратор UI
- `main/gui/components_v2/` — активные GUI-компоненты
- `main/scripts/dialogue_manager_ink.lua` — обёртка над `defold-ink`
- `main/scripts/scene_controller.lua` — exploration-сцены и hotspots
- `main/scripts/game_state.lua` — run-state текущего прохождения
- `main/scripts/save_manager.lua` — save для `Continue`
- `main/scripts/meta_state.lua` — meta-state временной петли

## Что Сейчас Есть

- рабочая глава `chapter_01`
- модульный Ink-сюжет через `main/story/chapter_01.ink` + `main/story/chapters/*.ink`
- временные петли, итерации, reset iteration и `Continue`
- exploration через hotspots
- data-driven телефон с SMS, почтой, звонками, уликами, камерой и терминалом
- карта `map_v2`, включая hub-режим для выбора маршрута из Ink
- инвентарь с действиями `use`, `inspect`, `read` через Ink-knot contract
- one-shot эффекты Ink: `# sfx`, `# shake`, `# pulse`

## Быстрый Старт

1. Установите Java 17+.
2. Если меняли `.ink`, перекомпилируйте сценарий:

```bash
tools\compile_ink.bat
```

Для Git Bash / Linux:

```bash
./tools/compile_ink.sh
```

3. Для локальной сборки из PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build.ps1 -NoDownload
```

Если `scripts/bob.jar` ещё не лежит в репозитории локально, уберите
`-NoDownload`, и скрипт скачает подходящий `bob.jar` сам.

4. Для запуска в Defold Editor откройте проект и используйте `Project -> Build`
   или `F5`.

## Где Читать Документацию

- [docs/README.md](docs/README.md) — карта документации
- [docs/reference/CODEX_CONTEXT.md](docs/reference/CODEX_CONTEXT.md) — быстрый вход для новой Codex-сессии
- [docs/reference/ARCHITECTURE.md](docs/reference/ARCHITECTURE.md) — текущая архитектура runtime
- [docs/reference/TODO.md](docs/reference/TODO.md) — живой backlog
- [docs/guides/HOW_TO_WRITE_INK.md](docs/guides/HOW_TO_WRITE_INK.md) — правила Ink и поддерживаемые теги

## Важные Caveats

- активный story-loader пока читает `/main/story/chapter_01.json`
- после любых правок `.ink` нужен новый compile
- `main/story/chapters/New/` больше не является рабочей веткой сценария; новый текст уже должен попадать в активные `chapters/*.ink`
- старый GUI и legacy runtime архивированы в `archive/legacy_runtime/` и не являются fallback
- папку `skills/` не трогаем
