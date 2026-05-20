local gs = require "main.scripts.game_state"
local meta = require "main.scripts.meta_state"
local scene_controller = require "main.scripts.scene_controller"
local yandex_ads = require "main.scripts.yandex_ads"

local M = {}

local function apply_single(cmd, ctx)
    if cmd.type == "enter_scene" then
        if cmd.scene == "phone_home" then
            ctx.open_phone()
        elseif scene_controller.enter then
            scene_controller.enter(cmd.scene)
        elseif scene_controller.enter_scene then
            scene_controller.enter_scene(cmd.scene)
        end
    elseif cmd.type == "return_to_scene" then
        if scene_controller.return_to_last_scene then
            scene_controller.return_to_last_scene()
        end
    elseif cmd.type == "set_flag" then
        if gs.set_flag then gs.set_flag(cmd.flag, cmd.value) end
    elseif cmd.type == "add_item" then
        if gs.add_item then gs.add_item(cmd.item) end
    elseif cmd.type == "remove_item" then
        if gs.remove_item then gs.remove_item(cmd.item) end
    elseif cmd.type == "set_quest" then
        if gs.set_quest then gs.set_quest(cmd.quest, cmd.status) end
    elseif cmd.type == "add_sms" then
        if gs.add_sms then
            -- opts (для add_old) важнее одиночного hot-флага. Передаём то что есть.
            gs.add_sms(cmd.contact, cmd.text, cmd.opts or cmd.hot)
        end
    elseif cmd.type == "reply_sms" then
        if gs.reply_sms then gs.reply_sms(cmd.contact, cmd.text) end
    elseif cmd.type == "reply_old_sms" then
        if gs.reply_old_sms then gs.reply_old_sms(cmd.contact, cmd.text, cmd.opts) end
    elseif cmd.type == "mark_sms_read" then
        if gs.mark_sms_read then gs.mark_sms_read(cmd.contact) end
    elseif cmd.type == "set_sms_tag" then
        if gs.set_sms_tag then gs.set_sms_tag(cmd.contact, cmd.tone, cmd.label) end
    elseif cmd.type == "bank_set_balance" then
        if gs.set_bank_balance then gs.set_bank_balance(cmd.amount) end
    elseif cmd.type == "bank_charge" then
        if gs.bank_charge then gs.bank_charge(cmd.amount, cmd.merchant) end
    elseif cmd.type == "add_msg" then
        if gs.add_msg then gs.add_msg(cmd.chat, cmd.text, cmd.opts) end
    elseif cmd.type == "reply_msg" then
        if gs.reply_msg then gs.reply_msg(cmd.chat, cmd.text) end
    elseif cmd.type == "reply_old_msg" then
        if gs.reply_old_msg then gs.reply_old_msg(cmd.chat, cmd.text, cmd.opts) end
    elseif cmd.type == "mark_msg_read" then
        if gs.mark_msg_read then gs.mark_msg_read(cmd.chat) end
    elseif cmd.type == "set_msg_tag" then
        if gs.set_msg_tag then gs.set_msg_tag(cmd.chat, cmd.tone, cmd.label) end
    elseif cmd.type == "set_msg_prompt" then
        if gs.set_msg_prompt then gs.set_msg_prompt(cmd.chat, cmd.knot, cmd.label) end
    elseif cmd.type == "add_note" then
        if gs.add_note then gs.add_note(cmd.title, cmd.body) end
    elseif cmd.type == "add_mail" then
        if gs.add_mail then gs.add_mail(cmd.from, cmd.subject, cmd.body) end
    elseif cmd.type == "mark_mail_read" then
        if gs.mark_mail_read then gs.mark_mail_read(cmd.index) end
    elseif cmd.type == "mark_all_mail_read" then
        if gs.mark_all_mail_read then gs.mark_all_mail_read() end
    elseif cmd.type == "add_call" then
        if gs.add_call then gs.add_call(cmd.who, cmd.kind) end
    elseif cmd.type == "mark_all_calls_seen" then
        if gs.mark_all_calls_seen then gs.mark_all_calls_seen() end
    elseif cmd.type == "add_clue" then
        if gs.add_clue then gs.add_clue(cmd.id, cmd.label) end
    elseif cmd.type == "add_terminal_line" then
        if gs.add_terminal_line then gs.add_terminal_line(cmd.level, cmd.text) end
    elseif cmd.type == "clear_terminal" then
        if gs.clear_terminal then gs.clear_terminal() end
    elseif cmd.type == "reset_terminal" then
        if gs.reset_terminal_to_defaults then gs.reset_terminal_to_defaults() end
    elseif cmd.type == "meta_add" then
        if meta.inc then meta.inc(cmd.key, cmd.delta) end
    elseif cmd.type == "meta_set" then
        if meta.set then meta.set(cmd.key, cmd.value) end
    elseif cmd.type == "phone_close" then
        ctx.close_phone()
    elseif cmd.type == "open_phone_app" then
        return ctx.open_phone_app(cmd.app)
    elseif cmd.type == "map_allow" then
        if gs.map_allow then gs.map_allow(cmd.poi) end
    elseif cmd.type == "map_allow_reset" then
        if gs.map_allow_reset then gs.map_allow_reset() end
    elseif cmd.type == "map_lock_to" then
        if gs.map_lock_to then gs.map_lock_to(cmd.poi) end
    elseif cmd.type == "map_lock_all" then
        if gs.map_lock_all then gs.map_lock_all() end
    elseif cmd.type == "hud_hint" then
        -- # hud:hint:phone | bag | reset — пульсация HUD-кнопки.
        -- ctx.set_hud_hint делегирует посыл сообщения в hud_v2.
        if ctx.set_hud_hint then ctx.set_hud_hint(cmd.target) end
    elseif cmd.type == "scene_char_show" then
        if ctx.scene_char_show then ctx.scene_char_show(cmd.scene, cmd.char) end
    elseif cmd.type == "scene_char_hide" then
        if ctx.scene_char_hide then ctx.scene_char_hide(cmd.scene, cmd.char) end
    elseif cmd.type == "scene_char_hide_all" then
        if ctx.scene_char_hide_all then ctx.scene_char_hide_all() end
    elseif cmd.type == "transit_start" then
        if ctx.show_transit then ctx.show_transit(cmd) end
    elseif cmd.type == "transit_end" then
        if ctx.hide_transit then ctx.hide_transit() end
    end
end

local function apply_from(cmds, start_index, ctx)
    local should_pause_render = false

    for i = start_index or 1, #cmds do
        local cmd = cmds[i]
        if cmd.type == "show_ad" then
            local function resume_after_ad()
                apply_from(cmds, i + 1, ctx)
                ctx.on_resume()
            end

            if cmd.ad_kind == "rewarded" then
                yandex_ads.show_rewarded(nil, function(rewarded)
                    if rewarded and cmd.reward_flag and gs.set_flag then
                        gs.set_flag(cmd.reward_flag, true)
                    end
                    resume_after_ad()
                end)
            else
                yandex_ads.show_fullscreen(resume_after_ad)
            end
            return true
        elseif cmd.type == "splash" then
            -- Универсальная splash-перебивка. Async-паттерн как у show_ad:
            -- запускаем компонент, остаток очереди — в on_done callback.
            if ctx.show_splash then
                ctx.show_splash(cmd, function()
                    apply_from(cmds, i + 1, ctx)
                    ctx.on_resume()
                end)
                return true
            end
        end

        if apply_single(cmd, ctx) then
            should_pause_render = true
        end
    end
    return should_pause_render
end

function M.apply(cmds, ctx)
    return apply_from(cmds or {}, 1, ctx)
end

return M
