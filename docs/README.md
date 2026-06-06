# Документация AVOS_S

Документация разделена на:
- **reference** — архитектурные документы, source-of-truth для структуры.
- **guides** — практические how-to и описания систем.
- **scenario_context** — сжатый пакет документов для GPT-проекта по сценарию, хабам, локациям и хотспотам.
- **archive** — история миграции, не источник правды.

## Читать Первым

1. `../README.md`
2. `reference/CODEX_CONTEXT.md` — быстрый вход для AI/новой сессии
3. `reference/ARCHITECTURE.md` — runtime + основные модули
4. `guides/HOW_TO_WRITE_INK.md` — ink-теги, паттерны
5. `scenario_context/README.md` — компактный контекст для GPT, который помогает со сценарием и хабами
6. `reference/TODO.md` — живые хвосты
12. `docs/guides/STORY_TESTING.md` — тестирование Ink

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
- `L10N_PLAN.md` — план локализации RU/EN/TR
- `TESTING_CHECKLIST.md` — ручной QA перед релизом

### Дизайн / нарратив
- `AVOS_S_Story_Bible.md`
- `AVOS_S_World_Doc_v3_color_palette.md`

## Guides

### Работа с контентом
- `HOW_TO_WRITE_INK.md` — все ink-теги и паттерны
| `STORY_TESTING.md` | Документация системы автоматического тестирования Ink-стори через inkjs |
- `HOW_TO_ADD_SCENES.md` — фоны, сцены, hotspot'ы
- `HOW_TO_ADD_PORTRAITS.md` — портреты персонажей (статика)
- `HOW_TO_ANIMATE_PORTRAITS.md` — layered-портреты: моргание + движение рта, пайплайн с нейронкой
- `HOW_TO_ADD_SCENE_CHARACTERS.md` — персонажи в полный рост на фоне сцены (клик/hover как у хотспотов)
- `HOW_TO_ADD_SOUNDS.md` — sfx + музыка

### Подсистемы UI
- `PHONE_SYSTEM.md` — phone overlay, apps, ink-теги телефона
- `HUB_SYSTEM.md` — хабы и переходы
- `HOTSPOTS.md` — стили hotspot'ов + dev-редактор координат
- `DEV_JUMP_CHECKPOINTS.md` — dev-прыжки по сценам для быстрой проверки
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
- `STORY_TESTING.md` — система тестирования сюжета через inkjs (CI, Walkthrough, ограничения)

## Legacy

Папка `docs/archive/` удалена в мае 2026 — legacy-snapshot'ы (`legacy-ui/*`,
`HOW_TO_WRITE_INK_old.md`, `HUB_SYSTEM_old.md`) больше не актуальны. Полная
история всё ещё доступна через `git log` / `git show`.

`archive/legacy_runtime/` (в корне проекта, не в docs/) — отключённый старый
runtime, **не fallback**.
