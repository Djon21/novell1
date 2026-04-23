// ГЛАВА 1: «ИТЕРАЦИЯ 001»
//
// Переменные выставляются Lua-стороной (dialogue_manager_ink) перед continue:
//   mc_gender, mc_name, npc_name
//   iteration_number, iteration_label, loop_awareness, completed_iterations
//
// Флаги состояния и инвентаря
VAR mc_gender = "male"
VAR mc_name   = "Артём"
VAR npc_name  = "Мила"
VAR iteration_number = 1
VAR iteration_label = "001"
VAR loop_awareness = 0
VAR completed_iterations = 0
VAR TRUST   = 0
VAR INSIGHT = 0
VAR SYNC    = 0
VAR coffee_drunk    = false
VAR phone_active    = false
VAR spot_phone_after_coffee_seen = false
VAR can_leave_apt   = false
VAR morning_choice  = ""
VAR newspaper_taken = false
VAR newspaper_kept  = false
VAR early_terminal_glitch = false
VAR log_message = ""
VAR log_marker  = ""
VAR inventory_item_id = ""
VAR inventory_item_name = ""
VAR inventory_item_verb = ""
VAR inventory_scene_id = ""

-> wake_intro
