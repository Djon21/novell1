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
- телефон больше не существует как отдельная scene `phone_home`: активный runtime работает через `phone_v2`, а старые `goto_scene:phone_home` живут только как compatibility alias в `ui_manager_v2`
- legacy UI оставлен в проекте только как archive / reference

## Самые вероятные направления следующей работы

- довести `city_map_hub` / карту мира до одной боевой схемы: `map_v2` уже живой, но Ink-узел маршрута всё ещё существует параллельно
- довести до конца `exits`-навигацию и карту мира
- полировать achievements / phone apps
- провести нормальный release QA под Яндекс.Игры

Из свежих закрытых хвостов:

- `game_state` для телефона теперь сам нормализует старые сейвы: SMS и заметки получают fallback `time/seq`, если их не было в старом save
- `get_sms()` и `get_notes()` больше не возвращают живые внутренние таблицы по ссылке
- список SMS-контактов сортируется по свежести последнего сообщения, а не по алфавиту
- legacy-derived предметы (`has_mug -> mug`, `has_phone -> phone`) теперь синхронизируются в обе стороны, а не только добавляются в инвентарь
- инвентарь больше не показывает `combine/give` как фальшивые disabled-действия: в UI оставлены только реальные MVP verbs `use/inspect/read`
- achievements больше не торчат в активном меню как битая кнопка: пункт скрыт до отдельной реализации экрана достижений
- живые `#017`-хардкоды убраны из runtime UI: текущая петля в диалоге, инвентаре и dossier-плашках карты теперь берётся из `meta_state`, а старые `#015/#016` остаются только как намеренные narrative-ссылки

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
