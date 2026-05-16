// ================================================================
// AVOS_S — 00_bootstrap.ink
// Общие переменные главы и стартовый переход.
// ================================================================

VAR mc_gender = "male"
VAR mc_name = "Артём"
VAR npc_name = "Мила"

// Склонения текущих имён для живого русского текста.
// По умолчанию игрок — Артём, NPC — Мила; при выборе персонажа
// значения переопределяются в 10_sunday_intro.ink.
VAR mc_name_gen = "Артёма"
VAR npc_name_gen = "Милы"
VAR mc_name_dat = "Артёму"
VAR npc_name_dat = "Миле"
VAR mc_name_acc = "Артёма"
VAR npc_name_acc = "Милу"
VAR mc_name_ins = "Артёмом"
VAR npc_name_ins = "Милой"
VAR mc_name_prep = "Артёме"
VAR npc_name_prep = "Миле"

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
VAR sunday_dressed = false
VAR sunday_ready_to_leave = false
VAR got_out_of_bed = false
VAR washed_up = false
VAR bathroom_morning_seen = false
VAR teeth_brushed = false
VAR toothbrush_taken = false
VAR toothpaste_taken = false
VAR toothbrush_pasted_ready = false
VAR sunday_morning_routine_seen = false
VAR sunday_messenger_invite_sent = false
VAR sunday_bedroom_window_seen = false
VAR sunday_kitchen_window_seen = false
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
VAR park_arrived = false
VAR park_where_message_sent = false
VAR park_entrance_seen = false
VAR park_path_seen = false
VAR park_npc_greeted = false
VAR park_place_chosen = false
VAR park_talk_place_bench = false
VAR park_talk_place_path = false
VAR park_bench_trash_seen = false
VAR park_trash_cup_taken = false
VAR park_bench_cleared = false
VAR park_water_given = false
VAR monday_started = false
VAR monday_morning_started = false

VAR day_strategy = ""
VAR office_strategy = ""
VAR current_iteration_end = ""

VAR anomaly_noticed = false
VAR anomaly_interpreted = false

VAR kitchen_intro_seen = false
VAR mug_taken = false
VAR phone_taken = false
VAR first_anomaly_seen = false

VAR used_fallback = false
VAR requested_clarification = false
VAR decision_deferred = false
VAR understood_uncertainty = false

VAR npc_opened_up = false
VAR player_was_honest = false

VAR inventory_item_id = ""
VAR inventory_item_name = ""
VAR inventory_item_verb = ""
VAR inventory_scene_id = ""
VAR inventory_target_id = ""    // hotspot_id для use-on-target или npc_id для give
VAR inventory_target_kind = ""  // "hotspot" | "npc" | "item" | ""

-> choose_character
