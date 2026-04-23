# Аудит документации

Актуально на `2026-04-22`.

Цель этой ревизии — разделить документацию на:

- рабочую, которая описывает текущий `v2` runtime
- архивную, которая сохраняет историю миграции и legacy UI

Папка `skills/` в этот аудит намеренно не входит.

## Что теперь считается рабочей документацией

- `README.md`
- `docs/reference/ARCHITECTURE.md`
- `docs/reference/CODEX_CONTEXT.md`
- `docs/reference/CONTINUE_HERE.md`
- `main/story/README_INK.md`
- `main/story/INK_STYLE.md`
- `docs/guides/HOW_TO_ADD_SCENES.md`
- `docs/guides/HOW_TO_ADD_BACKGROUNDS.md`
- `docs/guides/HOW_TO_ADD_PORTRAITS.md`
- `docs/guides/HOW_TO_ADD_SOUNDS.md`
- `docs/guides/GRAPHICS_GUIDE.md`
- `docs/guides/F1_HOTSPOT_EDITOR.md`
- `docs/guides/DESIGN_PORT_RULES.md`
- `docs/reference/ROADMAP.md`
- `docs/reference/TODO.md`

## Что теперь считается архивом

- `docs/archive/legacy-ui/AVOS_V2_PROGRESS.md`
- `docs/archive/legacy-ui/GUI_MIGRATION_PLAN.md`
- `docs/archive/legacy-ui/GUI_AUDIT.md`
- `docs/archive/legacy-ui/GUI_CREATION_GUIDE.md`
- `docs/archive/legacy-ui/GUI_VALIDATION_REPORT.md`
- `docs/archive/legacy-ui/INTEGRATION_REPORT.md`
- `docs/archive/legacy-ui/MIGRATION_STATUS.md`
- `docs/archive/legacy-ui/MIGRATION_COMPLETE.md`
- `docs/archive/legacy-ui/NODE_MAP.md`

## Что было исправлено в этой ревизии

- `README.md` обновлён под активный bootstrap `main_v2.collectionc`
- добавлен `docs/reference/ARCHITECTURE.md` как короткий source of truth по runtime
- `docs/reference/CODEX_CONTEXT.md` и `docs/reference/CONTINUE_HERE.md` синхронизированы с текущим состоянием `AVOS_S`
- `main/story/README_INK.md` обновлён под текущий loader и реальные Ink-теги
- инструкции по сценам, портретам, звукам, графике и F1-редактору приведены к `v2`-архитектуре
- roadmap и TODO отделены от завершённой migration-хронологии
- migration-документы помечены как архивные, чтобы не путать с боевой документацией

## Что ещё остаётся непокрытым

- нет отдельного `BUILD_GUIDE.md` с пошаговой сборкой под Яндекс.Игры
- нет отдельного `TESTING_GUIDE.md` с release-чеклистом

## Рекомендация на будущее

Если появляется новый runtime-модуль или новый контент-пайплайн, обновлять нужно как минимум:

1. `README.md`
2. `docs/reference/ARCHITECTURE.md`
3. профильный how-to / README рядом с модулем
4. `docs/reference/TODO.md`, если остался незакрытый хвост
