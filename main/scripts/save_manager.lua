-- save_manager.lua
-- Stores only run-state for the current playthrough.
-- Persistent loop/meta progression lives in meta_state.lua.
--
-- Save schema versioning:
--   _data.version = N — увеличивай при breaking-changes схемы. На load
--   старые версии прогоняются через migrate_save(). Если миграции нет —
--   откатываемся к defaults() и логируем (молча игнорить = терять прогресс).
--
-- Backup перед записью:
--   Перед каждым sys.save переименовываем текущий save.dat в save.dat.bak
--   (через двойной sys.save). Если основная запись прервалась (краш,
--   закрытие вкладки) — load умеет фоллбекнуться на .bak.
--
-- Throttling:
--   M.save() пишет на диск сразу. Для авто-сейва через подписку gs использует
--   debounce_save() — батчит запросы в окне DEBOUNCE_SEC. Критичные точки
--   (boundary, visibility loss) должны звать M.save_now() для немедленного flush.

local log = require "main.scripts.log"

local M = {}

local SAVE_PATH = sys.get_save_file("novell1", "save.dat")
local BACKUP_PATH = sys.get_save_file("novell1", "save.dat.bak")

local CURRENT_VERSION = 1
local DEBOUNCE_SEC = 0.5     -- окно для дебаунса auto-save

local _data = nil
local _dirty = false          -- есть несохранённые изменения
local _debounce_handle = nil  -- активный timer.delay handle

local function defaults()
    return {
        version    = CURRENT_VERSION,
        mc_gender  = nil,
        chapter    = 1,
        ink_state  = nil,
        game_state = nil,
    }
end

-- migrate_save(loaded) — поднимает старый формат до CURRENT_VERSION.
-- Каждая миграция: from_version → from_version+1, идём поступательно.
-- Возвращает мигрированную таблицу или nil если миграция невозможна
-- (тогда вызывающий fallback'ается на defaults()).
local function migrate_save(loaded)
    if type(loaded) ~= "table" then return nil end
    local v = tonumber(loaded.version) or 0

    -- v0 → v1: добавлен поле `version`. Содержимое (mc_gender, ink_state,
    -- game_state, chapter) совместимо. Просто проставляем версию.
    if v < 1 then
        loaded.version = 1
        v = 1
    end

    -- Будущие миграции сюда:
    -- if v < 2 then ... end

    if v ~= CURRENT_VERSION then
        log.warn("save_manager", "unknown save version", v,
            "- expected", CURRENT_VERSION, "; falling back to defaults")
        return nil
    end
    return loaded
end

-- Сырая запись на диск + ротация бэкапа. Не должна вызываться извне напрямую —
-- идти через M.save() / M.save_now() / debounce_save().
local function write_to_disk()
    if not _data then return end

    -- Бэкап: если был ОК-сейв на диске — переписываем его в .bak ПЕРЕД
    -- основной записью. Если основная запись прервётся, .bak останется
    -- последним валидным состоянием.
    local previous = sys.load(SAVE_PATH)
    if previous and next(previous) ~= nil then
        sys.save(BACKUP_PATH, previous)
    end

    sys.save(SAVE_PATH, _data)
    _dirty = false
end

local function ensure_loaded()
    if not _data then
        M.load()
    end
end

-- Дебаунс: пишет на диск через DEBOUNCE_SEC после последнего вызова.
-- Если уже стоит таймер — сбрасываем, ставим новый. Так массовые
-- мутации (например seed_phone_history, который ставит 15 sms подряд)
-- сольются в один write.
local function debounce_save()
    _dirty = true
    if _debounce_handle then
        timer.cancel(_debounce_handle)
        _debounce_handle = nil
    end
    _debounce_handle = timer.delay(DEBOUNCE_SEC, false, function()
        _debounce_handle = nil
        if _dirty then
            write_to_disk()
        end
    end)
end

function M.load()
    local loaded = sys.load(SAVE_PATH)
    -- Если основной сейв пустой/битый — пробуем backup.
    if not loaded or next(loaded) == nil then
        local backup = sys.load(BACKUP_PATH)
        if backup and next(backup) ~= nil then
            log.warn("save_manager", "main save empty, restored from backup")
            loaded = backup
        end
    end

    if loaded and next(loaded) ~= nil then
        local migrated = migrate_save(loaded)
        _data = migrated or defaults()
    else
        _data = defaults()
    end
    return _data
end

-- save() — дебаунсированная запись (используется для частых мутаций).
function M.save()
    ensure_loaded()
    debounce_save()
end

-- save_now() — немедленный flush на диск. Звать на критичных границах:
-- choice picked, scene transition complete, visibility lost, game closed.
function M.save_now()
    ensure_loaded()
    if _debounce_handle then
        timer.cancel(_debounce_handle)
        _debounce_handle = nil
    end
    write_to_disk()
end

function M.new_game()
    _data = defaults()
    M.save_now()
end

function M.clear_run()
    ensure_loaded()
    _data.mc_gender = nil
    _data.chapter = 1
    _data.ink_state = nil
    _data.game_state = nil
    M.save_now()
end

function M.has_save()
    ensure_loaded()
    -- Continue needs both halves of the run. On HTML5/Yandex an interrupted
    -- write can leave ink_state ahead of game_state; loading that produced
    -- dialogue over the menu background and could immediately reach END.
    return _data.ink_state ~= nil and _data.game_state ~= nil
end

function M.set_ink_state(state)
    ensure_loaded()
    _data.ink_state = state
    M.save()
end

function M.get_ink_state()
    ensure_loaded()
    return _data.ink_state
end

function M.set_game_state(state)
    ensure_loaded()
    _data.game_state = state
    M.save()
end

function M.get_game_state()
    ensure_loaded()
    return _data.game_state
end

function M.set_gender(gender)
    ensure_loaded()
    _data.mc_gender = gender
    M.save()
end

function M.get_gender()
    ensure_loaded()
    return _data.mc_gender
end

function M.get_mc_name()
    ensure_loaded()
    return _data.mc_gender == "female" and "Мила" or "Артём"
end

function M.get_npc_name()
    ensure_loaded()
    return _data.mc_gender == "female" and "Артём" or "Мила"
end

function M.set_chapter(n)
    ensure_loaded()
    _data.chapter = n
    M.save()
end

function M.get_chapter()
    ensure_loaded()
    return _data.chapter
end

return M
