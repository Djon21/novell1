// ================================================================
// LOOP RESET MODULE
// ================================================================
// This file contains the loop reset logic extracted from 10_apartment.ink.
// It handles the transition from iteration 1 to iteration 2, resetting
// all game state variables, flags, and items while preserving meta-state
// and character choices. The world returns to Sunday for a fresh playthrough.
// ================================================================

=== loop1_to_iter2_reset ===
// Сюжетный переход в новую петлю. Это не ручной reset_iteration:
// meta-состояние и выбор персонажа сохраняются, мир возвращается в воскресенье.
# meta:add:completed_iterations:1
# meta:add:iteration_number:1
# meta:add:loop_awareness:1
~ iteration_number = iteration_number + 1
~ loop_awareness = loop_awareness + 1
~ current_iteration_end = ""
~ anomaly_noticed = false
~ anomaly_interpreted = false
~ loop2_fake_wednesday_started = false
~ loop2_work_check_done = false
~ loop2_invite_after_office_sent = false
~ loop2_first_invite_rejected = false
~ loop2_returned_home = false
~ loop2_revealed_to_npc = false
~ loop2_monday_aware = false
~ loop2_office_mentioned = false

// Сброс sunday-world state.
~ coffee_drunk = false
~ phone_active = false
~ can_leave_apt = false
~ date_agreed = false
~ date_place_cafe = false
~ date_place_park = false
~ map_opened_after_apartment = false
~ date_route_chosen = false
~ met_npc_sunday = false
~ sunday_after_date_active = false
~ sunday_second_stop_done = false
~ sunday_went_to_shop = false
~ sunday_went_to_viewpoint = false
~ sunday_went_to_bar = false
~ bar_discussion_done = false
~ sunday_evening_started = false
~ sunday_finished = false
~ sunday_dressed = false
~ sunday_ready_to_leave = false
~ sunday_return_home_ad_seen = false
~ got_out_of_bed = false
~ washed_up = false
~ bathroom_morning_seen = false
~ teeth_brushed = false
~ toothbrush_taken = false
~ toothpaste_taken = false
~ toothbrush_pasted_ready = false
~ sunday_morning_routine_seen = false
~ sunday_messenger_invite_sent = false
~ sunday_bedroom_window_seen = false
~ sunday_kitchen_window_seen = false
~ breakfast_done = false
~ fridge_checked = false
~ water_drunk = false
~ kitchen_intro_seen = false
~ mug_taken = false
~ phone_taken = false
~ phone_history_seeded = true

// Сброс sunday map/shop/park/gift state, чтобы повтор воскресенья был честным.
~ sunday_shop_pre_date_visited = false
~ sunday_shop_bought_water = false
~ sunday_shop_bought_snack = false
~ sunday_shop_bought_drink_for_npc = false
~ sunday_shop_done = false
~ sunday_shop_with_npc_seen = false
~ sunday_shop_street_pre_date_seen = false
~ sunday_shop_street_with_npc_seen = false
~ sunday_gift_bought = false
~ sunday_gift_given = false
~ sunday_gift_right = false
~ sunday_current_gift = ""
~ sunday_gift_water_bottle = false
~ sunday_gift_iced_tea = false
~ sunday_gift_berry_soda = false
~ sunday_gift_coffee_can = false
~ sunday_gift_energy_drink = false
~ sunday_gift_crackers = false
~ sunday_gift_chips = false
~ sunday_gift_nuts = false
~ sunday_gift_dark_chocolate = false
~ sunday_gift_milk_chocolate = false
~ sunday_gift_waffle_bar = false
~ sunday_gift_keychain_flashlight = false
~ sunday_gift_small_broom = false
~ sunday_gift_wet_wipes = false
~ sunday_gift_paper_napkins = false
~ date_small_kindness = false
~ park_arrived = false
~ park_where_message_sent = false
~ park_entrance_seen = false
~ park_path_seen = false
~ park_npc_greeted = false
~ park_place_chosen = false
~ park_talk_place_bench = false
~ park_talk_place_path = false
~ park_bench_trash_seen = false
~ park_trash_cup_taken = false
~ park_bench_cleared = false
~ park_water_given = false

// Сброс weekday-world state: playable reset фактически возвращает воскресенье.
~ monday_started = false
~ tuesday_started = false
~ monday_morning_started = false
~ monday_workday_checked = false
~ monday_coffee_done = false
~ monday_breakfast_done = false
~ monday_water_drunk = false
~ monday_checked_in_office = false
~ monday_mail_read = false
~ monday_case_file_assembled = false
~ monday_case_file_submitted = false
~ monday_commute_auto = false
~ monday_commute_observed = false
~ monday_commute_steady = false
~ office_standard_solution_applied = false
~ office_clarification_requested = false
~ office_auto_solution_blocked = false
~ day_strategy = ""
~ office_strategy = ""
~ tuesday_desk_checked = false
~ tuesday_kitchen_window_seen = false
~ tuesday_phone_checked = false
~ tuesday_washed_up = false
~ tuesday_ready_to_leave = false
~ tuesday_coffee_done = false
~ tuesday_water_drunk = false
~ first_anomaly_seen = false
~ used_fallback = false
~ requested_clarification = false
~ decision_deferred = false
~ understood_uncertainty = false
~ npc_opened_up = false
~ player_was_honest = false

// Game-state flags для Lua-хотспотов и телефона.
# set_flag:iteration_001_finished=true
# set_flag:loop2_fake_wednesday_started=false
# set_flag:loop2_work_check_done=false
# set_flag:loop2_invite_after_office_sent=false
# set_flag:loop2_first_invite_rejected=false
# set_flag:loop2_returned_home=false
# set_flag:loop2_revealed_to_npc=false
# set_flag:phone_active=false
# set_flag:phone_taken=false
# set_flag:got_out_of_bed=false
# set_flag:washed_up=false
# set_flag:bedroom_morning_seen=false
# set_flag:bathroom_morning_seen=false
# set_flag:teeth_brushed=false
# set_flag:toothbrush_taken=false
# set_flag:toothpaste_taken=false
# set_flag:toothbrush_pasted_ready=false
# set_flag:coffee_drunk=false
# set_flag:breakfast_done=false
# set_flag:water_drunk=false
# set_flag:mug_taken=false
# set_flag:sunday_dressed=false
# set_flag:sunday_ready_to_leave=false
# set_flag:sunday_morning_routine_seen=false
# set_flag:sunday_messenger_invite_sent=false
# set_flag:sunday_bedroom_window_seen=false
# set_flag:sunday_kitchen_window_seen=false
# set_flag:date_agreed=false
# set_flag:date_place_cafe=false
# set_flag:date_place_park=false
# set_flag:date_route_chosen=false
# set_flag:met_npc_sunday=false
# set_flag:sunday_after_date_active=false
# set_flag:sunday_second_stop_done=false
# set_flag:sunday_evening_started=false
# set_flag:sunday_finished=false
# set_flag:left_apartment=false
# set_flag:map_opened_after_apartment=false
# set_flag:phone_history_seeded=true
# set_flag:msg_mila_replied=false
# set_flag:msg_artem_replied=false
# set_flag:park_arrived=false
# set_flag:park_where_message_sent=false
# set_flag:park_npc_greeted=false
# set_flag:park_place_chosen=false
# set_flag:cafe_arrived=false
# set_flag:cafe_order_done=false
# set_flag:monday_started=false
# set_flag:monday_morning_started=false
# set_flag:monday_finished=false
# set_flag:tuesday_pending=false
# set_flag:monday_workday_checked=false
# set_flag:monday_coffee_done=false
# set_flag:monday_breakfast_done=false
# set_flag:monday_water_drunk=false
# set_flag:monday_checked_in_office=false
# set_flag:monday_mail_read=false
# set_flag:monday_case_file_assembled=false
# set_flag:monday_case_file_submitted=false
# set_flag:monday_office_finished=false
# set_flag:tuesday_started=false
# set_flag:tuesday_morning_started=false
# set_flag:tuesday_phone_checked=false
# set_flag:tuesday_washed_up=false
# set_flag:tuesday_ready_to_leave=false
# set_flag:tuesday_coffee_done=false
# set_flag:tuesday_water_drunk=false
# set_flag:tuesday_left_home=false
# set_flag:tuesday_consequence_seen=false
# set_flag:tuesday_log_reviewed=false
# set_flag:tuesday_npc_talked=false
# set_flag:tuesday_appeal_read=false
# set_flag:tuesday_investigation_done=false
# set_flag:tuesday_rooftop_reached=false
# set_flag:tue_home_bedroom_seen=false
# set_flag:tue_home_hall_seen=false
# set_flag:tue_home_kitchen_seen=false
# set_flag:mon_home_bedroom_seen=false
# set_flag:mon_home_hall_seen=false
# set_flag:mon_home_kitchen_seen=false
# set_flag:monday_dressed=false
# set_flag:monday_washed_up=false
# set_flag:work_card_taken=false
# set_flag:monday_ready_for_work=false
# set_flag:monday_left_home=false
# set_flag:monday_folder_taken=false
# set_flag:monday_report_page_taken=false
# set_flag:mon_office_error_seen=false
# set_flag:reached_office=false
# set_flag:reached_work_district=false
# set_flag:kitchen_morning_seen=false
# set_flag:sunday_viewpoint_seen=false
# set_flag:park_npc_at_bench=false
# set_flag:park_npc_at_path=false
# set_flag:park_npc_bench_shown=false
# set_flag:park_npc_path_shown=false

// Предметы мира возвращаются на места.
# remove_item:phone
# remove_item:mug
# remove_item:toothbrush
# remove_item:toothpaste
# remove_item:toothbrush_pasted
# remove_item:park_trash_cup
# remove_item:water_bottle
# remove_item:gift_iced_tea
# remove_item:gift_berry_soda
# remove_item:gift_coffee_can
# remove_item:gift_energy_drink
# remove_item:gift_crackers
# remove_item:gift_chips
# remove_item:gift_nuts
# remove_item:gift_dark_chocolate
# remove_item:gift_milk_chocolate
# remove_item:gift_waffle_bar
# remove_item:gift_keychain_flashlight
# remove_item:gift_small_broom
# remove_item:gift_wet_wipes
# remove_item:gift_paper_napkins
# remove_item:card
# remove_item:folder
# remove_item:report_page
# remove_item:case_file

// Новый runtime-телефон петли: чистим и пересобираем воскресную историю.
# phone:loop_reset
-> phone_sms_seed_sunday_morning ->
-> phone_msg_seed_sunday_morning ->

# map:lock_all
# splash:day:wednesday
-> apartment_start
