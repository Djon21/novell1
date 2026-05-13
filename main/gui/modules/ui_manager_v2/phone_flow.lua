local gs = require "main.scripts.game_state"
local MSG = require "main.gui.modules.messages"

local M = {}

function M.has_access()
    return gs.has_item and gs.has_item("phone") or false
end

function M.open(ctx)
    ctx.dbg("[ui_manager_v2] open_phone()")
    if not M.has_access() then
        ctx.dbg("[ui_manager_v2] phone is unavailable, aborting")
        return false
    end

    ctx.overlays.phone = true
    ctx.sync_modal_state()
    msg.post(ctx.components.phone, MSG.open_phone)
    return true
end

function M.open_app(ctx, app_id)
    M.open(ctx)
    if ctx.overlays.phone then
        msg.post(ctx.components.phone, MSG.open_app, { id = app_id or "sms" })
        return true
    end
    return false
end

function M.close(ctx)
    ctx.dbg("[ui_manager_v2] close_phone()")
    ctx.overlays.phone = false
    ctx.sync_modal_state()
    msg.post(ctx.components.phone, MSG.close_phone)
end

function M.open_map_app(ctx)
    if not ctx.overlays.phone then
        return false
    end
    msg.post(ctx.components.phone, MSG.open_app, { id = "map" })
    return true
end

return M
