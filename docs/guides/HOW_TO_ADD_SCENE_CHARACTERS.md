# Сценические персонажи (scene characters)

Персонажи в полный рост на фоне сцены. Появляются по ink-тегу, могут быть кликабельными как хотспоты (с hover-эффектом). Стиль — классический VN (Persona, Doki Doki).

Это **отдельная система** от диалоговых портретов (см. `HOW_TO_ANIMATE_PORTRAITS.md` для бюстов в окне диалога).

---

## Архитектура

### GUI

В `main/gui/components_v2/dialogue_v2.gui` живут два слота:
- `scene_character_1`
- `scene_character_2`

Оба сидят между `scene_bg` (z=0.04) и `dlg_root` (z=0.10) — над фоном, под диалоговой панелью. Pivot NW (top-left). Скрипт ресайзит/позиционирует их при show.

Можно показать **до 2 персонажей одновременно** в одной сцене. Если нужно больше — расширь `SCENE_CHAR_NODES` в `dialogue_v2.gui_script` и добавь ноды в .gui.

### Файловая структура

```
main/images/characters/
├── mila/
│   ├── mila.atlas        (все позы Милы)
│   ├── idle.png          (стоит нейтрально)
│   ├── sitting.png       (когда сделаешь)
│   └── walking.png
├── artem/
│   ├── artem.atlas
│   └── idle.png
```

**Ключевой принцип**: персонажи рисуются **один раз на однородном фоне** (любая поза), затем переиспользуются в разных сценах с разными size/position. Не путать с прошлым подходом «персонаж + сцена» — это плохо масштабируется.

### Texture bindings в `dialogue_v2.gui`

Каждый персонаж — отдельный texture binding:
```
textures {
  name: "char_mila"
  texture: "/main/images/characters/mila/mila.atlas"
}
```

Префикс `char_` чтобы не путать с диалоговыми атласами (`mila`, `artem`).

### Конфиг

`main/scripts/scene_characters.lua` хранит ДВЕ таблицы:

**SCENE_GROUPS** — объединяет sub-сцены одной локации:
```lua
SCENE_GROUPS = {
    park_hub             = "park",
    park_riverside_bench = "park",
    park_riverside_path  = "park",
}
```

Это нужно потому что одна локация может состоять из нескольких scene_id (entrance, bench, path). Mila следует за игроком по всем sub-сценам своей группы, прячется только при выходе из группы.

**SCENES** — для каждой группы маппинг ключ → sprite-info:
```lua
SCENES = {
    park = {
        mila_idle = {
            atlas  = "char_mila",
            sprite = "idle",
            x = 820, y = 340, w = 95, h = 340,
            action = { type = "ink_knot", knot = "park_npc_arrives" },
            clickable_when = function(gs)
                return not gs.get_flag("park_npc_greeted")
            end,
        },
    },
}
```

Поля:
- `atlas` — texture binding из dialogue_v2.gui
- `sprite` — image id внутри атласа
- `x, y, w, h` — top-left позиция и размер в game coords (1280×720)
- `action` (опционально) — что делать при клике. Сейчас поддержано `{ type = "ink_knot", knot = "<knot_name>" }`. Без action персонаж декоративный.
- `clickable_when(gs)` (опционально) — функция возвращающая bool. Если false, action заблокирован (но персонаж видим).

### Логика slot-аллокатора

При `scene_characters.show(group, key)`:
1. Находит конфиг `SCENES[group][key]`
2. Проверяет: не показан ли уже (идемпотентно)
3. Берёт свободный slot (1 или 2)
4. Запоминает кто в каком slot'е
5. Отправляет `set_scene_character` в dialogue_v2

При `scene_characters.hide(group, key)`:
1. Находит занятый slot
2. Освобождает + шлёт `clear_scene_character`

При `on_scene_changed(new_scene_id)`:
- Если новая группа отличается от текущей → `hide_all()`
- Внутри одной группы (park_hub → park_riverside_bench) ничего не делает

### Hover / click

В `dialogue_v2.gui_script` функция `scene_char_pick(action)`:
- Идёт по всем slot'ам
- Для каждого проверяет: enabled + есть action + точка курсора попадает в нод
- Возвращает slot или nil

В `on_input`:
- Если `action_id == nil` (mouse moved) и `not pressed/released` → hover: scale до 1.04 на hovered slot, scale обратно для остальных. Анимация `OUTQUAD` 80ms.
- Если `action_id == hash("touch") and pressed` → шлёт `scene_character_clicked` в ui_manager

В `ui_manager_v2.script` обработчик `scene_character_clicked`:
1. Спрашивает у scene_characters action для slot'а
2. Если action.type == "ink_knot": exits scene_controller, запускает run_side_dialogue_knot

**Важно**: вся scene_character логика в `dialogue_v2.gui_script.on_input` гейтится `not self.visible` — клик/hover работает только в exploration-режиме. Во время диалога персонажи декоративные.

---

## Ink-теги

```
# scene_char:show:<group>:<key>     показать персонажа
# scene_char:hide:<group>:<key>     спрятать конкретного
# scene_char:hide_all               спрятать всех в текущей сцене
```

Примеры:
```ink
# scene_char:show:park:mila_idle
# scene_char:show:cafe:mila_sitting
# scene_char:hide:park:mila_idle
# scene_char:hide_all
```

Auto-hide при выходе из группы работает без явных тегов — Mila сама исчезнет при travel'е из парка в апартаменты.

---

## Pipeline: добавление новой позы

### 1. Сгенерить спрайт на однородном фоне

Используй нейронку (Nano Banana / LivePortrait / etc) — попроси нарисовать персонажа в нужной позе на **однородном magenta-фоне** `#FF00FF`. Поза в полный рост, центрирован, никаких декораций сцены.

Опционально — стиль должен совпадать с существующими позами того же персонажа (та же цветовая палитра, та же визуальная стилистика).

Положи в, например, `tools/port_p/raw_<char>_<pose>/`.

### 2. Удалить фон

```bash
python tools/remove_background.py tools/port_p/raw_<char>_<pose>/
```

По умолчанию использует `rembg + birefnet-general` (если установлен). Для сложных случаев попробуй `--model birefnet-portrait` или дополнительные параметры.

См. `HOW_TO_ANIMATE_PORTRAITS.md` для деталей про rembg.

### 3. Crop до bbox + ресайз под game scale (опционально)

Если спрайт сильно больше чем нужно в игре — обрежь и уменьши:

```bash
python tools/character_for_scene.py tools/port_p/raw_<char>_<pose>/sprite_nobg.png <pose> \
    --out-dir main/images/characters/<char>
```

Создаст:
- `main/images/characters/<char>/<pose>.png` — спрайт в game scale
- `main/images/characters/<char>/<pose>.scene.json` — `{x, y, w, h}` для конфига

**На практике** этот инструмент рассчитан на «персонаж был в сцене 1672×941 → персонаж для 1280×720». Если у тебя голый спрайт на чистом фоне — можешь просто ресайзнуть в Photopea / любом редакторе и положить вручную.

### 4. Зарегистрировать в атласе

В `main/images/characters/<char>/<char>.atlas`:
```
images {
  image: "/main/images/characters/<char>/<pose>.png"
}
```

### 5. Добавить конфиг

В `main/scripts/scene_characters.lua` → SCENES[group]:
```lua
<char>_<pose> = {
    atlas  = "char_<char>",
    sprite = "<pose>",
    x = ..., y = ..., w = ..., h = ...,
    action = { type = "ink_knot", knot = "..." },  -- опционально
    clickable_when = function(gs) ... end,         -- опционально
},
```

### 6. Использовать в ink

```ink
# scene_char:show:<group>:<char>_<pose>
```

### 7. Build + проверить

Ctrl+B в Defold → запустить → дойти до сцены → проверить визуально. Подкрутить x/y/w/h при необходимости.

---

## Pipeline: добавление нового персонажа

1. Создать `main/images/characters/<name>/`
2. Создать `<name>.atlas`
3. В `dialogue_v2.gui` добавить texture binding:
   ```
   textures {
     name: "char_<name>"
     texture: "/main/images/characters/<name>/<name>.atlas"
   }
   ```
4. Положить позы (см. выше)
5. Добавить entries в SCENES (или новые группы в SCENE_GROUPS если локация ещё не была)
6. Использовать в ink

---

## Размер и позиция

Координаты в SCENES — **top-left в game coords 1280×720**.

Эмпирическое правило:
- Персонаж стоит на земле → высота **40-55% game-высоты** (h=290-400)
- На переднем плане → 50-60% (h=360-430)
- Дальний план → 30-40% (h=215-290)
- Ширина определяется аспектом спрайта (обычно h × 0.3-0.4)

Позиция:
- Центр-левый: x≈300, центр: x≈580, центр-правый: x≈800
- y отсчитывается от верха, ноги обычно на уровне 670-700 (если в кадре), значит `y = 700 - h`

Откорректируешь визуально в редакторе — открыл, посмотрел, поправил x/y/w/h в конфиге.

---

## Auto-hide

При смене scene_id ui_manager_v2 вызывает `scene_characters.on_scene_changed(new_scene_id)`:
- Сравнивает группу нового scene_id с текущей
- Если группа изменилась И раньше была другая (не nil) → `hide_all()`
- Иначе ничего не делает

Логика обеспечивает что:
- При входе в группу (nil → park) сразу после show ничего не стирается
- При перемещении в той же группе (park_hub → park_riverside_bench) персонажи остаются
- При выходе из группы (park → apartment) персонажи прячутся

---

## Подводные камни

| Симптом | Причина | Решение |
|---|---|---|
| Персонаж не появляется | Не зарегистрирован в SCENES или texture binding отсутствует | Проверь оба места + правильность `atlas`/`sprite` значений |
| `[INFO] scene_char unknown: park mila_idle` в логе | Ключ в SCENES не совпадает с тем что в ink-теге | Сверь ключ |
| Hover не работает на десктопе | Нет `MOUSE_MOVE` binding в game.input_binding | Добавить триггер; либо использовать всегда-on pulse для индикации интерактивности |
| Mila «великан» / «малыш» | w/h в game-coords, но спрайт высокого разрешения растягивается | Подкрутить w/h в SCENES, или использовать `character_for_scene.py --game-width` |
| Клик не срабатывает | Нет `action` в конфиге, или `clickable_when` возвращает false | Проверь оба |
| Mila исчезает в начале сцены | `on_scene_changed` hide_all при первом входе (старый баг) | Должно быть исправлено — `_current_group` нач. nil, hide только при смене с не-nil |

---

## Чеклист добавления интерактивного персонажа

- [ ] Спрайт `<pose>.png` лежит в `main/images/characters/<char>/`
- [ ] `<char>.atlas` ссылается на спрайт
- [ ] Texture binding `char_<char>` в `dialogue_v2.gui`
- [ ] Entry в SCENES с `atlas`, `sprite`, `x`, `y`, `w`, `h`
- [ ] Если кликабельный — `action` + опционально `clickable_when`
- [ ] Если новая локация — `SCENE_GROUPS` mapping
- [ ] Ink-теги `scene_char:show/hide` расставлены в нужных knot'ах
- [ ] В соответствующей `locations.lua` сцене группы добавлен путь через scene_controller (опционально hide hotspot который теперь дублирует Mila как точку входа в knot)

---

## Файлы

| Файл | Назначение |
|---|---|
| `main/scripts/scene_characters.lua` | Config + slot allocator + show/hide/hide_all API |
| `main/gui/components_v2/dialogue_v2.gui` | Ноды `scene_character_1/2` + texture bindings |
| `main/gui/components_v2/dialogue_v2.gui_script` | Render `set_scene_character` / `clear_scene_character`, hover + click handlers |
| `main/gui/ui_manager_v2.script` | Bridge: scene_characters.set_ui + handle `scene_character_clicked` + scene-change subscription |
| `main/scripts/dialogue_manager_ink.lua` | Парсинг ink-тегов `scene_char:...` |
| `main/gui/modules/ui_manager_v2/dm_commands.lua` | Команды `scene_char_show / hide / hide_all` |
| `tools/character_for_scene.py` | Helper для масштабирования спрайтов под game resolution |
