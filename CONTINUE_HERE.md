# CONTINUE_HERE

Актуально на `2026-04-22`.

V2-миграция уже завершена. Этот файл больше не про rollout migration, а про то, с чего удобно продолжать работу в текущем `AVOS_S`.

## Читать в таком порядке

1. `CODEX_CONTEXT.md`
2. `README.md`
3. `ARCHITECTURE.md`
4. `TODO.md`
5. `main/story/README.md`

## Текущее состояние проекта

- активный bootstrap уже переключён на `main/main_v2.collectionc`
- основной UI живёт в `main/gui/components_v2/`
- Ink, `scene_controller` и `game_state` уже связаны в одном runtime
- legacy UI оставлен в проекте только как reference / fallback

## Самые вероятные направления следующей работы

- подключить bridge для `dm.get_effects()` в активный v2 UI
- довести до конца `exits`-навигацию и карту мира
- полировать gallery / achievements / phone apps
- провести нормальный release QA под Яндекс.Игры

## Где быстро искать контекст

- архитектура и вход: `ARCHITECTURE.md`
- story pipeline: `main/story/README.md`
- scenes / hotspots: `HOW_TO_ADD_SCENES.md`
- дизайн-портирование в Defold: `DESIGN_PORT_RULES.md`
- оперативные хвосты: `TODO.md`

## Что теперь считать архивом

Следующие файлы не удаляем, но читаем как историю миграции, а не как текущую инструкцию:

- `AVOS_V2_PROGRESS.md`
- `GUI_MIGRATION_PLAN.md`
- `GUI_AUDIT.md`
- `GUI_CREATION_GUIDE.md`
- `GUI_VALIDATION_REPORT.md`
- `INTEGRATION_REPORT.md`
- `MIGRATION_STATUS.md`
- `MIGRATION_COMPLETE.md`
- `NODE_MAP.md`
