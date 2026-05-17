# Project Inventory

**Auto-generated** скриптом `tools/generate_scenario_inventory.py`.
Запускать перед каждой сессией AI-сценариста чтобы документ отражал
текущее состояние проекта.

_Сгенерировано: 2026-05-17 12:37_

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

### `cafe_backroom` (Кафе — задняя)
 — source: `cafe.lua`, bg: `"bg_cafe_backroom_day"`

| Hotspot id | Label | Action | Gated |
|---|---|---|---|
| `backroom_to_cafe` | В зал | scene: `cafe_hub` | — |
| `leave_cafe_backroom` | — | knot: `leave_cafe` | — |

### `cafe_corner` (Кафе — уголок)
 — source: `cafe.lua`, bg: `"bg_cafe_corner_day"`

| Hotspot id | Label | Action | Gated |
|---|---|---|---|
| `corner_to_cafe` | В зал | scene: `cafe_hub` | — |
| `leave_cafe_corner` | — | knot: `leave_cafe` | — |

### `cafe_hub` (Кафе)
 — source: `cafe.lua`, bg: `"bg_cafe_morning"`, on_enter: `sunday_date_cafe_arrival`

| Hotspot id | Label | Action | Gated |
|---|---|---|---|
| `cafe_window_table` | Столик у окна | knot: `cafe_window_table` | 👁 |
| `cafe_bar` | Стойка | knot: `cafe_bar_interact` | — |
| `cafe_to_corner` | В уголок | scene: `cafe_corner` | — |
| `cafe_to_backroom` | Задняя | scene: `cafe_backroom` | — |
| `leave_cafe` | — | knot: `leave_cafe` | — |

### `monday_apartment_bedroom_morning` (Спальня)
 — source: `apartment_monday.lua`, bg: `"bg_apartment_bedroom_morning"`, on_enter: `mon_home_bedroom_intro`

| Hotspot id | Label | Action | Gated |
|---|---|---|---|
| `mon_bed` | Кровать | knot: `mon_home_bed` | — |
| `mon_bedroom_desk` | Рабочий стол | knot: `mon_home_bedroom_desk` | — |
| `mon_bathroom_wash` | Умыться | knot: `mon_home_wash_up` | 👁 |
| `mon_to_hall_from_bedroom` | В коридор | scene: `monday_apartment_hall_morning` | — |

### `monday_apartment_hall_morning` (Коридор)
 — source: `apartment_monday.lua`, bg: `"bg_apartment_hall_morning"`, on_enter: `mon_home_hall_intro`

| Hotspot id | Label | Action | Gated |
|---|---|---|---|
| `mon_to_bedroom` | В спальню | scene: `monday_apartment_bedroom_morning` | — |
| `mon_to_kitchen` | На кухню | scene: `monday_apartment_kitchen_morning` | — |
| `mon_hall_mirror` | Зеркало | knot: `mon_home_hall_mirror` | — |
| `mon_work_card` | Пропуск | knot: `mon_home_take_work_card` | 👁 |
| `mon_get_dressed` | Обувь и куртка | knot: `mon_home_get_dressed` | 👁 |
| `mon_exit_apartment` | Выйти | knot: `mon_home_leave_apartment` | 🔒 |

### `monday_apartment_kitchen_morning` (Кухня)
 — source: `apartment_monday.lua`, bg: `"bg_apartment_kitchen_morning"`, on_enter: `mon_home_kitchen_intro`

| Hotspot id | Label | Action | Gated |
|---|---|---|---|
| `mon_kitchen_coffee` | Кофе | knot: `mon_home_kitchen_coffee` | 👁 |
| `mon_kitchen_window` | Окно | knot: `mon_home_kitchen_window` | — |
| `mon_back_to_hall_from_kitchen` | В коридор | scene: `monday_apartment_hall_morning` | — |

### `office_meeting_room` (Переговорка)
 — source: `office_monday.lua`, bg: `office_bg("meeting_room")`

| Hotspot id | Label | Action | Gated |
|---|---|---|---|
| `meeting_room_table_folder` | Стол | knot: `meeting_room_take_folder` | 👁 |
| `meeting_room_table_after` | Стол | knot: `meeting_room_table_after` | 👁 |
| `meeting_room_to_workspace` | К рабочему месту | scene: `office_workspace` | — |
| `meeting_room_back_to_lobby` | В лобби | scene: `work_hub` | — |

### `office_workspace` (Рабочее место)
 — source: `office_monday.lua`, bg: `office_bg("workspace")`

| Hotspot id | Label | Action | Gated |
|---|---|---|---|
| `work_desk_mail` | Рабочий стол | knot: `work_desk_read_mail` | 👁 |
| `work_desk_waiting` | Рабочий стол | knot: `work_desk_needs_case_file` | 👁 |
| `work_desk_submit` | Рабочий стол | knot: `work_desk_case_file_prompt` | 👁 |
| `work_desk_done` | Рабочий стол | knot: `work_desk_done` | 👁 |
| `workspace_to_meeting_room` | В переговорку | scene: `office_meeting_room` | 🔒 |
| `workspace_back_to_lobby` | В лобби | scene: `work_hub` | — |

### `park_hub` (Парк у реки)
 — source: `park.lua`, bg: `"bg_park_riverside_entrance_morning"`, on_enter: `sunday_date_park_arrival`

| Hotspot id | Label | Action | Gated |
|---|---|---|---|
| `park_entrance_view` | Осмотреться | knot: `park_entrance_view` | 👁 |
| `park_bin` | Урна | knot: `park_bin_prompt` | 👁 |
| `park_message_where` | Написать | knot: `park_message_where_are_you` | 👁 |
| `park_offer_place` | Предложить | knot: `park_offer_place` | 👁 |
| `park_to_bench` | К скамейке | scene: `park_riverside_bench` | 👁 |
| `park_to_path` | По аллее | scene: `park_riverside_path` | 👁 |
| `leave_park` | Уйти | knot: `leave_park` | 👁 |

### `park_riverside_bench` (Парк у реки — скамейка)
 — source: `park.lua`, bg: `"bg_park_riverside_bench_morning"`, on_enter: `park_bench_npc_show`

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
 — source: `park.lua`, bg: `"bg_park_riverside_path_morning"`, on_enter: `park_path_npc_show`

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
 — source: `apartment_tuesday.lua`, bg: `"bg_apartment_bedroom_morning"`, on_enter: `tue_home_bedroom_intro`

| Hotspot id | Label | Action | Gated |
|---|---|---|---|
| `tue_bed` | Кровать | knot: `tue_home_bed` | — |
| `tue_phone_check` | Телефон | knot: `tue_home_check_phone` | 👁 |
| `tue_bedroom_desk` | Рабочий стол | knot: `tue_home_bedroom_desk` | — |
| `tue_bathroom_wash` | Умыться | knot: `tue_home_wash_up` | 👁 |
| `tue_to_hall_from_bedroom` | В коридор | scene: `tuesday_apartment_hall_morning` | — |

### `tuesday_apartment_hall_morning` (Коридор)
 — source: `apartment_tuesday.lua`, bg: `"bg_apartment_hall_morning"`, on_enter: `tue_home_hall_intro`

| Hotspot id | Label | Action | Gated |
|---|---|---|---|
| `tue_to_bedroom` | В спальню | scene: `tuesday_apartment_bedroom_morning` | — |
| `tue_to_kitchen` | На кухню | scene: `tuesday_apartment_kitchen_morning` | — |
| `tue_hall_mirror` | Зеркало | knot: `tue_home_hall_mirror` | — |
| `tue_get_ready` | Обувь и куртка | knot: `tue_home_get_ready` | 👁 |
| `tue_exit_apartment` | Выйти | knot: `tue_home_leave_apartment` | 🔒 |

### `tuesday_apartment_kitchen_morning` (Кухня)
 — source: `apartment_tuesday.lua`, bg: `"bg_apartment_kitchen_morning"`, on_enter: `tue_home_kitchen_intro`

| Hotspot id | Label | Action | Gated |
|---|---|---|---|
| `tue_kitchen_coffee` | Кофе | knot: `tue_home_kitchen_coffee` | 👁 |
| `tue_kitchen_window` | Окно | knot: `tue_home_kitchen_window` | — |
| `tue_back_to_hall_from_kitchen` | В коридор | scene: `tuesday_apartment_hall_morning` | — |

### `view_corner` (Смотровая — угол)
 — source: `viewpoint.lua`, bg: `"bg_observation_corner_day"`

| Hotspot id | Label | Action | Gated |
|---|---|---|---|
| `corner_to_view` | К перилам | scene: `view_hub` | — |
| `leave_view_corner` | Уйти | knot: `leave_viewpoint` | — |

### `view_hub` (Смотровая)
 — source: `viewpoint.lua`, bg: `"bg_observation_railing_day"`, on_enter: `sunday_viewpoint_arrival`

| Hotspot id | Label | Action | Gated |
|---|---|---|---|
| `view_railing` | Поручни | knot: `view_railing_interact` | — |
| `view_to_corner` | В угол | scene: `view_corner` | — |
| `leave_view` | Уйти | knot: `leave_viewpoint` | — |

### `work_hub` (Офис — лобби)
 — source: `office_monday.lua`, bg: `office_bg("lobby")`

| Hotspot id | Label | Action | Gated |
|---|---|---|---|
| `office_turnstile` | Турникет | knot: `office_turnstile_prompt` | 👁 |
| `office_to_workspace` | К рабочему месту | scene: `office_workspace` | 🔒 |
| `office_to_meeting_room` | В переговорку | scene: `office_meeting_room` | 🔒 |
| `leave_work` | — | knot: `leave_work` | — |

## Ink Knots

Все объявленные `=== knot_name ===` в `main/story/chapters/*.ink`
(без `_old*` версий). Используй ТОЛЬКО эти имена для `action_knot`
в hotspot'ах и для `# scene_char:show:...:...` если требуется.

### `10_apartment.ink`

| Knot | Аннотация |
|---|---|
| `apartment_bedroom_intro` | Кто пишет в воскресенье с утра? |
| `apartment_start` | Воскресное утро. |
| `bathroom_exit_locked` | Нет. Я уже в ванной, щётка и паста передо мной. |
| `bathroom_not_now` | Умылся. Второй раз бодрее не станет. |
| `bathroom_sink_prompt` | Щётка уже готова. Надо использовать её на раковине. |
| `bedroom_desk_morning` | На рабочем столе закрытый ноутбук, блокнот и кабель от телефона. |
| `choose_character` | Кто я? |
| `drink_water_kitchen` | Вода из-под фильтра прохладная и честная. Не кофе, не ритуал, просто способ напомнить телу, что оно существует. |
| `enter_bathroom_morning_first` | Ванная встречает прохладной плиткой, зеркалом и тем самым мятным запахом, который обещает бодрость, но пока только обеща |
| `enter_kitchen_morning_first` | Кухня встречает сухим щелчком холодильника и светлым окном во двор. |
| `leave_apartment` | Куртка и обувь наконец делают намерение выйти похожим на действие. |
| `leave_apartment_prompt` | Телефон уже вибрировал. Сначала надо ответить в Messenger — иначе выходить всё ещё некуда. |
| `look_bathroom_mirror` | Зеркало показывает человека, который уже взял телефон, но ещё не совсем проснулся. |
| `look_bed_morning` | Постель смята точно так же, как в прошлый раз. |
| `look_bedroom_window` | За окном город выглядит так, будто воскресенье у него началось раньше твоего: редкие машины, свет в стекле, кто-то с соб |
| `look_hall_mirror` | Зеркало в коридоре показывает ровно то, что должно: лицо, плечи, входную дверь за спиной. |
| `look_kitchen_fridge` | В холодильнике йогурт, сыр и контейнер, который лучше не открывать без отдельного морального разрешения. |
| `look_kitchen_window` | Лето держится во дворе уверенно: солнце на стекле машин, тени от деревьев, кто-то медленно несёт пакет из магазина. |
| `mon_home_bed` | Кровать выглядит слишком убедительно для понедельника. |
| `mon_home_bedroom_desk` | На рабочем столе лежит закрытый ноутбук. Воскресенье почти стерло его из внимания, но понедельник возвращает всё на мест |
| `mon_home_bedroom_intro` | Спальня собирается в понедельник из тех же предметов: кровать, окно, рабочий стол, дверь в ванную. |
| `mon_home_get_dressed` | Куртка снимается с крючка, обувь находится под банкеткой, ключи привычно проверяются в кармане. |
| `mon_home_hall_intro` | Коридор встречает более деловито, чем вчера: дверь, зеркало, обувь, куртка, полка у входа. |
| `mon_home_hall_mirror` | В зеркале всё выглядит собранно: светлая стена, край двери, человек, который должен выглядеть так, будто знает, куда идё |
| `mon_home_kitchen_coffee` | Кружка стоит на столе, как будто никогда не покидала кухню. И это правильно: кружки не носят в кармане через весь город. |
| `mon_home_kitchen_intro` | Кухня выглядит так, будто не знает разницы между воскресеньем и понедельником. |
| `mon_home_kitchen_window` | За окном город уже не просыпается — он работает. |
| `mon_home_leave_apartment` | Перед дверью всё на секунду останавливается. |
| `mon_home_take_work_card` | Пропуск находится в кармане куртки, где ему и положено быть. |
| `mon_home_wash_up` | В ванной холодная вода быстро стирает остатки сна. |
| `mon_office_evening_close` | Вечером квартира принимает тебя без вопросов. |
| `monday_morning_start` | Понедельник начинается без вибрации телефона. |
| `seed_phone_history` | *4821: списание 480 ₽. Кофейня «петля». 12 апр. Баланс 12 740 ₽. |
| `sunday_date_go_cafe` | — |
| `sunday_date_go_park` | - else: |
| `sunday_date_map_fallback` | Карта открыта. Осталось выбрать маршрут. |
| `sunday_evening_finish` | Вечер постепенно собирает квартиру вокруг тебя: коридор, кухня, свет из окна, телефон на ладони. |
| `sunday_evening_home` | Квартира встречает тем же спокойствием, с которого началось утро. Только теперь оно ощущается иначе: не как список дел,  |
| `sunday_get_dressed` | Куртка с вешалки, обувь у двери. Никакого торжественного выхода — просто бытовая последовательность, без которой человек |
| `sunday_home_after_date_router` | - else: |
| `sunday_home_too_early` | Домой пока рано. День только начал становиться настоящим воскресеньем. |
| `sunday_send_messenger_invite` | Телефон на столешнице коротко вибрирует — не как утренний шум, а как сообщение, которое ждало, пока ты наконец сделаешь  |
| `sunday_sleep_in_bed` | Спальня выглядит почти так же, как утром, только свет стал мягче и ниже. |
| `take_kitchen_apple` | В миске на столе лежат зелёные яблоки. Одно холодит ладонь чуть сильнее остальных. |
| `take_mug` | На столе стоит белая кружка с тонкой трещиной на ручке. |
| `take_phone` | Телефон лежит экраном вниз у тумбочки. |
| `take_toothbrush` | Зубная щётка стоит в стакане у раковины. |
| `take_toothpaste` | Тюбик пасты смят посередине и стоит так, будто его тоже подняли слишком рано. |
| `tue_home_bed` | Кровать уже не предлагает остаться. Она просто хранит форму тела, которое не выспалось до конца. |
| `tue_home_bedroom_desk` | Ноутбук на столе выглядит как быстрый способ сделать вид, что контроль возвращается. |
| `tue_home_bedroom_intro` | Спальня не изменилась. |
| `tue_home_check_phone` | Экран загорается сразу. |
| `tue_home_get_ready` | Обувь, куртка, ключи, пропуск. |
| `tue_home_hall_intro` | Коридор собирает вторник в маршрут: зеркало, дверь, обувь, ключи, куртка. |
| `tue_home_hall_mirror` | В зеркале нет ответа. |
| `tue_home_kitchen_coffee` | Кофе получается крепче, чем нужно. |
| `tue_home_kitchen_intro` | Кухня держится за бытовое упрямство. |
| `tue_home_kitchen_window` | За окном город выглядит так, будто вчерашний день нигде не задержался. |
| `tue_home_leave_apartment` | У двери появляется привычная пауза. |
| `tue_home_wash_up` | Холодная вода возвращает лицо в настоящее. |
| `tuesday_morning_start` | Вторник начинается не как повтор. |
| `use_coffee_machine_with_cup` | Кружка у меня. Надо не просто смотреть на чайник, а использовать её здесь. |
| `use_coffee_setup_no_mug` | Кружка у меня. Надо не просто смотреть на чайник, а использовать её здесь. |

### `91_inventory_actions.ink`

| Knot | Аннотация |
|---|---|
| `inv_apartment_bathroom_use_toothbrush_pasted_on_bathroom_sink` | Холодная вода. Мята. Несколько секунд перед зеркалом, в которых день наконец становится похож на день. |
| `inv_apartment_kitchen_morning_use_mug_on_coffee_setup` | На смятом листке всего одна строка: |
| `inv_apartment_kitchen_use_mug_on_coffee_setup` | Ставлю кружку на столешницу рядом с чайником. |
| `inv_combine_fallback` | - else: |
| `inv_combine_folder_with_report_page` | Вкладываю распечатку в папку, выравниваю край листа и закрываю обложку. |
| `inv_combine_toothbrush_with_toothpaste` | Выдавливаю пасту на щётку. Самое сложное решение утра пока принято. |
| `inv_fallback` | Сейчас я просто убираю предмет обратно. |
| `inv_give_fallback` | Хочется передать {inventory_item_name}, но сейчас момент не тот. |
| `inv_inspect_case_file` | Папка выглядит готовой. И в этом проблема: готовый вид легко принять за готовый ответ. |
| `inv_inspect_fallback` | Осматриваю {inventory_item_name}. Детали на месте. Ответов по-прежнему нет. |
| `inv_inspect_folder` | Обычная офисная папка. Чем аккуратнее она выглядит, тем легче забыть, что внутри может быть недостающая часть решения. |
| `inv_inspect_note` | Моя бумага. Мой почерк. Но ощущение, что писал это не я сегодняшний. |
| `inv_inspect_park_trash_cup` | Чужой пустой стаканчик. Не самая великая проблема дня, но начать разговор рядом с ним почему-то не хочется. |
| `inv_inspect_phone` | Телефон тёплый, будто я уже держал его в руках минуту назад. |
| `inv_inspect_report_page` | Один лист, несколько полей и слишком много пустых мест между строками. |
| `inv_inspect_toothbrush` | Обычная зубная щётка. Никакой тайны. Просто вещь, без которой утро становится социально рискованным. |
| `inv_inspect_toothbrush_pasted` | Щётка с пастой. Очень узкоспециализированный инструмент против воскресного состояния. |
| `inv_inspect_toothpaste` | Мятная паста. Тюбик смят посередине — классика людей, которые не хотят признавать, что пора купить новый. |
| `inv_inspect_water_bottle` | Бутылка воды из магазина. После второго кофе это почти романтическая предусмотрительность, если не произносить это вслух |
| `inv_office_workspace_give_case_file_on_npc` | Передаю папку коллеге. |
| `inv_office_workspace_use_case_file_on_work_desk_submit` | Кладу папку рядом с клавиатурой и прикрепляю её к рабочему кейсу. |
| `inv_park_hub_use_park_trash_cup_on_park_bin` | Стаканчик падает в урну с тихим пластиковым шорохом. Ничего героического — просто место у лавочки стало чуть больше похо |
| `inv_read_case_file` | Кейс 017. |
| `inv_read_fallback` | На {inventory_item_name} нечего читать. По крайней мере, пока. |
| `inv_read_note` | На смятом листке всего одна строка: |
| `inv_read_report_page` | Кейс 017. |
| `inv_use_fallback` | Сжимаю {inventory_item_name} в руке. Сейчас это ничего не изменит. |
| `inv_use_on_fallback` | - else: |
| `inv_use_park_trash_cup_on_fallback` | Стаканчик надо выкинуть в урну. Носить его по парку как аргумент — странная стратегия. |
| `inv_work_hub_use_card_on_office_turnstile` | Прикладываю пропуск к считывателю. |

### `92_phone_sms.ink`

| Knot | Аннотация |
|---|---|
| `sms_service_done` | — |
| `sms_thread_bank` | БАНК · СберID: |
| `sms_thread_clinic` | КЛИНИКА: |
| `sms_thread_coffee` | КОФЕЙНЯ РЯДОМ: |
| `sms_thread_delivery` | ДОСТАВКА: |
| `sms_thread_mama` | МАМА: |
| `sms_thread_market` | МАРКЕТ: |
| `sms_thread_metro` | МЕТРО: |
| `sms_thread_nm` | Н. М.: |
| `sms_thread_prod` | ОТДЕЛ · ПРОД: |
| `sms_thread_taxi` | ТАКСИ · ЯКС: |
| `sms_thread_unknown` | НОМЕР СКРЫТ: |
| `sms_thread_upravdom` | УПРАВДОМ: |

### `93_phone_messenger.ink`

| Knot | Аннотация |
|---|---|
| `msg_npc_place_sent` | Сообщение отправлено. |
| `msg_thread_artem` | Открываешь Messenger. |
| `msg_thread_mila` | Открываешь Messenger. |
| `msg_thread_prod_bot` | PROD-BOT: |
| `msg_thread_unknown` | Чат без имени. Аватар пустой. |
| `msg_thread_work_team` | Командный чат листается короткими служебными сообщениями. |

### `archive_tuesday.ink`

| Knot | Аннотация |
|---|---|
| `archive_shelves_interact` | Стеллажи уходят вглубь ровными рядами. Папки, коробки, старые номера дел — всё выглядит так, будто память здесь давно пр |
| `leave_archive` | Ты выходишь из архива. Воздух за дверью кажется легче, хотя вопросов меньше не стало. |

### `bar_sunday.ink`

| Knot | Аннотация |
|---|---|
| `bar_counter_interact` | Барная стойка тянется вдоль стены тёмной линией. За ней — бутылки, отражения и низкий свет, в котором легко сделать вид, |
| `leave_bar` | Ты выходишь из бара обратно в город. Ночной воздух кажется проще, чем свет внутри. |

### `cafe_sunday.ink`

| Knot | Аннотация |
|---|---|
| `cafe_bar_interact` | Стойка пахнет кофе и тёплой выпечкой. Бариста двигается быстро, но без суеты — как будто воскресенье здесь умеют не торо |
| `cafe_bar_interact_right_place` | Надо будет взять что-нибудь к столу. Не только же пытаться красиво разговаривать. |
| `cafe_bar_interact_wrong_place` | Кафе хорошее, но мы договорились не здесь. |
| `cafe_window_table` | Столик у окна держит ровно ту дистанцию, которая нужна для первого воскресного разговора: достаточно близко, чтобы слыша |
| `leave_cafe` | Ты выходишь из кафе на улицу. Телефон уже в руке — можно выбрать, куда идти дальше. |
| `sunday_date_cafe_arrival` | Кафе оказывается ровно таким, каким хотелось его увидеть утром: тёплый свет из окна, тёмное дерево, тихий звон чашек за  |
| `sunday_date_cafe_settle` | Разговор складывается из простых вещей: кто как спал, почему город утром кажется тише, что лучше — сладкое к кофе или пр |

### `commute_monday.ink`

| Knot | Аннотация |
|---|---|
| `mon_commute_entry` | Лифт, подъезд, двор — всё проходит почти без текста. |
| `mon_commute_office_approach` | Турникет принимает пропуск коротким писком. |
| `mon_commute_walk_auto` | Автоматический маршрут удобен тем, что не требует участия. |
| `mon_commute_walk_observe` | Ты намеренно замедляешься на пару шагов. |
| `mon_commute_walk_steady` | Ты держишь ровный темп, без рывков и без театральной собранности. |
| `mon_commute_work_district` | Бизнес-центр появляется слишком быстро. |

### `office_monday.ink`

| Knot | Аннотация |
|---|---|
| `leave_work` | Пока рано уходить. День ещё держит тебя за рабочий кейс. |
| `meeting_room_table_after` | Стол в переговорке снова пустой. Как будто папка никогда здесь не лежала. |
| `meeting_room_take_folder` | В переговорке слишком чисто для комнаты, где обычно пытаются договориться о сложном. |
| `mon_office_auto_standard` | Ты не успеваешь сформулировать сомнение до конца. |
| `mon_office_case_router` | - else: |
| `mon_office_clarify` | Ты выбираешь запрос уточнения. |
| `mon_office_core_choice` | На этот раз пауза не исчезает сама. |
| `mon_office_day_end` | К концу дня офис становится тише, но не мягче. |
| `mon_office_entry` | Офис встречает ровным светом, стеклом и воздухом, который как будто уже отфильтровали от всего лишнего. |
| `mon_office_manual_standard` | Ты подтверждаешь стандартный путь вручную. |
| `mon_office_npc_greeting` | Собрал{mc_gender == "female":а|} папку? Отлично. Тогда можно открыть кейс нормально, а не по памяти и не с чужих слов. |
| `mon_office_npc_strange` | Это называется “рабочий процесс”. Очень древняя аномалия. Люди веками делают вид, что привыкли. |
| `mon_office_result_system_bias` | День продолжается так, будто ничего страшного не произошло. |
| `mon_office_result_true_bias` | День не становится легче. Очередь не превращается в красивый отчёт. Никто не хлопает по плечу за то, что ты выбрал{mc_ge |
| `mon_office_stop_auto` | Ты отключаешь автоприменение для кейса. |
| `mon_office_system_warning` | ДАННЫХ НЕДОСТАТОЧНО. |
| `mon_office_task_intro` | Собранная папка оказывается рядом с клавиатурой. Бумага, разделитель, короткая выжимка по кейсу — всё выглядит достаточн |
| `office_turnstile_prompt` | Турникет ждёт пропуск. |
| `work_desk_case_file_prompt` | Папка собрана. Теперь её нужно передать в работу — не просто посмотреть на стол. |
| `work_desk_done` | Кейс уже передан в работу. На столе остался только след от действия: пустое место там, где лежала папка. |
| `work_desk_needs_case_file` | Распечатка есть. Но отдавать один лист как “пакет по кейсу” — это уже совсем офисная магия. |
| `work_desk_read_mail` | Рабочий стол встречает тебя не вещами, а очередью: монитор, почта, панель AVOS, короткое уведомление сверху. |

### `office_tuesday.ink`

| Knot | Аннотация |
|---|---|
| `tue_route_after_review` | К вечеру пазл не становится полным. |
| `tue_route_ask_npc` | Я думаю, мы вчера слишком легко приняли слово “обычно”. |
| `tue_route_entry` | Дорога до бизнес-центра снова оказывается короткой. |
| `tue_route_office_return` | На рабочем этаже всё как обычно. |
| `tue_route_read_appeal` | Карточка апелляции написана простым языком. |
| `tue_route_read_log` | Лог выглядит сухо и почти невиновно. |
| `tue_route_review_options` | На экране открыты три вещи: лог решения, карточка апелляции и короткая цепочка комментариев. |
| `tue_route_to_rooftop` | Вы поднимаетесь наверх без офисной шутки про традиции. |

### `park_sunday.ink`

| Knot | Аннотация |
|---|---|
| `leave_park` | Ты выходишь с набережной. Телефон уже в руке — можно выбрать, куда идти дальше. |
| `park_bench_interact` | Скамейка у воды теперь запомнилась не видом, а паузой, в которой вы оба не стали ничего портить лишними словами. |
| `park_bench_main_talk` | Вы садитесь на скамейку у воды. Не слишком близко, чтобы это требовало объяснений, но и не так далеко, чтобы можно было  |
| `park_bench_npc_show` | - else: |
| `park_bin_prompt` | Урна стоит у края дорожки. Ты её уже выбирал. В неё уже летел такой же стаканчик с тем же глухим звуком. |
| `park_entrance_view` | Вход в парк уже понятен: дорожка, вода дальше справа, зелень, тёплый камень под солнцем. |
| `park_message_where_are_you` | Ты открываешь Messenger. Палец зависает над полем ввода чуть дольше, чем нужно для простого вопроса. |
| `park_npc_arrives` | Нашёл. То есть нашёл тебя, а не смысл жизни. Хотя день уже странно удачный. |
| `park_offer_place` | Теперь место уже не абстрактный выбор на карте, а конкретная развилка: сесть у воды или уйти в тень аллеи. Лавочка приве |
| `park_path_main_talk` | Вы идёте по аллее в тени деревьев. Дорожка сама задаёт темп: достаточно медленно, чтобы говорить, и достаточно легко, чт |
| `park_path_npc_show` | - else: |
| `park_path_trees` | Аллея остаётся хорошим вариантом: идти проще, чем сидеть напротив и делать вид, что это просто прогулка. |
| `park_path_walk` | Вы проходите дальше по аллее. Несколько минут можно не решать ничего: только идти, слушать шаги и редкие голоса где-то в |
| `park_river_view` | Река движется медленно и уверенно. На таком фоне разговоры обычно становятся тише — не слабее, просто честнее. |
| `sunday_date_park_arrival` | Парк у реки встречает светом и воздухом. Здесь уже день: солнце выше крыш, вода блестит между деревьями, дорожки живут с |
| `sunday_date_park_settle` | Разговор начинается с простого: погода, дорога, смешная неловкость у входа, кто сколько кофе уже успел выпить. Но рядом  |
| `take_park_trash_cup` | Чужой пустой стаканчик стоит на краю лавочки. Тот же самый. С теми же отпечатками пальцев — твоими. |

### `rooftop_tuesday.ink`

| Knot | Аннотация |
|---|---|
| `tue_rooftop_ending_npc` | Становится легче. |
| `tue_rooftop_ending_system` | Формула складывается холодно и красиво. |
| `tue_rooftop_ending_true` | На этот раз мысль не выбирает между теплом и точностью. |
| `tue_rooftop_entry` | - else: |
| `tue_rooftop_iter001_entry` | Крыша во вторник холоднее, чем могла бы быть в понедельник. |
| `tue_rooftop_iter001_finish` | Ветер поднимается резко, но мир не ломается. |
| `tue_rooftop_iter001_realization` | Если данных недостаточно, нельзя просто выбрать стандартный ответ. |
| `tue_rooftop_iter001_talk` | Город внизу выглядит идеально нормальным. |
| `tue_rooftop_loop_entry` | Крыша снова встречает ветром. |
| `tue_rooftop_loop_route` | - else: |
| `tue_rooftop_loop_signal` | Ветер замирает. |
| `tue_rooftop_loop_talk` | Тогда что нам делать? |

### `shop_sunday.ink`

| Knot | Аннотация |
|---|---|
| `leave_shop` | Ты отходишь от витрины магазина. Стекло ещё держит отражение улицы, но телефон уже в руке — до встречи можно выбрать мар |
| `shop_cleaning_supplies_interact` | На крючках висят перчатки, щётки и совки. Внизу стоят швабры — слишком прямые, слишком терпеливые, будто они давно приня |
| `shop_counter_interact` | Касса уже сделала своё: короткий писк терминала, тонкий чек, пакет, который почти ничего не весит. |
| `shop_household_goods_interact` | Бытовой отдел встречает вещами, о которых вспоминают не вовремя: пакеты, губки, лампочки, батарейки, рулоны бумаги, чист |
| `shop_paper_goods_interact` | Полка с бумажными полотенцами и салфетками выглядит почти абсурдно спокойной: белые рулоны, мягкие упаковки, одинаковые  |
| `shop_sign_interact` | Вывеска светится без настроения: 24/7, красная полоса, белые буквы, обещание быть открытой даже тогда, когда человеку лу |
| `shop_snacks_interact` | Центральный стеллаж выглядит убедительнее, чем должен: батончики, жвачка, мармелад, маленькие пачки печенья. Всё слишком |
| `shop_window_interact` | Витрина собирает внутри маленькую выставку нормальности: вода ровными рядами, шоколадки у кассы, корзинки одна в другой, |
| `sunday_shop_arrival` | - else: |
| `sunday_shop_arrival_pre_date` | Внутри магазин почти пустой: холодильники гудят у дальней стены, возле кассы мигает терминал, на стеллаже кто-то оставил |
| `sunday_shop_arrival_with_npc` | Магазин 24/7 встречает белым светом, гулом холодильников и корзинками у входа. После прогулки это место выглядит не рома |
| `sunday_shop_settle` | Касса отвечает коротким писком, пакет шуршит у запястья, дверь выпускает вас обратно к улице. |
| `sunday_shop_street_arrival` | Магазин стоит внизу жилого дома: красная полоса над входом, бумажный штендер у двери, холодный свет за стеклом. Витрина  |

### `viewpoint_sunday.ink`

| Knot | Аннотация |
|---|---|
| `leave_viewpoint` | Телефон снова оказывается в руке. День уже не кажется коротким, но ему всё ещё нужен нормальный вечерний финал. |
| `sunday_viewpoint_arrival` | Смотровая оказывается не торжественной, а простой: город внизу, перила перед вами, ветер, который не требует разговарива |
| `sunday_viewpoint_settle` | Город снизу выглядит собранным и спокойным. Будто все маршруты в нём уже проложены, но сегодня можно не выбирать самый к |
| `view_railing_interact` | Поручни прохладные. За ними город выглядит собранным, почти спокойным. |

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

`card` `case_file` `folder` `mug` `park_trash_cup` `phone` `report_page` `toothbrush` `toothbrush_pasted` `toothpaste` `water_bottle`

## Flags

Все имена флагов встречающиеся в `# set_flag:`, `get_flag(...)`,
`set_flag(...)`. Всего: **112**.

**`bathroom_*`**: `bathroom_morning_seen`

**`bedroom_*`**: `bedroom_morning_seen`

**`breakfast_*`**: `breakfast_done`

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

**`monday_*`**: `monday_case_file_assembled` `monday_case_file_submitted` `monday_checked_in_office` `monday_coffee_done` `monday_dressed` `monday_finished` `monday_folder_taken` `monday_left_home` `monday_mail_read` `monday_morning_started` `monday_office_finished` `monday_ready_for_work` `monday_report_page_taken` `monday_started` `monday_washed_up` `monday_workday_checked`

**`mug_*`**: `mug_taken`

**`office_*`**: `office_auto_solution_blocked` `office_clarification_requested` `office_standard_solution_applied`

**`park_*`**: `park_arrived` `park_bench_cleared` `park_bench_trash_seen` `park_entrance_seen` `park_npc_at_bench` `park_npc_at_path` `park_npc_greeted` `park_path_seen` `park_place_chosen` `park_talk_place_bench` `park_talk_place_path` `park_trash_cup_taken` `park_water_given` `park_where_message_sent`

**`phone_*`**: `phone_active` `phone_history_seeded` `phone_taken`

**`reached_*`**: `reached_office` `reached_work_district`

**`sunday_*`**: `sunday_after_date_active` `sunday_bedroom_window_seen` `sunday_dressed` `sunday_evening_started` `sunday_finished` `sunday_kitchen_window_seen` `sunday_messenger_invite_sent` `sunday_morning_routine_seen` `sunday_ready_to_leave` `sunday_second_stop_done` `sunday_shop_bought_drink_for_npc` `sunday_shop_bought_snack` `sunday_shop_bought_water` `sunday_shop_done` `sunday_shop_pre_date_visited` `sunday_shop_street_pre_date_seen` `sunday_shop_street_with_npc_seen` `sunday_shop_with_npc_seen` `sunday_went_to_shop` `sunday_went_to_viewpoint`

**`teeth_*`**: `teeth_brushed`

**`toothbrush_*`**: `toothbrush_pasted_ready` `toothbrush_taken`

**`toothpaste_*`**: `toothpaste_taken`

**`tue_*`**: `tue_home_bedroom_seen` `tue_home_hall_seen` `tue_home_kitchen_seen`

**`tuesday_*`**: `tuesday_appeal_read` `tuesday_coffee_done` `tuesday_consequence_seen` `tuesday_desk_checked` `tuesday_investigation_done` `tuesday_kitchen_window_seen` `tuesday_left_home` `tuesday_log_reviewed` `tuesday_morning_started` `tuesday_npc_talked` `tuesday_pending` `tuesday_phone_checked` `tuesday_ready_to_leave` `tuesday_rooftop_reached` `tuesday_started` `tuesday_washed_up`

**`washed_*`**: `washed_up`

**`water_*`**: `water_drunk`

**`work_*`**: `work_card_taken`

## Backgrounds

Доступные bg-атласы (используются в `# bg:NAME` и `scene.bg`).
Source: `main/images/backgrounds/*.atlas`.

- `bg_apartment_bathroom_morning`
- `bg_apartment_bathroom_night`
- `bg_apartment_bedroom_morning`
- `bg_apartment_bedroom_night`
- `bg_apartment_hall_morning`
- `bg_apartment_hall_night`
- `bg_apartment_kitchen_morning`
- `bg_apartment_kitchen_night`
- `bg_archive_day`
- `bg_bar_maybe_night`
- `bg_cafe_backroom_day`
- `bg_cafe_corner_day`
- `bg_cafe_morning`
- `bg_observation_corner_day`
- `bg_observation_railing_day`
- `bg_office_lobby_day`
- `bg_office_lobby_night`
- `bg_office_meeting_room_day`
- `bg_office_meeting_room_night`
- `bg_office_workspace_day`
- `bg_office_workspace_night`
- `bg_park_riverside_bench_morning`
- `bg_park_riverside_entrance_morning`
- `bg_park_riverside_path_morning`
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
