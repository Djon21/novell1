-- dialogue_manager.lua
-- Движок диалогов: управляет состоянием истории.
-- Использовать как Lua-модуль: local dm = require "main.scripts.dialogue_manager"

local M = {}

local story           = nil
local current_scene   = nil
local current_index   = 1

-- Инициализация с данными истории
function M.init(story_data)
    story         = story_data
    current_scene = story_data.scenes[story_data.start]
    current_index = 1
end

-- Текущий узел (dialogue / choice / end)
function M.get_current_node()
    if not current_scene then return nil end
    return current_scene.nodes[current_index]
end

-- Цвет фона текущей сцены
function M.get_background()
    if not current_scene then return { r=0, g=0, b=0 } end
    return current_scene.background
end

-- Перейти к следующему узлу. Возвращает false если дошли до конца.
function M.advance()
    if not current_scene then return false end
    current_index = current_index + 1
    return current_index <= #current_scene.nodes
end

-- Выбрать вариант в узле choice (1-based).
function M.choose(option_index)
    local node = M.get_current_node()
    if not node or node.type ~= "choice" then return false end
    local option = node.options[option_index]
    if not option then return false end

    local next_scene = story.scenes[option.next]
    if not next_scene then
        print("[DM] Сцена не найдена: " .. tostring(option.next))
        return false
    end

    current_scene = next_scene
    current_index = 1
    return true
end

-- Перезапустить с начала
function M.restart()
    M.init(story)
end

return M
