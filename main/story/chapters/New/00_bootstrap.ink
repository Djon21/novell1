// ================================================================
// AVOS_S — 00_bootstrap.ink
// Общие VAR для всей главы + стартовый переход.
// ВАЖНО:
// - стартовые сюжетные knot'ы (wake_intro / choose_character / wake_after_choice)
//   сейчас живут в 01_apartment.ink
// - этот файл должен оставаться bootstrap-слоем, без дублирования knot'ов
// ================================================================

// ------------------------------------------------
// External vars (выставляются Lua до первого continue)
// dialogue_manager_ink.lua синхронизирует их с runtime/meta-state
// ------------------------------------------------
VAR mc_gender = "male"
VAR mc_name   = "Артём"
VAR npc_name  = "Мила"

VAR iteration_number      = 1
VAR iteration_label       = "001"
VAR loop_awareness        = 0
VAR completed_iterations  = 0

// ------------------------------------------------
// Core narrative parameters
// ------------------------------------------------
VAR TRUST   = 0
VAR INSIGHT = 0
VAR SYNC    = 0

// ------------------------------------------------
// Day-level narrative state
// Эти VAR используются для внутреннего ветвления Ink.
// Если то же состояние нужно scenes.lua / game_state,
// его нужно дублировать через # flag:* в соответствующих knot'ах.
// ------------------------------------------------
VAR day_strategy          = ""      // "" | "ignore" | "observe" | "engage" | "wait"
VAR morning_choice        = ""      // "coffee" | "phone_first" | etc.
VAR office_strategy       = ""      // "fallback" | "clarify" | "defer"
VAR current_iteration_end = ""      // "npc" | "system" | "true"

// ------------------------------------------------
// Apartment / morning flow
// ------------------------------------------------
VAR coffee_drunk                  = false
VAR phone_active                  = false
VAR can_leave_apt                 = false

VAR need_mug_for_coffee           = false
VAR need_phone                    = false

VAR kitchen_intro_seen            = false
VAR spot_phone_after_coffee_seen  = false
VAR bedroom_monitor_seen          = false
VAR bathroom_seen                 = false

// ------------------------------------------------
// Anomaly / interpretation state
// ------------------------------------------------
VAR anomaly_noticed               = false
VAR anomaly_interpreted           = false
VAR early_terminal_glitch         = false
VAR repeated_phrase_noticed       = false
VAR future_hint_seen              = false

// ------------------------------------------------
// Item / local story state
// ------------------------------------------------
VAR newspaper_taken               = false
VAR newspaper_kept                = false
VAR note_seen                     = false
VAR mug_taken                     = false
VAR phone_taken                   = false

// ------------------------------------------------
// Office / core mistake state
// ------------------------------------------------
VAR used_fallback                 = false
VAR requested_clarification       = false
VAR decision_deferred             = false
VAR understood_uncertainty        = false

// ------------------------------------------------
// Rooftop / relationship state
// ------------------------------------------------
VAR npc_opened_up                 = false
VAR player_was_honest             = false
VAR confession_unlocked           = false

// ------------------------------------------------
// Technical / utility vars
// Используются runtime-слоем для side-knot'ов и fallback-реплик
// ------------------------------------------------
VAR log_message = ""
VAR log_marker  = ""

VAR inventory_item_id    = ""
VAR inventory_item_name  = ""
VAR inventory_item_verb  = ""
VAR inventory_scene_id   = ""

// ------------------------------------------------
// Start
// ------------------------------------------------
-> wake_intro