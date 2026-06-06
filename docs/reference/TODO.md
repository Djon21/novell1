# TODO — Живой Backlog `AVOS_S`

Актуально на `2026-06-06`.

Здесь только незакрытые задачи. История уже выполненных пунктов живёт в git
history и commit messages.

## P1 — Проверить После Ручных Правок

- [ ] Прогнать полный smoke по новой редакции Ink: старт, квартира, метро,
  офис, крыша, ложные концовки, истинная концовка.
- [ ] Проверить `Continue` после крупных правок `chapter_01.json`: сохранение
  в диалоге, в exploration, после телефона, после карты, после инвентаря.
- [ ] Проверить phone-apps на мобильных aspect ratio: SMS, messenger, quests,
  notes, mail, calls, clues, terminal, map entry.

## P2 — Runtime И UX

- [ ] Довести achievements до полноценного экрана или оставить скрытыми до
  релизного этапа.

## P2 — Story / Loop

- [ ] Добавить больше loop-aware реплик в телефонный контент, если новая
  редакция сюжета стабилизировалась.

## P2 — Архитектура / Рефакторинг

- [ ] **Дожать ink-tag registry.** База уже есть: `M.register_tag(key, handler)`
  реализован в `dialogue_manager_ink.lua`, но основной массив тегов всё ещё
  живёт в большом `if/elseif` внутри `apply_tags`. Следующий шаг — вынести
  новые и редкие теги в registry, оставив core-теги inline только там, где это
  реально упрощает runtime.
- [ ] **Save migration refactor.** Заменить version ladder в
  `save_manager.lua:migrate_save()` на гибрид: `ipairs`-defaults для примитивов
  + version ladder только для сложных миграций (ink_state). Описание —
  `docs/design/SaveMigration.md`.

## P3 — Cleanup

- [ ] Проверить build-дубликаты документации в `build/default*` перед
  релизной упаковкой.

## Platform / Release

- [ ] Проверить интеграцию Яндекс SDK в реальной сборке.
- [ ] Пройти `docs/reference/TESTING_CHECKLIST.md` перед публикацией.

## Tooling

- [ ] **Ink linter: расширить проверки.** Базовые проверки уже работают в
  `tools/ink_lint.py`, есть CI workflow и `pre-commit` hook. Следующие шаги:
  BOM-чек, дубликаты knot-имён, проверка root-`chapter_01.ink`, сверка
  `goto_scene/explore` со списком реальных сцен, сверка item-id с
  `items_catalog.lua`.
- [ ] **CI workflow: добавить реальную сборку runtime.** `Ink Lint` уже есть в
  `.github/workflows/ink_lint.yml`. Добавить job с `bob.jar` (`resolve build`),
  а при желании ещё и отдельную проверку Lua syntax / smoke-проход тулинга.
- [ ] **Build automation: закрепить рабочий bob flow.** `scripts/build.ps1`
  уже починен под PowerShell 5.1 и текущий `bob.jar`, но стоит:
  задокументировать его как основной Windows build entrypoint, при желании
  добавить параметры `-Platform` / `-Variant`, и зеркально проверить shell-flow
  для `tools/compile_ink.sh` / будущего CI.
