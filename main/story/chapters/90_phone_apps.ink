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

=== phone_sms
# sms:read:anya
# goto_scene:phone_home
-> DONE

=== anya_chat
# sms:read:anya
# goto_scene:phone_home
-> DONE

=== phone_tasks
# goto_scene:phone_home
-> DONE

=== phone_notes
# goto_scene:phone_home
-> DONE

=== phone_contacts
# goto_scene:phone_home
-> DONE

=== phone_close
# phone:close
-> DONE

=== phone_stub_soon
# goto_scene:phone_home
-> DONE
