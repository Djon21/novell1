# План Миграции Системы Фонов V2

Дата фиксации: `2026-04-22`
Статус: **ЗАВЕРШЕНО** (см. раздел «Прогресс»).

## Цель

Перевести полноэкранные фоны с общего `main/images/backgrounds.atlas` на схему:

- `1 fullscreen background = 1 atlas`
- имена фонов в Ink и `scenes.lua` не меняются
- мелкие exploration/UI-спрайты вынесены в собственные атласы

## Почему Меняли Систему

Старый `backgrounds.atlas` хранил сразу несколько задач:

- полноэкранные сцены `bg_*`
- exploration scene objects (`mobile` и т.д.)
- hotspot sprites (`hotspot_circle`, `hotspot_ring`, `hotspot_dot`)

Для полноэкранных `1920x1080` изображений это плохо масштабировалось:

- atlas быстро рос до больших power-of-two размеров
- память расходовалась хуже, чем у набора отдельных atlas-ов
- риск упереться в лимиты платформ и получить лишний пустой padding
- мелкие UI-ассеты были связаны с тяжёлым набором сцен

## Целевая Архитектура

### Runtime Flow

`Ink / scenes.lua -> ui_manager_v2 -> dialogue_v2`

`ui_manager_v2` перед показом фона:

1. По `bg_name` выбирает atlas-ресурс из `DEDICATED_BG_ATLAS_PROPS`.
2. Делает `go.set(dialogue_gui, "textures", atlas, { key = "backgrounds" })`.
3. Все dedicated atlas-ы используют общий internal animation id `scene_bg`.
4. После этого шлёт в `dialogue_v2` `set_background { name = bg_name, animation = "scene_bg" }`.

`dialogue_v2` не знает про пути к atlas-файлам и работает через animation id из сообщения.

### Контекст: go.set Только Из .script

`scene_controller.set_background()` вызывается из `hotspots_v2.gui_script`
(на клик хотспота) — это **gui_script** контекст, и `go.*` API оттуда
недоступно. Поэтому `post_dialogue_background` в `ui_manager_v2` НЕ
вызывает `go.set` напрямую — он шлёт `msg.post(self.self_url,
"apply_dialogue_bg", {...})`. Хендлер `apply_dialogue_bg` исполняется
уже в `.script` контексте и безопасно дёргает `go.set`.

Это критичная инвариант: любые изменения swap-логики атласа должны
сохранять разделение «callback из gui_script → msg.post → script
on_message → go.set».

### Структура Ресурсов

- исходные изображения остаются в `main/images/bg_*.jpg`
- для каждого fullscreen background создан atlas-файл в `main/images/backgrounds/`
- atlas содержит ровно одну картинку
- картинка внутри dedicated atlas переименована в общий runtime
  animation id `scene_bg` через `rename_patterns`

Пример:

```text
main/images/bg_city_map.jpg
main/images/backgrounds/bg_city_map.atlas
```

```text
images {
  image: "/main/images/bg_city_map.jpg"
}
rename_patterns: "bg_city_map=scene_bg"
extrude_borders: 2
```

### Hotspot Sprites И Scene Objects

Вынесены в самостоятельные lightweight atlas-ы, чтобы `dialogue_v2`
получал только тяжёлый фон и ничего больше:

- `main/images/hotspots.atlas` — `hotspot_circle`, `hotspot_ring`, `hotspot_dot`
- `main/images/scene_objects.atlas` — `mobile` и будущие spot-спрайты

В `hotspots_v2.gui` для них объявлены отдельные texture slot'ы
`hotspots` и `scene_objects` (см. файл).

### Archive-only backgrounds.atlas

`archive/legacy_runtime/main/images/backgrounds.atlas` оставлен в репозитории только как архивный
след legacy v1 GUI. Старая схема смены фонов
считается **отключённой** и больше не поддерживается как fallback или rollback.

Важно:

- v2-стек (`main/gui/components_v2/` + `ui_manager_v2.script`) больше
  **не ссылается** на `backgrounds.atlas`
- содержимое `backgrounds.atlas` может со временем расходиться с legacy GUI
- любые правки новой системы фонов делаются только через dedicated atlas-ы в
  `main/images/backgrounds/`

## Правила Новой Системы

1. `bg_name` в Ink, `scenes.lua` и регистрации в `ui_manager_v2` должен совпадать один в один.
2. Полноэкранные фоны больше не добавляются в `archive/legacy_runtime/main/images/backgrounds.atlas`.
3. V2 GUI (`components_v2/*.gui`) НЕ должен ссылаться прямо на `archive/legacy_runtime/main/images/backgrounds.atlas`.
   Использовать texture slot `backgrounds` допустимо, если он указывает на dedicated atlas
   и работает через общий animation id `scene_bg`.
4. Hotspot sprites — только из `hotspots.atlas`. Scene objects — только из `scene_objects.atlas`.
5. Новый fullscreen background считается заведённым только после двух действий:
   atlas-файл создан и зарегистрирован в `ui_manager_v2.script`
   (`go.property` + запись в `DEDICATED_BG_ATLAS_PROPS`).

## Прогресс

- [x] Зафиксирован план миграции и правила новой системы
- [x] Обновлён гайд по добавлению новых фонов
- [x] Добавлен runtime-switch atlas-ов в `ui_manager_v2.script`
- [x] Созданы отдельные atlas-файлы для текущих fullscreen background
- [x] Покрыт кейс `bg_phone`, который раньше не лежал в общем `backgrounds.atlas`
- [x] Dedicated atlas-ы приведены к общему animation id `scene_bg`
- [x] Починен краш `go.set` из gui_script callback (apply_dialogue_bg через msg.post)
- [x] Hotspot sprites вынесены в `main/images/hotspots.atlas`
- [x] Scene objects (`mobile`) вынесены в `main/images/scene_objects.atlas`
- [x] `hotspots_v2.gui` переключён на `hotspots/` и `scene_objects/` texture slots
- [x] Удалён legacy fallback из `ui_manager_v2.script` (`legacy_backgrounds_atlas` свойство)
- [x] V2 backgrounds.atlas очищен от fullscreen-фонов и v2-ассетов
- [x] Legacy background switching объявлен архивным и больше не рассматривается как supported fallback
- [ ] Добавлены custom texture profiles (опционально, отдельный этап)

## Что Сделано В Этой Итерации

- новая схема описана и сохранена в docs
- `ui_manager_v2` умеет переключать atlas для `dialogue_v2` перед показом фона
- все 13 fullscreen background оформлены как отдельные atlas-файлы
- внешние контракты `# bg:bg_name` и `bg = "bg_name"` оставлены без изменений
- внутренний runtime-контракт для dedicated atlas-ов нормализован на `scene_bg`
- из `hotspots_v2.gui` убрана зависимость от `backgrounds.atlas` —
  он теперь использует `hotspots.atlas` и `scene_objects.atlas`
- legacy fallback в `ui_manager_v2.script` удалён: незарегистрированный
  `bg_name` теперь логируется как WARNING вместо возврата к старой схеме
- баг с `go.set` из gui_script-контекста зафиксирован и исправлен через
  msg.post-маршрутизацию

## Опциональный Этап (Не Делалось)

- custom `.texture_profiles` для fullscreen background atlas-ов
- проверка HTML5 / mobile memory behavior

## Rollback

Rollback к старой схеме смены фонов **не поддерживается**.

Если в v2 что-то ломается:

1. проверяем регистрацию `bg_name` в `ui_manager_v2.script`
2. проверяем dedicated atlas в `main/images/backgrounds/`
3. проверяем `rename_patterns: "bg_name=scene_bg"`

Возвращать `legacy_backgrounds_atlas`, снова подключать v2 к
`archive/legacy_runtime/main/images/backgrounds.atlas` или переносить v2-ассеты обратно в legacy atlas
не нужно.

## Файлы, Затронутые Этой Миграцией

- `docs/reference/BACKGROUND_SYSTEM_MIGRATION_PLAN.md` (этот документ)
- `docs/guides/HOW_TO_ADD_BACKGROUNDS.md`
- `docs/guides/HOW_TO_ADD_SCENES.md`
- `docs/guides/GRAPHICS_GUIDE.md`
- `docs/reference/ARCHITECTURE.md`
- `docs/reference/CODEX_CONTEXT.md`
- `README.md`
- `docs/guides/HOW_TO_WRITE_INK.md`
- `.opencode/skills/avos/SKILL.md`
- `main/gui/ui_manager_v2.script`
- `main/gui/components_v2/dialogue_v2.gui`
- `main/gui/components_v2/hotspots_v2.gui`
- `main/scripts/scenes.lua` (только комментарий про scene objects)
- `archive/legacy_runtime/main/images/backgrounds.atlas` (archive-only legacy след, не часть v2 runtime)
- `main/images/backgrounds/*.atlas` (13 dedicated atlas-ов)
- `main/images/hotspots.atlas` (новый)
- `main/images/scene_objects.atlas` (новый)
