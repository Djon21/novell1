# Logger модуль

Единый логгер проекта. Заменяет россыпь `print("[system] msg")` и
per-file `local DEBUG_LOG = false`-флагов.

**Файл:** `main/scripts/log.lua`

## Зачем

Раньше:
- 78 разрозненных `print("[ui_manager_v2]" / "[DM-Ink]" / "[phone_messenger]" ...)`.
- В 5 файлах `local DEBUG_LOG = false` — чтобы включить debug-логи приходилось руками
  ставить `true` и пересобирать.
- Невозможно отфильтровать «покажи только phone-логи».
- В release-билде console-spam.

Теперь:
- Один модуль, 5 уровней (`error/warn/info/debug/trace`).
- Глобальный toggle: `log.set_level("debug")` включает debug везде.
- Фильтр по подсистеме: `log.set_filter({"phone", "messenger"})` — только эти.
- Можно заглушить шумную систему: `log.silence("game_state")`.
- В release: `log.set_level("warn")` обрезает info/debug/trace.

## API

```lua
local log = require "main.scripts.log"

log.error("dm",         "knot not found:", knot_name)
log.warn ("phone",      "no atlas for bg:", name)
log.info ("ui_manager", "open_phone()")
log.debug("dm",         "tag", key, value)
log.trace("scene",      "render call", details)
```

Сигнатура одинаковая: `log.<level>(system, ...)`. Аргументы конкатенируются
через пробел через `tostring`.

### Управление

```lua
log.set_level("debug")               — глобальный уровень
log.get_level() -> "info"

log.set_filter({"phone", "msg"})     — оставить только эти системы
log.set_filter(nil)                  — снять фильтр

log.silence("game_state")            — заглушить одну систему
log.unsilence("game_state")
```

### Scoped logger

В большом файле удобно зафиксировать систему один раз:

```lua
local log = require("main.scripts.log").for_system("phone")

log.info("open_phone()")              -- автоматически с system="phone"
log.warn("no atlas:", name)
```

## Уровни

| Уровень | Когда использовать |
|---------|--------------------|
| `error` | Что-то сломалось, надо чинить (knot не найден, ассет не загрузился). |
| `warn`  | Подозрительно, но игра продолжается (опечатка в теге, пустой контакт). |
| `info`  | Обычная инфа: что произошло (open_phone, scene enter, выбор сделан). |
| `debug` | Диагностика для разработчика: значения переменных, переходы состояний. |
| `trace` | Очень подробно: каждый параграф ink, каждый кадр render. По умолчанию off. |

По умолчанию пороговый уровень `info` — debug и trace не печатаются.

## Формат вывода

```
[INFO  ui_manager] open_phone()
[WARN  phone] no atlas for bg: bg_foo
[ERROR dm] knot not found: bedroom_extra
[DEBUG dm] tag bg apartment_morning
```

## Системы (подсказка)

Стандартные имена систем в коде:

- `ui_manager` — `ui_manager_v2.script` + flow-модули
- `dm` — `dialogue_manager_ink.lua`
- `scene` — `scene_controller.lua`
- `game_state` — `game_state.lua`
- `phone_root` / `phone_sms` / `messenger` — phone apps
- `dialogue` — `dialogue_v2.gui_script`
- `hotspots` — `hotspots_v2.gui_script`
- `inventory` — `inventory_flow.lua`
- `yandex_ads` — `yandex_ads.lua`
- `l10n`, `hotspot_editor` — соответствующие модули

Когда добавляешь новую систему — выбери короткое имя (одно слово, snake_case).

## Миграция со старого `print("[X]")`

Шаблон:

```lua
-- Было:
print("[phone_messenger] TODO attach runtime hook")
print("[ui_manager_v2] WARNING: chapter_01 not found")
print("[DM-Ink] choice [" .. i .. "] " .. text)

-- Стало:
log.debug("messenger",  "TODO attach runtime hook")
log.warn ("ui_manager", "chapter_01 not found")
log.info ("dm",         "choice [" .. i .. "] " .. text)
```

Уровень выбирается по содержанию: WARNING → warn, ERROR → error, обычная
информация → info, диагностика → debug.

## Миграция со старых `DEBUG_LOG`-флагов

Раньше:
```lua
local DEBUG_LOG = false
local function dbg(...) if DEBUG_LOG then print(...) end end
```

Стало:
```lua
local log = require "main.scripts.log"
local function dbg(...) log.debug("system", ...) end
```

Глобальный toggle через `log.set_level("debug")` — включит сразу везде.

## Что мигрировано

В рамках первой волны мигрированы все известные `DEBUG_LOG`-флаги и
`print("[X]")` вызовы:

- `ui_manager_v2.script`, `dialogue_v2.gui_script`, `hotspots_v2.gui_script`,
  `phone_sms.gui_script`, `phone_v2_root.gui_script` — DEBUG_LOG → log.debug.
- `dialogue_manager_ink.lua`, `scene_controller.lua`, `game_state.lua`,
  `hotspot_editor.lua`, `l10n.lua` — print → log.warn/info.
- `message_flow.lua`, `background_flow.lua`, `effects_flow.lua`,
  `inventory_flow.lua`, `run_state.lua` — то же.
- `yandex_ads.lua` — все 20 prints.

Итого: ~70 prints + 5 DEBUG_LOG-флагов сведены к единому модулю.

## Включение debug в runtime

В Defold Editor можно поставить точку входа (например, debug-key F3) который
переключает уровень:

```lua
-- В каком-нибудь debug-скрипте:
function on_input(self, action_id, action)
    if action_id == hash("key_f3") and action.pressed then
        local log = require "main.scripts.log"
        if log.get_level() == "debug" then
            log.set_level("info")
        else
            log.set_level("debug")
        end
    end
end
```

В release-билде безопасно ставить `log.set_level("warn")` — info/debug
log'и ничего не будут печатать (just early return), оверхед минимальный.

## См. также

- `docs/guides/MESSAGES.md` — реестр msg-сообщений.
- `docs/guides/GUI_UTILS.md` — общие GUI-хелперы.
- `docs/guides/DRAG_SCROLL.md` — модуль drag-to-scroll.
