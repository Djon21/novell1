# AGENTS.md

## Project

Defold engine narrative point-and-click / visual novel. Russian language. Yandex Games SDK.

## Critical Commands

```bash
# After ANY .ink edit:
tools\compile_ink.bat chapter_01

# Build (requires Java 17+):
powershell -ExecutionPolicy Bypass -File .\scripts\build.ps1 -NoDownload

# CI lint:
python tools/ink_lint.py --ci
```

## Architecture

- Entry: `game.project → /main/main_v2.collectionc`
- UI orchestrator: `main/gui/ui_manager_v2.script` (~975 lines) → modules in `main/gui/modules/ui_manager_v2/`
- State facade: `main/scripts/game_state.lua` (~532 lines) → channels in `main/scripts/state/`
- Scene facade: `main/scripts/scenes.lua` (~75 lines) → scenes in `main/data/scenes/`
- Story pipeline: `main/story/chapter_01.ink` + `INCLUDE chapters/*.ink` → compile → `main/story/chapter_01.json`
- `chapter_01.ink` must only contain `INCLUDE` directives — no text/VAR/knots

## Gotchas

- Runtime loads ONE file: `/main/story/chapter_01.json`. After .ink edits, recompile.
- `main/story/chapters/New/` is NOT active. New text goes in `chapters/*.ink`.
- Legacy runtime in `archive/legacy_runtime/` is NOT a fallback.
- `skills/` directory is off-limits.
- Ink tag typos fail silently. Use exact tags from `docs/guides/HOW_TO_WRITE_INK.md`.
- `quest:complete` is invalid. Use `quest:done:ID`.
- `# return_to_scene` must be LAST tag before `-> DONE`.
- Phone is Lua overlay, not Ink scene. Never write static phone screens in Ink.
- `game_state.quests` is run-state only. Use `meta_state` for cross-iteration memory.
- Inventory knot resolution order: `inv_<scene>_<verb>_<item>` → `inv_<verb>_<item>` → fallbacks.
- Combine pairs sort lexically: `inv_combine_<low>_with_<high>`.
- Backgrounds require dedicated atlas + `go.property` + `DEDICATED_BG_ATLAS_PROPS` registration in `ui_manager_v2.script`.

## Where Things Live

| What | Path |
|---|---|
| Ink story | `main/story/chapter_01.ink`, `main/story/chapters/*.ink` |
| Scenes | `main/data/scenes/*.lua` |
| Items | `main/scripts/items_catalog.lua` |
| Quests | `main/scripts/quests.lua` |
| Phone contacts | `main/scripts/phone_contacts.lua` |
| GUI components | `main/gui/components_v2/` |
| Backgrounds | `main/images/backgrounds/*.atlas` |
| Phone assets | `main/images/phone/` |
| Localization | `main/data/strings/{ru,en,tr}.json` |
| Logs | `main/scripts/log.lua` (error/warn/info/debug/trace) |

## Documentation

Read in order: `README.md` → `docs/reference/CODEx_CONTEXT.md` → `docs/reference/ARCHITECTURE.md` → `docs/guides/HOW_TO_WRITE_INK.md`

Detailed UI module map: `docs/reference/UI_MANAGER_V2_ARCHITECTURE.md`
