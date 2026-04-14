-- save_manager.lua
-- Сохранение/загрузка прогресса игры между сессиями.
-- Хранит: пол ГГ, флаги TRUST/INSIGHT/SYNC, номер главы.

local M = {}

local SAVE_PATH = sys.get_save_file("novell1", "save.dat")

local _data = nil

local function defaults()
    return {
        mc_gender = nil,           -- "male" | "female" | nil (не выбран)
        flags     = { TRUST = 0, INSIGHT = 0, SYNC = 0 },
        chapter   = 1,
    }
end

-- -------------------------------------------------------
-- Загрузка / сохранение
-- -------------------------------------------------------

function M.load()
    local loaded = sys.load(SAVE_PATH)
    if loaded and loaded.flags then
        _data = loaded
    else
        _data = defaults()
    end
    return _data
end

function M.save()
    sys.save(SAVE_PATH, _data)
end

function M.reset()
    _data = defaults()
    M.save()
end

-- -------------------------------------------------------
-- Пол персонажа
-- -------------------------------------------------------

function M.set_gender(gender)   -- "male" | "female"
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

-- delta = { TRUST=1, INSIGHT=0, SYNC=-1 } и т.д.
function M.apply_flags(delta)
    for key, val in pairs(delta) do
        _data.flags[key] = (_data.flags[key] or 0) + val
    end
    M.save()
    -- Лог для отладки
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
