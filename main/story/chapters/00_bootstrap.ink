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
VAR can_leave_apt = false
VAR date_agreed = false
VAR date_place_cafe = false
VAR date_place_park = false
VAR map_opened_after_apartment = false
VAR date_route_chosen = false
VAR met_npc_sunday = false
VAR sunday_after_date_active = false
VAR sunday_second_stop_done = false
VAR sunday_went_to_shop = false
VAR sunday_went_to_viewpoint = false
VAR sunday_evening_started = false
VAR sunday_finished = false
VAR sunday_keys_taken = false
VAR sunday_dressed = false
VAR sunday_ready_to_leave = false
VAR sunday_bedroom_window_seen = false
VAR sunday_work_hint_seen = false
VAR breakfast_done = false
VAR fridge_checked = false
VAR water_drunk = false
VAR sunday_shop_pre_date_visited = false
VAR sunday_shop_bought_water = false
VAR sunday_shop_bought_snack = false
VAR sunday_shop_bought_drink_for_npc = false
VAR sunday_shop_done = false
VAR sunday_shop_with_npc_seen = false
VAR date_small_kindness = false
VAR monday_started = false
VAR monday_morning_started = false

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
VAR first_anomaly_seen = false

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
VAR inventory_target_id = ""    // hotspot_id для use-on-target или npc_id для give
VAR inventory_target_kind = ""  // "hotspot" | "npc" | "item" | ""

-> choose_character