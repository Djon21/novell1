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
local cloud_sync = require "main.scripts.cloud_sync"

local M = {}

local SAVE_PATH = sys.get_save_file("novell1", "save.dat")
local BACKUP_PATH = sys.get_save_file("novell1", "save.dat.bak")

-- Слоты: автосейв + 3 ручных. Автосейв — это SAVE_PATH (existing flow),
-- единственный синкается с облаком. Ручные слоты — локальные snapshot'ы
-- которые игрок явно создаёт в Save/Load меню; для них нет debounce и
-- backup'а — игрок сам управляет.
local SLOT_COUNT = 3
local function slot_path(slot)
    return sys.get_save_file("novell1", "save_slot" .. tostring(slot) .. ".dat")
end

local CURRENT_VERSION = 2     -- v2: добавлено save_time для cloud-merge
local DEBOUNCE_SEC = 0.5      -- окно для дебаунса auto-save

local _data = nil
local _dirty = false          -- есть несохранённые изменения
local _debounce_handle = nil  -- активный timer.delay handle

local function defaults()
    return {
        version    = CURRENT_VERSION,
        save_time  = 0,         -- unix-секунды последнего write_to_disk
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

    -- v1 → v2: добавлено поле save_time для cloud-merge. У старых сейвов
    -- проставляем 0 — на init pull облако всегда выиграет (если оно есть
    -- и в нём save_time > 0). Если cloud тоже пустой — играем с локального.
    if v < 2 then
        loaded.save_time = loaded.save_time or 0
        loaded.version = 2
        v = 2
    end

    -- Будущие миграции сюда:
    -- if v < 3 then ... end

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

    -- save_time проставляем перед записью. os.time() есть в Defold и
    -- работает кроссплатформенно (включая HTML5).
    _data.save_time = os.time()

    sys.save(SAVE_PATH, _data)
    _dirty = false

    -- Cloud-зеркало: throttled push (5с окно). fire-and-forget, ошибки
    -- молча логируются внутри cloud_sync. Если облако не ready — no-op.
    cloud_sync.push_throttled(_data)
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

-- cloud_init(callback) — инициализирует Yandex Player SDK и тянет облачный
-- сейв. Должен вызываться один раз на старте игры, до show_menu.
--
-- Контракт callback(err): err=nil → cloud успешно подтянут (или там пусто),
-- err!=nil → cloud недоступен, играем локально. В любом случае _data к
-- моменту вызова callback — финальный (либо local, либо overwritten cloud'ом).
--
-- Логика merge: если cloud.save_time > local.save_time → cloud выиграл.
-- Иначе local (включая случай когда cloud вообще пустой).
function M.cloud_init(callback)
    ensure_loaded()
    cloud_sync.init(function(init_err)
        if init_err then
            -- yagames недоступен / нет сети / нет auth. Играем локально.
            if callback then callback(init_err) end
            return
        end
        cloud_sync.pull(function(pull_err, cloud_data)
            if pull_err then
                log.info("save_manager", "cloud pull failed:", pull_err)
                if callback then callback(pull_err) end
                return
            end
            local local_time = (_data and _data.save_time) or 0
            local cloud_time = (cloud_data and cloud_data.save_time) or 0
            if cloud_data and cloud_time > local_time then
                local migrated = migrate_save(cloud_data)
                if migrated then
                    log.info("save_manager", "cloud save is newer (cloud=",
                        cloud_time, "local=", local_time, ") - using cloud")
                    _data = migrated
                    -- Сразу пишем локально, чтобы при следующем запуске
                    -- (даже без сети) мы имели свежую копию.
                    sys.save(SAVE_PATH, _data)
                else
                    log.warn("save_manager", "cloud save version unknown - ignored")
                end
            else
                log.info("save_manager", "local save is up to date (local=",
                    local_time, "cloud=", cloud_time, ")")
            end
            if callback then callback(nil) end
        end)
    end)
end

-- cloud_flush_now(callback) — синхронный push на final-хуке. Звать ПОСЛЕ
-- save_now() (т.е. _data уже свежий). Callback опционален — обычно final
-- не ждёт ответа, но HTML5 visibility-hook может хотеть подтверждение.
function M.cloud_flush_now(callback)
    if not _data then
        if callback then callback("no_data") end
        return
    end
    cloud_sync.flush_now(_data, callback)
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

-- ─── Slot API ────────────────────────────────────────────────────────────
-- Ручные слоты 1..3 + автосейв (SAVE_PATH).
-- Ручные слоты — это локальные snapshot'ы текущего _data:
--   save_to_slot(N)   — пишет копию текущего _data в save_slotN.dat.
--   load_from_slot(N) — читает save_slotN.dat, мигрирует, заменяет _data.
--                       После вызова обычный flow (M.save) запишет это в
--                       autosave save.dat.
--   get_slot_info(N)  — preview для UI: { exists, save_time, chapter, mc_gender }.
--                       Не мутирует _data, нужен для рендера панели слотов.
--
-- Cloud sync для ручных слотов НЕ делаем (Stage 3 syncит только autosave).
-- Игрок видит cross-device только текущий ран; слоты привязаны к устройству.

function M.slot_count() return SLOT_COUNT end

function M.save_to_slot(slot)
    ensure_loaded()
    if type(slot) ~= "number" or slot < 1 or slot > SLOT_COUNT then
        log.warn("save_manager", "save_to_slot: invalid slot", tostring(slot))
        return false
    end
    -- Перед записью обновляем save_time, чтобы у слота был корректный
    -- timestamp в UI (а не время последнего autosave-write).
    local snapshot = {
        version    = _data.version,
        save_time  = os.time(),
        mc_gender  = _data.mc_gender,
        chapter    = _data.chapter,
        ink_state  = _data.ink_state,
        game_state = _data.game_state,
    }
    sys.save(slot_path(slot), snapshot)
    log.info("save_manager", "saved to slot", slot, "chapter=", snapshot.chapter)
    return true
end

function M.load_from_slot(slot)
    if type(slot) ~= "number" or slot < 1 or slot > SLOT_COUNT then
        log.warn("save_manager", "load_from_slot: invalid slot", tostring(slot))
        return false
    end
    local loaded = sys.load(slot_path(slot))
    if not loaded or next(loaded) == nil then
        log.warn("save_manager", "load_from_slot: slot", slot, "empty")
        return false
    end
    local migrated = migrate_save(loaded)
    if not migrated then
        log.warn("save_manager", "load_from_slot: slot", slot, "incompatible version")
        return false
    end
    _data = migrated
    -- Сразу пишем в autosave чтобы это стало текущим ранным состоянием.
    -- save_now дёрнет cloud_push тоже — слот переезжает в облако через
    -- автосейв при следующих мутациях.
    M.save_now()
    log.info("save_manager", "loaded from slot", slot, "chapter=", _data.chapter)
    return true
end

-- get_slot_info(slot) → { exists, save_time, chapter, mc_gender } или nil
-- Только чтение, не мутирует _data. Slot 0 = автосейв (SAVE_PATH).
function M.get_slot_info(slot)
    local path
    if slot == 0 then
        path = SAVE_PATH
    elseif type(slot) == "number" and slot >= 1 and slot <= SLOT_COUNT then
        path = slot_path(slot)
    else
        return nil
    end
    local loaded = sys.load(path)
    if not loaded or next(loaded) == nil then
        return { exists = false, slot = slot }
    end
    return {
        exists    = true,
        slot      = slot,
        save_time = loaded.save_time or 0,
        chapter   = loaded.chapter or 1,
        mc_gender = loaded.mc_gender,
        -- has_run: достаточно ли данных для Continue (см. has_save).
        has_run   = (loaded.ink_state ~= nil and loaded.game_state ~= nil),
    }
end

function M.delete_slot(slot)
    if type(slot) ~= "number" or slot < 1 or slot > SLOT_COUNT then
        return false
    end
    -- Перезаписываем пустой таблицей. sys.save с {} даёт «пустой» сейв,
    -- next() которого вернёт nil → get_slot_info → exists=false.
    sys.save(slot_path(slot), {})
    log.info("save_manager", "deleted slot", slot)
    return true
end

return M
