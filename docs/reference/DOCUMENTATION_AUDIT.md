# Documentation Audit

Актуально на `2026-04-29`.

## Что Считается Source Of Truth

- `README.md`
- `docs/README.md`
- `docs/reference/CODEX_CONTEXT.md`
- `docs/reference/ARCHITECTURE.md`
- `docs/guides/HOW_TO_WRITE_INK.md`
- `docs/reference/TODO.md`

## Что Было Обновлено

- входные документы сокращены и синхронизированы с текущим `v2` runtime
- `TODO.md` очищен от закрытых пунктов и снова содержит только живой backlog
- `ARCHITECTURE.md` обновлён под phone apps, `map_v2` hub-mode, удалённый `nav_buttons_v2` и false endings
- `HOW_TO_WRITE_INK.md` обновлён под актуальные Ink-теги: mail, call, clue, camera, term, map hub, loop endings
- `L10N_PLAN.md` больше не ссылается на `chapters/New/` как рабочую ветку
- `CONTINUE_HERE.md` отражает, что новый сюжет должен жить в активных `chapters/*.ink`

## Что Не Трогать Как Рабочую Инструкцию

- `docs/archive/legacy-ui/*`
- `archive/legacy_runtime/*`
- `.opencode/*.md`
- `build/default*/main/story/*.md`

Эти файлы могут быть полезны как история, но не должны спорить с active docs.

## Caveats

- В рабочем дереве есть много ручных изменений GUI, assets и Ink. Документация обновлена под это состояние, но сама игра должна быть проверена через Defold.
- `docs/reference/INVENTORY_SYSTEM.md` объединил архитектурный обзор и старый `docs/guides/INVENTORY_SYSTEM_guide.md` (удалён 2026-05).
- Если `chapter_01` будет окончательно утверждён как новый канон, можно убрать из docs последние пояснения про бывшую папку `New/`.
