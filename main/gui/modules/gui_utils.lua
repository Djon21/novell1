-- gui_utils.lua
-- Базовые утилиты для работы с GUI нодами

local M = {}

-- Проверяет, существует ли нода
function M.node_exists(node_id)
    local ok, node = pcall(gui.get_node, node_id)
    return ok and node ~= nil
end

-- Безопасное получение ноды (возвращает nil если не найдена)
function M.get_node_safe(node_id)
    local ok, node = pcall(gui.get_node, node_id)
    if ok then
        return node
    end
    return nil
end

-- Устанавливает видимость ноды безопасно
function M.set_enabled_safe(node, enabled)
    if node then
        gui.set_enabled(node, enabled)
        return true
    end
    return false
end

-- Устанавливает текст ноды безопасно
function M.set_text_safe(node, text)
    if node then
        gui.set_text(node, text or "")
        return true
    end
    return false
end

-- Устанавливает цвет ноды безопасно
function M.set_color_safe(node, color)
    if node and color then
        gui.set_color(node, color)
        return true
    end
    return false
end

-- Устанавливает позицию ноды безопасно
function M.set_position_safe(node, position)
    if node and position then
        gui.set_position(node, position)
        return true
    end
    return false
end

-- Получает позицию ноды безопасно
function M.get_position_safe(node)
    if node then
        return gui.get_position(node)
    end
    return nil
end

-- Скрывает группу нод
function M.hide_nodes(nodes)
    for _, node in ipairs(nodes) do
        if node then
            gui.set_enabled(node, false)
        end
    end
end

-- Показывает группу нод
function M.show_nodes(nodes)
    for _, node in ipairs(nodes) do
        if node then
            gui.set_enabled(node, true)
        end
    end
end

-- Отменяет все анимации на ноде
function M.cancel_animations(node)
    if node then
        gui.cancel_animation(node, "position")
        gui.cancel_animation(node, "position.x")
        gui.cancel_animation(node, "position.y")
        gui.cancel_animation(node, "position.z")
        gui.cancel_animation(node, "color")
        gui.cancel_animation(node, "color.w")
        gui.cancel_animation(node, "scale")
        gui.cancel_animation(node, "rotation")
    end
end

-- Проверяет, находится ли точка внутри ноды
function M.is_point_inside(node, x, y)
    if not node then return false end
    
    local pos = gui.get_position(node)
    local size = gui.get_size(node)
    
    local left = pos.x - size.x * 0.5
    local right = pos.x + size.x * 0.5
    local bottom = pos.y - size.y * 0.5
    local top = pos.y + size.y * 0.5
    
    return x >= left and x <= right and y >= bottom and y <= top
end

-- Клонирует дерево нод (для templates)
function M.clone_tree_safe(node_id)
    if type(node_id) == "string" then
        node_id = M.get_node_safe(node_id)
    end
    
    if node_id then
        return gui.clone_tree(node_id)
    end
    return nil
end

-- Удаляет дерево нод
function M.delete_tree_safe(node)
    if node then
        gui.delete_node(node)
        return true
    end
    return false
end

-- Устанавливает альфа-канал цвета ноды
function M.set_alpha(node, alpha)
    if node then
        local color = gui.get_color(node)
        color.w = alpha
        gui.set_color(node, color)
        return true
    end
    return false
end

-- Получает альфа-канал цвета ноды
function M.get_alpha(node)
    if node then
        local color = gui.get_color(node)
        return color.w
    end
    return 0
end

-- Создает вектор цвета из RGB (0-1) и альфы
function M.color(r, g, b, a)
    return vmath.vector4(r or 0, g or 0, b or 0, a or 1)
end

-- Создает вектор позиции
function M.vec3(x, y, z)
    return vmath.vector3(x or 0, y or 0, z or 0)
end

-- Логирование с префиксом
function M.log(system, message)
    print("[" .. system .. "] " .. tostring(message))
end

function M.warn(system, message)
    print("[" .. system .. "] ⚠️ " .. tostring(message))
end

function M.error(system, message)
    print("[" .. system .. "] ❌ " .. tostring(message))
end

return M
