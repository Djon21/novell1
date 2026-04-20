---
name: AVOS
description: Canonical project memory for AVOS (runtime architecture, active docs, workflows, pitfalls, and release readiness)
license: MIT
compatibility: opencode
metadata:
  audience: AVOS developers and coding agents
  framework: defold
  language: lua
  project: AVOS
  updated: 2026-04-21
---

## What I do

I am the project-level memory skill for AVOS. Use me to avoid re-reading scattered docs and to start tasks with correct context.

I provide:

- Current runtime architecture (V2 is active, legacy is reference only)
- Source-of-truth files for gameplay systems
- Practical workflows (story, scenes, hotspots, quests, UI)
- Known pitfalls from production fixes
- Documentation map (what is active vs archive)
- Yandex Games release readiness snapshot

---

## When to use me

Use this skill whenever you start work in this repository, especially for:

- Feature implementation touching multiple systems
- Bugfixes in UI/dialogue/scene flow
- Documentation updates
- Onboarding a new session/agent
- Pre-release checks for Yandex Games

Do not use this as the only truth for micro-details; always verify changed files quickly.

---

## Project snapshot (current)

- Engine: Defold
- Story: Ink (`defold-ink`)
- Platform target: HTML5 / Yandex Games
- Active bootstrap: `game.project` -> `/main/main_v2.collectionc`
- Resolution: `1280x720`
- SDK dependency present: `defold-yagames` (dependency configured)
- UI state: modular V2 components active

Key startup files:

- `game.project`
- `main/main_v2.collection`
- `main/gui/ui_manager_v2.script`

---

## Runtime architecture

### Core systems

- `main/scripts/dialogue_manager_ink.lua`
  - Parses Ink output and tags
  - Emits dialogue/choice/end state
  - Supports tags: `flag`, `item:add/remove`, `set_quest`, `sms:add`, `note:add`, `goto_scene`/`explore`, `return_to_scene`, `phone:close`

- `main/scripts/game_state.lua`
  - Single source of truth for gameplay runtime state
  - flags, inventory, quests, current_scene, sms/notes/calls/mail/clues adapters

- `main/scripts/scene_controller.lua`
  - Exploration mode controller
  - Enters scenes, renders hotspots/objects, handles clicks
  - Uses scene stack return flow (not flat last-scene only)

- `main/scripts/scenes.lua`
  - Data-driven scene catalog
  - `hotspots`, `objects`, `condition(gs)`, `visible_when(gs)`, `on_enter`

- `main/scripts/save_manager.lua`
  - Saves both `ink_state` and `game_state`
  - Uses `sys.save()` (HTML5 local storage)

### UI V2

- Orchestrator: `main/gui/ui_manager_v2.script`
- Components in `main/gui/components_v2/`:
  - `main_menu_v2`, `dialogue_v2`, `hotspots_v2`, `nav_buttons_v2`, `hud_v2`, `choice_v2`, `inventory_v2`, `phone_v2`, `map_v2`, `effects`

Render/component order in `main/main_v2.collection` is important.

### Legacy (reference)

- `main/main.collection`
- `main/gui/ui_manager.script`
- `main/gui/components/*`

Legacy is kept for reference/fallback context, not as active runtime.

---

## Data/content map

- Story source: `main/story/chapter_01.ink`
- Story runtime: `main/story/chapter_01.json`
- Story style rules: `main/story/INK_STYLE.md`
- Quests catalog: `main/scripts/quests.lua`
- Items catalog: `main/scripts/items_catalog.lua`
- Backgrounds/atlases: `main/images/*`
- Sounds: `main/sounds/*`

---

## Active docs map

Use `docs/` as the single docs entry.

- `docs/README.md` - top-level docs index
- `docs/guides/` - practical how-to guides
- `docs/planning/` - roadmap/todo/platform requirements
- `docs/internal/` - internal tech references
- `docs/history/` - archive; historical only

Priority reading for coding tasks:

1. `README.md`
2. `docs/planning/TODO.md`
3. `docs/planning/ROADMAP.md`
4. Relevant file in `docs/guides/`
5. For deep UI work: `docs/internal/V2_ARCHITECTURE.md` and `docs/guides/DESIGN_PORT_RULES.md`

---

## Daily workflows

### Story change

1. Edit `main/story/chapter_01.ink`
2. Compile Ink (`tools/compile_ink.bat`)
3. Run in Defold, validate dialogue/choices/tags

### Add or edit scene

1. Edit `main/scripts/scenes.lua`
2. Use F1 hotspot editor in runtime to tune coordinates
3. Re-check locked/visible conditions and returns to dialogue

### Quest update

1. Update quest tags in Ink (`quest:start`, `quest:done`)
2. Update `main/scripts/quests.lua` metadata/steps
3. Verify phone quest view (`phone_v2`) via game_state flow

### UI component changes

1. Update component `.gui` + `.gui_script`
2. Preserve component order in `main/main_v2.collection`
3. Validate z-order, alpha inheritance, dynamic node rendering

---

## Critical implementation rules

1. Do not treat archive docs as current architecture specs.
2. Keep `main_v2.collection` as active unless explicitly changing bootstrap.
3. Avoid parented dynamic GUI nodes when they misrender; prefer absolute placement.
4. For message payloads (`msg.post`), send serializable data only (no functions).
5. Keep scene/quest/item logic data-driven (catalog files first, script glue second).

---

## Yandex Games readiness (snapshot)

Reference: `docs/planning/YANDEX_GAMES_REQUIREMENTS.md`.

Current practical summary:

- Dependency for Yandex SDK is configured.
- Publication checklist still has open items (e.g., final initialization flow checks, release validations, promo materials).
- Use planning checklist as release gate before moderation submission.

---

## Start-of-session checklist for agents

1. Confirm branch and `git status`.
2. Verify bootstrap in `game.project`.
3. Read `README.md` + `docs/README.md`.
4. Read `docs/planning/TODO.md` for current priorities.
5. Read only affected guides/internal docs for touched subsystem.

---

## End-of-task checklist for agents

1. Update affected docs if behavior/API changed.
2. Keep links/path references inside `docs/` valid.
3. If a report is historical and closed, place it in `docs/history/`.
4. Do not leave stale references to legacy UI in active docs.
