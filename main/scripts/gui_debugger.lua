-- gui_debugger.lua
-- Visual GUI debugger for AVOS project
-- Press F2 to toggle debugger overlay
-- Shows all enabled GUI nodes with their properties

local M = {}

M.enabled = false
M.nodes_info = {}

-- Recursively collect all nodes from a GUI component
local function collect_nodes_recursive(node, parent_name, depth, results)
    if not node then return end
    
    local id = gui.get_id(node)
    local enabled = gui.is_enabled(node)
    
    -- Only collect enabled nodes
    if enabled then
        local pos = gui.get_position(node)
        local size = gui.get_size(node)
        local color = gui.get_color(node)
        local screen_pos = gui.get_screen_position(node)
        
        table.insert(results, {
            id = id,
            parent = parent_name,
            depth = depth,
            pos = pos,
            screen_pos = screen_pos,
            size = size,
            color = color,
            alpha = color.w,
            enabled = enabled,
        })
    end
    
    -- Recursively collect children
    local children = gui.get_children(node)
    if children then
        for _, child in ipairs(children) do
            collect_nodes_recursive(child, id, depth + 1, results)
        end
    end
end

-- Collect all nodes from all GUI components
function M.collect_all_nodes()
    M.nodes_info = {}
    
    -- Get all GUI components in the scene
    -- This is a simplified version - in real implementation you'd need to
    -- iterate through all GUI components
    
    return M.nodes_info
end

-- Print nodes info to console
function M.print_nodes()
    print("\n========== GUI DEBUGGER ==========")
    print(string.format("Total enabled nodes: %d", #M.nodes_info))
    print("==================================")
    
    for i, info in ipairs(M.nodes_info) do
        local indent = string.rep("  ", info.depth)
        print(string.format("%s[%d] %s (parent: %s)", 
            indent, i, info.id, info.parent or "root"))
        print(string.format("%s    pos: (%.1f, %.1f, %.3f)", 
            indent, info.pos.x, info.pos.y, info.pos.z))
        print(string.format("%s    screen: (%.1f, %.1f)", 
            indent, info.screen_pos.x, info.screen_pos.y))
        print(string.format("%s    size: (%.1f, %.1f)", 
            indent, info.size.x, info.size.y))
        print(string.format("%s    alpha: %.2f, enabled: %s", 
            indent, info.alpha, tostring(info.enabled)))
    end
    
    print("==================================\n")
end

-- Toggle debugger
function M.toggle()
    M.enabled = not M.enabled
    if M.enabled then
        print("[gui_debugger] ENABLED - Press F2 to disable")
        M.collect_all_nodes()
        M.print_nodes()
    else
        print("[gui_debugger] DISABLED")
    end
end

return M
