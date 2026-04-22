---
name: avos
description: AVOS project complete development guide - architecture, Ink scripting, game state, scenes, content workflow, and integration patterns
license: MIT
compatibility: opencode
metadata:
  audience: AVOS developers
  framework: defold
  language: lua, ink
  project: AVOS visual novel
  updated: 2026-04-21
---

## What I do

I am the **complete development guide** for the AVOS visual novel project. I provide:

- **Project Architecture**: Full understanding of V2 UI system, game state, scene controller, dialogue manager
- **Ink Scripting**: Complete INK_STYLE.md specification with tags, variables, and integration patterns
- **Content Workflow**: How to add backgrounds, sounds, portraits, scenes, items, quests
- **Game State Management**: Flags, inventory, quests, SMS, notes, saves
- **Scene System**: Point-and-click exploration, hotspots, navigation, conditions
- **Integration Patterns**: How Ink, scenes, UI, and game state work together
- **Development Tools**: F1 hotspot editor, Ink compiler, Python generators

## When to use me

**ALWAYS use this skill when:**

- Working on ANY aspect of AVOS project (code, content, scripts)
- Writing or editing Ink scenarios in `main/story/`
- Adding new scenes, items, quests, or game content
- Modifying game state, flags, or inventory system
- Working with scene_controller or dialogue_manager_ink
- Integrating Ink with point-and-click exploration
- Adding backgrounds, sounds, portraits, or other assets
- Debugging game flow, state management, or scene transitions
- Understanding project architecture and data flow
- Creating or modifying UI components (use with defold-gui skill)

**DO NOT use for:**

- Pure GUI/UI work without game logic (use defold-gui skill instead)
- General Defold questions unrelated to AVOS

---

## 🎮 PROJECT OVERVIEW

### What is AVOS?

**АВОСЬ** is a hybrid visual novel with point-and-click adventure elements built on Defold engine.

**Key Features:**
- Non-linear narrative powered by Ink scripting language
- Point-and-click exploration with hotspot system
- RPG mechanics: inventory, quests, choice system (TRUST/INSIGHT/SYNC)
- Interactive phone (SMS, notes, quests)
- Time loops as core narrative mechanic
- Gender choice for protagonist with dynamic text substitution

**Target Platform:** HTML5 (Yandex.Games), PC + mobile devices
**Resolution:** 960×640 (landscape orientation)

---

## 📁 PROJECT STRUCTURE

```
AVOS_S/
├── main/
│   ├── gui/
│   │   ├── components_v2/          # V2 UI system (ACTIVE)
│   │   │   ├── atoms/              # Reusable UI elements
│   │   │   ├── main_menu_v2.gui/.gui_script
│   │   │   ├── hud_v2.gui/.gui_script
│   │   │   ├── dialogue_v2.gui/.gui_script
│   │   │   ├── choice_v2.gui/.gui_script
│   │   │   ├── nav_buttons_v2.gui/.gui_script
│   │   │   ├── inventory_v2.gui/.gui_script
│   │   │   ├── phone_v2.gui/.gui_script
│   │   │   ├── map_v2.gui/.gui_script
│   │   │   ├── hotspots_v2.gui/.gui_script
│   │   │   └── effects.gui/.gui_script
│   │   ├── modules/
│   │   │   └── v2_theme.lua        # Centralized theme
│   │   ├── components/             # Legacy UI (READ-ONLY)
│   │   └── ui_manager_v2.script    # V2 orchestrator
│   ├── scripts/
│   │   ├── dialogue_manager_ink.lua    # Ink → UI engine
│   │   ├── scene_controller.lua        # Point-and-click scenes
│   │   ├── game_state.lua              # Single source of truth
│   │   ├── scenes.lua                  # Scene catalog (data)
│   │   ├── items_catalog.lua           # Item catalog
│   │   ├── quests.lua                  # Quest catalog
│   │   ├── save_manager.lua            # Save/load system
│   │   └── hotspot_editor.lua          # F1 coordinate editor
│   ├── story/
│   │   ├── chapter_01.ink              # Source scenario
│   │   ├── chapter_01.json             # Compiled Ink
│   │   └── INK_STYLE.md                # Ink specification
│   ├── images/                         # Graphics (backgrounds, portraits, atlases)
│   ├── sounds/                         # Audio (SFX, music)
│   └── fonts/                          # Fonts
├── tools/                              # Development utilities
├── .opencode/                          # Architecture docs
├── main_v2.collection                  # V2 collection (ACTIVE)
└── game.project                        # Defold config
```

---

## 🎯 CONTROL FLOW

### Normal Scenario Path:

1. `ui_manager_v2` loads `main/story/chapter_01.json`
2. `dialogue_manager_ink` returns current UI node
3. `ui_manager_v2` decides what to show:
   - dialogue
   - choice
   - end
   - or exploration scene

### Exploration Path:

1. Ink command `enter_scene` transfers control to `scene_controller`
2. `scene_controller` renders scene background / hotspots / objects
3. Hotspot can:
   - Go to another scene
   - Set flag
   - Add/remove item
   - Open ink-knot and return player to dialogue mode

---

## 📊 GAME STATE SYSTEM

### game_state.lua - Single Source of Truth

**Stores:**
```lua
_flags       = {}    -- Boolean/numeric flags
_inventory   = {}    -- List of item_id
_quests      = {}    -- { [quest_id] = "active"|"done"|"failed" }
_current_scene = nil -- Current scene ID
_sms         = {}    -- Messages by contact
_sms_unread  = {}    -- Unread counters
_notes       = {}    -- Notes
```

**API:**
```lua
-- Flags
get_flag(name), set_flag(name, value)

-- Inventory
has_item(id), add_item(id), remove_item(id)
get_inventory() -- returns full list

-- Quests
get_quest(id), set_quest(id, status)

-- Phone
add_sms(contact_id, text), mark_sms_read(contact_id)
add_note(title, body)

-- Reactive subscriptions
subscribe(callback) -- called on any state change

-- Serialization
serialize(), deserialize(data)
```

### Flag Naming Conventions:

- `has_X` - player has item (`has_phone`, `has_mug`)
- `X_seen` - scene/dialogue already happened (`kitchen_intro_seen`)
- `need_X` - intermediate goal activated (`need_mug_for_coffee`)
- `X_done` - action completed (`coffee_drunk`, `left_apartment`)
- `_underscore_prefix` - system flags set by engine (`_phone_return_scene`)

---

## 🗺️ SCENE SYSTEM

### scenes.lua - Scene Catalog

**Scene Structure:**
```lua
scene_id = {
    bg = "bg_name",              -- fullscreen фон. Один dedicated atlas на bg_name
                                 -- в main/images/backgrounds/, регистрируется в
                                 -- ui_manager_v2.script.
    on_enter = { ... },          -- Auto-trigger on first visit
    objects = { ... },           -- Sprites on top of background
    hotspots = { ... },          -- Clickable zones
    exits = {                    -- Navigation (optional)
        W = { scene = "kitchen", label = "Кухня" },
        N = { scene = "bathroom", label = "Ванная" },
    }
}
```

**Hotspot Structure:**
```lua
{
    rect = { x=100, y=200, w=150, h=100 },  -- Click area
    label = "Кофеварка",                     -- Display name
    icon = "\u{e541}",                       -- Material Icons UTF-8
    locked = false,                          -- Disabled state
    condition = function(gs)                 -- Show if true
        return not gs.get_flag("coffee_made")
    end,
    visible_when = function(gs)              -- Hide if false
        return gs.get_flag("kitchen_unlocked")
    end,
    actions = {
        { type = "ink_knot", knot = "make_coffee" },
        { type = "set_flag", flag = "coffee_made", value = true },
        { type = "add_item", item = "mug" },
        { type = "goto_scene", scene = "apartment_hub" },
    }
}
```

**Existing Scenes:**
- `apartment_hub` - apartment corridor (4 hotspots)
- `kitchen` - kitchen (4 hotspots, auto-trigger)
- `bathroom` - bathroom (1 hotspot, auto-trigger)
- `bedroom_day` - bedroom (3 hotspots, 1 object)
- `phone_home` - phone home screen (6 hotspots)

### scene_controller.lua API:

```lua
enter(scene_id)              -- Enter scene
exit()                       -- Exit scene
return_to_last_scene()       -- Return to previous
on_hotspot_click(index)      -- Handle click
serialize(), deserialize()   -- For saves
```

---

## ✍️ INK SCRIPTING SPECIFICATION

### File Skeleton:

```ink
// Variables set by Lua BEFORE first continue:
VAR mc_gender = "male"
VAR mc_name   = "Артём"
VAR npc_name  = "Мила"

// Drama flags for branching:
VAR TRUST   = 0
VAR INSIGHT = 0
VAR SYNC    = 0

// Custom vars for local logic:
VAR coffee_drunk = false

-> wake_intro   // starting knot

=== wake_intro
# bg:bg_bedroom_01 # speaker:mc
Text paragraph. Each paragraph is a separate "click".
-> choose_character
```

### Supported Tags:

**Visual & Audio:**
```ink
# bg:IMAGE              -- Change background (bg:none to remove)
# color:R,G,B           -- Tint background (0..1)
# speaker:ID            -- Speaker name (mc/npc/none/Name)
# sfx:NAME              -- One-shot sound effect
# shake:I,D             -- Screen shake (intensity, duration)
# pulse:D,R,G,B         -- Color flash (RGB 0..255)
```

**Game State:**
```ink
# flag:NAME=VAL         -- Write to game_state
# item:add:ID           -- Add item to inventory
# item:remove:ID        -- Remove item
# quest:start:ID        -- Activate quest (status "active")
# quest:done:ID         -- Complete quest (status "done")
# quest:fail:ID         -- Fail quest
```

**Phone:**
```ink
# sms:add:CONTACT:TEXT  -- Add SMS message
# note:add:TITLE:BODY   -- Add note
# phone:close           -- Exit phone scene
```

**Scenes (Point-and-Click):**
```ink
# explore:SCENE_ID      -- Transfer control to point-and-click
# goto_scene:SCENE_ID   -- Same as explore
# return_to_scene       -- Return to previous scene
```

### VAR vs # flag: - CRITICAL DISTINCTION

**Two parallel state systems:**

1. **`VAR` / `~ assignment`** - Internal Ink variables
   - Visible in `{conditions}` and `{expressions}` inside ink file
   - **NOT visible** in `scenes.lua` and `game_state`

2. **`# flag:X=Y`** - Writes to Lua state (`game_state`)
   - Visible in `scenes.lua` via `gs.get_flag("X")`
   - **NOT visible** from ink conditions

**Rule:**
- Need to branch **inside story** (`{coffee_drunk: ...}`) → use VAR
- Need to open/close **hotspot or hide scene object** → use flag
- Need BOTH → **duplicate**:

```ink
~ coffee_drunk = true
# flag:coffee_drunk=true
```

### Choices:

```ink
* [Check notifications]
    ~ INSIGHT = INSIGHT + 1
    # speaker:none
    Opening app. Three patches in queue.
    -> metro_continue

* [Postpone]
    ~ SYNC = SYNC + 1
    # speaker:mc
    Later. Not now.
    -> metro_continue
```

- `*` - one-time choice (disappears after click)
- `+` - repeatable choice
- Conditional: `* {SYNC >= 2 && INSIGHT >= 2} [<<Synchronize rhythm>>]`

### Gender & Names:

```ink
Woke up{mc_gender == "female":?|?}
In reflection - {mc_gender == "female":female|male} face.
I didn't notice{mc_gender == "female":d|d}.
```

Names auto-substitute: `{mc_name}`, `{npc_name}`

### Integration with Point-and-Click:

**Pattern: "Short monologue from scene"**
```ink
=== take_mug
# speaker:none
In drawer - one clean mug.

# speaker:mc
Will do. Taking it with me.

# flag:has_mug=true
# return_to_scene
-> DONE
```

**Pattern: "Exit from story scene to point-and-click"**
```ink
=== wake_after_choice
# bg:bg_bedroom_03 # speaker:mc
...long monologue...
-> apartment_hub

=== apartment_hub
# bg:bg_apartment # explore:apartment_hub # speaker:mc
Corridor. Quiet.
-> DONE
```

Tag `# explore:apartment_hub` transfers control to `scene_controller` on scene `apartment_hub`. Ink side goes into "waiting" state.

---

## 📦 CONTENT CATALOGS

### items_catalog.lua - Item Catalog

**Item Structure:**
```lua
item_id = {
    name   = "Name",
    type   = "key|consumable|clue",
    source = "where obtained",
    iter   = "#017",
    clue   = "yes|no",
    desc   = "Description",
    verbs  = { "use", "inspect", "combine", "read", "give" },
    icon   = string.char(...),  -- Material Icons UTF-8
    qty    = 1,
}
```

**Existing Items:** mug, phone, key, cup, note, card, usb, cig, cash (9 items)

### quests.lua - Quest Catalog

**Quest Structure:**
```lua
quest_id = {
    name = "Name",
    description = "Description",
    steps = {
        { text = "Step 1", done_when = "flag_name" },
        { text = "Step 2", done_when = "flag_name" },
    },
}
```

**Existing Quests:**
- `reply_anya` - Reply to Anya (2 steps)
- `go_to_office` - Get to office (3 steps)

**Progress:** Function `progress(id, gs)` returns `done_count, total_count, steps_table`

---

## 🎨 CONTENT WORKFLOW

### Adding Backgrounds:

See `docs/guides/HOW_TO_ADD_BACKGROUNDS.md` and architecture in
`docs/reference/BACKGROUND_SYSTEM_MIGRATION_PLAN.md`.

1. Prepare image: JPEG 1920×1080, ~250-350 KB
2. Add to `main/images/bg_<name>.jpg`
3. Create dedicated atlas `main/images/backgrounds/bg_<name>.atlas`
   with `rename_patterns: "bg_<name>=scene_bg"`
4. Register in `main/gui/ui_manager_v2.script`:
   - `go.property("bg_<name>_atlas", resource.atlas(...))`
   - add `bg_<name> = "bg_<name>_atlas"` to `DEDICATED_BG_ATLAS_PROPS`
5. Reference in Ink: `# bg:bg_<name>`

`main/images/backgrounds.atlas` (без подпапки) — legacy, для v2 не используется.

### Adding Sounds:

See `HOW_TO_ADD_SOUNDS.md`

1. Prepare audio: OGG Vorbis, 128 kbps, 44100 Hz
2. Add to `main/sounds/`
3. Create `.sound` descriptor
4. Reference in Ink: `# sfx:sound_name`

### Adding Portraits:

See `HOW_TO_ADD_PORTRAITS.md`

1. Prepare image: PNG 512×512 with transparency
2. Add to `main/images/`
3. Add to `characters.atlas` or `v2.atlas`
4. Auto-detected by name in dialogue_v2

### Adding Scenes:

See `HOW_TO_ADD_SCENES.md`

1. Add scene definition to `main/scripts/scenes.lua`
2. Define background, hotspots, objects
3. Use F1 hotspot editor to set coordinates
4. Reference in Ink: `# explore:scene_id`

---

## 🛠️ DEVELOPMENT TOOLS

### F1 Hotspot Editor (hotspot_editor.lua)

Visual coordinate editor for hotspots:
- **F1** - toggle on/off
- **Tab** - switch hotspot
- **Arrow keys** - move hotspot
- **P** - print coordinates to console

See `F1_HOTSPOT_EDITOR.md`

### Ink Compiler:

```bash
# Windows:
tools\compile_ink.bat

# Linux/macOS:
./tools/compile_ink.sh
```

Compiles `main/story/chapter_01.ink` → `chapter_01.json`

### Python Generators (tools/):

- `gen_bg_menu.py` - generate menu
- `gen_bg_phone_v2.py` - generate phone UI
- `gen_hotspot_sprites.py` - generate hotspot sprites
- `refactor_hud_v2.py` - refactor HUD

---

## 🔄 INTEGRATION PATTERNS

### Pattern: Ink → Scene → Ink

```ink
=== apartment_intro
# bg:bg_apartment # speaker:mc
I'm in the corridor. Time to explore.
# explore:apartment_hub
-> DONE

// Player clicks hotspot "Kitchen" in apartment_hub scene
// Hotspot action: { type = "ink_knot", knot = "enter_kitchen" }

=== enter_kitchen
# bg:bg_kitchen # speaker:mc
Kitchen. Smells like coffee.
# return_to_scene
-> DONE
```

### Pattern: Quest Progress

```ink
// Start quest
# quest:start:make_coffee

// In scene hotspot action:
{ type = "set_flag", flag = "coffee_made", value = true }

// In quest definition (quests.lua):
steps = {
    { text = "Make coffee", done_when = "coffee_made" }
}

// Complete quest
# quest:done:make_coffee
```

### Pattern: Conditional Hotspot

```lua
-- In scenes.lua:
hotspots = {
    {
        label = "Exit door",
        locked = true,
        condition = function(gs)
            return gs.get_flag("coffee_drunk") and gs.has_item("phone")
        end,
        actions = {
            { type = "goto_scene", scene = "world_map" }
        }
    }
}
```

### Pattern: Phone App → Ink

```lua
-- In ui_manager_v2.script:
if app_id == "sms" then
    msg.post("/ink#dialogue_manager", "play_knot", { knot = "phone_sms" })
end
```

```ink
=== phone_sms
# speaker:none
Messages from Anya.

* [Read message]
    # sms:add:anya:"PATCH temporal_sync.module"
    -> phone_sms

* [Back]
    # return_to_scene
    -> DONE
```

---

## 🚨 COMMON PITFALLS

### 1. VAR vs Flag Confusion

**WRONG:**
```ink
~ has_phone = true
// Hotspot condition in scenes.lua won't see this!
```

**CORRECT:**
```ink
~ has_phone = true
# flag:has_phone=true
// Now both Ink and scenes.lua can see it
```

### 2. Quest Complete vs Done

**WRONG:**
```ink
# quest:complete:make_coffee  // NOT SUPPORTED!
```

**CORRECT:**
```ink
# quest:done:make_coffee
```

### 3. Forgetting return_to_scene

**WRONG:**
```ink
=== take_mug
# speaker:mc
Taking mug.
# flag:has_mug=true
-> DONE
// Player stuck! No way back to scene!
```

**CORRECT:**
```ink
=== take_mug
# speaker:mc
Taking mug.
# flag:has_mug=true
# return_to_scene
-> DONE
```

### 4. Hotspot Without Condition

If hotspot should disappear after use, add condition:

```lua
condition = function(gs)
    return not gs.get_flag("mug_taken")
end
```

### 5. Scene Not in scenes.lua

**ERROR:** `explore:unknown_scene` will crash!

Always define scene in `scenes.lua` before referencing in Ink.

### 6. Calling go.* From gui_script Context

`scene_controller._ui.set_background()` is invoked from
`hotspots_v2.gui_script` (gui_script context). From there `go.*` API is
not available — calling it crashes:

```
ERROR:SCRIPT: You can only access go.* functions and values from a
script instance (.script file)
```

`ui_manager_v2.script` works around this: `post_dialogue_background()`
posts `apply_dialogue_bg` message to itself, and `go.set` runs inside
its own `on_message` handler (.script context). Do NOT inline `go.set`
into UI callbacks.

### 7. Adding Background Without Dedicated Atlas

V2 expects each fullscreen `bg_name` to have a dedicated atlas in
`main/images/backgrounds/<bg_name>.atlas` AND a `go.property` +
`DEDICATED_BG_ATLAS_PROPS` entry in `ui_manager_v2.script`. Missing
either piece → background goes black with a warning in console.
The legacy `main/images/backgrounds.atlas` is no longer a fallback for
v2. See `docs/reference/BACKGROUND_SYSTEM_MIGRATION_PLAN.md`.

---

## 📚 KEY DOCUMENTS

**Architecture:**
- `CODEX_CONTEXT.md` - Project map (read first!)
- `ROADMAP.md` - Development roadmap
- `V2_ARCHITECTURE.md` - V2 UI system architecture
- `DESIGN_PORT_RULES.md` - GUI rules (use with defold-gui skill)

**Ink Scripting:**
- `main/story/INK_STYLE.md` - Complete Ink specification (379 lines)

**Content Guides:**
- `HOW_TO_ADD_BACKGROUNDS.md`
- `HOW_TO_ADD_SOUNDS.md`
- `HOW_TO_ADD_PORTRAITS.md`
- `HOW_TO_ADD_SCENES.md`

**Tools:**
- `F1_HOTSPOT_EDITOR.md` - Hotspot coordinate editor

---

## 🎯 DEVELOPMENT WORKFLOW

### 1. Writing Scenario:

```bash
# Edit
main/story/chapter_01.ink

# Compile
tools/compile_ink.bat  # Windows
./tools/compile_ink.sh # Linux/macOS

# Result
main/story/chapter_01.json
```

### 2. Adding Content:

- Backgrounds: Follow HOW_TO_ADD_BACKGROUNDS.md
- Sounds: Follow HOW_TO_ADD_SOUNDS.md
- Portraits: Follow HOW_TO_ADD_PORTRAITS.md
- Scenes: Follow HOW_TO_ADD_SCENES.md

### 3. Testing:

```
1. Open Defold Editor
2. Project → Build (Ctrl+B)
3. Run (F5)
4. Check console for errors
```

### 4. Commit:

```bash
git add .
git commit -m "feat: description"
git push origin AVOS_S
```

---

## 🔧 REACTIVE SYSTEM

game_state notifies subscribers on any change:

```lua
-- Subscribe
gs.subscribe(function()
    -- Update UI
end)

-- Change automatically triggers subscribers
gs.set_flag("has_phone", true)
```

**Used for:**
- Auto-update HUD when inventory changes
- Reactive quest progress
- Phone notification badges
- Scene hotspot visibility

---

## 📊 DATA-DRIVEN DESIGN

**Principle:** Content (scenes, items, quests) described as data in .lua tables, not as code.

**Examples:**
- `scenes.lua` - scenes as tables with hotspots
- `items_catalog.lua` - items as tables with fields
- `quests.lua` - quests as tables with steps

**Benefits:**
- Easy to add new content
- No code changes for new scenes/items
- Can generate from external sources

---

## 🎮 UI MANAGER V2 INTEGRATION

### Modes (base_mode):

```lua
"menu"        -- Main menu (everything hidden except main_menu_v2)
"nav"         -- Navigation (nav_buttons_v2 shown)
"exploration" -- Exploration (hotspots_v2, hud_v2 shown)
"dialogue"    -- Dialogue (dialogue_v2 shown, hotspots hidden)
"choice"      -- Choice (choice_v2 shown over dialogue)
```

### Overlays (overlay_mode):

```lua
"inventory"   -- Inventory open
"phone"       -- Phone open
"map"         -- Map open
nil           -- No overlay
```

### Key Methods:

```lua
show_menu()
show_exploration()
show_dialogue()
show_nav()
hide_nav()

open_inventory()
close_inventory()
open_phone()
close_phone()
open_map()
close_map()

render_dialogue(data)
show_choice(data)
hide_choice()
```

---

## 🎨 WORKING WITH GUI

For GUI-specific work (creating components, styling, layouts), **use the defold-gui skill** in combination with this skill.

**This skill (avos):** Game logic, Ink integration, state management, content workflow
**defold-gui skill:** GUI creation, V2 theme, alpha inheritance, dynamic nodes, z-order

---

## ✅ CHECKLIST: Adding New Feature

- [ ] Read relevant documentation (ROADMAP.md, INK_STYLE.md, etc.)
- [ ] Understand data flow (Ink → game_state → scene_controller → UI)
- [ ] Add data definitions (scenes.lua, items_catalog.lua, quests.lua)
- [ ] Write Ink scenario with proper tags
- [ ] Compile Ink (tools/compile_ink.bat)
- [ ] Add assets (backgrounds, sounds, portraits)
- [ ] Test in Defold (F5)
- [ ] Check console for errors
- [ ] Use F1 hotspot editor if needed
- [ ] Commit with descriptive message

---

## 🚀 QUICK REFERENCE

**Current Bootstrap:** `game.project` → `main_v2.collection`
**Active UI:** V2 system (`components_v2/`, `ui_manager_v2.script`)
**Legacy UI:** Read-only (`components/`, `ui_manager.script`)
**Branch:** AVOS_S
**Resolution:** 960×640
**Platform:** HTML5 (Yandex.Games)

**Key Files:**
- `main/gui/ui_manager_v2.script` - UI orchestrator
- `main/scripts/dialogue_manager_ink.lua` - Ink engine
- `main/scripts/scene_controller.lua` - Scene engine
- `main/scripts/game_state.lua` - State management
- `main/scripts/scenes.lua` - Scene catalog
- `main/story/chapter_01.ink` - Main scenario
- `main/story/INK_STYLE.md` - Ink specification

---

**Last Updated:** 2026-04-21
**Author:** OpenCode AI + AVOS Team
