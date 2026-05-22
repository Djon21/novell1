local dm = require "main.scripts.dialogue_manager_ink"
local backlog = require "main.scripts.dialogue_backlog"

local M = {}

function M.cancel_autoplay(self)
    if self.dialogue_autoplay_handle then
        timer.cancel(self.dialogue_autoplay_handle)
        self.dialogue_autoplay_handle = nil
    end
end

function M.reset_autoplay_state(self)
    M.cancel_autoplay(self)
    self.dialogue_waiting_for_typewriter = false
    self.dialogue_node_type = nil
    self.dialogue_current_text = ""
end

function M.reset_backlog()
    backlog.clear()
end

function M.open_backlog(ctx)
    ctx.overlays.backlog = true
    ctx.sync_modal_state()
    msg.post(ctx.components.hotspots, "hide_all")
    msg.post(ctx.components.dialogue, "open_backlog")
    msg.post(ctx.components.hud, "open_backlog")
end

function M.close_backlog(ctx)
    ctx.overlays.backlog = false
    ctx.sync_modal_state()
    msg.post(ctx.components.hud, "close_backlog")
    msg.post(ctx.components.dialogue, "close_backlog")
    if ctx.base_mode and ctx.base_mode() ~= "dialogue" then
        ctx.render_current_scene()
    end
end

function M.append_backlog(entry)
    backlog.add(entry)
end

local function compute_autoplay_delay(text, skip_mode, ctx)
    if skip_mode then
        return ctx.skip_advance_delay
    end
    local text_len = #(text or "")
    return math.min(ctx.auto_advance_max_delay, math.max(ctx.auto_advance_min_delay, 0.75 + (text_len / 28)))
end

local function can_autoadvance(self, ctx)
    return self.dialogue_node_type == "dialogue"
        and ctx.base_mode() == "dialogue"
        and not ctx.overlays.choice
        and not ctx.overlays.inventory
        and not ctx.overlays.phone
        and not ctx.overlays.backlog
        and not self.dialogue_waiting_for_typewriter
        and not ctx.at_end()
end

function M.apply_toggle_state(self, ctx)
    msg.post(ctx.components.dialogue, "set_auto", { on = self.dialogue_auto == true })
    msg.post(ctx.components.dialogue, "set_skip", { on = self.dialogue_skip == true })
end

function M.schedule_autoadvance(self, ctx)
    M.cancel_autoplay(self)
    if not can_autoadvance(self, ctx) then
        return
    end
    if not self.dialogue_auto and not self.dialogue_skip then
        return
    end

    if self.dialogue_skip and dm.is_last_in_queue and dm.is_last_in_queue() then
        return
    end

    local delay = compute_autoplay_delay(self.dialogue_current_text, self.dialogue_skip, ctx)
    self.dialogue_autoplay_handle = timer.delay(delay, false, function()
        self.dialogue_autoplay_handle = nil
        if not can_autoadvance(self, ctx) then
            return
        end
        msg.post(".", "dialogue_next")
    end)
end

function M.nudge_skip(self, ctx)
    if not self.dialogue_skip then
        return
    end
    if self.dialogue_node_type ~= "dialogue" then
        return
    end

    if dm.is_last_in_queue and dm.is_last_in_queue() then
        if self.dialogue_waiting_for_typewriter then
            timer.delay(0, false, function()
                if self.dialogue_waiting_for_typewriter and self.dialogue_node_type == "dialogue" then
                    msg.post(ctx.components.dialogue, "finish_typewriter")
                end
            end)
        end
        return
    end

    if self.dialogue_waiting_for_typewriter then
        timer.delay(0, false, function()
            if self.dialogue_skip and self.dialogue_waiting_for_typewriter and self.dialogue_node_type == "dialogue" then
                msg.post(ctx.components.dialogue, "finish_typewriter")
            end
        end)
    else
        M.schedule_autoadvance(self, ctx)
    end
end

function M.set_play_mode(self, mode, on, ctx)
    if mode == "auto" then
        self.dialogue_auto = on and true or false
        if self.dialogue_auto then
            self.dialogue_skip = false
        end
    elseif mode == "skip" then
        self.dialogue_skip = on and true or false
        if self.dialogue_skip then
            self.dialogue_auto = false
        end
    end

    M.cancel_autoplay(self)
    M.apply_toggle_state(self, ctx)
    M.nudge_skip(self, ctx)
    if not self.dialogue_waiting_for_typewriter then
        M.schedule_autoadvance(self, ctx)
    end
end

function M.reset_play_modes(self, ctx)
    self.dialogue_auto = false
    self.dialogue_skip = false
    M.reset_autoplay_state(self)
    M.apply_toggle_state(self, ctx)
end

return M
