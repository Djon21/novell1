# CONTINUE_HERE

Актуально на `2026-04-23`.

V2-миграция уже завершена. Этот файл больше не про rollout migration, а про то, с чего удобно продолжать работу в текущем `AVOS_S`.

## Читать в таком порядке

1. `docs/reference/CODEX_CONTEXT.md`
2. `README.md`
3. `docs/reference/ARCHITECTURE.md`
4. `docs/reference/TODO.md`
5. `main/story/README_INK.md`

## Текущее состояние проекта

- активный bootstrap уже переключён на `main/main_v2.collectionc`
- основной UI живёт в `main/gui/components_v2/`
- Ink, `scene_controller` и `game_state` уже связаны в одном runtime
- legacy UI оставлен в проекте только как archive / reference

## Самые вероятные направления следующей работы

- пересмотреть рендер квестов в телефоне: `phone_v2` показывает только 2 карточки, а завершённые квесты могут вытеснять активные
- довести до конца `exits`-навигацию и карту мира
- полировать achievements / phone apps
- провести нормальный release QA под Яндекс.Игры

## Где быстро искать контекст

- архитектура и вход: `docs/reference/ARCHITECTURE.md`
- story pipeline: `main/story/README_INK.md`
- scenes / hotspots: `docs/guides/HOW_TO_ADD_SCENES.md`
- дизайн-портирование в Defold: `docs/guides/DESIGN_PORT_RULES.md`
- оперативные хвосты: `docs/reference/TODO.md`

## Что теперь считать архивом

Следующие файлы не удаляем, но читаем как историю миграции, а не как текущую инструкцию:

- `docs/archive/legacy-ui/AVOS_V2_PROGRESS.md`
- `docs/archive/legacy-ui/GUI_MIGRATION_PLAN.md`
- `docs/archive/legacy-ui/GUI_AUDIT.md`
- `docs/archive/legacy-ui/GUI_CREATION_GUIDE.md`
- `docs/archive/legacy-ui/GUI_VALIDATION_REPORT.md`
- `docs/archive/legacy-ui/INTEGRATION_REPORT.md`
- `docs/archive/legacy-ui/MIGRATION_STATUS.md`
- `docs/archive/legacy-ui/MIGRATION_COMPLETE.md`
- `docs/archive/legacy-ui/NODE_MAP.md`
