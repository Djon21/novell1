# АВОСЬ

`AVOS_S` — narrative point-and-click / visual novel на Defold.

Текущий runtime уже работает через `v2`-стек:

- Ink отвечает за диалоги и ветвления
- `scene_controller.lua` отвечает за exploration-сцены
- `game_state.lua` отвечает за runtime-state текущего прохождения
- `save_manager.lua` хранит persisted run-state
- `meta_state.lua` хранит долгую прогрессию временной петли
- `ui_manager_v2.script` и `main/gui/components_v2/` отвечают за интерфейс

## Что уже есть

- активный bootstrap: `game.project -> /main/main_v2.collectionc`
- рабочая глава `chapter_01`
- старт новой итерации через меню
- возврат в меню после конца главы
- `Continue` для незавершённого прохождения
- meta-state между циклами: `iteration_number`, `completed_iterations`, `loop_awareness`

## Быстрый старт

1. Откройте проект в Defold Editor.
2. Если меняли `.ink`, перекомпилируйте сценарий:

```bash
# Windows
tools\compile_ink.bat

# Linux/macOS
./tools/compile_ink.sh
```

3. Запустите `Project -> Build` или `F5`.

## Где читать документацию

Подробная навигация по docs собрана в `docs/README.md`.

### Читать первым

- `docs/reference/CODEX_CONTEXT.md`
- `docs/reference/ARCHITECTURE.md`
- `docs/reference/LOOP_SYSTEM.md`
- `main/story/README_INK.md`

### Практические гайды

- `docs/guides/HOW_TO_ADD_SCENES.md`
- `docs/guides/HOW_TO_ADD_BACKGROUNDS.md`
- `docs/guides/HOW_TO_ADD_PORTRAITS.md`
- `docs/guides/HOW_TO_ADD_SOUNDS.md`

## Важные caveats

- активный story-loader пока жёстко читает только `main/story/chapter_01.json`
- после правок `.ink` обязательно нужен новый compile
- bulk compile пропускает `*_old.ink`, чтобы архивные story-черновики не создавали лишние `.json`
- one-shot Ink-эффекты `# sfx`, `# shake`, `# pulse` уже подключены к активному `v2` runtime через `dm.get_effects()`; новые SFX нужно добавлять и в `sfx_player`, и в `M.SFX_URLS` в `ui_manager_v2.script`

## Legacy

Старый GUI и legacy runtime больше не являются fallback-веткой. Они архивированы в `archive/legacy_runtime/`.
