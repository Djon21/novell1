# Модули Ink

`main/story/chapters/` содержит активные include-файлы для `chapter_01.ink`.

## Активные Файлы

- `00_bootstrap.ink` — общие `VAR`, стартовый переход, bootstrap
- `10_apartment.ink` — воскресная квартира и выход к карте
- `02_sunday_date.ink` — воскресная встреча с NPC
- `20_monday_home.ink` / `21_monday_commute.ink` / `22_monday_office.ink` — понедельник
- `30_tuesday_home.ink` / `31_tuesday_investigation.ink` / `32_tuesday_rooftop.ink` — вторник
- `91_inventory_actions.ink` — действия предметов
- `92_phone_sms.ink` / `93_phone_messenger.ink` / `94_phone_mail.ink` — телефон
- `archive/` — старые версии (не подключены к `chapter_01.ink`)

## Правила

- Новые игровые главы добавляем сюда и подключаем через `INCLUDE` в `../chapter_01.ink`.
- Файлы из этой папки не компилируются отдельно.
- Runtime получает их только через `chapter_01.json`.
- `New/` больше не используется как отдельная ветка. Если нужен новый канон, переносим текст в активные файлы.
- Общие служебные knot'ы лучше держать в отдельных `90+` файлах, чтобы не смешивать их с локациями.

## После Изменений

```bash
tools\compile_ink.bat chapter_01
```

Потом проверить старт игры, `Continue` и те GUI-механики, чьи теги менялись.
