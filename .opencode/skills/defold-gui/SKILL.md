---
name: defold-gui
description: Expert assistance with Defold GUI system, Lua scripting, and visual novel UI patterns
license: MIT
compatibility: opencode
metadata:
  audience: game developers
  framework: defold
  language: lua
---

## What I do

I provide expert guidance on Defold game engine GUI development, specifically:

- **GUI Component Architecture**: Help design and structure GUI components (.gui + .gui_script files)
- **Node Management**: Assist with creating, positioning, and animating GUI nodes
- **Atlas Integration**: Guide on texture atlas setup and sprite management
- **Lua Scripting**: Debug and optimize GUI scripts with proper message passing
- **Visual Novel Patterns**: Implement dialogue systems, portraits, choices, and UI transitions
- **Performance**: Optimize GUI rendering, reduce node count, and improve frame rates
- **Defold Best Practices**: Follow official guidelines for GUI hierarchy, z-ordering, and resource management

## When to use me

Use this skill when you are:

- Creating new GUI components or screens
- Debugging GUI rendering issues (invisible nodes, incorrect positioning, z-order problems)
- Implementing UI animations and transitions
- Working with texture atlases and sprite animations
- Setting up message passing between GUI components
- Optimizing GUI performance
- Migrating or refactoring existing GUI code
- Implementing visual novel UI patterns (dialogue boxes, portraits, choice menus)

## Key Defold GUI Concepts

### Node Types
- **TYPE_BOX**: Rectangular nodes for backgrounds, borders, containers
- **TYPE_TEXT**: Text rendering with font support
- **TYPE_PIE**: Circular/pie-shaped nodes for buttons, indicators
- **TYPE_TEMPLATE**: Reusable GUI templates

### Common Issues I Help With

1. **Invisible Nodes**
   - Check `enabled` property
   - Verify `color.w` (alpha) is not 0
   - Ensure `inherit_alpha` is set correctly
   - Confirm z-order doesn't hide nodes behind others

2. **Positioning Problems**
   - Understand pivot points (PIVOT_SW, PIVOT_CENTER, etc.)
   - Use absolute vs relative positioning correctly
   - Avoid `gui.set_parent()` for dynamic nodes (use absolute coordinates instead)

3. **Atlas/Texture Issues**
   - Register textures in GUI file's `textures` section
   - Use `gui.set_texture()` and `gui.play_flipbook()` for sprites
   - Ensure atlas contains the referenced images

4. **Message Passing**
   - Use `msg.post()` with proper URL format: `"#component_id"` or `"main:/go_id#component_id"`
   - Handle messages in `on_message(self, message_id, message, sender)`

5. **Performance**
   - Minimize dynamic node creation
   - Use `gui.set_enabled()` instead of creating/deleting nodes
   - Batch similar operations
   - Avoid unnecessary `update()` calls

## Visual Novel Specific Patterns

### Dialogue System
- Portrait display with fade/slide animations
- Text typewriter effect (character-by-character)
- Speaker name and tag display
- Message history and backlog

### Choice System
- Dynamic choice button creation
- Hover/click states
- Timer countdown for timed choices
- Keyboard/gamepad navigation

### UI Modals
- Backdrop dimming
- Modal window positioning
- Proper z-ordering (backdrop < modal < buttons)
- ESC key handling for closing

### Inventory/Phone Systems
- Grid-based item display
- Dynamic slot creation
- Item details panel
- Verb/action buttons

## Code Examples

### Creating Dynamic Nodes
```lua
-- Create a box node
local node = gui.new_box_node(vmath.vector3(100, 100, 0), vmath.vector3(200, 50, 0))
gui.set_color(node, vmath.vector4(1, 1, 1, 1))
gui.set_id(node, "my_box")

-- IMPORTANT: Don't use gui.set_parent() for dynamic nodes
-- Use absolute screen coordinates instead
```

### Showing Sprites from Atlas
```lua
-- In GUI file, add texture:
-- textures {
--   name: "v2"
--   texture: "/main/images/v2.atlas"
-- }

-- In script:
local portrait = gui.get_node("portrait_bg")
gui.set_texture(portrait, "v2")
gui.play_flipbook(portrait, "artem")
gui.set_enabled(portrait, true)
```

### UTF-8 String Handling (Cyrillic)
```lua
-- Standard Lua string.lower() doesn't work with Cyrillic
-- Use custom UTF-8 aware function:
local function utf8_lower(s)
    local upper_to_lower = {
        ["А"]="а", ["Б"]="б", ["В"]="в", ["Г"]="г", ["Д"]="д",
        ["Е"]="е", ["Ё"]="ё", ["Ж"]="ж", ["З"]="з", ["И"]="и",
        -- ... add all Cyrillic letters
    }
    local result = {}
    for ch in string.gmatch(s or "", "([%z\1-\127\194-\244][\128-\191]*)") do
        result[#result + 1] = upper_to_lower[ch] or ch:lower()
    end
    return table.concat(result)
end
```

### Typewriter Effect
```lua
function update(self, dt)
    if not self.typewriter_active then return end
    
    self.typewriter_accum = self.typewriter_accum + dt
    local chars_to_show = math.floor(self.typewriter_accum * CHARS_PER_SECOND)
    
    if chars_to_show > self.typewriter_shown then
        self.typewriter_shown = chars_to_show
        local visible_text = table.concat(self.typewriter_chars, "", 1, chars_to_show)
        gui.set_text(gui.get_node("text"), visible_text)
    end
end
```

## Questions to Ask

When helping with GUI issues, I will ask:

1. What is the expected behavior vs actual behavior?
2. Are there any error messages in the console?
3. Have you checked the node's `enabled` state and `color.w` (alpha)?
4. Is the texture/atlas properly registered in the GUI file?
5. What is the z-order of the problematic nodes?
6. Are you using `inherit_alpha` correctly?
7. For dynamic nodes: are you using absolute coordinates instead of `gui.set_parent()`?

## Resources

- [Defold GUI Manual](https://defold.com/manuals/gui/)
- [Defold GUI API Reference](https://defold.com/ref/gui/)
- [Defold Best Practices](https://defold.com/manuals/best-practices/)

## Project-Specific Context

This project (AVOS) uses:
- **V2 UI System**: Modern modular GUI in `main/gui/components_v2/`
- **Legacy UI**: Old monolithic GUI in `main/gui/components/`
- **Theme System**: `main/gui/modules/v2_theme.lua` for colors and fonts
- **Atlases**: `v2.atlas`, `backgrounds.atlas`, `characters.atlas`
- **Fonts**: JetBrains Mono, Unbounded, Caveat, Manrope, Material Icons

Common patterns in this project:
- All V2 components use absolute positioning (no parenting)
- Modal overlays use z-index 0.5-0.6
- Backdrop dimming at z-index 0.4
- UTF-8 aware string handling for Cyrillic text
- Typewriter effects for dialogue
- Dynamic node creation for inventory/choices
