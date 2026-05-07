local dm = require "main.scripts.dialogue_manager_ink"

local M = {}

local function dispatch(effect, ctx)
    if not effect or not effect.type then
        return
    end

    if effect.type == "sfx" then
        local url = effect.name and ctx.sfx_urls[effect.name] or nil
        if url then
            msg.post(url, "play_sound", {
                delay = 0,
                gain = tonumber(effect.gain) or 0.6,
            })
        else
            print("[ui_manager_v2] WARNING: unknown sfx effect:", tostring(effect.name))
        end
    elseif effect.type == "shake" then
        msg.post(ctx.components.effects, "play_shake", {
            intensity = tonumber(effect.intensity) or 0.2,
            duration = tonumber(effect.duration) or 0.4,
        })
    elseif effect.type == "pulse" then
        msg.post(ctx.components.effects, "play_pulse", {
            duration = tonumber(effect.duration) or 0.5,
            r = tonumber(effect.r) or 1,
            g = tonumber(effect.g) or 1,
            b = tonumber(effect.b) or 1,
        })
    end
end

function M.consume(ctx)
    local effects = dm.get_effects and dm.get_effects() or {}
    for _, effect in ipairs(effects) do
        dispatch(effect, ctx)
    end
end

return M
