# CODEX_CONTEXT

Актуально на `2026-04-29` (обновлено), ветка `AVOS_S`.

Этот файл — быстрый вход в проект для новой Codex-сессии.

## Читать Первым

1. `README.md`
2. `docs/reference/ARCHITECTURE.md`
3. `main/story/README_INK.md`
4. `docs/reference/LOOP_SYSTEM.md`
5. `docs/reference/TODO.md`

## Активный Runtime

- `game.project -> /main/main_v2.collectionc`
- главный UI: `main/gui/ui_manager_v2.script`
- GUI: `main/gui/components_v2/`
- сценарий: `main/story/chapter_01.ink` + `main/story/chapters/*.ink`
- compiled story: `main/story/chapter_01.json`
- старый runtime лежит в `archive/legacy_runtime/` и не участвует в игре

## Основные Модули

- `dialogue_manager_ink.lua` — `defold-ink`, команды из тегов, one-shot эффекты, jump в knot'ы.
- `game_state.lua` — состояние текущего прохождения: flags, inventory, quests, SMS, notes, mail, calls, clues, camera, terminal, current_scene.
- `save_manager.lua` — run-save для `Continue`: Ink history + `game_state`.
- `meta_state.lua` — долгий meta-state петли: iteration, awareness, false endings, выбор персонажа.
- `scene_controller.lua` — exploration-сцены, hotspots и scene objects.
- `ui_manager_v2.script` — меню, диалог, exploration, overlays, phone, map, inventory.

## Что Важно Помнить

- После правок `.ink` всегда запускать `tools\compile_ink.bat`.
- Runtime всё ещё грузит один `/main/story/chapter_01.json`.
- `main/story/chapters/New/` больше не рабочая ветка. Новый сюжет должен быть уже перенесён в активные `chapters/*.ink`.
- `Continue` чувствителен к структуре compiled Ink JSON. После крупных правок сценария лучше проверять и новый старт, и загрузку.
- Телефон data-driven: контент добавляется через Ink-теги и хранится в `game_state`.
- Карта уже умеет runtime `set_points`, обычные verbs `route/save/share` и hub-режим через `# map:hub:KNOT`.
- `nav_buttons_v2` удалён из активной схемы. Навигация идёт через hotspots и карту.
- `open_achievements` остаётся скрытым пунктом будущего этапа.
- Папку `skills/` не трогаем.

## Недавние Закрытые Хвосты

- подключены one-shot эффекты `# sfx`, `# shake`, `# pulse`
- loop labels больше не сидят на старом `#017`
- добавлены недостающие квесты `make_coffee` и `find_phone`
- телефон переведён на data-driven model
- инвентарь получил Ink-действия `use/inspect/read`
- `city_map_hub` объединён с `map_v2` через hub-режим
- phone apps `mail/call/clues/camera/terminal` получили storage/API
- debug-log spam сокращён через `DEBUG_LOG = false`
- исправлен баг с повторным диалогом спальни: `# set_flag:` не парсился в `apply_tags` → флаг `bedroom_morning_seen` никогда не ставился → вечный цикл
- исправлен `# add_item:` и `# remove_item:` — не распознавались в `apply_tags`
- добавлена система SMS-ответов: `# sms:reply:contact:text`, авто-флаги `sms_<contact>_replied` и `sms_<contact>_read`
- SMS-переписка стала кликабельной: тап на строку → `sms_open_contact` → Ink-knot `sms_thread_<contact>`
- написан knot `sms_thread_mila`, квест `reply_mila` полностью закрыт через ink
- создана `docs/guides/HOW_TO_WRITE_INK.md` — практическая инструкция по ink для проекта

## Где Лежит Контент

- Ink: `main/story/chapter_01.ink`, `main/story/chapters/*.ink`
- сцены: `main/scripts/scenes.lua`
- предметы: `main/scripts/items_catalog.lua`
- квесты: `main/scripts/quests.lua`
- фоны: `main/images/backgrounds/*.atlas`
- телефонные GUI: `main/gui/components_v2/phone_*.gui`
- телефонные ассеты: `main/images/phone/`
