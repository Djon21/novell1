local yagames = require "yagames.yagames"

local M = {
    ready = false,
    initializing = false,
    ad_open = false,
}

local pending_init_callbacks = {}
local INIT_TIMEOUT_SEC = 2.0
local FULLSCREEN_TIMEOUT_SEC = 3.0

local function call_later(callback, ...)
    if not callback then return end
    local args = { ... }
    timer.delay(0, false, function()
        callback(unpack(args))
    end)
end

local function set_master_gain(value)
    local ok, err = pcall(sound.set_group_gain, "master", value)
    if not ok then
        print("[yandex_ads] sound gain failed:", err)
    end
end

local function call_yagames(name, ...)
    local fn = yagames and yagames[name]
    if type(fn) ~= "function" then
        return false, "missing yagames." .. tostring(name)
    end
    return pcall(fn, ...)
end

local function finish_init(err)
    M.ready = not err
    M.initializing = false

    local callbacks = pending_init_callbacks
    pending_init_callbacks = {}
    for _, callback in ipairs(callbacks) do
        callback(err)
    end
end

function M.init(callback)
    if M.ready then
        call_later(callback, nil)
        return
    end

    if callback then
        table.insert(pending_init_callbacks, callback)
    end

    if M.initializing then
        return
    end

    M.initializing = true
    local completed = false
    local function complete(err)
        if completed then return end
        completed = true
        finish_init(err)
    end

    timer.delay(INIT_TIMEOUT_SEC, false, function()
        if completed then return end
        print("[yandex_ads] Yandex SDK init timeout")
        complete("timeout")
    end)

    local ok, call_err = call_yagames("init", function(_, err)
        if err then
            print("[yandex_ads] Yandex SDK init error:", err)
        else
            print("[yandex_ads] Yandex SDK ready")
        end
        complete(err)
    end)
    if not ok then
        print("[yandex_ads] Yandex SDK init call failed:", call_err)
        complete(call_err)
    end
end

local function wait_until_ready(on_ready, on_done)
    if M.ready then
        on_ready()
        return
    end

    print("[yandex_ads] ad delayed: Yandex SDK is not ready yet")
    M.init(function(err)
        if err then
            call_later(on_done, false)
            return
        end
        on_ready()
    end)
end

function M.show_fullscreen(on_done)
    if M.ad_open then
        print("[yandex_ads] fullscreen skipped: another ad is already open")
        call_later(on_done, false)
        return
    end
    wait_until_ready(function()
        local finished = false
        local opened = false
        local function finish(was_shown)
            if finished then return end
            finished = true
            set_master_gain(1)
            call_yagames("features_gameplayapi_start")
            M.ad_open = false
            if on_done then on_done(was_shown == true) end
        end

        M.ad_open = true
        call_yagames("features_gameplayapi_stop")

        timer.delay(FULLSCREEN_TIMEOUT_SEC, false, function()
            if finished then return end
            if not opened then
                print("[yandex_ads] fullscreen timeout")
                finish(false)
            end
        end)

        local ok, err = call_yagames("adv_show_fullscreen_adv", {
            open = function()
                opened = true
                set_master_gain(0)
                print("[yandex_ads] fullscreen opened")
            end,

            close = function(_, was_shown)
                print("[yandex_ads] fullscreen closed, was_shown=", tostring(was_shown))
                finish(was_shown == true)
            end,

            offline = function()
                print("[yandex_ads] fullscreen offline")
                finish(false)
            end,

            error = function(_, err)
                print("[yandex_ads] fullscreen error:", err)
                finish(false)
            end,
        })
        if not ok then
            print("[yandex_ads] fullscreen call failed:", err)
            finish(false)
        end
    end, on_done)
end

function M.show_rewarded(on_reward, on_done)
    if M.ad_open then
        print("[yandex_ads] rewarded skipped: another ad is already open")
        call_later(on_done, false)
        return
    end
    wait_until_ready(function()
        local rewarded = false
        local finished = false
        local opened = false
        local function finish()
            if finished then return end
            finished = true
            set_master_gain(1)
            call_yagames("features_gameplayapi_start")
            M.ad_open = false
            if on_done then on_done(rewarded) end
        end

        M.ad_open = true
        call_yagames("features_gameplayapi_stop")

        timer.delay(FULLSCREEN_TIMEOUT_SEC, false, function()
            if finished then return end
            if not opened then
                print("[yandex_ads] rewarded timeout")
                finish()
            end
        end)

        local ok, err = call_yagames("adv_show_rewarded_video", {
            open = function()
                opened = true
                set_master_gain(0)
                print("[yandex_ads] rewarded opened")
            end,

            rewarded = function()
                rewarded = true
                print("[yandex_ads] rewarded counted")
                if on_reward then on_reward() end
            end,

            close = function()
                print("[yandex_ads] rewarded closed, rewarded=", tostring(rewarded))
                finish()
            end,

            error = function(_, err)
                print("[yandex_ads] rewarded error:", err)
                finish()
            end,
        })
        if not ok then
            print("[yandex_ads] rewarded call failed:", err)
            finish()
        end
    end, on_done)
end

return M
