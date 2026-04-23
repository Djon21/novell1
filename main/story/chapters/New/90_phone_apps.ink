// ================================================================
// ТЕЛЕФОН: compatibility-knot'ы для phone_v2
// ================================================================
// Реальное содержимое телефона теперь живёт в phone_v2 + game_state.
// Ink не рендерит отдельные экраны SMS/квестов/заметок: он только
// добавляет данные через теги (# sms:add, # quest:start, # note:add)
// и может менять loop-awareness через meta-теги.
//
// Эти knot'ы оставлены как совместимость для старых переходов.
// Вместо статичного текста они просто открывают текущий phone_v2.

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
