-- save_manager.lua
-- Сохранение/загрузка прогресса игры между сессиями.
-- Хранит: пол ГГ, номер главы, состояние ink-истории.
-- Флаги драмы (TRUST/INSIGHT/SYNC) живут внутри ink_state как VAR'ы —
-- дублировать их здесь не нужно.
-- Использует sys.save() — на HTML5 пишет в localStorage (работает на Яндекс Играх).

local M = {}

local SAVE_PATH = sys.get_save_file("novell1", "save.dat")

local _data = nil

local function defaults()
    return {
        mc_gender  = nil,
        chapter    = 1,
        ink_state  = nil,   -- { ink = story.get_state(), index = paragraph_idx }
        game_state = nil,   -- snapshot game_state.serialize() — point-and-click слой
    }
end

-- -------------------------------------------------------
-- Загрузка / сохранение
-- -------------------------------------------------------

function M.load()
    local loaded = sys.load(SAVE_PATH)
    -- sys.load возвращает пустую таблицу, если файла нет.
    -- Наличие mc_gender — простейший маркер «это наше сохранение».
    if loaded and next(loaded) ~= nil then
        _data = loaded
    else
        _data = defaults()
    end
    return _data
end

function M.save()
    sys.save(SAVE_PATH, _data)
end

-- Полный сброс (новая игра)
function M.new_game()
    _data = defaults()
    M.save()
end

-- -------------------------------------------------------
-- Есть ли сохранение для продолжения
-- -------------------------------------------------------
function M.has_save()
    if not _data then return false end
    if _data.mc_gender == nil then return false end
    return _data.ink_state ~= nil
end

-- -------------------------------------------------------
-- Ink story state
-- -------------------------------------------------------

function M.set_ink_state(state)
    _data.ink_state = state
    M.save()
end

function M.get_ink_state()
    return _data and _data.ink_state
end

-- -------------------------------------------------------
-- Game state (inventory / quests / flags / current_scene)
-- -------------------------------------------------------

function M.set_game_state(state)
    _data.game_state = state
    M.save()
end

function M.get_game_state()
    return _data and _data.game_state
end

-- -------------------------------------------------------
-- Пол персонажа
-- -------------------------------------------------------

function M.set_gender(gender)
    _data.mc_gender = gender
    M.save()
end

function M.get_gender()
    return _data.mc_gender
end

function M.get_mc_name()
    return _data.mc_gender == "female" and "Мила" or "Артём"
end

function M.get_npc_name()
    -- Выбрал Артёма → НПС Мила, выбрал Милу → НПС Артём
    return _data.mc_gender == "female" and "Артём" or "Мила"
end

-- -------------------------------------------------------
-- Глава
-- -------------------------------------------------------

function M.set_chapter(n)
    _data.chapter = n
    M.save()
end

function M.get_chapter()
    return _data.chapter
end

return M
