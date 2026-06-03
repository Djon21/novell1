# Найденные несостыковки в ink-логике

Дата: 2026-06-03
Обнаружено в ходе ревью loop-логики (iter 1 → iter 2 → iter 3+).

**Статус:** 🔴🟡 критические и средние исправлены в коммите (см. ниже). Остались 🟡 дизайнерские и 🟢 косметические.

---

## 🔴 Критические — 7 `# set_flag:`, не сброшенных в `10_reset.ink`

Эти флаги управляют `visible_when` (видимость хотспота) или `on_enter` (вход в сцену) в Lua.
Если не сбросить — после ресета хотспот не появится, NPC-интро не сработает.

_Исправлено:_ добавлены `# set_flag:...=false` в `10_reset.ink:240-243`.

| № | Флаг | Где ставится | Что ломается в iter 2+ |
|---|---|---|---|
| 1 | `monday_folder_taken` | `locations/office_monday.ink:607` | Хотспот «взять папку» не появится (`office_monday.lua:179`) |
| 2 | `park_npc_at_bench` | `locations/park_sunday.ink:249` | NPC не появится на скамейке (`park.lua:132`), хотспот приветствия скрыт (`park.lua:164`) |
| 3 | `park_npc_at_path` | `locations/park_sunday.ink:245` | NPC не появится на дорожке (`park.lua:208`), хотспот приветствия скрыт (`park.lua:237`) |
| 4 | `park_npc_bench_shown` | `locations/park_sunday.ink:273` | Интро NPC на скамейке не сработает (`park.lua:133`) |
| 5 | `park_npc_path_shown` | `locations/park_sunday.ink:288` | Интро NPC на дорожке не сработает (`park.lua:209`) |
| 6 | `kitchen_morning_seen` | `10_apartment.ink:150` | Кухонный входной узел не сработает (`apartment.lua:256`) |
| 7 | `sunday_viewpoint_seen` | `locations/viewpoint_sunday.ink:38` | Сцена прибытия на смотровую не сработает (`viewpoint.lua:29`) |

---

## 🟡 Средние — 5 флагов, ломающие квесты в `quests.lua`

Флаги используются в `done_when`. После ресета квесты уже выполнены — игрок не сможет их пройти заново.

_Исправлено:_ добавлены `# set_flag:...=false` в `10_reset.ink:233-237`.

| № | Флаг | Где ставится | Квест |
|---|---|---|---|
| 1 | `monday_report_page_taken` | `locations/office_monday.ink:554` | `quests.lua:124` |
| 2 | `monday_folder_taken` | `locations/office_monday.ink:607` | `quests.lua:125` |
| 3 | `mon_office_error_seen` | `locations/office_monday.ink:269,376,395,417` | `quests.lua:128` — «Увидеть стандартное решение» |
| 4 | `reached_office` | `locations/commute_monday.ink:108` | `quests.lua:114` |
| 5 | `reached_work_district` | `locations/commute_monday.ink:93` | `quests.lua:113` |

---

## ⚪ Ink-only, безвредны для Lua — 15 флагов

Ставятся через `# set_flag:` в ink, но **ни одна Lua-сцена их не читает** (нет `visible_when`, `clickable_when`, `on_enter`, `done_when`).
Визуально ничего не ломают, но засоряют runtime-память.

| № | Флаг | Где ставится |
|---|---|---|
| 1 | `mon_office_arrived` | `locations/office_monday.ink:40` |
| 2 | `cafe_talk_done` | `locations/cafe_sunday.ink:435` |
| 3 | `cafe_order_coffee` | `locations/cafe_sunday.ink:141` |
| 4 | `cafe_order_sweet` | `locations/cafe_sunday.ink:157` |
| 5 | `cafe_order_tea` | `locations/cafe_sunday.ink:176` |
| 6 | `cafe_shelf_detail_seen` | `locations/cafe_sunday.ink:218` |
| 7 | `cafe_window_detail_seen` | `locations/cafe_sunday.ink:209` |
| 8 | `cafe_backroom_board_seen` | `locations/cafe_sunday.ink:488` |
| 9 | `cafe_backroom_books_seen` | `locations/cafe_sunday.ink:505` |
| 10 | `cafe_backroom_mirror_seen` | `locations/cafe_sunday.ink:479` |
| 11 | `bar_counter_seen_after_reveal` | `locations/bar_sunday.ink:206` |
| 12 | `messenger_prod_bot_questioned` | `93_phone_messenger.ink:578` |
| 13 | `messenger_unknown_asked_synthesis` | `93_phone_messenger.ink:613` |
| 14 | `messenger_unknown_asked_who` | `93_phone_messenger.ink:605` |
| 15 | `messenger_work_team_ack` | `93_phone_messenger.ink:552` |

---

## 🟡 Дизайнерские — логика есть, но не доведена

### 1. `SYNC` — мёртвый параметр

Инкрементится в 8+ местах:
- `cafe_sunday.ink` (`~ SYNC = SYNC + 1`)
- `park_sunday.ink` (`~ SYNC = SYNC + 1`)
- `bar_sunday.ink` (`~ SYNC = SYNC + 1`)
- `10a_sunday.ink` (вечер, `~ SYNC = SYNC + 1`)
- `10b_monday.ink` (`~ SYNC = SYNC + 1`)
- `locations/office_monday.ink` (`~ SYNC = SYNC + 1`)
- `locations/rooftop_tuesday.ink` (`~ SYNC = SYNC + 1`)

Но **нигде не проверяется** в ink-условии `{SYNC >= N:}`.
На крыше для true ending проверяются `TRUST >= 3` и `INSIGHT >= 3`, но `SYNC` игнорируется.

### 2. `day_strategy` / `office_strategy` — строки, которые не читаются

Присваиваются в `mon_office_core_choice`:
- `~ day_strategy = "fallback"` / `~ office_strategy = "fallback"`
- `~ day_strategy = "clarify"` / `~ office_strategy = "clarify"`
- `~ day_strategy = "stop_auto"` / `~ office_strategy = "stop_auto"`

Но нигде не проверяются в `{day_strategy == "fallback":}`.

---

## 🟢 Косметические — 50 неиспользуемых VAR

Объявлены в `00_bootstrap.ink`, но ни разу не встречаются в `{varname}` условии ни в одном .ink-файле:

- Имена персонажей: `mc_name`, `mc_name_gen`, `mc_name_dat`, `mc_name_acc`, `mc_name_ins`, `mc_name_prep`, `npc_name_acc`, `npc_name_prep`
- Счётчики: `iteration_label`, `completed_iterations`
- Статы: `SYNC` (см. 🟡 выше)
- Флаги, управляемые Lua: `phone_active`, `can_leave_apt`, `map_opened_after_apartment`, `date_route_chosen`, `sunday_went_to_viewpoint`, `sunday_went_to_bar`, `sunday_finished`, `sunday_ready_to_leave`, `sunday_return_home_ad_seen`, `got_out_of_bed`, `washed_up`, `bathroom_morning_seen`, `teeth_brushed`, `sunday_morning_routine_seen`, `sunday_bedroom_window_seen`, `fridge_checked`, `sunday_shop_bought_water`, `sunday_shop_with_npc_seen`, `sunday_shop_street_pre_date_seen`, `sunday_shop_street_with_npc_seen`, `park_arrived`, `park_talk_place_path`, `park_trash_cup_taken`, `monday_started`, `monday_morning_started`, `office_standard_solution_applied`, `day_strategy`, `office_strategy`, `anomaly_noticed`, `anomaly_interpreted`, `loop2_fake_wednesday_started`, `loop2_invite_after_office_sent`, `loop2_first_invite_rejected`, `loop2_returned_home`, `loop2_monday_aware`, `kitchen_intro_seen`, `phone_taken`, `tuesday_started`, `tuesday_coffee_done`
