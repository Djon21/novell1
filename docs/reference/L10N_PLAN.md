# L10N Plan

Актуально на `2026-04-29`.

Локализация пока не реализована в runtime. Этот документ фиксирует будущий план.

## Приоритеты

1. UI-строки меню, HUD, телефона, карты, инвентаря.
2. Системные подписи и сообщения ошибок.
3. Ink-сценарий.

## Что Локализовать Первым

- главное меню
- кнопки `Continue`, `Start`, `Reset iteration`
- названия phone apps
- подписи inventory verbs
- статусы карты
- static text в `phone_*.gui`

## Ink

Активный нарратив сейчас лежит в:

- `main/story/chapter_01.ink`
- `main/story/chapters/00_bootstrap.ink`
- `main/story/chapters/01_apartment.ink`
- `main/story/chapters/02_metro.ink`
- `main/story/chapters/03_office.ink`
- `main/story/chapters/04_rooftop.ink`
- `main/story/chapters/90_phone_apps.ink`
- `main/story/chapters/91_inventory_actions.ink`

`chapters/New/` больше не является отдельной рабочей веткой.

## Рекомендуемый Подход

Для UI можно начать с `main/scripts/l10n.lua` и таблицы строк:

```lua
local M = {}

M.ru = {
    menu_start = "НАЧАТЬ ИТЕРАЦИЮ",
    menu_continue = "ПРОДОЛЖИТЬ",
    menu_reset = "СБРОСИТЬ ИТЕРАЦИЮ",
}

M.en = {
    menu_start = "START ITERATION",
    menu_continue = "CONTINUE",
    menu_reset = "RESET ITERATION",
}

return M
```

Для Ink лучше не смешивать языки в одном `.ink`. Когда дойдём до перевода сценария, безопаснее собрать отдельный translated root и отдельный compiled JSON.

## Caveats

- `defold-ink` replay чувствителен к структуре compiled JSON.
- Перевод Ink лучше делать после стабилизации новой редакции сюжета.
- Для турецкого и других языков с расширенной латиницей нужно проверить шрифт.
