-- cloud_sync.lua
-- Обёртка над Yandex Player API (yagames.player_*) для облачных сейвов.
--
-- Лимиты Яндекс.Игр:
--   player_set_data   — 200 KB на один сейв.
--   player_set_stats  — 10 KB для числовых ключей (не используем, у нас единый JSON).
--   private/quote запросов не задокументированы, но best-practice — не чаще
--   раза в несколько секунд. Поэтому push throttled на 5с.
--
-- Дизайн-принципы:
--   1) НИКОГДА не блочим геймплей: yagames может быть не загружен (ПК-сборка),
--      pcall везде. Если что-то падает — silently ready=false, продолжаем
--      жить на локальных сейвах.
--   2) Авторизация необязательна: y.player_init работает и для guest'ов
--      (anonymous id), просто их сейв привязан к браузеру/устройству.
--      Полноценная sync между устройствами — только для авторизованных.
--   3) Push fire-and-forget: ошибки в лог, без retry. Главный сейв уже на
--      диске через save_manager → cloud — только зеркало.

local log = require "main.scripts.log"

local M = {
    ready         = false,   -- player_init успешно отстрелял
    initializing  = false,   -- идёт init, не дёргаем повторно
    available     = nil,     -- yagames вообще доступен? lazy-проверка
}

local yagames = nil  -- ленивая загрузка, чтобы require'а не было на ПК

local INIT_TIMEOUT_SEC  = 3.0
local PUSH_THROTTLE_SEC = 5.0
local PULL_TIMEOUT_SEC  = 3.0
local MAX_SAVE_BYTES    = 180 * 1024  -- запас от лимита 200 KB Яндекса

local _push_handle  = nil
local _pending_data = nil   -- последний снэпшот для отложенного push'а
local _init_callbacks = {}

local function call_later(callback, ...)
    if not callback then return end
    local args = { ... }
    timer.delay(0, false, function()
        callback(unpack(args))
    end)
end

-- Lazy-load yagames. На Windows/macOS/Linux сборке модуля может не быть
-- (или быть, но не инициализированным). pcall защищает от require-error.
local function ensure_yagames()
    if M.available ~= nil then return M.available end
    local ok, mod = pcall(require, "yagames.yagames")
    if ok and mod then
        yagames = mod
        M.available = true
    else
        log.info("cloud_sync", "yagames module unavailable - cloud sync disabled")
        M.available = false
    end
    return M.available
end

-- Оценка размера будущего JSON. Грубо: пробегаем по таблице и считаем
-- через rxi_json внутри yagames мы не имеем — используем sys.save в /tmp?
-- Нет, проще: tostring длина после json.encode стандартной либой если есть.
-- Lua не имеет встроенного json. Используем приблизительную оценку через
-- pcall(cjson.encode) если доступно, иначе heuristic: считаем строки/числа.
local function estimate_size(data)
    -- На HTML5 yagames использует rxi_json внутренне. Здесь нам нужна только
    -- грубая оценка. Простейший вариант — sys.save во временный файл и
    -- посмотреть размер. Но это и есть запись на диск.
    -- Поэтому: эвристика через подсчёт длин строк рекурсивно.
    local function rec(v)
        local t = type(v)
        if t == "string" then return #v + 2 end
        if t == "number" or t == "boolean" then return 12 end
        if t == "table" then
            local n = 2
            for k, vv in pairs(v) do
                n = n + (type(k) == "string" and #k + 4 or 12) + rec(vv) + 1
            end
            return n
        end
        return 4
    end
    return rec(data or {})
end

local function finish_init(err)
    M.ready = not err
    M.initializing = false
    local cbs = _init_callbacks
    _init_callbacks = {}
    for _, cb in ipairs(cbs) do
        cb(err)
    end
end

-- init(callback) — стартует Yandex SDK + player_init. callback(err).
-- err = nil → ready=true, можно push/pull.
-- err != nil → ready=false, cloud отключён до перезапуска игры.
function M.init(callback)
    if M.ready then
        call_later(callback, nil)
        return
    end
    if callback then table.insert(_init_callbacks, callback) end
    if M.initializing then return end

    if not ensure_yagames() then
        finish_init("unavailable")
        return
    end

    M.initializing = true
    local completed = false
    local function complete(err)
        if completed then return end
        completed = true
        if err then
            log.info("cloud_sync", "init failed:", err)
        else
            log.info("cloud_sync", "ready")
        end
        finish_init(err)
    end

    timer.delay(INIT_TIMEOUT_SEC, false, function()
        complete("timeout")
    end)

    -- 1) Базовый SDK init (тот же что yandex_ads делает, но у yagames он
    -- идемпотентен — повторный вызов сразу даст ok).
    local ok, err = pcall(yagames.init, function(_, sdk_err)
        if sdk_err then return complete(sdk_err) end
        -- 2) player_init: для гостей тоже работает.
        local ok2, err2 = pcall(yagames.player_init, { scopes = false }, function(_, p_err)
            complete(p_err)
        end)
        if not ok2 then complete(err2 or "player_init call failed") end
    end)
    if not ok then complete(err or "sdk init call failed") end
end

-- pull(callback) — загрузка сейва из облака. callback(err, data).
-- data = nil → в облаке ничего нет, err = nil тоже nil (это OK кейс).
-- err != nil → не удалось, callback(err, nil).
function M.pull(callback)
    if not M.ready then
        call_later(callback, "not_ready", nil)
        return
    end
    local completed = false
    local function complete(err, data)
        if completed then return end
        completed = true
        callback(err, data)
    end
    timer.delay(PULL_TIMEOUT_SEC, false, function()
        complete("timeout", nil)
    end)
    local ok, err = pcall(yagames.player_get_data, nil, function(_, p_err, result)
        if p_err then return complete(p_err, nil) end
        -- result — таблица { save = <наш save> } или пустая {}.
        local payload = result and result.save or nil
        complete(nil, payload)
    end)
    if not ok then complete(err or "pull call failed", nil) end
end

-- Внутренний синхронный push. data — полный snapshot save_manager._data.
-- flush=true → Яндекс сразу шлёт на сервер (без батчинга на их стороне).
local function do_push(data, flush, callback)
    if not M.ready then
        call_later(callback, "not_ready")
        return
    end
    local size = estimate_size(data)
    -- Мониторинг роста сейва. Если приближаемся к лимиту — надо включать
    -- ink state-snapshot (Stage 6, отложено). Сейчас типичный размер 15-25 KB
    -- при одной главе, 50-80 выборах. При 3+ главах или 200+ выборах ждём
    -- ~50-80 KB. Лимит Яндекса 200 KB.
    log.info("cloud_sync", "push size:", size, "bytes")
    if size > MAX_SAVE_BYTES then
        log.warn("cloud_sync", "save too large for cloud:", size, "bytes (limit",
            MAX_SAVE_BYTES, ") - skipping push. Time to enable ink state-snapshot.")
        call_later(callback, "too_large")
        return
    end
    local ok, err = pcall(yagames.player_set_data, { save = data }, flush == true,
        function(_, p_err)
            if p_err then
                log.info("cloud_sync", "push error:", p_err)
            end
            if callback then callback(p_err) end
        end)
    if not ok then
        log.info("cloud_sync", "push call failed:", err)
        if callback then callback(err or "push call failed") end
    end
end

-- push_throttled(data) — отложенный fire-and-forget push (5с окно).
-- Перезаписывает pending payload, таймер не сбрасывает (накапливание).
-- Цель: не жечь квоту Яндекса при частых debounce-write'ах.
function M.push_throttled(data)
    _pending_data = data
    if _push_handle then return end  -- таймер уже стоит, payload обновили
    _push_handle = timer.delay(PUSH_THROTTLE_SEC, false, function()
        _push_handle = nil
        local payload = _pending_data
        _pending_data = nil
        if payload and M.ready then
            do_push(payload, false, nil)
        end
    end)
end

-- flush_now(data, callback) — синхронный push. Звать на final hook.
-- Игнорирует throttle, шлёт немедленно с flush=true.
function M.flush_now(data, callback)
    if _push_handle then
        timer.cancel(_push_handle)
        _push_handle = nil
    end
    _pending_data = nil
    if not M.ready then
        call_later(callback, "not_ready")
        return
    end
    do_push(data, true, callback)
end

return M
