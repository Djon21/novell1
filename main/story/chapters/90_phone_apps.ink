// ============================================
// PHONE APPS (LEGACY COMPATIBILITY ONLY)
// ============================================
//
// ❗ НЕ ДОБАВЛЯТЬ СЮДА КОНТЕНТ
//
// Этот файл существует только для поддержки старых переходов.
// Телефон в v2 — data-driven через game_state.
//
// Весь новый контент:
// - sms:add
// - note:add
// - quest:*
//
// ============================================

// DEPRECATED: legacy app entry. New flow: open phone_v2 directly via UI.
=== phone_sms
# sms:read:anya
# phone:close
-> DONE

// DEPRECATED: legacy app entry. New flow: app content is data-driven in phone_v2.
=== anya_chat
# sms:read:anya
# phone:close
-> DONE

// DEPRECATED: legacy app entry. Quests are rendered by phone_v2 from game_state.
=== phone_tasks
# phone:close
-> DONE

// DEPRECATED: legacy app entry. Notes are rendered by phone_v2 from game_state.
=== phone_notes
# phone:close
-> DONE

// DEPRECATED: legacy app entry. Contacts are rendered by phone_v2 from game_state.
=== phone_contacts
# phone:close
-> DONE

// Active compatibility close hook for phone_v2 overlay.
=== phone_close
# phone:close
-> DONE
