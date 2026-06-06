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

## Removing a Quest (Checklist)

To fully remove a quest from the game, do ALL of the following:

1. **`main/scripts/quests.lua`** — delete the quest from `M.quests {}` AND from `phone_order`
2. **`main/story/**/*.ink`** — grep for `quest:start:QUEST_ID` and `quest:done:QUEST_ID` in ALL `.ink` files; remove those tags
3. **`main/gui/modules/ui_manager_v2/dev_jump.lua`** — grep for `QUEST_ID`; if present in `state.quests`, remove it
4. **Save file** — after the above steps, old save files may still contain the quest. The player needs to delete saves or start a new game. If you must add a migration, put `_quests["QUEST_ID"] = nil` in `game_state.deserialize()` but REMOVE it after one release.
5. **Flags** — grep for each flag used in the quest's steps across ALL `.ink` and `.lua`. If a flag is ONLY used by this quest → remove the VAR from `00_bootstrap.ink` and all `set_flag`/`~ flag =` calls. If the flag is shared with other systems (scenes, phone, messenger, etc.) → leave it untouched.

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

## Bugfix Protocol

When the user reports a bug, do NOT guess or theorize. READ the actual source code (`.ink`, `.lua`, `.gui`) that could be relevant BEFORE responding. Trace the exact code path step by step. If you can't find the root cause, ask the user for more specific details (screenshots, save state, dev jump preset). Do not propose fixes without understanding why the current code behaves the way it does.

## TODO / Known Technical Debt

- **Save migration refactor** — `docs/reference/TODO.md` P2 — Архитектура / Рефакторинг
- **Phone quest cards → gui.clone_tree** — `docs/reference/TODO.md` P2
- **Templating для остальных phone-apps** — `docs/reference/TODO.md` P2

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
