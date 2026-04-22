# Инструкция По Добавлению Новых Фонов

Текущий проект использует новую схему:

- `1 fullscreen background = 1 atlas`
- `Ink` и `scenes.lua` продолжают работать через имя `bg_name`
- `ui_manager_v2` сам переключает atlas у `dialogue_v2` перед `gui.play_flipbook()`
- внутри dedicated atlas-ов fullscreen background нормализуется к общему animation id `scene_bg`
- `main/images/backgrounds.atlas` больше **не используется** v2-стеком — он остался
  только для legacy v1 GUI (`main/gui/components/`). Ничего нового туда не кладём.

Мелкие ассеты у v2 живут в собственных атласах:

- `main/images/hotspots.atlas` — `hotspot_circle`, `hotspot_ring`, `hotspot_dot`
- `main/images/scene_objects.atlas` — `mobile` и будущие spot-спрайты

## Где Теперь Лежит Фон

Для каждого полноэкранного фона есть две сущности:

1. исходное изображение в `main/images/`
2. отдельный atlas-файл в `main/images/backgrounds/`

Пример:

```text
main/images/bg_city_map.jpg
main/images/backgrounds/bg_city_map.atlas
```

## Требования К Fullscreen Background

- формат: `JPG` или `PNG`
- рекомендуемое разрешение: `1920x1080`
- имя файла: `bg_name.jpg`
- atlas-файл: `main/images/backgrounds/bg_name.atlas`
- внешнее имя фона остаётся `bg_name`, но внутри dedicated atlas используется общий animation id `scene_bg`

## Шаг 1: Положить Изображение В Проект

Пример:

```text
main/images/bg_city_map.jpg
```

## Шаг 2: Создать Отдельный Atlas

Создайте файл:

```text
main/images/backgrounds/bg_city_map.atlas
```

Содержимое:

```text
images {
  image: "/main/images/bg_city_map.jpg"
}
rename_patterns: "bg_city_map=scene_bg"
extrude_borders: 2
```

Важно:

- один atlas содержит ровно один fullscreen background
- в dedicated atlas обязательно нужен `rename_patterns: "bg_name=scene_bg"`, чтобы все runtime atlas-ы отдавали один и тот же animation id
- не добавляйте новый fullscreen background в `main/images/backgrounds.atlas`

## Шаг 3: Зарегистрировать Atlas В `ui_manager_v2.script`

В `main/gui/ui_manager_v2.script` нужно добавить:

1. `go.property(...)` для нового atlas
2. запись в таблицу `DEDICATED_BG_ATLAS_PROPS`

Пример:

```lua
go.property("bg_city_map_atlas", resource.atlas("/main/images/backgrounds/bg_city_map.atlas"))
```

И в таблицу:

```lua
bg_city_map = "bg_city_map_atlas",
```

Без этого ресурс не будет гарантированно включён в bundle и runtime-switch не увидит новый фон.

## Шаг 4: Использовать Фон В Сценарии

### В Ink

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

## Правило Именования

Одинаковое логическое имя должно пройти через внешнюю цепочку:

- файл картинки: `bg_city_map.jpg`
- atlas: `bg_city_map.atlas`
- runtime key в Ink/scenes: `bg_city_map`
- Ink tag: `# bg:bg_city_map`
- `scenes.lua`: `bg = "bg_city_map"`

Внутри dedicated atlas при этом должен существовать общий animation id `scene_bg`.

Если `bg_name` снаружи не совпадёт с регистрацией в `ui_manager_v2`, или в atlas не будет `scene_bg`, фон не переключится.

## Если Нужен Не Fullscreen Background, А Scene Object

Мелкие overlay-спрайты живут в `main/images/scene_objects.atlas`.

Чтобы добавить новый scene object:

1. Положи `.png` в `main/images/`
2. Допиши `images { image: "/main/images/<name>.png" }` в `main/images/scene_objects.atlas`
3. В `scenes.lua` укажи `image = "<name>"` в `objects = { ... }`

`hotspots_v2.gui` уже подключает этот atlas как texture slot
`scene_objects` — отдельная регистрация в `ui_manager_v2.script` не нужна.

```lua
image = "mobile"
```

Такие ресурсы:

- не называем `bg_*`
- не оформляем как отдельный fullscreen atlas
- не кладём в `main/images/backgrounds.atlas` (он остался только для legacy v1 GUI)

## Чеклист

- [ ] Картинка лежит в `main/images/`
- [ ] Для неё создан отдельный atlas в `main/images/backgrounds/`
- [ ] В `ui_manager_v2.script` добавлен `go.property(...)`
- [ ] В `DEDICATED_BG_ATLAS_PROPS` добавлена запись для `bg_name`
- [ ] Имя `bg_name` совпадает в atlas, Ink и `scenes.lua`
- [ ] Фон проверен в игре

## Связанный Документ

- `docs/reference/BACKGROUND_SYSTEM_MIGRATION_PLAN.md`
