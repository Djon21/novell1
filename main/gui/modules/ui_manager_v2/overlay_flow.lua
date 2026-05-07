local meta = require "main.scripts.meta_state"
local ui_state = require "main.scripts.ui_state"

local M = {}

function M.sync_modal_state(overlays)
    ui_state.modal_open = (overlays.phone or overlays.inventory or overlays.map or overlays.backlog) and true or false
end

function M.show_menu(ctx)
    ctx.set_base_mode("menu")
    ctx.set_at_end(false)
    ctx.reset_dialogue_play_modes()

    msg.post(ctx.components.hud,       "hide_hud")
    msg.post(ctx.components.dialogue,  "hide_dialogue")
    msg.post(ctx.components.dialogue,  "hide_bg")
    msg.post(ctx.components.choice,    "hide_choice")
    msg.post(ctx.components.inventory, "hide_inventory")
    msg.post(ctx.components.phone,     "close_phone")
    msg.post(ctx.components.map,       "close_map")
    msg.post(ctx.components.hotspots,  "hide_all")

    ctx.refresh_menu_state()
    msg.post(ctx.components.main_menu, "show_menu")
    ctx.dbg("[ui_manager_v2] mode: menu")
end

function M.show_exploration(ctx)
    ctx.set_base_mode("exploration")
    ctx.reset_dialogue_autoplay_state()
    ctx.dbg("[ui_manager_v2] show_exploration()")

    msg.post(ctx.components.main_menu, "hide_menu")
    msg.post(ctx.components.dialogue,  "hide_dialogue")
    msg.post(ctx.components.dialogue,  "show_bg")
    msg.post(ctx.components.hud,       "show_hud")

    ctx.close_phone()
    ctx.close_inventory()
    ctx.close_map()
    ctx.hide_choice()
    ctx.dbg("[ui_manager_v2] mode: exploration")
end

function M.show_dialogue(ctx)
    ctx.set_base_mode("dialogue")

    msg.post(ctx.components.main_menu, "hide_menu")
    msg.post(ctx.components.dialogue,  "show_bg")
    msg.post(ctx.components.hud,       "show_hud")
    msg.post(ctx.components.hotspots,  "hide_all")
    msg.post(ctx.components.dialogue,  "show_dialogue")
    ctx.dbg("[ui_manager_v2] mode: dialogue")
end

function M.open_inventory(ctx)
    ctx.dbg("[ui_manager_v2] open_inventory()")
    ctx.clear_armed_state()
    ctx.overlays.inventory = true
    M.sync_modal_state(ctx.overlays)
    msg.post(ctx.components.inventory, "show_inventory")
end

function M.close_inventory(ctx)
    ctx.dbg("[ui_manager_v2] close_inventory()")
    ctx.overlays.inventory = false
    M.sync_modal_state(ctx.overlays)
    msg.post(ctx.components.inventory, "hide_inventory")
end

function M.open_map(ctx)
    if ctx.open_phone_map_app() then
        return
    end
    ctx.overlays.map = true
    M.sync_modal_state(ctx.overlays)
    ctx.sync_map_overlay(ctx.resolve_map_selected_pin(), "> карта синхронизирована _")
    msg.post(ctx.components.map, "open_map")
end

function M.open_map_hub(ctx, primary_knot)
    ctx.overlays.map = true
    M.sync_modal_state(ctx.overlays)
    ctx.set_at_end(false)
    msg.post(ctx.components.dialogue, "hide_dialogue")
    ctx.sync_map_overlay(ctx.resolve_map_selected_pin(), "> выбрать маршрут _")
    msg.post(ctx.components.map, "open_map_hub", { primary_knot = primary_knot })
end

function M.close_map(ctx)
    ctx.overlays.map = false
    M.sync_modal_state(ctx.overlays)
    msg.post(ctx.components.map, "close_map")
end

function M.show_choice(ctx, opts, timer_sec, title)
    ctx.overlays.choice = true

    local location_label = ctx.resolve_current_location_label()
    ctx.post_location_to_ui(location_label)

    msg.post(ctx.components.choice, "show_choice", {
        opts = opts or {},
        timer_sec = timer_sec or 18,
        title = title,
        loop = meta.get and meta.get("iteration_number", 1) or 1,
        loop_label = meta.get_iteration_label and meta.get_iteration_label() or nil,
        iteration_number = meta.get and meta.get("iteration_number", 1) or 1,
        iteration_label = meta.get_iteration_label and meta.get_iteration_label() or nil,
        scene_id = ctx.current_scene_id(),
        location_label = location_label,
        location_name = location_label,
    })
end

function M.hide_choice(ctx)
    ctx.overlays.choice = false
    msg.post(ctx.components.choice, "hide_choice")
end

return M
