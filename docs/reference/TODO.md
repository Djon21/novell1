# TODO — аудит кода `AVOS_S`

Оперативный backlog после ручного прохода по runtime, GUI, state, Ink-интеграции и контентным модулям.
Здесь только живые баги, заглушки и нестыковки, которые реально видны в текущем коде.

## P2 — незавершённые системы и заглушки

- [x] Завести реальные storage/API для `mail`, `call log`, `clues` в `game_state` или скрыть эти разделы телефона. Сейчас GUI показывает их как живые приложения, а state всегда отдаёт пустые списки. — добавлены `_mails/_call_log/_clues` с API (`add_mail/mark_mail_read/mark_all_mail_read/add_call/mark_all_calls_seen/add_clue/has_clue`), сериализация и ink-теги `mail/call/clue` (см. `README_INK.md`).
- [x] Добить `camera` и `terminal`: сейчас это статичные placeholder-вьюхи, а compatibility-knot `phone_stub_soon` всё ещё живёт в Ink. — добавлены сторы `_camera` и `_terminal_lines` с API (`set_camera_feed/reset_camera_feed/add_terminal_line/clear_terminal/reset_terminal_to_defaults`), ink-теги `camera:*` и `term:*`, `refresh_camera/refresh_terminal` в `phone_v2`, дефолтный сид для терминала при старте/reset; `phone_stub_soon` удалён из обоих `90_phone_apps.ink`.
- [x] Довести `city_map_hub` / карту мира до одной боевой схемы: сейчас часть маршрута живёт в Ink-узле с выбором, а отдельный `map_v2` существует параллельно как другая система. — добавлен hub-режим в `map_v2` (msg `open_map_hub {primary_knot}`, поле `route_knot` на пинах, `map_hub_route {knot}`), ink-тег `# map:hub:KNOT` (scene_bucket), форс-чойс `* [Метро «Технопарк»] -> metro` в `city_map_hub` заменён на `# map:hub:metro -> DONE` в обоих `01_apartment.ink`; при закрытии карты без выбора срабатывает fallback на `primary_knot` (см. `README_INK.md`).
- [x] Добавить реальные `exits` в `scenes.lua` или перестать держать `nav_buttons_v2` как будто он участвует в навигации. Сейчас перемещение почти полностью сидит на hotspot'ах. — выбран второй путь: `nav_buttons_v2` удалён (`.gui`, `.gui_script`), компонент снят с `main_v2.collection`, из `ui_manager_v2.script` вычищены `M.components.nav`, `show_nav/hide_nav`, `nav_go`, `current_scene_exits`, `set_exits`. Вся навигация остаётся через hotspots (`goto_scene`). Документация обновлена: `ARCHITECTURE.md`, `HOW_TO_ADD_SCENES.md`, `ROADMAP.md`, `DESIGN_PORT_RULES.md`.
- [x] Проверить и закрыть оставшийся regression-flow `exploration -> phone/map/inventory -> side dialogue -> return_to_scene -> save/load`. — аудит подтвердил, что архитектура корректна: `gs.subscribe` ловит каждое изменение `game_state` (включая `gs.set_scene` из `scene_controller.enter/exit/return_to_last_scene/reset`) и вызывает `persist_run_state` → `sm.set_game_state{gs, scene_controller}`. Ink-состояние отдельно автосейвится через `save_ink_state()` в `dialogue_manager_ink` на каждом `advance/jump_to_knot/choose`. На load `restore_run_state` восстанавливает `_scene_stack` и при `_active=true` вызывает `scene_controller.enter`, дальше `# return_to_scene` корректно поп'ает стек. Replay ink защищён `suppress_effects=true` → флаги/инвентарь/sms не дублируются. Из `on_message` убраны мёртвые хэндлеры `exploration_started/ended` (никто их в v2 не постит, дублировали то, что уже делает `gs.subscribe`); над `persist_run_state` добавлен комментарий с описанием save-точек.

## P2 — баги модели данных и UI-состояния

## P3 — нестыковки, cleanup и техдолг

- [x] Убрать дубли в `main_menu_v2.gui_script`: файл содержит повторные определения `animate_alpha`, `animate_x`, `animate_y`, `glitch_burst`, `schedule_next_glitch`. — удалены дублированные определения (старая «мягкая» ветка `glitch_burst`/`schedule_next_glitch` и второй блок `animate_alpha/x/y`). В файле осталась только активная ветка: `start_glitch_loop` → `schedule_next_glitch` (delay `0.35 + rnd*1.35`, до 3 aftershock'ов) → `glitch_burst` (mode-based: violent/hard/normal). Поведение не изменилось.
- [x] Убрать или хотя бы резко сократить debug-log spam в `ui_manager_v2`, `phone_v2`, `dialogue_v2`, `hotspots_v2` перед следующей волной контентного тестирования. — в каждый файл добавлен `DEBUG_LOG = false` + `dbg(...)` хелпер; все verbose-prints (mode/overlay transitions, init, show_view, refresh, portraits, hotspot hits) переключены на `dbg()`; реальные WARNING/ERROR (`no atlas`, `no inventory knot`, `chapter_01.json not found`, `bg animation not found`) оставлены как голые `print()`.
- [ ] Решить судьбу `click_001`: либо зарегистрировать его в `sfx_player`, либо вычистить из документации как неиспользуемый asset.

## Loop system / narrative

- [ ] Расширить loop-aware реплики за пределы `wake_intro`, `wake_after_choice` и финалов главы.
- [ ] Решить, растёт ли `loop_awareness` всегда на `+1` за конец главы или должен зависеть от выборов и найденных аномалий.
- [ ] Добавить удобный debug reset для `meta_state`, чтобы не чистить цикл вручную во время тестов.

## Platform / release

- [ ] Проверить интеграцию Яндекс SDK в реальной сборке, а не только по коду.
- [ ] Подготовить отдельный testing checklist для предрелизной проверки.
- [ ] Определить объём и приоритет EN-локализации.
