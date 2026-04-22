# Инструкция по добавлению новых фонов

Текущий проект использует `main/images/backgrounds.atlas` как общий атлас для:

- полноэкранных фонов
- scene objects для exploration
- некоторых UI-спрайтов, связанных с hotspot'ами

## Требования к фону

- формат: `JPG`
- рекомендуемое разрешение: `1920x1080`
- имя файла: `bg_name.jpg`
- хранение: `main/images/`

## Шаг 1: Положить файл в проект

Пример:

```text
main/images/bg_city_map.jpg
```

## Шаг 2: Добавить в `main/images/backgrounds.atlas`

```text
images {
  image: "/main/images/bg_city_map.jpg"
}
```

## Шаг 3: Использовать фон

### В Ink-диалоге

```ink
# bg:bg_city_map
```

### В exploration-сцене

```lua
city_map = {
    bg = "bg_city_map",
    hotspots = { ... },
}
```

## Важно про имена

- в atlas пишется путь `/main/images/bg_city_map.jpg`
- в Ink и `scenes.lua` используется имя `bg_city_map`

## Если нужен не фон, а scene object

Для небольших спрайтов поверх фона используйте тот же `backgrounds.atlas`, но без префикса `bg_`, если это отдельный object asset:

```text
images {
  image: "/main/images/mobile.png"
}
```

Потом в `scenes.lua`:

```lua
image = "mobile"
```

## Чеклист

- [ ] файл лежит в `main/images/`
- [ ] запись добавлена в `backgrounds.atlas`
- [ ] имя без расширения совпадает с тем, что используется в Ink / `scenes.lua`
- [ ] фон проверен в игре
