# CONTINUE_HERE

Актуально на `2026-04-29`.

## Читать В Таком Порядке

1. `docs/reference/CODEX_CONTEXT.md`
2. `docs/reference/ARCHITECTURE.md`
3. `main/story/README_INK.md`
4. `docs/reference/TODO.md`
5. `docs/reference/TESTING_CHECKLIST.md`

## Текущее Состояние

- активный bootstrap: `main/main_v2.collectionc`
- активный UI: `main/gui/components_v2/`
- активный story runtime: `main/story/chapter_01.json`
- активные Ink sources: `main/story/chapter_01.ink` + `main/story/chapters/*.ink`
- `main/story/chapters/New/` больше не используется как отдельная ветка
- телефон overlay-only, через `phone_v2`
- карта объединена с `city_map_hub` через `map_v2` hub-mode
- `nav_buttons_v2` убран; навигация через hotspots / map
- legacy runtime только в `archive/legacy_runtime/`

## Свежие Закрытые Хвосты

- phone apps получили storage/API для mail, calls, clues, camera, terminal
- `phone_stub_soon` удалён из active Ink
- `city_map_hub` больше не отдельный choice-узел маршрута, а открывает `map_v2`
- debug-log spam сокращён через `DEBUG_LOG = false`
- `click_001` вычищен как неиспользуемый asset
- loop-aware финалы расширены: ложные концовки запоминаются в `meta_state`
- release testing checklist и L10N plan заведены

## Самые Вероятные Следующие Работы

- проверить Яндекс SDK в реальной сборке
- прогнать `docs/reference/TESTING_CHECKLIST.md`
- полировать новые GUI телефона и карту после ручных правок
- довести локализацию до первого рабочего слоя
- решить, когда `chapter_01` будет окончательно считаться новым каноном

## Архив

Эти документы читаем только как историю, не как рабочие инструкции:

- `docs/archive/legacy-ui/*`
- `archive/legacy_runtime/README.md`
- `.opencode/*.md`
