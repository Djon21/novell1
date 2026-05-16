-- messages.lua
-- Централизованный реестр всех msg-сообщений в проекте.
--
-- Зачем: заменяет россыпь `hash("dialogue_next")`, `hash("phone_input")`
-- по коду на `M.dialogue_next` / `M.phone_input`. Опечатка ловится сразу
-- при require (модуль валидирует имена в init), а не превращается в
-- молчаливый no-op в runtime.
--
-- Использование:
--
--   local M = require "main.gui.modules.messages"
--
--   msg.post("#ui_manager_v2", M.open_phone)
--   if message_id == M.dialogue_next then ... end
--
-- Все значения — pre-computed hash. hash("foo") в Defold вызывается
-- runtime, но равен M.foo (один и тот же hash), так что взаимозаменяемо.

local M = {}

-- ---------------------------------------------------------------------------
-- Lifecycle (phone-app компоненты, оверлеи)
-- ---------------------------------------------------------------------------
M.open_app             = hash("open_app")
M.close_app            = hash("close_app")
M.refresh_app          = hash("refresh_app")

-- ---------------------------------------------------------------------------
-- Phone overlay + apps
-- ---------------------------------------------------------------------------
M.open_phone           = hash("open_phone")
M.close_phone          = hash("close_phone")
M.refresh_phone        = hash("refresh_phone")
M.set_phone_notif      = hash("set_phone_notif")
M.set_phone_time       = hash("set_phone_time")
M.set_phone_enabled    = hash("set_phone_enabled")
M.phone_input          = hash("phone_input")
M.phone_app_clicked    = hash("phone_app_clicked")
M.phone_sms_viewed     = hash("phone_sms_viewed")
M.sms_open_contact     = hash("sms_open_contact")
M.open_sms_thread      = hash("open_sms_thread")
M.messenger_open_chat  = hash("messenger_open_chat")

-- ---------------------------------------------------------------------------
-- Dialogue
-- ---------------------------------------------------------------------------
M.dialogue_next        = hash("dialogue_next")
M.dialogue_updated     = hash("dialogue_updated")
M.dialogue_skip        = hash("dialogue_skip")
M.dialogue_auto        = hash("dialogue_auto")
M.set_auto             = hash("set_auto")
M.set_skip             = hash("set_skip")
M.show_dialogue        = hash("show_dialogue")
M.hide_dialogue        = hash("hide_dialogue")
M.render_dialogue      = hash("render_dialogue")
M.resize_dialogue      = hash("resize_dialogue")
M.typewriter_done      = hash("typewriter_done")
M.finish_typewriter    = hash("finish_typewriter")
M.apply_dialogue_bg    = hash("apply_dialogue_bg")

-- ---------------------------------------------------------------------------
-- Choice
-- ---------------------------------------------------------------------------
M.show_choice          = hash("show_choice")
M.hide_choice          = hash("hide_choice")
M.choice_picked        = hash("choice_picked")
M.choice_timeout       = hash("choice_timeout")
M.choice_cancelled     = hash("choice_cancelled")

-- ---------------------------------------------------------------------------
-- Inventory
-- ---------------------------------------------------------------------------
M.open_inventory          = hash("open_inventory")
M.close_inventory         = hash("close_inventory")
M.show_inventory          = hash("show_inventory")
M.hide_inventory          = hash("hide_inventory")
M.refresh_inventory       = hash("refresh_inventory")
M.set_inventory_count     = hash("set_inventory_count")
M.inventory_verb          = hash("inventory_verb")
M.cancel_armed_inventory  = hash("cancel_armed_inventory")
M.show_armed_banner       = hash("show_armed_banner")
M.hide_armed_banner       = hash("hide_armed_banner")

-- ---------------------------------------------------------------------------
-- Map (телефонная карта — phone_map)
-- ---------------------------------------------------------------------------
M.map_travel           = hash("map_travel")
M.select_pin           = hash("select_pin")

-- ---------------------------------------------------------------------------
-- HUD
-- ---------------------------------------------------------------------------
M.show_hud             = hash("show_hud")
M.hide_hud             = hash("hide_hud")
M.set_hud_hint         = hash("set_hud_hint")
M.set_overlay_state    = hash("set_overlay_state")
M.set_log              = hash("set_log")
M.set_progress         = hash("set_progress")
M.set_points           = hash("set_points")
M.set_loop_state       = hash("set_loop_state")
M.set_location         = hash("set_location")
M.toggle_mute          = hash("toggle_mute")
M.set_mute_state       = hash("set_mute_state")
M.return_to_menu       = hash("return_to_menu")

-- ---------------------------------------------------------------------------
-- Menu
-- ---------------------------------------------------------------------------
M.show_menu            = hash("show_menu")
M.hide_menu            = hash("hide_menu")
M.start_game           = hash("start_game")
M.continue_game        = hash("continue_game")
M.reset_iteration      = hash("reset_iteration")
M.open_gallery         = hash("open_gallery")
M.open_achievements    = hash("open_achievements")

-- ---------------------------------------------------------------------------
-- Backgrounds / эффекты
-- ---------------------------------------------------------------------------
M.set_background       = hash("set_background")
M.show_bg              = hash("show_bg")
M.hide_bg              = hash("hide_bg")
M.show_effects         = hash("show_effects")
M.hide_effects         = hash("hide_effects")
M.set_effects          = hash("set_effects")
M.play_pulse           = hash("play_pulse")
M.play_shake           = hash("play_shake")

-- ---------------------------------------------------------------------------
-- Loop / story endings
-- ---------------------------------------------------------------------------
M.chapter_finished     = hash("chapter_finished")
M.false_ending         = hash("false_ending")
M.true_ending          = hash("true_ending")

-- ---------------------------------------------------------------------------
-- Backlog
-- ---------------------------------------------------------------------------
M.open_backlog         = hash("open_backlog")
M.close_backlog        = hash("close_backlog")
M.clear_backlog        = hash("clear_backlog")

-- ---------------------------------------------------------------------------
-- Hotspots / scene-controller
-- ---------------------------------------------------------------------------
M.set_hotspot          = hash("set_hotspot")
M.set_scene_object     = hash("set_scene_object")
M.hide_all             = hash("hide_all")
M.layout_changed       = hash("layout_changed")
M.toggle_scan          = hash("toggle_scan")

-- ---------------------------------------------------------------------------
-- Hotspot editor (dev-only, F1)
-- ---------------------------------------------------------------------------
M.edit_toggle          = hash("edit_toggle")
M.edit_exit            = hash("edit_exit")
M.edit_next            = hash("edit_next")
M.edit_shift           = hash("edit_shift")
M.edit_left            = hash("edit_left")
M.edit_right           = hash("edit_right")
M.edit_up              = hash("edit_up")
M.edit_down            = hash("edit_down")
M.edit_w_plus          = hash("edit_w_plus")
M.edit_w_minus         = hash("edit_w_minus")
M.edit_h_plus          = hash("edit_h_plus")
M.edit_h_minus         = hash("edit_h_minus")
M.edit_print           = hash("edit_print")

-- ---------------------------------------------------------------------------
-- Dev checkpoints (debug build only)
-- ---------------------------------------------------------------------------
M.dev_jump_next        = hash("dev_jump_next")
M.dev_jump_apply       = hash("dev_jump_apply")

-- ---------------------------------------------------------------------------
-- Input action_id'ы (стандартные Defold-инпуты, пригодятся для сравнений)
-- ---------------------------------------------------------------------------
M.touch                = hash("touch")
M.key_esc              = hash("key_esc")
M.scroll               = hash("scroll")
M.scroll_up            = hash("scroll_up")
M.scroll_down          = hash("scroll_down")
M.wheel                = hash("wheel")
M.wheel_up             = hash("wheel_up")
M.wheel_down           = hash("wheel_down")
M.mouse_wheel          = hash("mouse_wheel")
M.mouse_wheel_up       = hash("mouse_wheel_up")
M.mouse_wheel_down     = hash("mouse_wheel_down")

return M
