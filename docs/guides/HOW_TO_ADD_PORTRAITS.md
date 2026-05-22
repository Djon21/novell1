# Портреты персонажей

Статичные портреты (одна картинка, без анимации). Для **анимированных портретов** (моргание + рот) см. [`HOW_TO_ANIMATE_PORTRAITS.md`](HOW_TO_ANIMATE_PORTRAITS.md).

## Файловая структура

Каждый персонаж — отдельная папка и отдельный атлас:

```
main/images/portraits/
├── mila/
│   ├── mila.atlas
│   └── mila_base.png        (для анимированной Милы)
├── artem/
│   ├── artem.atlas
│   └── artem.png            (статичный)
└── narrator/
    ├── narrator.atlas
    └── narrator.png
```

Один портрет = один атлас = один texture-binding в `dialogue_v2.gui`. Никаких общих атласов, никакого `v2.atlas` (его больше нет).

## Шаги для нового статичного персонажа («аня»)

### 1. Положить PNG

```
main/images/portraits/anya/anya.png
```

Требования:
- формат PNG, прозрачный фон
- рекомендуемый размер `512×512` (квадрат)
- латиница, lowercase

### 2. Создать атлас `anya.atlas`

```
main/images/portraits/anya/anya.atlas
```

Содержимое:

```
images {
  image: "/main/images/portraits/anya/anya.png"
}
extrude_borders: 0
```

`extrude_borders: 0` нужен чтобы 512×512 атлас не разросся до 1024×1024 ради 2px бордюра. Для **статичных** нерастягивающихся спрайтов это OK.

**Важно**: если будешь потом превращать персонажа в анимированного (см. `HOW_TO_ANIMATE_PORTRAITS.md`), `extrude_borders` нужно вернуть на `2` — иначе при flipbook-анимации соседние кадры в текстуре будут протекать в края и появится видимая полоса.

### 3. Зарегистрировать texture в `dialogue_v2.gui`

Найди секцию `textures {}` и добавь:

```
textures {
  name: "anya"
  texture: "/main/images/portraits/anya/anya.atlas"
}
```

### 4. Добавить персонажа в `CHARS`

В `main/gui/components_v2/dialogue_v2.gui_script`:

```lua
["аня"] = {
    color = vmath.vector4(1.0, 0.702, 0.278, 1.0),
    icon = string.char(0xEE, 0x9F, 0xBB),
    atlas = "anya",
    portrait = "anya",
},
```

Поля:
- `color` — цвет акцента nameplate
- `icon` — fallback-иконка если спрайт не найден
- `atlas` — имя texture-binding из шага 3
- `portrait` — animation id или image id из атласа (для статика совпадает с именем PNG без расширения)

Можно дублировать запись с латинским ключом если в ink-сценариях используется `# speaker:Anya`:

```lua
anya = { ... тот же контент ... },
```

### 5. Использовать в Ink

```ink
# speaker:Аня
Привет.
```

Lookup в `CHARS` приводит speaker к lower-case, так что `Аня` / `аня` / `АНЯ` найдут одну запись.

## Спецзначения speaker

- `# speaker:mc` — имя главного героя из `save_manager` (Артём/Мила)
- `# speaker:npc` — имя второго ключевого персонажа
- `# speaker:none` — нарратив без портрета
- `# speaker:narrator` — терминал-нарратор (зелёный текст)

## Текстурный профиль

Любой PNG под `main/images/portraits/**` автоматически попадает в профиль **UI** (см. `main/textures.texture_profiles`). Профиль определяет BASIS-сжатие для HTML5-сборки.

## Чеклист добавления персонажа

- [ ] PNG в `main/images/portraits/<name>/<name>.png`
- [ ] `<name>.atlas` создан, ссылается на PNG
- [ ] `textures {}` в `dialogue_v2.gui` содержит binding `<name>`
- [ ] Запись в `CHARS` в `dialogue_v2.gui_script` с `atlas` и `portrait`
- [ ] Реплика `# speaker:<Имя>` проверена в игре

## Что НЕ нужно делать

- НЕ редактируй `novel_ui.gui` — это legacy UI
- НЕ добавляй портреты в общий атлас — каждый персонаж в своей папке/атласе
- НЕ дублируй PNG в `main/images/` корне — там legacy-картинки от старой архитектуры, не используются
