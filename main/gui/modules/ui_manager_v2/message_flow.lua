local dm = require "main.scripts.dialogue_manager_ink"
local gs = require "main.scripts.game_state"
local sm = require "main.scripts.save_manager"
local meta = require "main.scripts.meta_state"
local scene_controller = require "main.scripts.scene_controller"
local contacts = require "main.scripts.phone_contacts"

local M = {}

local function handle_menu(ctx, message_id, message, sender)
    if message_id == hash("show_menu") then
        ctx.show_menu()
        return true
    elseif message_id == hash("start_game") then
        ctx.start_new_run(false)
        return true
    elseif message_id == hash("continue_game") then
        sm.load()
        meta.init()
        if not sm.has_save() then
            print("[ui_manager_v2] continue_game ignored: no run-state save")
            ctx.refresh_menu_state()
            return true
        end

        local ok, bytes = pcall(sys.load_resource, "/main/story/chapter_01.json")
        if not ok or not bytes then
            print("[ui_manager_v2] ERROR: chapter_01.json not found")
            return true
        end
        ctx.prepare_run_restore()
        local restored = ctx.restore_run_state({ defer_scene_enter = true })
        ctx.reset_dialogue_backlog()
        dm.load_saved(bytes)
        if restored and restored.scene_to_enter then
            ctx.enter_restored_scene(restored.scene_to_enter)
        end
        ctx.handle_dialogue_update()
        ctx.sync_ui_state()
        return true
    elseif message_id == hash("reset_iteration") or message_id == hash("open_gallery") then
        ctx.reset_iteration_and_restart()
        return true
    elseif message_id == hash("open_achievements") then
        ctx.dbg("[ui_manager_v2] open_achievements (TODO)")
        return true
    end
    return false
end

local function finish_chapter_and_return_to_menu(ctx, log_prefix)
    local next_loop = meta.complete_iteration()
    sm.clear_run()
    ctx.reset_runtime_state()
    if log_prefix then
        ctx.dbg(log_prefix, next_loop.iteration_number)
    end
    ctx.show_menu()
end

local function reset_run_and_return_to_menu(ctx)
    sm.clear_run()
    ctx.reset_runtime_state()
    ctx.show_menu()
end

local function handle_ending(ctx, message_id, message, sender)
    if message_id == hash("chapter_finished") then
        finish_chapter_and_return_to_menu(ctx, "[ui_manager_v2] chapter_finished -> iteration")
        return true
    elseif message_id == hash("false_ending") then
        local iter = meta.get("iteration_number", 1) or 1
        if iter < 2 then
            print("[ui_manager_v2] iter 001: ignoring false_ending -> chapter_finished")
            finish_chapter_and_return_to_menu(ctx, "[ui_manager_v2] iter 001 forced-finish -> iteration")
            return true
        end

        local id = message and message.id or "unknown"
        local is_new = meta.record_false_ending(id)
        print("[ui_manager_v2] false_ending '" .. id .. "' new=" .. tostring(is_new)
              .. " awareness=" .. tostring(meta.get("loop_awareness"))
              .. " false_count=" .. tostring(meta.get_false_endings_count()))

        reset_run_and_return_to_menu(ctx)
        return true
    elseif message_id == hash("true_ending") then
        local iter = meta.get("iteration_number", 1) or 1
        if iter < 2 then
            print("[ui_manager_v2] iter 001: ignoring true_ending -> chapter_finished")
            finish_chapter_and_return_to_menu(ctx, nil)
            return true
        end

        if not meta.is_true_ending_unlocked() then
            print("[ui_manager_v2] WARNING: true_ending reached but not unlocked - treating as false_ending 'early_true'")
            meta.record_false_ending("early_true")
            reset_run_and_return_to_menu(ctx)
            return true
        end

        finish_chapter_and_return_to_menu(ctx, "[ui_manager_v2] true_ending -> iteration")
        return true
    end
    return false
end

local function handle_system(ctx, message_id, message, sender)
    if message_id == hash("apply_dialogue_bg") then
        ctx.apply_dialogue_bg(message and message.name)
        return true
    end
    return false
end

local function handle_dialogue(ctx, message_id, message, sender)
    if message_id == hash("dialogue_updated") then
        ctx.handle_dialogue_update()
        return true
    elseif message_id == hash("dialogue_next") then
        ctx.cancel_dialogue_autoplay()
        if dm.advance then dm.advance() end
        ctx.handle_dialogue_update()
        return true
    elseif message_id == hash("typewriter_done") then
        ctx.self.dialogue_waiting_for_typewriter = false
        if ctx.self.dialogue_skip or ctx.self.dialogue_auto then
            ctx.schedule_dialogue_autoadvance()
        end
        return true
    elseif message_id == hash("dialogue_skip") then
        ctx.dbg("[ui_manager_v2] dialogue_skip", message.on)
        ctx.set_dialogue_play_mode("skip", message and message.on)
        return true
    elseif message_id == hash("dialogue_auto") then
        ctx.dbg("[ui_manager_v2] dialogue_auto", message.on)
        ctx.set_dialogue_play_mode("auto", message and message.on)
        return true
    elseif message_id == hash("open_backlog") then
        ctx.open_dialogue_backlog()
        return true
    elseif message_id == hash("close_backlog") then
        ctx.close_dialogue_backlog()
        return true
    end
    return false
end

local function append_choice_to_backlog(ctx, index, speaker)
    local self = ctx.self
    local opt = self.current_choice_options and self.current_choice_options[index]
    if not opt then
        return
    end

    local text = tostring(opt.text or "")
    if self.current_choice_question and self.current_choice_question ~= "" then
        text = tostring(self.current_choice_question) .. "\n> " .. text
    end
    ctx.append_dialogue_backlog({
        kind = "choice",
        speaker = speaker,
        text = text,
    })
end

local function handle_choice(ctx, message_id, message, sender)
    if message_id == hash("choice_picked") then
        local idx = message and message.index
        append_choice_to_backlog(ctx, idx, "ВЫБОР")
        ctx.hide_choice()
        if dm.choose then dm.choose(message.index) end
        ctx.handle_dialogue_update()
        return true
    elseif message_id == hash("choice_timeout") then
        append_choice_to_backlog(ctx, 1, "АВТО-ВЫБОР")
        ctx.hide_choice()
        if dm.choose then dm.choose(1) end
        ctx.handle_dialogue_update()
        return true
    elseif message_id == hash("choice_cancelled") then
        ctx.hide_choice()
        return true
    end
    return false
end

local function handle_inventory(ctx, message_id, message, sender)
    if message_id == hash("open_inventory") then
        ctx.dbg("[ui_manager_v2] open_inventory from", sender)
        ctx.open_inventory()
        return true
    elseif message_id == hash("close_inventory") then
        ctx.dbg("[ui_manager_v2] close_inventory")
        ctx.close_inventory()
        return true
    elseif message_id == hash("inventory_verb") then
        ctx.dbg("[ui_manager_v2] inventory_verb", message.item_id, message.verb,
            message.target_item_id or "")
        ctx.handle_inventory_verb(message.item_id, message.verb, {
            target_item_id = message.target_item_id,
        })
        return true
    elseif message_id == hash("cancel_armed_inventory") then
        ctx.clear_armed_state()
        return true
    end
    return false
end

local function handle_sms_open_contact(ctx, contact_id)
    if not contact_id then
        return
    end

    if gs.mark_sms_read then gs.mark_sms_read(contact_id) end

    local replied_flag = "sms_" .. tostring(contact_id) .. "_replied"
    if gs.get_flag and gs.get_flag(replied_flag) then
        return
    end

    ctx.close_phone()
    local knot_name = nil
    if contacts and contacts.get_ink_thread then
        knot_name = contacts.get_ink_thread(contact_id)
    end
    knot_name = knot_name or ("sms_thread_" .. tostring(contact_id))
    if dm.has_knot and dm.has_knot(knot_name) then
        local keep_bg = nil
        if scene_controller.is_active and scene_controller.is_active() then
            keep_bg = scene_controller.get_current_bg and scene_controller.get_current_bg() or nil
            if scene_controller.exit then scene_controller.exit() end
        end
        ctx.run_side_dialogue_knot(knot_name, keep_bg)
    end
end

-- Параллель к sms: тап на messenger-чат → если есть msg_thread_<chat> knot
-- и игрок ещё не отвечал, закрываем phone и прыгаем туда. Если knot'а нет
-- или уже ответили — игнорим (phone_messenger показывает inline view).
local function handle_messenger_open_chat(ctx, chat_id)
    if not chat_id then return end
    local replied_flag = "msg_" .. tostring(chat_id) .. "_replied"
    if gs.get_flag and gs.get_flag(replied_flag) then return end
    local knot_name = "msg_thread_" .. tostring(chat_id)
    if not (dm.has_knot and dm.has_knot(knot_name)) then return end
    ctx.close_phone()
    local keep_bg = nil
    if scene_controller.is_active and scene_controller.is_active() then
        keep_bg = scene_controller.get_current_bg and scene_controller.get_current_bg() or nil
        if scene_controller.exit then scene_controller.exit() end
    end
    ctx.run_side_dialogue_knot(knot_name, keep_bg)
end

local function handle_phone(ctx, message_id, message, sender)
    if message_id == hash("open_phone") then
        ctx.dbg("[ui_manager_v2] open_phone from", sender)
        ctx.open_phone()
        return true
    elseif message_id == hash("close_phone") then
        ctx.close_phone()
        return true
    elseif message_id == hash("phone_sms_viewed") then
        if gs.mark_all_sms_read then
            gs.mark_all_sms_read()
        end
        return true
    elseif message_id == hash("sms_open_contact") then
        handle_sms_open_contact(ctx, message and message.contact_id)
        return true
    elseif message_id == hash("messenger_open_chat") then
        handle_messenger_open_chat(ctx, message and message.chat_id)
        return true
    elseif message_id == hash("phone_app_clicked") then
        ctx.dbg("[ui_manager_v2] phone_app_clicked", message.id)
        return true
    elseif message_id == hash("map_travel") then
        local scene_id = message and message.scene
        ctx.dbg("[ui_manager_v2] map_travel ->", scene_id)
        if scene_id then
            ctx.close_phone()
            scene_controller.enter(scene_id)
        end
        return true
    end
    return false
end

local function handle_map(ctx, message_id, message, sender)
    if message_id == hash("open_map") then
        ctx.open_map()
        return true
    elseif message_id == hash("close_map") then
        ctx.close_map()
        return true
    elseif message_id == hash("map_verb") then
        ctx.dbg("[ui_manager_v2] map_verb", message.pin_id, message.verb)
        ctx.handle_map_verb(message.pin_id, message.verb)
        return true
    elseif message_id == hash("map_hub_route") then
        ctx.dbg("[ui_manager_v2] map_hub_route", message and message.knot)
        local knot = message and message.knot
        ctx.close_map()
        if knot then
            ctx.run_side_dialogue_knot(knot, nil, { allow_chapter_end = true })
        end
        return true
    end
    return false
end

function M.handle(ctx, message_id, message, sender)
    if handle_menu(ctx, message_id, message, sender) then return true end
    if handle_ending(ctx, message_id, message, sender) then return true end
    if handle_system(ctx, message_id, message, sender) then return true end
    if handle_dialogue(ctx, message_id, message, sender) then return true end
    if handle_choice(ctx, message_id, message, sender) then return true end
    if handle_inventory(ctx, message_id, message, sender) then return true end
    if handle_phone(ctx, message_id, message, sender) then return true end
    if handle_map(ctx, message_id, message, sender) then return true end
    return false
end

return M
