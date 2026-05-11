# TODO — Живой Backlog `AVOS_S`

Актуально на `2026-05-11`.

Здесь только незакрытые задачи. История уже выполненных пунктов живёт в git
history и commit messages.

## P1 — Проверить После Ручных Правок

- [ ] Прогнать полный smoke по новой редакции Ink: старт, квартира, метро,
  офис, крыша, ложные концовки, истинная концовка.
- [ ] Проверить `Continue` после крупных правок `chapter_01.json`: сохранение
  в диалоге, в exploration, после телефона, после карты, после инвентаря.
- [ ] Проверить phone-apps на мобильных aspect ratio: SMS, messenger, quests,
  notes, mail, calls, clues, camera, terminal, map entry.

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
- [ ] **Save versioning.** Сейчас старые сейвы могут крашнуть после изменения
  схемы. Добавить `save_version` поле и цепочку migrate-функций.
- [ ] **Pluggable ink-tag handlers.** `apply_tags` в dialogue_manager_ink —
  большой if/elseif. Разбить через `M.register_tag(key, handler)` API.

## P3 — Cleanup

- [ ] Проверить build-дубликаты документации в `build/default*` перед
  релизной упаковкой.
- [ ] Завершить L10N для UI-строк (RU/EN/TR через `l10n.t()`). Ink не трогаем.

## Platform / Release

- [ ] Проверить интеграцию Яндекс SDK в реальной сборке.
- [ ] Пройти `docs/reference/TESTING_CHECKLIST.md` перед публикацией.

## Tooling

- [ ] **Ink linter (pre-commit hook):** BOM-чек, undefined knot references,
  дубликаты knot-имён. У тебя ink будет 10K+ строк к финалу — без проверок ад.
- [ ] **CI workflow:** GitHub Actions с компиляцией ink через inklecate +
  lua-syntax check. Сейчас `.github/` отсутствует.
