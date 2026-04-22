# Аудит документации

Актуально на `2026-04-22`.

Цель этой ревизии — разделить документацию на:

- рабочую, которая описывает текущий `v2` runtime
- архивную, которая сохраняет историю миграции и legacy UI

Папка `skills/` в этот аудит намеренно не входит.

## Что теперь считается рабочей документацией

- `README.md`
- `ARCHITECTURE.md`
- `CODEX_CONTEXT.md`
- `CONTINUE_HERE.md`
- `main/story/README.md`
- `main/story/INK_STYLE.md`
- `HOW_TO_ADD_SCENES.md`
- `HOW_TO_ADD_BACKGROUNDS.md`
- `HOW_TO_ADD_PORTRAITS.md`
- `HOW_TO_ADD_SOUNDS.md`
- `GRAPHICS_GUIDE.md`
- `F1_HOTSPOT_EDITOR.md`
- `DESIGN_PORT_RULES.md`
- `ROADMAP.md`
- `TODO.md`

## Что теперь считается архивом

- `AVOS_V2_PROGRESS.md`
- `GUI_MIGRATION_PLAN.md`
- `GUI_AUDIT.md`
- `GUI_CREATION_GUIDE.md`
- `GUI_VALIDATION_REPORT.md`
- `INTEGRATION_REPORT.md`
- `MIGRATION_STATUS.md`
- `MIGRATION_COMPLETE.md`
- `NODE_MAP.md`

## Что было исправлено в этой ревизии

- `README.md` обновлён под активный bootstrap `main_v2.collectionc`
- добавлен `ARCHITECTURE.md` как короткий source of truth по runtime
- `CODEX_CONTEXT.md` и `CONTINUE_HERE.md` синхронизированы с текущим состоянием `AVOS_S`
- `main/story/README.md` обновлён под текущий loader и реальные Ink-теги
- инструкции по сценам, портретам, звукам, графике и F1-редактору приведены к `v2`-архитектуре
- roadmap и TODO отделены от завершённой migration-хронологии
- migration-документы помечены как архивные, чтобы не путать с боевой документацией

## Что ещё остаётся непокрытым

- нет отдельного `BUILD_GUIDE.md` с пошаговой сборкой под Яндекс.Игры
- нет отдельного `TESTING_GUIDE.md` с release-чеклистом
- документация честно фиксирует, что `# sfx/#shake/#pulse` уже парсятся, но ещё не проигрываются в активном `v2`-UI

## Рекомендация на будущее

Если появляется новый runtime-модуль или новый контент-пайплайн, обновлять нужно как минимум:

1. `README.md`
2. `ARCHITECTURE.md`
3. профильный how-to / README рядом с модулем
4. `TODO.md`, если остался незакрытый хвост
