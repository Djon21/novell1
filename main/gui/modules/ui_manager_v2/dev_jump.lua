-- Dev checkpoints for fast manual testing.
-- Works only in debug builds: F3 selects checkpoint, F4 jumps to it.

local dm = require "main.scripts.dialogue_manager_ink"
local gs = require "main.scripts.game_state"
local log = require "main.scripts.log"
local scene_controller = require "main.scripts.scene_controller"
local sm = require "main.scripts.save_manager"

local M = {}

local selected_index = 0

local function is_debug_build()
    if not sys or not sys.get_engine_info then return false end
    local info = sys.get_engine_info()
    return info and info.is_debug == true
end

local BASE_PHONE_MESSAGES = {
    sms = {
        { "mama", "Не забудь позавтракать. И не сиди весь день дома." },
        { "bank", "Карта *4821: списание 349 ₽. Кофе и выпечка. 08:41." },
        { "prod", "Напоминание: в понедельник до 11:00 подтвердите статус по кейсу 017." },
    },
    msg = {
        { "friends", "Доброе утро, выжившие. Кто сегодня не отменяет планы в последний момент?" },
        { "work_team", "Понедельничная планёрка перенесена на 10:40. Да, в воскресенье. Нет, я тоже не рад." },
        { "prod_bot", "CASE-017 создан." },
    },
}

local function clone_message_list(list)
    local out = {}
    for i, entry in ipairs(list or {}) do
        out[i] = { entry[1], entry[2] }
    end
    return out
end

local function common_phone_state()
    return {
        flags = {
            phone_active = true,
            phone_taken = true,
        },
        vars = {
            phone_active = true,
            phone_taken = true,
        },
        items = { "phone" },
        sms = clone_message_list(BASE_PHONE_MESSAGES.sms),
        msg = clone_message_list(BASE_PHONE_MESSAGES.msg),
    }
end

local function sunday_ready_state()
    local state = common_phone_state()
    state.flags.got_out_of_bed = true
    state.flags.bathroom_morning_seen = true
    state.flags.toothbrush_taken = true
    state.flags.toothpaste_taken = true
    state.flags.toothbrush_pasted_ready = true
    state.flags.teeth_brushed = true
    state.flags.washed_up = true
    state.flags.mug_taken = true
    state.flags.coffee_drunk = true
    state.flags.sunday_morning_routine_seen = true
    state.flags.sunday_messenger_invite_sent = true
    state.flags.date_agreed = true
    state.flags.date_place_park = true
    state.flags.sunday_dressed = true
    state.flags.sunday_ready_to_leave = true

    state.vars.got_out_of_bed = true
    state.vars.bathroom_morning_seen = true
    state.vars.toothbrush_taken = true
    state.vars.toothpaste_taken = true
    state.vars.toothbrush_pasted_ready = true
    state.vars.teeth_brushed = true
    state.vars.washed_up = true
    state.vars.mug_taken = true
    state.vars.coffee_drunk = true
    state.vars.sunday_morning_routine_seen = true
    state.vars.sunday_messenger_invite_sent = true
    state.vars.date_agreed = true
    state.vars.date_place_park = true
    state.vars.sunday_dressed = true
    state.vars.sunday_ready_to_leave = true

    table.insert(state.items, "mug")
    table.insert(state.items, "toothbrush_pasted")

    state.quests = {
        find_phone = "done",
        make_coffee = "done",
        reply_npc = "done",
        meet_npc = "active",
    }

    table.insert(state.msg, { "mila", "Ты сегодня вообще живой?" })
    table.insert(state.msg, { "mila", "Я уже второй кофе пью." })
    table.insert(state.msg, { "mila", "Выберемся куда-нибудь, пока день не стал совсем домашним?" })
    return state
end

local function park_state()
    local state = sunday_ready_state()
    state.flags.park_arrived = true
    state.flags.park_entrance_seen = true
    state.flags.park_where_message_sent = true
    state.flags.park_npc_greeted = true

    state.vars.park_arrived = true
    state.vars.park_entrance_seen = true
    state.vars.park_where_message_sent = true
    state.vars.park_npc_greeted = true
    return state
end

local function monday_state()
    local state = common_phone_state()
    state.flags.sunday_finished = true
    state.flags.monday_started = true
    state.flags.monday_morning_started = true

    state.vars.sunday_finished = true
    state.vars.monday_started = true
    state.vars.monday_morning_started = true
    state.vars.iteration_number = 1

    state.items = { "phone" }
    state.quests = {
        go_to_office = "active",
    }
    return state
end

local function monday_office_state()
    local state = monday_state()
    state.flags.monday_dressed = true
    state.flags.work_card_taken = true
    state.flags.mon_office_started = true

    table.insert(state.items, "card")
    state.quests.go_to_office = "done"
    state.quests.work_case = "active"
    return state
end

local function tuesday_state()
    local state = common_phone_state()
    state.flags.sunday_finished = true
    state.flags.monday_started = true
    state.flags.tuesday_started = true
    state.flags.tuesday_morning_started = true

    state.vars.sunday_finished = true
    state.vars.monday_started = true
    state.vars.iteration_number = 1

    state.quests = {
        follow_monday_trace = "active",
    }
    return state
end

local PRESETS = {
    {
        id = "sunday_start_bedroom",
        label = "Sunday: bedroom start",
        scene = "apartment_bedroom",
        state = {},
    },
    {
        id = "sunday_ready_to_leave",
        label = "Sunday: apartment ready to leave",
        scene = "apartment_hub",
        state = sunday_ready_state(),
    },
    {
        id = "sunday_park_route",
        label = "Sunday: route to park",
        knot = "sunday_date_go_park",
        state = sunday_ready_state(),
        allow_chapter_end = true,
    },
    {
        id = "sunday_park_bench",
        label = "Sunday: park bench exploration",
        scene = "park_riverside_bench",
        state = park_state(),
    },
    {
        id = "monday_home",
        label = "Monday: apartment morning",
        scene = "monday_apartment_bedroom_morning",
        state = monday_state(),
    },
    {
        id = "monday_office_choice",
        label = "Monday: office core choice",
        knot = "mon_office_core_choice",
        state = monday_office_state(),
        allow_chapter_end = true,
    },
    {
        id = "tuesday_home",
        label = "Tuesday: apartment morning",
        scene = "tuesday_apartment_bedroom_morning",
        state = tuesday_state(),
    },
    {
        id = "tuesday_rooftop",
        label = "Tuesday: rooftop finale",
        knot = "tue_rooftop_entry",
        state = tuesday_state(),
        allow_chapter_end = true,
    },
}

local function current_preset()
    local index = selected_index
    if index < 1 then index = 1 end
    return PRESETS[index]
end

local function notify(text)
    log.info("dev_jump", text)
    print("[dev_jump] " .. text)
end

local function set_story_var(name, value)
    if dm.set_var then
        dm.set_var(name, value, true)
    end
end

local function merge_state(dst, src)
    if not src then return dst end
    for key, value in pairs(src) do
        if type(value) == "table" then
            dst[key] = dst[key] or {}
            if #value > 0 then
                for _, item in ipairs(value) do table.insert(dst[key], item) end
            else
                for k, v in pairs(value) do dst[key][k] = v end
            end
        else
            dst[key] = value
        end
    end
    return dst
end

local function apply_state(state)
    state = state or {}

    for name, value in pairs(state.flags or {}) do
        gs.set_flag(name, value)
    end

    for name, value in pairs(state.vars or {}) do
        set_story_var(name, value)
    end

    for _, item_id in ipairs(state.items or {}) do
        gs.add_item(item_id)
    end

    for id, status in pairs(state.quests or {}) do
        gs.set_quest(id, status)
    end

    for _, entry in ipairs(state.sms or {}) do
        gs.add_sms(entry[1], entry[2])
    end

    for _, entry in ipairs(state.msg or {}) do
        gs.add_msg(entry[1], entry[2])
    end

    if state.map_lock_all then
        gs.map_lock_all()
    elseif state.map_lock_to then
        gs.map_lock_to(state.map_lock_to)
    elseif state.map_allow then
        gs.map_allow_reset()
        for _, poi_id in ipairs(state.map_allow) do
            gs.map_allow(poi_id)
        end
    end
end

local function reset_ui(ctx, base_mode)
    local UI = ctx.M
    UI.at_end = false
    UI.base_mode = base_mode
    UI.overlays.choice = false
    UI.overlays.inventory = false
    UI.overlays.phone = false
    UI.overlays.backlog = false

    ctx.sync_modal_state()
    ctx.reset_dialogue_backlog()

    msg.post(UI.components.choice, "hide_choice")
    msg.post(UI.components.inventory, "hide_inventory")
    msg.post(UI.components.phone, "close_phone")
    msg.post(UI.components.hotspots, "hide_all")
end

function M.is_enabled()
    return is_debug_build()
end

function M.select_next()
    if not M.is_enabled() then return false end
    selected_index = selected_index + 1
    if selected_index > #PRESETS then selected_index = 1 end

    local p = current_preset()
    notify(("selected %d/%d: %s [%s]"):format(selected_index, #PRESETS, p.label, p.id))
    return true
end

function M.apply_selected(ctx)
    if not M.is_enabled() then return false end
    local preset = current_preset()
    if not preset then return false end

    local bytes = ctx.load_main_story_bytes()
    if not bytes then return false end

    local gender = preset.gender or "male"
    sm.new_game()
    sm.set_gender(gender)

    ctx.reset_runtime_state()
    dm.init(bytes)
    reset_ui(ctx, preset.scene and "exploration" or "dialogue")

    local state = merge_state({}, preset.state)
    apply_state(state)
    set_story_var("mc_gender", gender)
    set_story_var("mc_name", gender == "female" and "Мила" or "Артём")
    set_story_var("npc_name", gender == "female" and "Артём" or "Мила")

    if preset.scene then
        scene_controller.enter(preset.scene, { skip_on_enter = preset.skip_on_enter ~= false })
        ctx.show_exploration()
    elseif preset.knot then
        dm.jump_to_knot(preset.knot, { allow_chapter_end = preset.allow_chapter_end == true })
        ctx.handle_dialogue_update()
    end

    ctx.sync_ui_state()
    ctx.persist_run_state()
    notify(("jumped to: %s [%s]"):format(preset.label, preset.id))
    return true
end

function M.get_presets()
    return PRESETS
end

return M
