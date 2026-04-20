---
name: defold-gui
description: AVOS project GUI standards - Defold V2 UI system, design port rules, theme system, and battle-tested patterns
license: MIT
compatibility: opencode
metadata:
  audience: AVOS developers
  framework: defold
  language: lua
  project: AVOS visual novel
---

## What I do

I am the **authoritative source** for AVOS GUI development standards. I enforce:

- **DESIGN_PORT_RULES.md**: Battle-tested rules from real bugs (with commit references)
- **V2 Theme System**: Color palette, fonts, layout constants from `v2_theme.lua`
- **Component Architecture**: Modular V2 system in `main/gui/components_v2/`
- **Alpha Inheritance Rules**: The #1 cause of invisible nodes - I prevent this
- **Dynamic Node Patterns**: Absolute positioning, no parenting, explicit z-order
- **Message Passing**: Serialization rules, URL formats, clean data structures
- **Visual Novel Patterns**: Dialogue, portraits, choices, inventory, phone UI

## When to use me

**ALWAYS use this skill when:**

- Creating ANY new GUI component in `main/gui/components_v2/`
- Debugging invisible nodes, positioning issues, or z-order problems
- Porting HTML/CSS designs to Defold GUI
- Working with dynamic node creation (inventory slots, choice buttons, etc.)
- Implementing modals, overlays, or multi-layer UI
- Using texture atlases and sprite animations
- Handling Cyrillic text (UTF-8 string operations)
- Setting up message passing between components

**DO NOT use for:**
- Legacy UI in `main/gui/components/` (read-only, do not modify)
- Non-GUI Lua scripting (use general Lua skills)
- Game logic outside of UI layer

---

## 🚨 CRITICAL RULES (from DESIGN_PORT_RULES.md)

These are **battle-tested rules** from real production bugs. Follow them religiously.

### Rule #1: Alpha Inheritance - The Main Trap

**Problem:** Component renders (backdrop darkens screen) but all content is invisible.

**Cause:** In Defold: `effective_alpha(child) = inherit_alpha ? parent.alpha * child.alpha : child.alpha`

If parent has `color.w = 0.0` and child has `inherit_alpha: true`, child gets `alpha = 0`.

**MANDATORY PATTERNS:**

```lua
-- ✅ CORRECT: Root container (grouping node)
nodes {
  position { x: 0.0 y: 0.0 z: 0.4 }
  size { x: 0.0 y: 0.0 }           -- Does not render itself
  color { x: 0.0 y: 0.0 z: 0.0 w: 1.0 }  -- w=1.0 !!!
  type: TYPE_BOX
  id: "dlg_root"
  inherit_alpha: true
}

-- ❌ WRONG: Root with w=0.0 kills all children
nodes {
  color { x: 0.0 y: 0.0 z: 0.0 w: 0.0 }  -- w=0.0 = invisible children!
  inherit_alpha: true
}

-- ✅ CORRECT: Backdrop with dimming
nodes {
  position { x: 0.0 y: 0.0 z: 0.40 }
  color { x: 0.027 y: 0.023 z: 0.102 w: 0.55 }  -- Dimming
  type: TYPE_BOX
  id: "backdrop"
  inherit_alpha: false  -- Children must NOT inherit this 0.55!
}

-- ✅ CORRECT: Modal content (child of backdrop)
nodes {
  position { x: 20.0 y: 40.0 z: 0.50 }
  color { x: 0.047 y: 0.039 z: 0.141 w: 0.98 }
  type: TYPE_BOX
  id: "modal"
  inherit_alpha: false  -- Does NOT inherit backdrop's 0.55
}
```

**Commits:** `2e4501b`, `5048df8`, `26c5113`, `de3de5f`

---

### Rule #2: Dynamic Nodes MUST NOT Use gui.set_parent()

**Problem:** `gui.new_box_node()` + `gui.set_parent()` = node is enabled, alpha=1, but INVISIBLE. Clicks work (`gui.pick_node` succeeds) but nothing renders.

**MANDATORY PATTERN:**

```lua
-- ❌ WRONG: Parenting dynamic nodes (DOES NOT RENDER)
local bg = gui.new_box_node(vmath.vector3(0, y_local, 0.63), size)
gui.set_parent(bg, gui.get_node("opts_panel"))

-- ✅ CORRECT: Absolute coordinates, no parent
local PANEL_X = 160  -- From .gui file
local PANEL_Y = 160
local bg = gui.new_box_node(
    vmath.vector3(PANEL_X + 0, PANEL_Y + y_local, 0.63),
    size
)
-- NO gui.set_parent() call!
```

**Why:** Defold's dynamic node rendering has a bug with parented nodes. Use absolute screen coordinates.

**Commits:** `4440f85`, `68c0c31`

---

### Rule #3: Z-Order Between Components

**Inside one .gui file:** z-order works normally (higher z = on top).

**Between GUI components in same GO:** z is IGNORED. Render order = component order in GO.

**MANDATORY ORDER in main_v2.collection:**

```
1. ui_manager_v2 (script only)
2. main_menu_v2       (fullscreen menu, hidden during game)
3. dialogue_v2        (contains scene_bg - room background)
4. hotspots_v2        (above background)
5. nav_buttons_v2     (navigation arrows)
6. hud_v2             (BAG/PHN badges)
7. choice_v2          (modal overlays)
8. inventory_v2       (modal)
9. phone_v2           (modal)
10. map_v2            (modal)
11. effects           (scan/grain/vignette, topmost)
```

**Z-Index Ranges:**
- `0.06-0.07`: Scene backgrounds
- `0.40-0.45`: Backdrops (dimming)
- `0.50-0.57`: Modal content
- `0.60-0.70`: Effects overlay

**Commit:** `fc21c07`

---

### Rule #4: Dynamic Nodes Need Explicit Z

**Problem:** Dynamic node created but invisible, even though enabled=true.

**Cause:** `gui.new_box_node(vmath.vector3(x, y, 0), ...)` defaults to z=0. If static nodes have z>0 (e.g., scene_bg z=0.06), dynamic nodes render UNDER them.

**MANDATORY:**

```lua
-- ❌ WRONG: Default z=0
local node = gui.new_box_node(vmath.vector3(x, y, 0), size)

-- ✅ CORRECT: Explicit z
local node = gui.new_box_node(vmath.vector3(x, y, 0.55), size)
```

**Commit:** `30ab28e`

---

### Rule #5: msg.post() Cannot Serialize Functions

**Problem:** `ERROR:SCRIPT: unsupported value type in table: function`

**Cause:** Tables from `scenes.lua` often contain `visible_when = function(gs) ... end`. Passing to `msg.post()` crashes.

**MANDATORY PATTERN:**

```lua
-- ❌ WRONG: Sending table with functions
local hotspot = scenes[scene_id].hotspots[1]  -- Contains visible_when function
msg.post(target, "set_hotspot", { data = hotspot })  -- CRASH!

-- ✅ CORRECT: Clean serializable data
local clean = {
    rect   = data.rect and { x=data.rect.x, y=data.rect.y, w=data.rect.w, h=data.rect.h } or nil,
    label  = data.label,
    icon   = data.icon,
    locked = data.locked and true or false,
}
msg.post(target, "set_hotspot", { index = i, data = clean })
```

**Allowed types:** `string`, `number`, `boolean`, `nil`, flat tables, `vmath.vector3/4`, `hash`

**Forbidden:** functions, userdata, upvalues, metatables

**Commit:** `55d575f`

---

### Rule #6: Texture Atlas Usage

**Pattern:**

```lua
-- In .gui file:
textures {
  name: "v2"
  texture: "/main/images/v2.atlas"
}

-- In script:
local node = gui.get_node("portrait_bg")
gui.set_texture(node, "v2")           -- Assigns atlas resource
gui.play_flipbook(node, "artem")      -- Shows specific frame
gui.set_enabled(node, true)
```

**Filter "none" backgrounds:**

```lua
if not bg_name or bg_name == "" or bg_name == "none" then 
    return 
end
gui.play_flipbook(bg_node, bg_name)
```

**Commits:** `96afd02`, `e70e52a`

---

### Rule #7: Input Focus Required

If component has `function on_input(self, ...)`, it MUST call:

```lua
function init(self)
    msg.post(".", "acquire_input_focus")
    -- ... rest of init
end
```

Without this, input events never arrive.

**Commit:** `fc21c07`

---

### Rule #8: gui.pick_node() Works on Disabled Nodes

`gui.pick_node()` checks geometry only, NOT `enabled` flag or alpha.

**MANDATORY CHECK:**

```lua
-- ❌ WRONG: Picks disabled nodes
if gui.pick_node(node, action.x, action.y) then
    -- Fires even if node is disabled!
end

-- ✅ CORRECT: Check enabled first
if gui.is_enabled(node) and gui.pick_node(node, action.x, action.y) then
    -- Safe
end
```

**Commit:** `55d08ee`

---

## 🎨 V2 THEME SYSTEM (v2_theme.lua)

**ALWAYS use theme constants. NEVER hardcode colors/fonts.**

### Color Palette

```lua
local theme = require "main.gui.modules.v2_theme"

-- Dark backgrounds (ink layers)
theme.COLORS.ink_0        -- #07061a (darkest)
theme.COLORS.ink_1        -- #0c0a24
theme.COLORS.ink_2        -- #171232
theme.COLORS.frame        -- #221947

-- Text (beige paper)
theme.COLORS.paper        -- #f3ecd9 (main text)
theme.COLORS.paper_soft   -- 70% alpha
theme.COLORS.paper_medium -- 50% alpha
theme.COLORS.paper_dim    -- #c9c0a8 (dimmed)
theme.COLORS.paper_faint  -- 30% alpha

-- Accents
theme.COLORS.accent       -- #7df9ff (cyan)
theme.COLORS.accent_soft  -- 70% alpha
theme.COLORS.accent_dim   -- 30% alpha
theme.COLORS.accent_hot   -- #ff3d7f (magenta)
theme.COLORS.amber        -- #ffb347
theme.COLORS.violet       -- #7a5cff
theme.COLORS.stamp        -- #c8142a (red stamp)
theme.COLORS.crt_green    -- #5aff7a (narrator CRT mode)
```

### Fonts

```lua
-- JetBrains Mono (UI/technical)
theme.FONTS.mono_10       -- "jb_mono_10"
theme.FONTS.mono_12       -- "jb_mono_12"
theme.FONTS.mono_bold_14  -- "jb_mono_bold_14"

-- Unbounded (titles/buttons)
theme.FONTS.title_20      -- "unbounded_bold_20"
theme.FONTS.title_32      -- "unbounded_bold_32"

-- Caveat (handwritten notes)
theme.FONTS.caveat_18     -- "caveat_18"

-- Manrope (body text)
theme.FONTS.body_14       -- "manrope_14"
theme.FONTS.body_16       -- "manrope_16"

-- Material Icons
theme.FONTS.icons         -- "icons"
```

### Semantic Roles

```lua
-- Apply role to node:
theme.apply(gui.get_node("title"), "title")

-- Available roles:
"title"         -- Large screen titles (Unbounded 32, paper)
"title_large"   -- Extra large (Unbounded 72, paper)
"button"        -- Menu buttons (Unbounded 20, paper)
"body"          -- Dialogue text (Manrope 16, paper)
"body_small"    -- Small descriptions (Manrope 14, paper_soft)
"mono"          -- HUD/timers (JB Mono 12, paper_soft)
"mono_small"    -- Tiny technical (JB Mono 10, paper_medium)
"mono_accent"   -- Highlighted mono (JB Mono 12, accent)
"eyebrow"       -- Supertitle (JB Mono 10, accent)
"caveat"        -- Handwritten notes (Caveat 18, amber)
"stamp"         -- Red stamp text (JB Mono stamp, stamp red)
"hint_hot"      -- Magenta hint (JB Mono 10, accent_hot)
"hint_amber"    -- Amber hint (JB Mono 10, amber)
"hint_violet"   -- Violet hint (JB Mono 10, violet)
"hint_cyan"     -- Cyan hint (JB Mono 10, accent)
```

### Layout Constants

```lua
theme.LAYOUT.screen_w = 960
theme.LAYOUT.screen_h = 640
theme.LAYOUT.hud_strip_h = 32
theme.LAYOUT.corner_size = 22
theme.LAYOUT.portrait_size = 96
theme.LAYOUT.inv_slot_size = 96
theme.LAYOUT.nav_btn_size = 112
```

### Animation Presets

```lua
local anim = theme.ANIM.fade_in_fast
gui.animate(node, "color.w", 1.0, anim.easing, anim.duration)

-- Available presets:
theme.ANIM.fade_in_fast   -- 0.25s OUTCUBIC
theme.ANIM.fade_in_slow   -- 0.7s OUTCUBIC
theme.ANIM.hover          -- 0.18s OUTQUAD
theme.ANIM.click_press    -- 0.08s OUTQUAD
```

---

## 📐 COMPONENT CREATION CHECKLIST

When creating a new V2 component, follow this exact order:

### 1. Read Source Material
- [ ] Read corresponding `*_mobile.html` from `Downloads/AVOS (14)/`
- [ ] If HTML missing, ASK USER - do not guess

### 2. Plan Structure
- [ ] List static nodes (in .gui file)
- [ ] List dynamic nodes (created in script)
- [ ] Check font/icon availability (Material Icons codepoints)
- [ ] Design hierarchy with alpha-inheritance in mind (Rule #1)

### 3. Choose Z-Values
- [ ] Pick z-range that doesn't conflict with other components
- [ ] Document z-values in component header comment

### 4. Create .gui File
- [ ] Add all required fonts in `fonts { }` section
- [ ] Add all required textures in `textures { }` section
- [ ] Create root container: `size 0×0, color.w=1.0, inherit_alpha: true`
- [ ] Set `script: "/main/gui/components_v2/xxx_v2.gui_script"`
- [ ] Set `max_nodes: 512` (or higher if needed)

### 5. Create .gui_script File
- [ ] `require "main.gui.modules.v2_theme"` at top
- [ ] In `init()`: call `msg.post(".", "acquire_input_focus")` if using `on_input()`
- [ ] In `init()`: call `gui.get_node()` for all static nodes
- [ ] Dynamic nodes: use absolute coordinates, explicit z (Rules #2, #4)
- [ ] Message handlers: clean data before `msg.post()` (Rule #5)

### 6. Add to Collection
- [ ] Add component to `main/main_v2.collection` in correct order (Rule #3)
- [ ] Verify z-order and render order

### 7. Wire to UI Manager
- [ ] Add show/hide handlers in `ui_manager_v2.script`
- [ ] Add event routing (button clicks, etc.)

### 8. Test
- [ ] Visual smoke test in Defold
- [ ] Compare with HTML mockup
- [ ] Test all interactive elements
- [ ] Check on different screen sizes (if applicable)

### 9. Commit
- [ ] Commit with prefix: `feat(v2): add xxx_v2 component`
- [ ] Reference any related issues/docs

---

## 🐛 DEBUGGING METHODOLOGY

When something doesn't work, follow this sequence:

### 1. Force Enable
```lua
gui.set_enabled(node, true)  -- Force on
```

### 2. Paint Bright
```lua
gui.set_color(node, vmath.vector4(1, 0, 1, 1))  -- Magenta
gui.set_size(node, vmath.vector3(960, 640, 0))  -- Fullscreen
```

### 3. Log Everything
```lua
print("[component] node:", node)
print("[component] pos:", gui.get_screen_position(node))
print("[component] color:", gui.get_color(node))
print("[component] enabled:", gui.is_enabled(node))
print("[component] size:", gui.get_size(node))
```

### 4. Check Alpha Chain
Walk from node to root, multiply all alphas:
```lua
local function debug_alpha_chain(node)
    local alpha = 1.0
    local current = node
    while current do
        local color = gui.get_color(current)
        local inherit = gui.get_inherit_alpha(current)
        print(string.format("[alpha] %s: color.w=%.2f inherit=%s", 
            gui.get_id(current), color.w, tostring(inherit)))
        if inherit then
            alpha = alpha * color.w
        end
        current = gui.get_parent(current)
    end
    print("[alpha] effective:", alpha)
end
```

### 5. Check Z and Order
- [ ] Log z-value of node
- [ ] Check component order in collection
- [ ] Verify no other component overlaps

### 6. Check Pick vs Render
If `gui.pick_node()` works but node invisible = alpha/z/parent issue (Rules #1, #3, #4)

---

## 🔧 AVOS-SPECIFIC PATTERNS
