// ================================================================
// AVOS_S — 00_bootstrap.ink
// Общие переменные главы и стартовый переход.
// ================================================================

VAR mc_gender = "male"
VAR mc_name = "Артём"
VAR npc_name = "Мила"

VAR iteration_number = 1
VAR iteration_label = "001"
VAR loop_awareness = 0
VAR completed_iterations = 0
VAR false_endings_count = 0

VAR TRUST = 0
VAR INSIGHT = 0
VAR SYNC = 0

VAR coffee_drunk = false
VAR phone_active = false
VAR spot_phone_after_coffee_seen = false
VAR can_leave_apt = false

VAR morning_choice = ""
VAR day_strategy = ""
VAR office_strategy = ""
VAR current_iteration_end = ""

VAR newspaper_taken = false
VAR newspaper_kept = false
VAR early_terminal_glitch = false

VAR anomaly_noticed = false
VAR anomaly_interpreted = false
VAR repeated_phrase_noticed = false
VAR future_hint_seen = false

VAR kitchen_intro_seen = false
VAR need_mug_for_coffee = false
VAR need_phone = false
VAR mug_taken = false
VAR phone_taken = false
VAR bedroom_monitor_seen = false
VAR bathroom_seen = false

VAR used_fallback = false
VAR requested_clarification = false
VAR decision_deferred = false
VAR understood_uncertainty = false

VAR npc_opened_up = false
VAR player_was_honest = false
VAR confession_unlocked = false

VAR log_message = ""
VAR log_marker = ""

VAR inventory_item_id = ""
VAR inventory_item_name = ""
VAR inventory_item_verb = ""
VAR inventory_scene_id = ""

-> wake_intro