// ================================================================
// AVOS_S — 00_bootstrap.ink
// Общие переменные главы и стартовый переход.
// ================================================================

VAR mc_gender = "male"
VAR npc_gender = "female"   // зеркально к mc_gender; используется для согласования NPC-окончаний
VAR mc_name = "Артём"
VAR npc_name = "Мила"

// Склонения текущих имён для живого русского текста.
// По умолчанию игрок — Артём, NPC — Мила; при выборе персонажа
// значения переопределяются в 10_apartment.ink.
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

// Bank / purchase state lives in Lua runtime.
// Ink only sends tags like `# bank:set:272229` and
// `# bank:charge:980:Кофейня «петля»`.

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
VAR sunday_return_home_ad_seen = false
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
VAR sunday_shop_street_pre_date_seen = false
VAR sunday_shop_street_with_npc_seen = false
VAR sunday_gift_bought = false
VAR sunday_gift_given = false
VAR sunday_gift_right = false
VAR sunday_current_gift = ""
VAR sunday_gift_water_bottle = false
VAR sunday_gift_iced_tea = false
VAR sunday_gift_berry_soda = false
VAR sunday_gift_coffee_can = false
VAR sunday_gift_energy_drink = false
VAR sunday_gift_crackers = false
VAR sunday_gift_chips = false
VAR sunday_gift_nuts = false
VAR sunday_gift_dark_chocolate = false
VAR sunday_gift_milk_chocolate = false
VAR sunday_gift_waffle_bar = false
VAR sunday_gift_keychain_flashlight = false
VAR sunday_gift_small_broom = false
VAR sunday_gift_wet_wipes = false
VAR sunday_gift_paper_napkins = false
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
VAR monday_workday_checked = false
VAR monday_coffee_done = false
VAR monday_breakfast_done = false
VAR monday_water_drunk = false
VAR monday_checked_in_office = false
VAR monday_mail_read = false
VAR monday_case_file_assembled = false
VAR monday_case_file_submitted = false
// commute-варианты понедельника (выставляются в mon_commute_entry,
// читаются в office_monday для выбора окраски турникет-сцены).
VAR monday_commute_auto = false
VAR monday_commute_observed = false
VAR monday_commute_steady = false
VAR office_standard_solution_applied = false
// результаты понедельничного кейса в офисе — определяют ветку текста
// для вторничного «эхо рабочего чата» (tue_home_check_phone, 10_apartment).
VAR office_clarification_requested = false
VAR office_auto_solution_blocked = false

VAR day_strategy = ""
VAR office_strategy = ""
VAR current_iteration_end = ""

VAR anomaly_noticed = false
VAR anomaly_interpreted = false

// Iter 2 entry / fake Wednesday state.
VAR loop2_fake_wednesday_started = false
VAR loop2_work_check_done = false
VAR loop2_invite_after_office_sent = false
VAR loop2_first_invite_rejected = false
VAR loop2_returned_home = false

VAR kitchen_intro_seen = false
VAR mug_taken = false
VAR phone_taken = false
VAR phone_history_seeded = false

// One-shot гарды для tue_home_bedroom_desk и tue_home_kitchen_window —
// чтобы +INSIGHT не фармился многократным кликом по описательному хотспоту.
VAR tuesday_desk_checked = false
VAR tuesday_kitchen_window_seen = false

// Вторник: квартирная подготовка.
// Дублируем game-state flags в Ink VAR там, где они нужны
// для авторских условий внутри .ink (не только для Lua visible_when).
VAR tuesday_started = false
VAR tuesday_phone_checked = false
VAR tuesday_washed_up = false
VAR tuesday_ready_to_leave = false
VAR tuesday_coffee_done = false
VAR tuesday_water_drunk = false
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
