local dm = require "main.scripts.dialogue_manager_ink"
local catalog = require "main.scripts.items_catalog"
local ui_state = require "main.scripts.ui_state"

local M = {}

local ENABLED_VERBS = {
    use = true,
    inspect = true,
    read = true,
    give = true,
    combine = true,
}

local function resolve_knot(item_id, verb, scene_id, target_id)
    local candidates = {}

    if verb == "combine" and target_id and target_id ~= "" then
        local low, high = item_id, target_id
        if low > high then low, high = high, low end
        table.insert(candidates, "inv_combine_" .. low .. "_with_" .. high)
    elseif target_id and target_id ~= "" then
        if scene_id and scene_id ~= "" then
            table.insert(candidates, "inv_" .. scene_id .. "_" .. verb .. "_" .. item_id .. "_on_" .. target_id)
        end
        table.insert(candidates, "inv_" .. verb .. "_" .. item_id .. "_on_" .. target_id)
        table.insert(candidates, "inv_" .. verb .. "_" .. item_id .. "_on_fallback")
        table.insert(candidates, "inv_" .. verb .. "_on_" .. target_id)
    else
        if scene_id and scene_id ~= "" then
            table.insert(candidates, "inv_" .. scene_id .. "_" .. verb .. "_" .. item_id)
        end
        table.insert(candidates, "inv_" .. verb .. "_" .. item_id)
    end

    table.insert(candidates, "inv_" .. verb .. "_fallback")
    table.insert(candidates, "inv_fallback")

    for _, knot_name in ipairs(candidates) do
        if dm.has_knot and dm.has_knot(knot_name) then
            return knot_name
        end
    end
    return nil
end

function M.set_armed(item_id, verb, ctx)
    ui_state.set_armed(item_id, verb)
    local item = catalog.get_runtime and catalog.get_runtime(item_id) or catalog.get(item_id)
    local item_name = item and item.name or item_id
    ctx.show_armed_banner({
        item_id = item_id,
        item_name = item_name,
        verb = verb,
    })
end

function M.clear_armed(ctx)
    ui_state.clear_armed()
    ctx.hide_armed_banner()
end

local function fire_knot(item_id, verb, scene_id, target_id, target_kind, ctx)
    local item = catalog.get_runtime and catalog.get_runtime(item_id) or catalog.get(item_id)
    local knot_name = resolve_knot(item_id, verb, scene_id, target_id)
    if not knot_name then
        print("[inventory_flow] WARNING: no inventory knot for", item_id, verb, scene_id, target_id or "")
        return false
    end

    if dm.set_inventory_action_context then
        dm.set_inventory_action_context({
            item_id = item_id,
            item_name = item and item.name or item_id,
            verb = verb,
            scene_id = scene_id,
            target_id = target_id,
            target_kind = target_kind,
        })
    end
    ctx.jump_inventory_knot(knot_name)
    return true
end

function M.handle_verb(item_id, verb, extra, ctx)
    if not item_id or not verb then
        return
    end
    if not ENABLED_VERBS[verb] then
        print("[inventory_flow] inventory verb is not enabled in MVP:", tostring(verb))
        return
    end

    local scene_id = ctx.current_scene_id()
    local scene_data = ctx.current_scene_data()
    if not scene_id or scene_id == "" then
        print("[inventory_flow] inventory verbs are only supported from exploration in MVP")
        ctx.close_inventory()
        return
    end

    if verb == "combine" then
        local target_item = extra and extra.target_item_id or nil
        ctx.close_inventory()
        fire_knot(item_id, "combine", scene_id, target_item, target_item and "item" or nil, ctx)
        return
    end

    if item_id == "phone" and (verb == "use" or verb == "read") then
        ctx.close_inventory()
        ctx.open_phone()
        return
    end

    if verb == "use" then
        ctx.close_inventory()
        M.set_armed(item_id, "use", ctx)
        return
    end

    if verb == "give" then
        local npc_id = scene_data and scene_data.npc or nil
        ctx.close_inventory()
        if npc_id and npc_id ~= "" then
            fire_knot(item_id, "give", scene_id, npc_id, "npc", ctx)
        else
            fire_knot(item_id, "give", scene_id, nil, nil, ctx)
        end
        return
    end

    ctx.close_inventory()
    fire_knot(item_id, verb, scene_id, nil, nil, ctx)
end

function M.handle_armed_hotspot(hotspot_id, ctx)
    local armed = ui_state.get_armed()
    if not armed then
        return false
    end
    M.clear_armed(ctx)

    local scene_id = ctx.current_scene_id()
    if not scene_id or scene_id == "" then
        return false
    end

    fire_knot(armed.item_id, armed.verb, scene_id, hotspot_id, "hotspot", ctx)
    return true
end

return M
