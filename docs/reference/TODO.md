# TODO — Живой Backlog `AVOS_S`

Актуально на `2026-05-31`.

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

- [ ] Полировать карту после `map_v2` hub-mode: выбранный маршрут, fallback
  при закрытии, визуальное состояние активного pin.
- [ ] Довести achievements до полноценного экрана или оставить скрытыми до
  релизного этапа.

## P2 — Story / Loop

- [ ] Финально решить канон `chapter_01`: старый сюжет больше не нужен или
  нужен отдельный archive snapshot.
- [ ] Проверить баланс false endings: две уникальные ложные концовки должны
  открыть true ending, повтор той же ложной концовки не должен повторно
  повышать awareness.
- [ ] Добавить больше loop-aware реплик в телефонный контент, если новая
  редакция сюжета стабилизировалась.

## P2 — Архитектура / Рефакторинг

- [ ] **Phone quest cards → gui.clone_tree.** В `phone_quests.gui` карточка
  плоская (все 36 нод верхнего уровня с абсолютными координатами). Через
  Defold Editor сделать `quest1_*` детьми `quest1_bg` (drag-and-drop в
  Outline пересчитает позиции). Затем удалить `quest2_*` и `quest3_*`
  группы. После этого обновить `phone_quests.gui_script`: в init клонировать
  proto-карточку, wrapper для `questN_X` id-резолва.
- [ ] **Templating для остальных phone-apps.** `phone_quests.gui` (2704),
  `phone_mail.gui` (2658), `phone_call.gui` (2389) — повторы quest/mail/call
  rows аналогично проблеме messenger. По образцу phone_sms / phone_messenger
  выделить list + detail template'ы.
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
- [ ] Завершить L10N для UI-строк (RU/EN/TR через `l10n.t()`). Ink не трогаем.

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
