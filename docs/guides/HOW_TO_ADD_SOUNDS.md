# Инструкция по добавлению новых звуков

## Шаг 1: Подготовка звукового файла

1. **Формат:** OGG Vorbis (.ogg) - рекомендуется
   - Альтернатива: WAV 16-бит моно/стерео
   - ⚠️ НЕ используйте MP3 (не поддерживается Defold)
   - ⚠️ НЕ используйте WAV 24-бит (не поддерживается Defold)

2. **Параметры для конвертации:**
   - Битрейт: 128 kbps (для SFX достаточно)
   - Частота: 44100 Hz
   - Каналы: Mono (для коротких SFX) или Stereo

3. **Длительность:**
   - Короткие SFX: 0.5-3 секунды
   - Фоновые звуки: 5-10 секунд (можно зациклить)

4. **Назовите файл:** `название_звука.ogg`

## Шаг 2: Добавление файла в проект

1. Поместите файл в папку: `main/sounds/`
2. Пример: `main/sounds/door_open.ogg`

## Шаг 3: Создание .sound дескриптора

1. Создайте файл: `main/sounds/название_звука.sound`
2. Содержимое файла:

```
sound: "/main/sounds/название_звука.ogg"
looping: 0
group: "sfx"
gain: 1.0
```

**Параметры:**
- `looping: 0` - не зацикливать (для SFX)
- `looping: 1` - зацикливать (для фоновой музыки)
- `group: "sfx"` - группа звуковых эффектов
- `group: "music"` - группа музыки
- `gain: 1.0` - громкость (0.0 - 1.0)

**Пример для door_open.sound:**
```
sound: "/main/sounds/door_open.ogg"
looping: 0
group: "sfx"
gain: 1.0
```

## Шаг 4: Регистрация в main.collection

1. Откройте файл: `main/main.collection`
2. Найдите секцию `embedded_instances` с `id: "sfx_player"`
3. Добавьте новый компонент **перед** закрывающей строкой `position {`:

```
  "components {\n"
  "  id: \"название_звука\"\n"
  "  component: \"/main/sounds/название_звука.sound\"\n"
  "}\n"
```

**Пример:**
```
  "components {\n"
  "  id: \"door_open\"\n"
  "  component: \"/main/sounds/door_open.sound\"\n"
  "}\n"
```

## Шаг 5: Регистрация в novel_ui.gui_script

1. Откройте файл: `main/gui/novel_ui.gui_script`
2. Найдите строку `S.SFX_URLS = {`
3. Добавьте новую запись:

```lua
S.SFX_URLS = {
	terminal_wake = msg.url("main:/sfx_player#terminal_wake"),
	coffee_brew = msg.url("main:/sfx_player#coffee_brew"),
	название_звука = msg.url("main:/sfx_player#название_звука"),
}
```

**Пример:**
```lua
	door_open = msg.url("main:/sfx_player#door_open"),
```

## Шаг 6: Использование в игре

В файле `chapter_01.ink` используйте тег:
```
# sfx:название_звука
```

**Пример:**
```
=== enter_room
# speaker:none
Дверь открывается со скрипом.
# sfx:door_open
-> DONE
```

## Список существующих звуков

- `terminal_wake` - звук включения терминала
- `coffee_brew` - звук варки кофе
- `phone_notify` - вибрация/уведомление телефона
- `heartbeat` - учащенное сердцебиение
- `paper_rustle` - шуршание газеты
- `click_001` - звук клика (дополнительный)

## Конвертация звуков

**Онлайн-конвертеры:**
- CloudConvert: https://cloudconvert.com/wav-to-ogg
- Online-Convert: https://audio.online-convert.com/convert-to-ogg
- FreeConvert: https://www.freeconvert.com/wav-to-ogg

**Командная строка (ffmpeg):**
```bash
ffmpeg -i input.wav -acodec libvorbis -q:a 4 output.ogg
```

## Атрибуция звуков

Если звук взят из freesound.org или другого источника, добавьте информацию в:
`main/sounds/CREDITS.md`

**Формат:**
```markdown
### название_звука.ogg
- **Title:** Название звука
- **Author:** Автор
- **Source:** https://freesound.org/s/12345/
- **License:** Creative Commons 0 (CC0)
```

## Важно!

- ⚠️ Defold НЕ поддерживает MP3
- ⚠️ Defold НЕ поддерживает WAV 24-бит (только 8/16-бит)
- ✅ Используйте OGG для максимальной совместимости
- Имя в .sound файле: `/main/sounds/название.ogg`
- Имя в ink-теге: `sfx:название` (без расширения и пути)
- ID компонента в main.collection должен совпадать с именем в SFX_URLS
