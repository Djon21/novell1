# Инструкция по добавлению новых звуков

## Что важно знать заранее

Текущий `v2` runtime уже содержит:

- `music_player` в `main/main_v2.collection`
- `sfx_player` в `main/main_v2.collection`
- парсинг Ink-тегов `# sfx:name` в `dialogue_manager_ink.lua`
- playback bridge `dm.get_effects()` в `ui_manager_v2.script`

То есть одноразовые SFX уже реально проигрываются в `v2`, а `# shake` и `# pulse` работают как one-shot визуальные эффекты через `effects`.

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

## Шаг 3b: Добавить routing в `ui_manager_v2.script`

В `main/gui/ui_manager_v2.script` новый id нужно добавить в таблицу `M.SFX_URLS`:

```lua
M.SFX_URLS = {
    door_open = "/sfx_player#door_open",
}
```

Без этого `# sfx:door_open` будет валидным для Ink, но `ui_manager_v2` не найдёт URL и выведет warning вместо проигрывания.

## Шаг 4: Использовать звук в Ink

```ink
# sfx:door_open
```

## Как это работает в активном v2 UI

Сейчас active `v2` runtime уже забирает `dm.get_effects()` и делает следующее:

- `# sfx:name` -> проигрывает звук через `sfx_player`
- `# shake:intensity,duration` -> шлёт one-shot тряску в `effects`
- `# pulse:duration,r,g,b` -> шлёт цветовую вспышку в `effects`

Важно: для нового `# sfx:name` одного `sfx_player` недостаточно. Нужны оба шага:

- зарегистрировать `.sound` в `main/main_v2.collection`
- добавить id в `M.SFX_URLS` в `main/gui/ui_manager_v2.script`

## Что реально уже зарегистрировано в `sfx_player`

- `terminal_wake`
- `coffee_brew`
- `phone_notify`
- `heartbeat`
- `paper_rustle`

## Атрибуция

Если звук взят извне, обновите `main/sounds/CREDITS.md`.

## Чеклист

- [ ] `.ogg` лежит в `main/sounds/`
- [ ] создан `.sound`
- [ ] компонент добавлен в `sfx_player` или `music_player`
- [ ] новый id добавлен в `M.SFX_URLS` в `main/gui/ui_manager_v2.script`
- [ ] тег `# sfx:name` использует правильный id
- [ ] обновлён `CREDITS.md`, если это внешний asset
- [ ] звук проверен в игре через реальный Ink-тег
