-- dialogue_manager.lua
-- Движок диалогов: состояние истории, флаги, подстановка имён.

local M = {}

local sm = require "main.scripts.save_manager"

local story         = nil
local current_scene = nil
local current_index = 1

-- -------------------------------------------------------
-- Подстановка токенов в строку.
-- Поддерживаемые токены:
--   {MC_NAME}             — имя главного героя
--   {NPC_NAME}            — имя НПС (противоположный персонаж)
--   {MC|мужск|женск}      — форма слова по полу ГГ
--   {NPC|мужск|женск}     — форма слова по полу НПС
--
-- Примеры в тексте:
--   "я просну{MC|лся|лась}"        → "я проснулся" / "я проснулась"
--   "я замети{MC|л|ла}"            → "я заметил"   / "я заметила"
--   "{MC|искал|искала} файл"       → "искал файл"  / "искала файл"
--   "{NPC|он|она} смотрит"         → "он смотрит"  / "она смотрит"
-- -------------------------------------------------------
local function sub(text)
    if not text then return text end

    local mc_female = sm.get_gender() == "female"

    text = text:gsub("{MC_NAME}",  sm.get_mc_name())
    text = text:gsub("{NPC_NAME}", sm.get_npc_name())

    -- {MC|мужская форма|женская форма}
    text = text:gsub("{MC|([^|]*)|([^}]*)}", function(m, f)
        return mc_female and f or m
    end)

    -- {NPC|мужская форма|женская форма} — НПС противоположного пола
    text = text:gsub("{NPC|([^|]*)|([^}]*)}", function(m, f)
        return mc_female and m or f
    end)

    return text
end

-- Возвращает копию узла с подставленными именами
local function process_node(node)
    if not node then return nil end
    local n = {}
    for k, v in pairs(node) do n[k] = v end

    n.text      = sub(n.text)
    n.character = sub(n.character)

    if n.options then
        local opts = {}
        for i, opt in ipairs(n.options) do
            local o = {}
            for k, v in pairs(opt) do o[k] = v end
            o.text = sub(o.text)
            opts[i] = o
        end
        n.options = opts
    end
    return n
end

-- -------------------------------------------------------
-- Инициализация
-- -------------------------------------------------------
function M.init(story_data)
    story         = story_data
    sm.load()
    current_scene = story_data.scenes[story_data.start]
    current_index = 1
end

-- -------------------------------------------------------
-- Текущий узел (с подставленными именами)
-- -------------------------------------------------------
function M.get_current_node()
    if not current_scene then return nil end
    return process_node(current_scene.nodes[current_index])
end

-- -------------------------------------------------------
-- Цвет фона текущей сцены
-- -------------------------------------------------------
function M.get_background()
    if not current_scene then return { r=0, g=0, b=0 } end
    return current_scene.background
end

-- -------------------------------------------------------
-- Перейти к следующему узлу.
-- Если сцена закончилась и есть next_scene — переходим туда.
-- -------------------------------------------------------
function M.advance()
    if not current_scene then return false end
    current_index = current_index + 1

    if current_index > #current_scene.nodes then
        if current_scene.next_scene then
            local next = story.scenes[current_scene.next_scene]
            if next then
                current_scene = next
                current_index = 1
                return true
            end
        end
        return false
    end
    return true
end

-- -------------------------------------------------------
-- Выбрать вариант (1-based).
-- Применяет флаги, переходит в следующую сцену.
-- -------------------------------------------------------
function M.choose(option_index)
    local node = M.get_current_node()
    if not node then return false end

    local option = node.options and node.options[option_index]
    if not option then return false end

    -- Установить пол если это гендерный выбор
    if option.gender then
        sm.set_gender(option.gender)
    end

    -- Применить флаги
    if option.flags then
        sm.apply_flags(option.flags)
    end

    -- Переход в следующую сцену
    if option.next then
        local next = story.scenes[option.next]
        if not next then
            print("[DM] Сцена не найдена: " .. tostring(option.next))
            return false
        end
        current_scene = next
        current_index = 1
    end

    return true
end

-- -------------------------------------------------------
-- Перезапустить с начала (не сбрасывает сохранение)
-- -------------------------------------------------------
function M.restart()
    M.init(story)
end

return M
