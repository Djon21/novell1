# Project Inventory

**Auto-generated** скриптом `tools/generate_scenario_inventory.py`.
Запускать перед каждой сессией AI-сценариста чтобы документ отражал
текущее состояние проекта.

_Сгенерировано: 2026-05-21 13:11_

Это **источник правды для AI** о том что реально существует в проекте:
scene_id, knot имена, hotspot id, флаги, предметы. Не ссылайся на
вещи которых нет в этом списке — спроси у пользователя сначала.

---

## Scenes

Exploration-сцены и их хотспоты. Source: `main/data/scenes/*.lua`.

**Gated column:**
- 👁 — у хотспота есть `visible_when` (может быть скрыт по условию)
- 🔒 — у хотспота есть `condition` (виден, но locked/неактивен по условию)
- `—` — без условий, виден всегда

> ⚠️ **Inventory НЕ показывает сами Lua-условия** видимости/доступности.
> Если задача зависит от «когда виден этот хотспот», «при каких флагах»,
> «почему он не появляется» — открой соответствующий `main/data/scenes/<file>.lua`
> и читай `visible_when` / `condition` функции там. Они часто многострочные
> и могут ссылаться на shared-хелперы (`not_chosen_or_met`, `can_offer_place`).

### `apartment_bathroom` (Ванная)
 — source: `apartment.lua`, bg: `apartment_bg("bathroom")`, on_enter: `enter_bathroom_morning_first`

| Hotspot id | Label | Action | Gated |
|---|---|---|---|
| `bathroom_mirror` | Зеркало | knot: `look_bathroom_mirror` | — |
| `bathroom_toothbrush` | Щётка | knot: `take_toothbrush` | 👁 |
| `bathroom_toothpaste` | Паста | knot: `take_toothpaste` | 👁 |
| `bathroom_sink` | Раковина | knot: `bathroom_sink_prompt` | 👁 |
| `bathroom_exit_locked` | В спальню | knot: `bathroom_exit_locked` | 👁 |
| `back_to_bedroom_from_bathroom` | В спальню | scene: `apartment_bedroom` | 👁 |

### `apartment_bedroom` (Спальня)
 — source: `apartment.lua`, bg: `apartment_bg("bedroom")`, on_enter: `apartment_bedroom_intro`

| Hotspot id | Label | Action | Gated |
|---|---|---|---|
| `phone_on_bedside` | Телефон | knot: `take_phone` | 👁 |
| `bedroom_desk` | Рабочий стол | knot: `bedroom_desk_morning` | 👁 |
| `bedroom_bed` | Встать | knot: `look_bed_morning` | 👁 |
| `bedroom_bed_sleep_sunday` | Лечь спать | knot: `sunday_sleep_in_bed` | 👁 |
| `to_bathroom_from_bedroom` | В ванную | scene: `apartment_bathroom` | 👁 |
| `bedroom_window` | Окно | knot: `look_bedroom_window` | 👁 |
| `back_to_hall_from_bedroom` | В коридор | scene: `apartment_hub` | 👁 |

### `apartment_hub` (Коридор)
 — source: `apartment.lua`, bg: `apartment_bg("hall")`, on_enter: `sunday_home_after_date_router`

| Hotspot id | Label | Action | Gated |
|---|---|---|---|
| `to_bedroom` | В спальню | scene: `apartment_bedroom` | — |
| `to_kitchen` | На кухню | scene: `apartment_kitchen` | 👁 |
| `exit_apartment` | Выйти | knot: `leave_apartment_prompt` | 👁 |
| `hall_mirror` | Зеркало | knot: `look_hall_mirror` | — |
| `hall_jacket_shoes` | Куртка и обувь | knot: `sunday_get_dressed` | 👁 |

### `apartment_kitchen` (Кухня)
 — source: `apartment.lua`, bg: `apartment_bg("kitchen")`, on_enter: `enter_kitchen_morning_first`

| Hotspot id | Label | Action | Gated |
|---|---|---|---|
| `coffee_setup` | Кофе | knot: `use_coffee_setup_no_mug` | 👁 |
| `take_mug_kitchen` | Кружка | knot: `take_mug` | 👁 |
| `kitchen_apples` | Яблоко | knot: `take_kitchen_apple` | 👁 |
| `kitchen_fridge` | Холодильник | knot: `look_kitchen_fridge` | 👁 |
| `kitchen_window` | Окно | knot: `look_kitchen_window` | — |
| `back_to_hall_from_kitchen` | В коридор | scene: `apartment_hub` | — |

### `archive_hub` (Архив)
 — source: `archive.lua`, bg: `"bg_archive_day"`

| Hotspot id | Label | Action | Gated |
|---|---|---|---|
| `archive_shelves` | Стеллажи | knot: `archive_shelves_interact` | — |
| `leave_archive` | — | knot: `leave_archive` | — |

### `bar_hub` (Бар Maybe)
 — source: `bar.lua`, bg: `"bg_bar_maybe_night"`

| Hotspot id | Label | Action | Gated |
|---|---|---|---|
| `bar_counter` | Стойка бара | knot: `bar_counter_interact` | — |
| `leave_bar` | — | knot: `leave_bar` | — |

### `cafe_backroom` (Кафе — проход)
 — source: `cafe.lua`, bg: `"bg_cafe_backroom_day"`

| Hotspot id | Label | Action | Gated |
|---|---|---|---|
| `cafe_backroom_mirror` | Зеркало | knot: `cafe_backroom_mirror_interact` | — |
| `cafe_backroom_board` | Объявления | knot: `cafe_backroom_board_interact` | — |
| `cafe_backroom_coatrack` | Вешалка | knot: `cafe_backroom_coatrack_interact` | — |
| `cafe_backroom_books` | Книги | knot: `cafe_backroom_books_interact` | — |
| `backroom_to_cafe` | В зал | scene: `cafe_hub` | — |

### `cafe_corner` (Кафе — уголок)
 — source: `cafe.lua`, bg: `"bg_cafe_corner_day"`

| Hotspot id | Label | Action | Gated |
|---|---|---|---|
| `cafe_corner_talk` | Разговор | knot: `cafe_corner_main_talk` | 👁 |
| `cafe_corner_table` | Столик | knot: `cafe_corner_table_interact` | — |
| `cafe_corner_window` | Окно | knot: `cafe_corner_window_interact` | — |
| `cafe_corner_shelf` | Полка | knot: `cafe_corner_shelf_interact` | — |
| `corner_to_cafe` | В зал | scene: `cafe_hub` | — |

### `cafe_hub` (Кафе)
 — source: `cafe.lua`, bg: `"bg_cafe_day"`, on_enter: `sunday_date_cafe_arrival`

| Hotspot id | Label | Action | Gated |
|---|---|---|---|
| `cafe_bar` | Заказ | knot: `cafe_bar_interact` | 👁 |
| `cafe_window_table` | Столик у окна | knot: `cafe_window_table` | — |
| `cafe_hall_light` | Зал | knot: `cafe_hall_light_interact` | — |
| `cafe_to_corner` | В уголок | scene: `cafe_corner` | 🔒 |
| `cafe_to_backroom` | К проходу | scene: `cafe_backroom` | — |
| `leave_cafe` | Уйти | knot: `leave_cafe` | — |

### `monday_apartment_bedroom_morning` (Спальня)
 — source: `apartment_monday.lua`, bg: `"bg_apartment_bedroom_day"`, on_enter: `mon_home_bedroom_intro`

| Hotspot id | Label | Action | Gated |
|---|---|---|---|
| `mon_bed` | Кровать | knot: `mon_home_bed` | — |
| `mon_bedroom_desk` | Рабочий стол | knot: `mon_home_bedroom_desk` | — |
| `mon_bathroom_wash` | Умыться | knot: `mon_home_wash_up` | 👁 |
| `mon_to_hall_from_bedroom` | В коридор | scene: `monday_apartment_hall_morning` | — |

### `monday_apartment_hall_morning` (Коридор)
 — source: `apartment_monday.lua`, bg: `"bg_apartment_hall_day"`, on_enter: `mon_home_hall_intro`

| Hotspot id | Label | Action | Gated |
|---|---|---|---|
| `mon_to_bedroom` | В спальню | scene: `monday_apartment_bedroom_morning` | — |
| `mon_to_kitchen` | На кухню | scene: `monday_apartment_kitchen_morning` | — |
| `mon_hall_mirror` | Зеркало | knot: `mon_home_hall_mirror` | — |
| `mon_work_card` | Пропуск | knot: `mon_home_take_work_card` | 👁 |
| `mon_get_dressed` | Обувь и куртка | knot: `mon_home_get_dressed` | 👁 |
| `mon_exit_apartment_locked` | Выйти | knot: `mon_home_leave_apartment_locked` | 👁 |
| `mon_exit_apartment` | Выйти | knot: `mon_home_leave_apartment` | 👁 |

### `monday_apartment_kitchen_morning` (Кухня)
 — source: `apartment_monday.lua`, bg: `"bg_apartment_kitchen_day"`, on_enter: `mon_home_kitchen_intro`

| Hotspot id | Label | Action | Gated |
|---|---|---|---|
| `mon_kitchen_coffee` | Кофе | knot: `mon_home_kitchen_coffee` | 👁 |
| `mon_kitchen_coffee_after` | Кружка | knot: `mon_home_kitchen_coffee_after` | 👁 |
| `mon_kitchen_water` | Вода | knot: `mon_home_kitchen_water` | 👁 |
| `mon_kitchen_breakfast` | Завтрак | knot: `mon_home_kitchen_breakfast` | 👁 |
| `mon_kitchen_breakfast_after` | Стол | knot: `mon_home_kitchen_breakfast_after` | 👁 |
| `mon_kitchen_window` | Окно | knot: `mon_home_kitchen_window` | — |
| `mon_back_to_hall_from_kitchen` | В коридор | scene: `monday_apartment_hall_morning` | — |

### `office_meeting_room` (Переговорка)
 — source: `office_monday.lua`, bg: `office_bg("meeting_room")`

| Hotspot id | Label | Action | Gated |
|---|---|---|---|
| `meeting_room_table_folder` | Папки | knot: `meeting_room_take_folder` | 👁 |
| `meeting_room_table_after` | Пустой стол | knot: `meeting_room_table_after` | 👁 |
| `meeting_room_to_workspace` | К рабочему месту | scene: `office_workspace` | — |
| `meeting_room_back_to_lobby` | В лобби | scene: `work_hub` | — |

### `office_workspace` (Рабочее место)
 — source: `office_monday.lua`, bg: `office_bg("workspace")`

| Hotspot id | Label | Action | Gated |
|---|---|---|---|
| `work_desk_mail` | Почта | knot: `work_desk_read_mail` | 👁 |
| `work_desk_waiting` | Рабочий стол | knot: `work_desk_needs_case_file` | 👁 |
| `work_desk_submit` | Передать кейс | knot: `work_desk_case_file_prompt` | 👁 |
| `work_desk_done` | Рабочий стол | knot: `work_desk_done` | 👁 |
| `workspace_to_meeting_room_locked` | В переговорку | knot: `workspace_to_meeting_room_locked` | 👁 |
| `workspace_to_meeting_room` | В переговорку | scene: `office_meeting_room` | 👁 |
| `workspace_back_to_lobby` | В лобби | scene: `work_hub` | — |

### `park_hub` (Парк у реки)
 — source: `park.lua`, bg: `"bg_park_riverside_entrance_day"`, on_enter: `sunday_date_park_arrival`

| Hotspot id | Label | Action | Gated |
|---|---|---|---|
| `park_entrance_view` | Осмотреться | knot: `park_entrance_view` | 👁 |
| `park_bin` | Урна | knot: `park_bin_prompt` | 👁 |
| `park_offer_place` | Предложить | knot: `park_offer_place` | 👁 |
| `park_to_bench` | К скамейке | scene: `park_riverside_bench` | 👁 |
| `park_to_path` | По аллее | scene: `park_riverside_path` | 👁 |
| `leave_park` | Уйти | knot: `leave_park` | 👁 |

### `park_riverside_bench` (Парк у реки — скамейка)
 — source: `park.lua`, bg: `"bg_park_riverside_bench_day"`, on_enter: `park_bench_npc_show`

| Hotspot id | Label | Action | Gated |
|---|---|---|---|
| `park_bench` | Скамейка | knot: `park_bench_interact` | — |
| `park_trash_cup` | Стаканчик | knot: `take_park_trash_cup` | 👁 |
| `park_npc_greeting_bench` | Поздороваться | knot: `park_npc_arrives` | 👁 |
| `park_river_view` | Река | knot: `park_river_view` | — |
| `park_offer_place_bench` | Предложить | knot: `park_offer_place` | 👁 |
| `bench_to_path` | Пройтись | scene: `park_riverside_path` | 👁 |
| `bench_to_entrance` | К входу | scene: `park_hub` | 👁 |

### `park_riverside_path` (Парк у реки — аллея)
 — source: `park.lua`, bg: `"bg_park_riverside_path_day"`, on_enter: `park_path_npc_show`

| Hotspot id | Label | Action | Gated |
|---|---|---|---|
| `park_path_walk` | Пройтись | knot: `park_path_walk` | 👁 |
| `park_path_trees` | Тень деревьев | knot: `park_path_trees` | 👁 |
| `park_npc_greeting_path` | Поздороваться | knot: `park_npc_arrives` | 👁 |
| `park_offer_place_path` | Предложить | knot: `park_offer_place` | 👁 |
| `path_to_bench` | К скамейке | scene: `park_riverside_bench` | 👁 |
| `path_to_entrance` | К входу | scene: `park_hub` | 👁 |

### `shop_front` (Магазин 24/7)
 — source: `shop.lua`, bg: `shop_bg("front")`, on_enter: `sunday_shop_arrival`

| Hotspot id | Label | Action | Gated |
|---|---|---|---|
| `shop_drinks` | Напитки | knot: `shop_drinks_interact` | 👁 |
| `shop_snacks` | Снеки | knot: `shop_snacks_interact` | 👁 |
| `shop_counter` | Касса | knot: `shop_counter_interact` | — |
| `to_shop_household` | В отдел | scene: `shop_household` | — |
| `to_shop_street` | На улицу | scene: `shop_street` | — |

### `shop_household` (Бытовой отдел)
 — source: `shop.lua`, bg: `shop_bg("household")`

| Hotspot id | Label | Action | Gated |
|---|---|---|---|
| `shop_household_goods` | Хозтовары | knot: `shop_household_goods_interact` | — |
| `shop_cleaning_supplies` | Уборка | knot: `shop_cleaning_supplies_interact` | — |
| `shop_paper_goods` | Салфетки | knot: `shop_paper_goods_interact` | — |
| `to_shop_front` | К кассе | scene: `shop_front` | — |

### `shop_hub` (У магазина)
 — source: `shop.lua`, bg: `shop_bg("street")`, alias_of: `shop_street`, on_enter: `sunday_shop_street_arrival`

| Hotspot id | Label | Action | Gated |
|---|---|---|---|
| `shop_enter` | Войти | scene: `shop_front` | — |
| `shop_window` | Витрина | knot: `shop_window_interact` | — |
| `shop_sign` | Вывеска | knot: `shop_sign_interact` | — |
| `leave_shop_area` | Уйти | knot: `leave_shop` | — |

### `shop_street` (У магазина)
 — source: `shop.lua`, bg: `shop_bg("street")`, on_enter: `sunday_shop_street_arrival`

| Hotspot id | Label | Action | Gated |
|---|---|---|---|
| `shop_enter` | Войти | scene: `shop_front` | — |
| `shop_window` | Витрина | knot: `shop_window_interact` | — |
| `shop_sign` | Вывеска | knot: `shop_sign_interact` | — |
| `leave_shop_area` | Уйти | knot: `leave_shop` | — |

### `tuesday_apartment_bedroom_morning` (Спальня)
 — source: `apartment_tuesday.lua`, bg: `"bg_apartment_bedroom_day"`, on_enter: `tue_home_bedroom_intro`

| Hotspot id | Label | Action | Gated |
|---|---|---|---|
| `tue_bed` | Кровать | knot: `tue_home_bed` | — |
| `tue_phone_check` | Телефон | knot: `tue_home_check_phone` | 👁 |
| `tue_bedroom_desk` | Рабочий стол | knot: `tue_home_bedroom_desk` | — |
| `tue_bathroom_wash` | Умыться | knot: `tue_home_wash_up` | 👁 |
| `tue_to_hall_from_bedroom` | В коридор | scene: `tuesday_apartment_hall_morning` | — |

### `tuesday_apartment_hall_morning` (Коридор)
 — source: `apartment_tuesday.lua`, bg: `"bg_apartment_hall_day"`, on_enter: `tue_home_hall_intro`

| Hotspot id | Label | Action | Gated |
|---|---|---|---|
| `tue_to_bedroom` | В спальню | scene: `tuesday_apartment_bedroom_morning` | — |
| `tue_to_kitchen` | На кухню | scene: `tuesday_apartment_kitchen_morning` | — |
| `tue_hall_mirror` | Зеркало | knot: `tue_home_hall_mirror` | — |
| `tue_get_ready` | Обувь и куртка | knot: `tue_home_get_ready` | 👁 |
| `tue_exit_apartment_locked` | Выйти | knot: `tue_home_leave_apartment_locked` | 👁 |
| `tue_exit_apartment` | Выйти | knot: `tue_home_leave_apartment` | 👁 |

### `tuesday_apartment_kitchen_morning` (Кухня)
 — source: `apartment_tuesday.lua`, bg: `"bg_apartment_kitchen_day"`, on_enter: `tue_home_kitchen_intro`

| Hotspot id | Label | Action | Gated |
|---|---|---|---|
| `tue_kitchen_coffee` | Кофе | knot: `tue_home_kitchen_coffee` | 👁 |
| `tue_kitchen_coffee_after` | Кружка | knot: `tue_home_kitchen_coffee_after` | 👁 |
| `tue_kitchen_water` | Вода | knot: `tue_home_kitchen_water` | 👁 |
| `tue_kitchen_window` | Окно | knot: `tue_home_kitchen_window` | — |
| `tue_back_to_hall_from_kitchen` | В коридор | scene: `tuesday_apartment_hall_morning` | — |

### `view_corner` (Смотровая — лавочка)
 — source: `viewpoint.lua`, bg: `"bg_observation_corner_day"`

| Hotspot id | Label | Action | Gated |
|---|---|---|---|
| `view_corner_sit` | Сесть рядом | knot: `view_corner_main_talk` | 👁 |
| `view_corner_bench` | Скамейка | knot: `view_corner_bench_interact` | — |
| `view_corner_glass` | Стекло | knot: `view_corner_glass_interact` | — |
| `view_corner_planter` | Зелень | knot: `view_corner_planter_interact` | — |
| `corner_to_view` | К перилам | scene: `view_hub` | — |

### `view_hub` (Смотровая)
 — source: `viewpoint.lua`, bg: `"bg_observation_railing_day"`, on_enter: `sunday_viewpoint_arrival`

| Hotspot id | Label | Action | Gated |
|---|---|---|---|
| `view_railing` | Поручни | knot: `view_railing_interact` | — |
| `view_city` | Город | knot: `view_city_interact` | — |
| `view_binoculars` | Бинокль | knot: `view_binoculars_interact` | — |
| `view_to_corner` | К лавочке | scene: `view_corner` | — |
| `leave_view` | Уйти | knot: `leave_viewpoint` | — |

### `work_hub` (Офис — лобби)
 — source: `office_monday.lua`, bg: `office_bg("lobby")`

| Hotspot id | Label | Action | Gated |
|---|---|---|---|
| `office_turnstile` | Турникет | knot: `office_turnstile_prompt` | 👁 |
| `office_to_workspace_locked` | К рабочему месту | knot: `office_to_workspace_locked` | 👁 |
| `office_to_workspace` | К рабочему месту | scene: `office_workspace` | 👁 |
| `office_to_meeting_room_locked_turnstile` | В переговорку | knot: `office_to_meeting_room_locked_turnstile` | 👁 |
| `office_to_meeting_room_locked_mail` | В переговорку | knot: `office_to_meeting_room_locked_mail` | 👁 |
| `office_to_meeting_room` | В переговорку | scene: `office_meeting_room` | 👁 |
| `leave_work` | — | knot: `leave_work` | — |

## Ink Knots

Все объявленные `=== knot_name ===` в `main/story/chapters/*.ink`
(без `_old*` версий). Используй ТОЛЬКО эти имена для `action_knot`
в hotspot'ах и для `# scene_char:show:...:...` если требуется.

Колонка `Kind` — структурная подсказка, не пересказ содержимого. Тексты
knot'ов в inventory намеренно не выводятся, чтобы файл оставался
компактным source of truth по ID.

### `10_apartment.ink`

| Knot | Kind |
|---|---|
| `apartment_bedroom_intro` | `knot` |
| `apartment_start` | `knot` |
| `bathroom_exit_locked` | `knot` |
| `bathroom_not_now` | `knot` |
| `bathroom_sink_prompt` | `knot` |
| `bedroom_desk_morning` | `knot` |
| `choose_character` | `knot` |
| `enter_bathroom_morning_first` | `knot` |
| `enter_kitchen_morning_first` | `knot` |
| `leave_apartment` | `knot` |
| `leave_apartment_prompt` | `knot` |
| `look_bathroom_mirror` | `knot` |
| `look_bed_morning` | `knot` |
| `look_bedroom_window` | `knot` |
| `look_hall_mirror` | `knot` |
| `look_kitchen_fridge` | `knot` |
| `look_kitchen_window` | `knot` |
| `mon_home_bed` | `knot` |
| `mon_home_bedroom_desk` | `knot` |
| `mon_home_bedroom_intro` | `knot` |
| `mon_home_get_dressed` | `knot` |
| `mon_home_hall_intro` | `knot` |
| `mon_home_hall_mirror` | `knot` |
| `mon_home_kitchen_breakfast` | `knot` |
| `mon_home_kitchen_breakfast_after` | `knot` |
| `mon_home_kitchen_coffee` | `knot` |
| `mon_home_kitchen_coffee_after` | `knot` |
| `mon_home_kitchen_intro` | `knot` |
| `mon_home_kitchen_water` | `knot` |
| `mon_home_kitchen_window` | `knot` |
| `mon_home_leave_apartment` | `knot` |
| `mon_home_leave_apartment_locked` | `knot` |
| `mon_home_take_work_card` | `knot` |
| `mon_home_wash_up` | `knot` |
| `mon_office_evening_close` | `knot` |
| `monday_morning_start` | `knot` |
| `seed_phone_history` | `knot` |
| `sunday_date_go_cafe` | `knot` |
| `sunday_date_go_park` | `knot` |
| `sunday_date_map_fallback` | `knot` |
| `sunday_evening_finish` | `knot` |
| `sunday_evening_home` | `knot` |
| `sunday_get_dressed` | `knot` |
| `sunday_home_after_date_router` | `knot` |
| `sunday_home_too_early` | `knot` |
| `sunday_send_messenger_invite` | `knot` |
| `sunday_sleep_in_bed` | `knot` |
| `sunday_start_splash` | `knot` |
| `take_kitchen_apple` | `knot` |
| `take_mug` | `knot` |
| `take_phone` | `knot` |
| `take_toothbrush` | `knot` |
| `take_toothpaste` | `knot` |
| `tue_home_bed` | `knot` |
| `tue_home_bedroom_desk` | `knot` |
| `tue_home_bedroom_intro` | `knot` |
| `tue_home_check_phone` | `knot` |
| `tue_home_get_ready` | `knot` |
| `tue_home_hall_intro` | `knot` |
| `tue_home_hall_mirror` | `knot` |
| `tue_home_kitchen_coffee` | `knot` |
| `tue_home_kitchen_coffee_after` | `knot` |
| `tue_home_kitchen_intro` | `knot` |
| `tue_home_kitchen_water` | `knot` |
| `tue_home_kitchen_window` | `knot` |
| `tue_home_leave_apartment` | `knot` |
| `tue_home_leave_apartment_locked` | `knot` |
| `tue_home_wash_up` | `knot` |
| `tuesday_morning_start` | `knot` |
| `use_coffee_setup_no_mug` | `knot` |

### `91_inventory_actions.ink`

| Knot | Kind |
|---|---|
| `inv_apartment_bathroom_use_toothbrush_pasted_on_bathroom_sink` | `inventory` |
| `inv_apartment_kitchen_morning_use_mug_on_coffee_setup` | `inventory` |
| `inv_apartment_kitchen_use_mug_on_coffee_setup` | `inventory` |
| `inv_combine_fallback` | `inventory` |
| `inv_combine_folder_with_report_page` | `inventory` |
| `inv_combine_toothbrush_with_toothpaste` | `inventory` |
| `inv_fallback` | `inventory` |
| `inv_give_fallback` | `inventory` |
| `inv_inspect_card` | `inventory` |
| `inv_inspect_case_file` | `inventory` |
| `inv_inspect_fallback` | `inventory` |
| `inv_inspect_folder` | `inventory` |
| `inv_inspect_gift_berry_soda` | `inventory` |
| `inv_inspect_gift_chips` | `inventory` |
| `inv_inspect_gift_coffee_can` | `inventory` |
| `inv_inspect_gift_crackers` | `inventory` |
| `inv_inspect_gift_dark_chocolate` | `inventory` |
| `inv_inspect_gift_energy_drink` | `inventory` |
| `inv_inspect_gift_iced_tea` | `inventory` |
| `inv_inspect_gift_keychain_flashlight` | `inventory` |
| `inv_inspect_gift_milk_chocolate` | `inventory` |
| `inv_inspect_gift_nuts` | `inventory` |
| `inv_inspect_gift_paper_napkins` | `inventory` |
| `inv_inspect_gift_small_broom` | `inventory` |
| `inv_inspect_gift_waffle_bar` | `inventory` |
| `inv_inspect_gift_wet_wipes` | `inventory` |
| `inv_inspect_note` | `inventory` |
| `inv_inspect_park_trash_cup` | `inventory` |
| `inv_inspect_phone` | `inventory` |
| `inv_inspect_report_page` | `inventory` |
| `inv_inspect_toothbrush` | `inventory` |
| `inv_inspect_toothbrush_pasted` | `inventory` |
| `inv_inspect_toothpaste` | `inventory` |
| `inv_inspect_water_bottle` | `inventory` |
| `inv_office_workspace_give_case_file_on_npc` | `inventory` |
| `inv_office_workspace_use_case_file_on_work_desk_submit` | `inventory` |
| `inv_park_hub_use_park_trash_cup_on_park_bin` | `inventory` |
| `inv_read_case_file` | `inventory` |
| `inv_read_fallback` | `inventory` |
| `inv_read_note` | `inventory` |
| `inv_read_report_page` | `inventory` |
| `inv_use_card_on_fallback` | `inventory` |
| `inv_use_case_file_on_fallback` | `inventory` |
| `inv_use_fallback` | `inventory` |
| `inv_use_on_fallback` | `inventory` |
| `inv_use_park_trash_cup_on_fallback` | `inventory` |
| `inv_work_hub_use_card_on_office_turnstile` | `inventory` |

### `92_phone_sms.ink`

| Knot | Kind |
|---|---|
| `phone_bank_charge_cafe_coffee_sweet` | `knot` |
| `phone_bank_charge_cafe_tea_small` | `knot` |
| `phone_bank_charge_cafe_two_coffee` | `knot` |
| `phone_bank_charge_shop_120` | `knot` |
| `phone_bank_charge_shop_140` | `knot` |
| `phone_bank_charge_shop_160` | `knot` |
| `phone_bank_charge_shop_170` | `knot` |
| `phone_bank_charge_shop_180` | `knot` |
| `phone_bank_charge_shop_190` | `knot` |
| `phone_bank_charge_shop_210` | `knot` |
| `phone_bank_charge_shop_220` | `knot` |
| `phone_bank_charge_shop_230` | `knot` |
| `phone_bank_charge_shop_240` | `knot` |
| `phone_bank_charge_shop_320` | `knot` |
| `phone_bank_charge_shop_350` | `knot` |
| `phone_bank_charge_shop_360` | `knot` |
| `phone_bank_charge_shop_380` | `knot` |
| `phone_bank_charge_shop_420` | `knot` |
| `phone_bank_charge_shop_490` | `knot` |
| `phone_bank_charge_shop_95` | `knot` |
| `phone_sms_seed_sunday_morning` | `phone_sms_event` |
| `phone_sms_take_phone_sunday_morning` | `phone_sms_event` |
| `phone_sms_tuesday_case_followup` | `phone_sms_event` |
| `sms_service_done` | `knot` |

### `93_phone_messenger.ink`

| Knot | Kind |
|---|---|
| `msg_npc_place_sent` | `knot` |
| `msg_thread_artem` | `msg_thread` |
| `msg_thread_mila` | `msg_thread` |
| `msg_thread_prod_bot` | `msg_thread` |
| `msg_thread_unknown` | `msg_thread` |
| `msg_thread_work_team` | `msg_thread` |
| `phone_msg_park_arrival_prompt` | `phone_msg_event` |
| `phone_msg_park_where_reply_bench` | `phone_msg_event` |
| `phone_msg_park_where_reply_path` | `phone_msg_event` |
| `phone_msg_seed_sunday_morning` | `phone_msg_event` |
| `phone_msg_sunday_evening_home_thanks` | `phone_msg_event` |
| `phone_msg_sunday_evening_reply_calm` | `phone_msg_event` |
| `phone_msg_sunday_evening_reply_warm` | `phone_msg_event` |
| `phone_msg_sunday_invite_after_coffee` | `phone_msg_event` |
| `phone_msg_take_phone_sunday_morning` | `phone_msg_event` |

### `archive_tuesday.ink`

| Knot | Kind |
|---|---|
| `archive_shelves_interact` | `knot` |
| `leave_archive` | `knot` |

### `bar_sunday.ink`

| Knot | Kind |
|---|---|
| `bar_counter_interact` | `knot` |
| `leave_bar` | `knot` |

### `cafe_sunday.ink`

| Knot | Kind |
|---|---|
| `cafe_backroom_board_interact` | `knot` |
| `cafe_backroom_books_interact` | `knot` |
| `cafe_backroom_coatrack_interact` | `knot` |
| `cafe_backroom_mirror_interact` | `knot` |
| `cafe_bar_interact` | `knot` |
| `cafe_bar_interact_right_place` | `knot` |
| `cafe_bar_interact_wrong_place` | `knot` |
| `cafe_corner_main_talk` | `knot` |
| `cafe_corner_shelf_interact` | `knot` |
| `cafe_corner_table_interact` | `knot` |
| `cafe_corner_window_interact` | `knot` |
| `cafe_hall_light_interact` | `knot` |
| `cafe_window_table` | `knot` |
| `leave_cafe` | `knot` |
| `sunday_date_cafe_arrival` | `knot` |
| `sunday_date_cafe_arrival_after_gift` | `knot` |
| `sunday_date_cafe_settle` | `knot` |

### `commute_monday.ink`

| Knot | Kind |
|---|---|
| `mon_commute_entry` | `knot` |
| `mon_commute_office_approach` | `knot` |
| `mon_commute_walk_auto` | `knot` |
| `mon_commute_walk_observe` | `knot` |
| `mon_commute_walk_steady` | `knot` |
| `mon_commute_work_district` | `knot` |

### `office_monday.ink`

| Knot | Kind |
|---|---|
| `leave_work` | `knot` |
| `meeting_room_table_after` | `knot` |
| `meeting_room_take_folder` | `knot` |
| `mon_office_auto_standard` | `knot` |
| `mon_office_case_router` | `knot` |
| `mon_office_clarify` | `knot` |
| `mon_office_core_choice` | `knot` |
| `mon_office_day_end` | `knot` |
| `mon_office_entry` | `knot` |
| `mon_office_manual_standard` | `knot` |
| `mon_office_npc_greeting` | `knot` |
| `mon_office_npc_strange` | `knot` |
| `mon_office_result_system_bias` | `knot` |
| `mon_office_result_true_bias` | `knot` |
| `mon_office_stop_auto` | `knot` |
| `mon_office_system_warning` | `knot` |
| `mon_office_task_intro` | `knot` |
| `office_to_meeting_room_locked_mail` | `knot` |
| `office_to_meeting_room_locked_turnstile` | `knot` |
| `office_to_workspace_locked` | `knot` |
| `office_turnstile_prompt` | `knot` |
| `work_desk_case_file_prompt` | `knot` |
| `work_desk_done` | `knot` |
| `work_desk_needs_case_file` | `knot` |
| `work_desk_read_mail` | `knot` |
| `workspace_to_meeting_room_locked` | `knot` |

### `office_tuesday.ink`

| Knot | Kind |
|---|---|
| `tue_route_after_review` | `knot` |
| `tue_route_ask_npc` | `knot` |
| `tue_route_entry` | `knot` |
| `tue_route_office_return` | `knot` |
| `tue_route_read_appeal` | `knot` |
| `tue_route_read_log` | `knot` |
| `tue_route_review_options` | `knot` |
| `tue_route_to_rooftop` | `knot` |

### `park_sunday.ink`

| Knot | Kind |
|---|---|
| `leave_park` | `knot` |
| `park_bench_interact` | `knot` |
| `park_bench_main_talk` | `knot` |
| `park_bench_npc_show` | `knot` |
| `park_bin_prompt` | `knot` |
| `park_entrance_view` | `knot` |
| `park_message_where_are_you` | `knot` |
| `park_npc_arrives` | `knot` |
| `park_npc_arrives_after_gift` | `knot` |
| `park_offer_place` | `knot` |
| `park_path_main_talk` | `knot` |
| `park_path_npc_show` | `knot` |
| `park_path_trees` | `knot` |
| `park_path_walk` | `knot` |
| `park_river_view` | `knot` |
| `sunday_date_park_arrival` | `knot` |
| `sunday_date_park_settle` | `knot` |
| `take_park_trash_cup` | `knot` |

### `rooftop_tuesday.ink`

| Knot | Kind |
|---|---|
| `tue_rooftop_ending_npc` | `knot` |
| `tue_rooftop_ending_system` | `knot` |
| `tue_rooftop_ending_true` | `knot` |
| `tue_rooftop_entry` | `knot` |
| `tue_rooftop_iter001_entry` | `knot` |
| `tue_rooftop_iter001_finish` | `knot` |
| `tue_rooftop_iter001_realization` | `knot` |
| `tue_rooftop_iter001_talk` | `knot` |
| `tue_rooftop_loop_entry` | `knot` |
| `tue_rooftop_loop_route` | `knot` |
| `tue_rooftop_loop_signal` | `knot` |
| `tue_rooftop_loop_talk` | `knot` |

### `shop_sunday.ink`

| Knot | Kind |
|---|---|
| `leave_shop` | `knot` |
| `shop_cleaning_supplies_interact` | `knot` |
| `shop_cleaning_supplies_pre_date` | `knot` |
| `shop_cleaning_supplies_with_npc` | `knot` |
| `shop_counter_interact` | `knot` |
| `shop_drinks_interact` | `knot` |
| `shop_drinks_pre_date` | `knot` |
| `shop_drinks_with_npc` | `knot` |
| `shop_household_goods_interact` | `knot` |
| `shop_household_goods_pre_date` | `knot` |
| `shop_household_goods_with_npc` | `knot` |
| `shop_paper_goods_interact` | `knot` |
| `shop_paper_goods_pre_date` | `knot` |
| `shop_paper_goods_with_npc` | `knot` |
| `shop_sign_interact` | `knot` |
| `shop_snacks_interact` | `knot` |
| `shop_snacks_pre_date` | `knot` |
| `shop_snacks_with_npc` | `knot` |
| `shop_window_interact` | `knot` |
| `sunday_shop_arrival` | `knot` |
| `sunday_shop_arrival_pre_date` | `knot` |
| `sunday_shop_arrival_with_npc` | `knot` |
| `sunday_shop_settle` | `knot` |
| `sunday_shop_street_arrival` | `knot` |

### `sunday_gift_reactions.ink`

| Knot | Kind |
|---|---|
| `sunday_gift_react` | `knot` |
| `sunday_gift_react_cafe` | `knot` |
| `sunday_gift_react_park` | `knot` |

### `viewpoint_sunday.ink`

| Knot | Kind |
|---|---|
| `leave_viewpoint` | `knot` |
| `sunday_viewpoint_arrival` | `knot` |
| `sunday_viewpoint_settle` | `knot` |
| `view_binoculars_interact` | `knot` |
| `view_city_interact` | `knot` |
| `view_corner_bench_interact` | `knot` |
| `view_corner_glass_interact` | `knot` |
| `view_corner_main_talk` | `knot` |
| `view_corner_planter_interact` | `knot` |
| `view_railing_interact` | `knot` |

## Characters (CHARS)

Speaker keys из `dialogue_v2.gui_script` CHARS table. Используются
в `# speaker:KEY`. Каждый персонаж может иметь несколько алиасов
(латинский ID и кириллическая форма) — обе формы работают одинаково.

| Atlas | Aliases (для `# speaker:`) | Анимации портрета |
|---|---|---|
| `mila` | `mila`, `мила` | idle, blink, talk |
| `artem` | `artem`, `артём` | idle, blink, talk |
| `narrator` | `narrator` | static |

## Scene Characters

Персонажи в полный рост на фоне сцены (`# scene_char:show:GROUP:KEY`).
Source: `main/scripts/scene_characters.lua`.

### Scene groups

| scene_id | group |
|---|---|
| `park_hub` | `park` |
| `park_riverside_bench` | `park` |
| `park_riverside_path` | `park` |

### Available characters per group

**`park`**:
  - `mila_idle` — sprite=`idle`, atlas=`char_mila`, click→knot=`park_npc_arrives`
  - `mila_idle_bench` — sprite=`idle`, atlas=`char_mila`, click→knot=`park_npc_arrives`
  - `mila_idle_path` — sprite=`idle`, atlas=`char_mila`, click→knot=`park_npc_arrives`
  - `mila_sitting` — sprite=`sitting`, atlas=`char_mila`

## Items

Все ID из ink-тегов `# add_item:` / `# remove_item:`.

`card` `case_file` `folder` `gift_berry_soda` `gift_chips` `gift_coffee_can` `gift_crackers` `gift_dark_chocolate` `gift_energy_drink` `gift_iced_tea` `gift_keychain_flashlight` `gift_milk_chocolate` `gift_nuts` `gift_paper_napkins` `gift_small_broom` `gift_waffle_bar` `gift_wet_wipes` `mug` `park_trash_cup` `phone` `report_page` `toothbrush` `toothbrush_pasted` `toothpaste` `water_bottle`

## Flags

Все имена флагов встречающиеся в `# set_flag:`, `get_flag(...)`,
`set_flag(...)`. Всего: **149**.

**`bathroom_*`**: `bathroom_morning_seen`

**`bedroom_*`**: `bedroom_morning_seen`

**`breakfast_*`**: `breakfast_done`

**`cafe_*`**: `cafe_arrived` `cafe_backroom_board_seen` `cafe_backroom_books_seen` `cafe_backroom_mirror_seen` `cafe_order_coffee` `cafe_order_done` `cafe_order_sweet` `cafe_order_tea` `cafe_shelf_detail_seen` `cafe_talk_done` `cafe_window_detail_seen`

**`coffee_*`**: `coffee_drunk`

**`date_*`**: `date_agreed` `date_place_cafe` `date_place_park` `date_route_chosen` `date_small_kindness`

**`first_*`**: `first_anomaly_seen`

**`fridge_*`**: `fridge_checked`

**`got_*`**: `got_out_of_bed`

**`iteration_*`**: `iteration_001_finished`

**`kitchen_*`**: `kitchen_intro_seen` `kitchen_morning_seen`

**`left_*`**: `left_apartment`

**`map_*`**: `map_opened_after_apartment`

**`messenger_*`**: `messenger_prod_bot_questioned` `messenger_unknown_asked_synthesis` `messenger_unknown_asked_who` `messenger_work_team_ack`

**`met_*`**: `met_npc_sunday`

**`mon_*`**: `mon_home_bedroom_seen` `mon_home_hall_seen` `mon_home_kitchen_seen` `mon_office_arrived` `mon_office_error_seen`

**`monday_*`**: `monday_breakfast_done` `monday_case_file_assembled` `monday_case_file_submitted` `monday_checked_in_office` `monday_coffee_done` `monday_commute_auto` `monday_commute_observed` `monday_commute_steady` `monday_dressed` `monday_finished` `monday_folder_taken` `monday_left_home` `monday_mail_read` `monday_morning_started` `monday_office_finished` `monday_ready_for_work` `monday_report_page_taken` `monday_started` `monday_washed_up` `monday_water_drunk` `monday_workday_checked`

**`mug_*`**: `mug_taken`

**`office_*`**: `office_auto_solution_blocked` `office_clarification_requested` `office_standard_solution_applied`

**`park_*`**: `park_arrived` `park_bench_cleared` `park_bench_trash_seen` `park_entrance_seen` `park_npc_at_bench` `park_npc_at_path` `park_npc_bench_shown` `park_npc_greeted` `park_npc_path_shown` `park_path_seen` `park_place_chosen` `park_talk_place_bench` `park_talk_place_path` `park_trash_cup_taken` `park_water_given` `park_where_message_sent`

**`phone_*`**: `phone_active` `phone_history_seeded` `phone_taken`

**`reached_*`**: `reached_office` `reached_work_district`

**`sunday_*`**: `sunday_after_date_active` `sunday_bedroom_window_seen` `sunday_dressed` `sunday_evening_started` `sunday_finished` `sunday_gift_berry_soda` `sunday_gift_bought` `sunday_gift_chips` `sunday_gift_coffee_can` `sunday_gift_crackers` `sunday_gift_dark_chocolate` `sunday_gift_energy_drink` `sunday_gift_given` `sunday_gift_iced_tea` `sunday_gift_keychain_flashlight` `sunday_gift_milk_chocolate` `sunday_gift_nuts` `sunday_gift_paper_napkins` `sunday_gift_right` `sunday_gift_small_broom` `sunday_gift_waffle_bar` `sunday_gift_water_bottle` `sunday_gift_wet_wipes` `sunday_kitchen_window_seen` `sunday_messenger_invite_sent` `sunday_morning_routine_seen` `sunday_ready_to_leave` `sunday_return_home_ad_seen` `sunday_second_stop_done` `sunday_shop_bought_drink_for_npc` `sunday_shop_bought_snack` `sunday_shop_done` `sunday_shop_pre_date_visited` `sunday_shop_street_pre_date_seen` `sunday_shop_street_with_npc_seen` `sunday_shop_with_npc_seen` `sunday_viewpoint_seen` `sunday_went_to_shop` `sunday_went_to_viewpoint`

**`teeth_*`**: `teeth_brushed`

**`toothbrush_*`**: `toothbrush_pasted_ready` `toothbrush_taken`

**`toothpaste_*`**: `toothpaste_taken`

**`tue_*`**: `tue_home_bedroom_seen` `tue_home_hall_seen` `tue_home_kitchen_seen`

**`tuesday_*`**: `tuesday_appeal_read` `tuesday_coffee_done` `tuesday_consequence_seen` `tuesday_desk_checked` `tuesday_investigation_done` `tuesday_kitchen_window_seen` `tuesday_left_home` `tuesday_log_reviewed` `tuesday_morning_started` `tuesday_npc_talked` `tuesday_pending` `tuesday_phone_checked` `tuesday_ready_to_leave` `tuesday_rooftop_reached` `tuesday_started` `tuesday_washed_up` `tuesday_water_drunk`

**`washed_*`**: `washed_up`

**`work_*`**: `work_card_taken`

## Backgrounds

Доступные bg-атласы (используются в `# bg:NAME` и `scene.bg`).
Source: `main/images/backgrounds/*.atlas`.

- `bg_apartment_bathroom_day`
- `bg_apartment_bathroom_night`
- `bg_apartment_bedroom_day`
- `bg_apartment_bedroom_night`
- `bg_apartment_hall_day`
- `bg_apartment_hall_night`
- `bg_apartment_kitchen_day`
- `bg_apartment_kitchen_night`
- `bg_archive_day`
- `bg_bar_maybe_night`
- `bg_cafe_backroom_day`
- `bg_cafe_corner_day`
- `bg_cafe_day`
- `bg_observation_corner_day`
- `bg_observation_railing_day`
- `bg_office_lobby_day`
- `bg_office_lobby_night`
- `bg_office_meeting_room_day`
- `bg_office_meeting_room_night`
- `bg_office_workspace_day`
- `bg_office_workspace_night`
- `bg_park_riverside_bench_day`
- `bg_park_riverside_entrance_day`
- `bg_park_riverside_path_day`
- `bg_rooftop`
- `bg_shop_front_day`
- `bg_shop_household_day`
- `bg_shop_street_day`

## Phone Map POIs

POI на карте телефона. `# map:allow:POI`, `# map:lock_to:POI`.

| POI | Scene при тапе | Label |
|---|---|---|
| `poi_archive` | `archive_hub` | Архив |
| `poi_bar` | `bar_hub` | Бар Maybe |
| `poi_cafe` | `cafe_hub` | Кафе |
| `poi_home` | `apartment_hub` | Домой |
| `poi_park` | `park_hub` | Парк у реки |
| `poi_shop` | `shop_hub` | Магазин 24/7 |
| `poi_view` | `view_hub` | Смотровая |
| `poi_work` | `work_hub` | На работу |
