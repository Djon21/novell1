# Документация AVOS_S

Документация разделена на:
- **reference** — архитектурные документы, source-of-truth для структуры.
- **guides** — практические how-to и описания систем.
- **archive** — история миграции, не источник правды.

## Читать Первым

1. `../README.md`
2. `reference/CODEX_CONTEXT.md` — быстрый вход для AI/новой сессии
3. `reference/ARCHITECTURE.md` — runtime + основные модули
4. `guides/HOW_TO_WRITE_INK.md` — ink-теги, паттерны
5. `reference/TODO.md` — живые хвосты

## Reference

### Точка входа / контекст
- `CODEX_CONTEXT.md` — быстрый вход для новой сессии (поглотил CONTINUE_HERE)
- `ARCHITECTURE.md` — runtime, модули, ink pipeline, ограничения
- `ROADMAP.md` — крупные направления
- `TODO.md` — живые хвосты задач

### Системы
- `LOOP_SYSTEM.md` — итерации, meta-state, false/true endings
- `INVENTORY_SYSTEM.md` — инвентарь и ink-действия предметов
- `GAME_STATE.md` — фасад state-системы, channel-модули в `main/scripts/state/`
- `UI_MANAGER_V2_ARCHITECTURE.md` — архитектурный обзор + потоки + чек-листы
- `UI_MANAGER_V2_MODULES.md` — справочник flow-модулей
- `L10N_PLAN.md` — план локализации RU/EN/TR
- `TESTING_CHECKLIST.md` — ручной QA перед релизом

### Дизайн / нарратив
- `AVOS_S_Story_Bible.md`
- `AVOS_S_World_Doc_v3_color_palette.md`

## Guides

### Работа с контентом
- `HOW_TO_WRITE_INK.md` — все ink-теги и паттерны
- `HOW_TO_ADD_SCENES.md` — фоны, сцены, hotspot'ы
- `HOW_TO_ADD_PORTRAITS.md` — портреты персонажей
- `HOW_TO_ADD_SOUNDS.md` — sfx + музыка

### Подсистемы UI
- `PHONE_SYSTEM.md` — phone overlay, apps, ink-теги телефона
- `HUB_SYSTEM.md` — хабы и переходы
- `HOTSPOT_VISUALS.md` — стили hotspot'ов
- `F1_HOTSPOT_EDITOR.md` — dev-редактор координат
- `DIALOGUE_BACKLOG.md` — backlog реплик и выборов
- `UI_COLOR_SYSTEM_RECOMMENDATIONS.md`

### Дизайн / графика
- `GRAPHICS_GUIDE.md`
- `DESIGN_PORT_RULES.md`

### Технические модули
- `LOGGING.md` — единый logger (log.lua)
- `MESSAGES.md` — реестр msg-сообщений (messages.lua)
- `GUI_UTILS.md` — общие GUI-хелперы
- `DRAG_SCROLL.md` — drag-to-scroll для phone-app'ов
- `YANDEX_SDK_AND_ADS.md` — Yandex Games SDK и реклама

## Legacy

Папка `docs/archive/` удалена в мае 2026 — legacy-snapshot'ы (`legacy-ui/*`,
`HOW_TO_WRITE_INK_old.md`, `HUB_SYSTEM_old.md`) больше не актуальны. Полная
история всё ещё доступна через `git log` / `git show`.

`archive/legacy_runtime/` (в корне проекта, не в docs/) — отключённый старый
runtime, **не fallback**.
