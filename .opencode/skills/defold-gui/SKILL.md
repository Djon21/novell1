---
name: defold-gui
description: AVOS project GUI standards - Defold V2 UI system, design port rules, theme system, battle-tested patterns, and official Defold GUI best practices
license: MIT
compatibility: opencode
metadata:
  audience: AVOS developers
  framework: defold
  language: lua
  project: AVOS visual novel
  updated: 2026-04-20
---

## What I do

I am the **authoritative source** for AVOS GUI development standards and Defold GUI best practices. I enforce:

- **DESIGN_PORT_RULES.md**: Battle-tested rules from real bugs (with commit references)
- **V2 Theme System**: Color palette, fonts, layout constants from `v2_theme.lua`
- **Component Architecture**: Modular V2 system in `main/gui/components_v2/`
- **Alpha Inheritance Rules**: The #1 cause of invisible nodes - I prevent this
- **Dynamic Node Patterns**: Absolute positioning, no parenting, explicit z-order
- **Message Passing**: Serialization rules, URL formats, clean data structures
- **Visual Novel Patterns**: Dialogue, portraits, choices, inventory, phone UI
- **Official Defold GUI Practices**: Layouts, node types, rendering optimization, input handling

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
- Working with GUI layouts for different screen sizes/orientations
- Optimizing GUI rendering and draw calls
- Implementing GUI scripts and input handling

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

---

## 📚 OFFICIAL DEFOLD GUI BEST PRACTICES

### GUI Component Structure

**Creating GUI Components:**

1. GUI components are created from `.gui` files (scene prototypes)
2. Each GUI component must be attached to a game object in a collection
3. GUI components render independently of game view (by default on top)
4. GUI components don't have visual representation in collection editor

**GUI Properties:**

- `Script`: GUI script bound to this component
- `Material`: Material used for rendering (can have multiple materials per GUI)
- `Adjust Reference`: Controls node adjust mode calculation (`Per Node` or `Disable`)
- `Max Nodes`: Maximum number of nodes for this GUI
- `Max Dynamic Textures`: Max textures created via `gui.new_texture()`

### Node Types and Usage

**Box Nodes:**
- Rectangular nodes with color, texture, or flipbook animation
- Always rendered even without texture (assign textures for proper batching!)
- Support Slice-9 texturing for scalable UI elements
- Tint color multiplies onto image data (white = no tint)

**Text Nodes:**
- Display text with font resources
- Alignment controlled by pivot: Center/West/East
- Line Break property for multi-line text
- Leading (line spacing) and Tracking (letter spacing) properties

**Pie Nodes:**
- Circular/ellipsoid nodes, can be partially filled or inverted
- Inner Radius, Outer Bounds, Perimeter Vertices properties
- Pie Fill Angle controls fill amount

**Template Nodes:**
- Instances based on other GUI scene files
- Reusable GUI components

**ParticleFX Nodes:**
- Play particle effects in GUI

### Node Properties Deep Dive

**Pivot Point:**
- Center point for rotation, scaling, size changes
- Options: Center, North, South, East, West, NE, NW, SE, SW
- Changing pivot moves node so new pivot is at node's position
- Text alignment: Center = center-aligned, West = left, East = right

**Anchoring (X/Y Anchor):**
- Controls position when scene/parent boundaries stretch
- `None`: Keeps position from center relative to adjusted size
- `Left/Right` (X): Scales horizontal position to keep percentage from edges
- `Top/Bottom` (Y): Scales vertical position to keep percentage from edges

**Adjust Mode:**
- Controls what happens when scene/parent boundaries adjust to screen
- `Fit`: Content fits inside stretched bounding box (smallest dimension)
- `Zoom`: Content covers stretched bounding box (largest dimension)
- `Stretch`: Content fills stretched bounding box completely
- Ignored if GUI's `Adjust Reference` is `Disabled`

**Practical Example - Pivot, Anchors, Adjust Mode:**

For a 640x1136 UI that needs to adapt to wider screens:
1. Top/bottom panels: Pivot North/South, Adjust Mode Stretch, X Anchor Left/Right
2. Side elements: Set X Anchor to Left/Right, Pivot to West/East
3. Center elements: Pivot Center, Anchors None for relative positioning

### Draw Order and Rendering

**Within one .gui file:**
- Nodes render in list order (top = first/behind, bottom = last/front)
- Z-value doesn't control order (but affects render range)
- Use Alt+Up/Down to reorder nodes
- Parents drawn before children

**Between GUI components:**
- Z is IGNORED between components in same game object
- Render order = component order in game object
- Use Layers to override draw order within a GUI

**Layers for Optimization:**
- Group nodes by type, texture, blend mode, font for batching
- Assign layers to control draw order independent of hierarchy
- Child nodes inherit parent's layer if unset
- "null" layer drawn before any named layer
- Reduces draw calls significantly

**Example Layer Setup:**
```
Layer "graphics": all button backgrounds
Layer "text": all button text
Result: 2 draw calls instead of 6 (for 3 buttons)
```

### GUI Layouts for Multiple Resolutions

**Display Profiles:**
- Define in `.display_profiles` file (or use builtins)
- Each profile has Width, Height, Device Models qualifiers
- Device Models: comma-separated, matches start of model name
- Example: `"iPhone10,3", "iPhone10,6"` for iPhone X

**Auto Layout Selection:**
- ON (default): Engine automatically selects best matching layout
- OFF: Use `gui.set_layout()` manually from script
- Scoring: based on area and aspect ratio differences
- Orientation matching: landscape/portrait preference

**Creating Layouts:**
- Right-click Layouts in Outline → Add → Layout
- Each layout overrides properties from Default layout
- Overridden properties marked in blue
- Layouts cannot add/remove nodes, only override properties

**Layout Change Messages:**
```lua
function on_message(self, message_id, message, sender)
  if message_id == hash("layout_changed") then
    -- message.id contains hashed layout id
    if message.id == hash("Portrait") then
      -- handle portrait layout
    end
  end
end
```

**Manual Layout Control:**
```lua
-- Set layout manually (when Auto Layout Selection is OFF)
local ok = gui.set_layout("Portrait")  -- returns true if exists

-- Get all available layouts
local layouts = gui.get_layouts()  -- returns {id_hash = vector3(w,h,0)}
```

### GUI Scripts

**Script Lifecycle:**
```lua
function init(self)
  -- Initialization, call msg.post(".", "acquire_input_focus") if using on_input
end

function final(self)
  -- Cleanup
end

function update(self, dt)
  -- Per-frame updates
end

function on_message(self, message_id, message, sender)
  -- Handle messages
end

function on_input(self, action_id, action)
  -- Handle input (requires acquire_input_focus)
end

function on_reload(self)
  -- Hot reload handling
end
```

**Important Notes:**
- GUI scripts use `gui.*` namespace, NOT `go.*`
- Attempting to use `go.*` functions will cause error
- Message passing works like any script component
- Address GUI: `msg.post("hud#gui", "message", data)`

**Node Addressing:**
```lua
-- Static nodes (from .gui file)
local node = gui.get_node("node_id")

-- Dynamic nodes (created at runtime)
local new_node = gui.new_box_node(pos, size)
-- Keep reference! Dynamic nodes have no id by design
```

**Dynamic Node Creation:**
```lua
-- Create from scratch
local box = gui.new_box_node(vmath.vector3(x, y, z), vmath.vector3(w, h, 0))
local text = gui.new_text_node(vmath.vector3(x, y, z), "Hello")

-- Clone existing
local clone = gui.clone(original_node)
local tree = gui.clone_tree(root_node)  -- returns table of cloned nodes
```

### Slice-9 Texturing

**When to Use:**
- Panels/dialogs that resize to fit content
- Health bars that scale
- Any UI element that needs context-sensitive sizing

**How It Works:**
- Define 4 margins (left, top, right, bottom) in pixels
- Corners never scale
- Edges scale along one axis only
- Center scales both axes

**Important:**
- Only applied when changing node SIZE, not SCALE
- For Sprites: Image Trim Mode must be OFF
- Avoid scaling down segments below original size (mipmap artifacts)

**Slice9 Property Format:**
```
Slice9: left, top, right, bottom (clockwise from left)
```

### Input Handling

**Acquiring Input Focus:**
```lua
function init(self)
  msg.post(".", "acquire_input_focus")
end

function on_input(self, action_id, action)
  if action_id == hash("touch") and action.pressed then
    local node = gui.get_node("button")
    if gui.pick_node(node, action.x, action.y) then
      -- Handle button press
    end
  end
end
```

**Important:** `gui.pick_node()` checks geometry only, ignores `enabled` flag and alpha!

**Safe Pick Pattern:**
```lua
if gui.is_enabled(node) and gui.pick_node(node, action.x, action.y) then
  -- Safe to interact
end
```

### Runtime Property Manipulation

**Get/Set GUI Resources:**
```lua
-- Fonts
go.get("#gui", "fonts", { key = "default" })
go.set("#gui", "fonts", font_resource, { key = "default" })

-- Materials
go.get("#gui", "materials", { key = "effect" })
go.set("#gui", "materials", material_resource, { key = "effect" })

-- Textures (atlases)
go.get("#gui", "textures", { key = "theme" })
go.set("#gui", "textures", atlas_resource, { key = "theme" })
```

### Performance Optimization

**Batching Rules:**
Nodes batch together when they share:
- Same node type
- Same atlas/tile source
- Same blend mode
- Same font (for text)

**Breaking Batches:**
- Different node types
- Clipping nodes (always break batch)
- Each stencil scope breaks batch
- Mixed node types in hierarchy

**Optimization Strategy:**
1. Use layers to group similar nodes
2. Assign textures to all box nodes (even invisible ones)
3. Minimize node type mixing
4. Use same atlas for related graphics
5. Group text nodes by font

### Common Pitfalls

1. **Box nodes without textures** - Always assign texture for proper batching
2. **Forgetting acquire_input_focus** - Input won't work without it
3. **Using go.* in GUI scripts** - Use gui.* namespace only
4. **Scaling instead of sizing for Slice-9** - Change SIZE property, not SCALE
5. **Picking disabled nodes** - Always check `gui.is_enabled()` before `gui.pick_node()`
6. **Dynamic nodes without references** - Keep references, they have no ids
7. **Z-order between components** - Use component order in game object, not z-values

---

## 🔧 AVOS-SPECIFIC PATTERNS
