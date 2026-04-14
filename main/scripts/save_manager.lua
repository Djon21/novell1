-- save_manager.lua
-- Сохранение/загрузка прогресса игры между сессиями.
-- Хранит: пол ГГ, флаги TRUST/INSIGHT/SYNC, главу, текущую позицию.
-- Использует sys.save() — на HTML5 пишет в localStorage (работает на Яндекс Играх).

local M = {}

local SAVE_PATH = sys.get_save_file("novell1", "save.dat")

local _data = nil

local function defaults()
    return {
        mc_gender  = nil,
        flags      = { TRUST = 0, INSIGHT = 0, SYNC = 0 },
        chapter    = 1,
        scene_id   = nil,   -- id текущей сцены (строка-ключ)
        node_index = 1,     -- индекс текущего узла
    }
end

-- -------------------------------------------------------
-- Загрузка / сохранение
-- -------------------------------------------------------

function M.load()
    local loaded = sys.load(SAVE_PATH)
    if loaded and loaded.flags then
        _data = loaded
        -- Докидываем поля для совместимости со старыми сохранениями
        if _data.scene_id   == nil then _data.scene_id   = nil end
        if _data.node_index == nil then _data.node_index = 1   end
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
-- Прогресс (сцена + узел)
-- -------------------------------------------------------

-- Есть ли сохранение для продолжения
function M.has_save()
    return _data ~= nil
       and _data.mc_gender ~= nil
       and _data.scene_id  ~= nil
end

-- Сохранить текущую позицию
function M.save_progress(scene_id, node_index)
    _data.scene_id   = scene_id
    _data.node_index = node_index
    M.save()
end

function M.get_saved_scene() return _data and _data.scene_id          end
function M.get_saved_node()  return _data and (_data.node_index or 1) end

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
-- Флаги
-- -------------------------------------------------------

function M.get_flags()
    return _data.flags
end

function M.apply_flags(delta)
    for key, val in pairs(delta) do
        _data.flags[key] = (_data.flags[key] or 0) + val
    end
    M.save()
    print(string.format("[Save] TRUST=%d  INSIGHT=%d  SYNC=%d",
        _data.flags.TRUST, _data.flags.INSIGHT, _data.flags.SYNC))
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
