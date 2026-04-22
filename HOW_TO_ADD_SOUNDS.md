# Инструкция по добавлению новых звуков

## Что важно знать заранее

Текущий `v2` runtime уже содержит:

- `music_player` в `main/main_v2.collection`
- `sfx_player` в `main/main_v2.collection`
- парсинг Ink-тегов `# sfx:name` в `dialogue_manager_ink.lua`

Но при этом активный `ui_manager_v2.script` пока не забирает `dm.get_effects()`. Поэтому одноразовые SFX уже являются частью формата, но их playback bridge для `v2` ещё не доведён до конца.

## Формат файлов

- рекомендуется `OGG`
- `WAV` допустим как исходник, но в runtime лучше держать `OGG`
- `MP3` не использовать как основной runtime-формат

## Шаг 1: Добавить исходный файл

Пример:

```text
main/sounds/door_open.ogg
```

## Шаг 2: Создать `.sound` descriptor

Пример `main/sounds/door_open.sound`:

```text
sound: "/main/sounds/door_open.ogg"
looping: 0
group: "sfx"
gain: 1.0
```

Для фоновой музыки:

```text
looping: 1
group: "music"
```

## Шаг 3: Зарегистрировать звук в `main/main_v2.collection`

Ищите embedded instance `sfx_player` и добавляйте новый component внутрь него:

```text
"components {\n"
"  id: \"door_open\"\n"
"  component: \"/main/sounds/door_open.sound\"\n"
"}\n"
```

Если это музыка, правится `music_player`, а не `sfx_player`.

## Шаг 4: Использовать звук в Ink

```ink
# sfx:door_open
```

## Важный caveat активного v2 UI

На данный момент:

- `dialogue_manager_ink.lua` кладёт `# sfx`, `# shake`, `# pulse` в очередь эффектов
- legacy `dialogue_system.gui_script` умел эту очередь читать
- активный `ui_manager_v2.script` пока этого не делает

Итог: после добавления звука в `sfx_player` тег уже будет валидным с точки зрения формата, но в текущем `v2` runtime он не заиграет, пока не будет реализован bridge к `dm.get_effects()`.

## Что реально уже зарегистрировано в `sfx_player`

- `terminal_wake`
- `coffee_brew`
- `phone_notify`
- `heartbeat`
- `paper_rustle`

Файл `click_001` лежит в `main/sounds/`, но в текущем `main_v2.collection` не зарегистрирован.

## Атрибуция

Если звук взят извне, обновите `main/sounds/CREDITS.md`.

## Чеклист

- [ ] `.ogg` лежит в `main/sounds/`
- [ ] создан `.sound`
- [ ] компонент добавлен в `sfx_player` или `music_player`
- [ ] тег `# sfx:name` использует правильный id
- [ ] обновлён `CREDITS.md`, если это внешний asset
- [ ] если звук должен реально звучать в `v2`, задача на bridge `dm.get_effects()` тоже учтена
