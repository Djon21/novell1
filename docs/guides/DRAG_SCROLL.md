# Drag-Scroll модуль

Универсальная state-машина для drag-to-scroll по вертикали. Используется
в phone-апках (`phone_sms`, `phone_messenger`, `phone_quests`, `phone_mail`,
`phone_term`, `phone_call`) и подходит для любого gui_script где нужно
листать содержимое пальцем или мышью с зажатой ЛКМ.

**Файл:** `main/gui/modules/drag_scroll.lua`

## Когда использовать

Подключай этот модуль вместо ручной реализации drag-state, если в твоём
gui_script:
- есть scrollable список / лента / лог;
- нужно различать **tap** (короткое касание = открыть элемент) и **drag**
  (свайп = пролистать);
- инпут приходит через `phone_input` от `phone_v2_root` или напрямую через
  `on_input(action_id, action)`.

Не нужен если у тебя одна кнопка/тайл, или скролл только колесом мыши без
drag-жеста.

## API

### `drag_scroll.new(opts)`

Создаёт state. Все поля кроме `on_step` опциональны.

| Поле           | Тип       | Дефолт | Что делает                                                                   |
|----------------|-----------|--------|------------------------------------------------------------------------------|
| `step_px`      | number    | `64`   | Сдвиг пальца в пикселях, дающий 1 шаг скролла (`on_step` вызовется с `±1`)   |
| `threshold_px` | number    | `8`    | Минимальное смещение чтобы тап превратился в drag                            |
| `on_step`      | function  | —      | `(owner, delta)` — вызывается каждые `step_px` при движении. **Обязательно** |
| `owner`        | any       | `nil`  | Передаётся первым аргументом в `on_step`. Обычно `self` gui_script'а         |
| `is_inside`    | function  | `nil`  | `(x, y) -> bool`. Опц. фильтр на pressed: drag начинается только если true   |
| `invert`       | bool      | `false`| `true` инвертирует направление шагов                                         |

Возвращает state-объект, храни его на `self`.

### `drag_scroll.handle(state, action)`

Обрабатывает один touch event. Возвращает строку:

| Результат | Что значит | Что делать caller'у |
|-----------|-----------|---------------------|
| `"swallow"` | Press внутри area / mid-drag / завершение drag-жеста | `return true` (event поглощён) |
| `"tap"` | Released без движения — игрок тапнул, не свайпнул | Сделать hit-test и обработку tap'а |
| `"ignore"` | Press вне area, или mouse_move без активного drag | Прокинуть дальше / `return false` |

`action` — стандартный Defold input action: `{x, y, pressed, released}`.

### `drag_scroll.reset(state)`

Принудительный сброс drag-state. Вызывай в `close_app`/при смене view,
чтобы не остался зависший `dragging=true` если приложение закрыли посреди
drag-жеста.

### `drag_scroll.was_drag(state)`

Возвращает `true` если последний завершившийся жест был drag'ом (палец
двигался). Редко нужно — обычно `"tap"` ответа от `handle()` достаточно.

## Типичный паттерн использования

```lua
local drag_scroll = require "main.gui.modules.drag_scroll"

local function scroll_list(self, delta)
    self.offset = math.max(0, math.min(max_offset, self.offset + delta))
    refresh(self)
end

local function inside_list(x, y)
    return point_in(x, y, LIST_X, LIST_Y, LIST_W, LIST_H)
end

function init(self)
    self.list_drag = drag_scroll.new({
        step_px      = 64,
        threshold_px = 8,
        owner        = self,
        is_inside    = inside_list,
        on_step      = function(owner, delta) scroll_list(owner, delta) end,
    })
end

function on_message(self, message_id, message, sender)
    if message_id == hash("close_app") then
        drag_scroll.reset(self.list_drag)
    elseif message_id == hash("phone_input") then
        local action = build_action_from_message(message)
        local result = drag_scroll.handle(self.list_drag, action)
        if result == "swallow" then return end
        if result == "tap" then
            -- Hit-test и обработка tap'а
            local item = pick_item(self, action.x, action.y)
            if item then open_item(self, item) end
            return
        end
        -- "ignore" → событие нас не касается
    end
end
```

## Inversion (`invert = true`)

По умолчанию: drag вниз → `on_step(owner, +1)`, drag вверх → `on_step(owner, -1)`.

Для apps где нужен «контент следует за пальцем» (классический терминал /
мессенджер чат / лента писем — drag вверх показывает старые сообщения)
ставь `invert = true`. Тогда:

- drag вниз → `on_step(owner, -1)` (offset уменьшается, к новым)
- drag вверх → `on_step(owner, +1)` (offset растёт, к старым)

| Где используется invert | Почему                                  |
|-------------------------|------------------------------------------|
| `phone_messenger` chat  | Свайп вверх по баблам = старые сообщения |
| `phone_mail`            | Свайп вверх = старые письма              |
| `phone_term`            | Свайп вверх = старые строки лога         |
| `phone_call`            | Свайп вверх = старые звонки              |

`phone_sms` list, `phone_messenger` list, `phone_quests` — без invert.

## `is_inside` vs всегда-drag

Два паттерна:

### С `is_inside` (рекомендуется для списков с тапаемыми соседями)

```lua
is_inside = function(x, y) return inside_list_rect(x, y) end
```

Press вне области → `handle` возвращает `"ignore"`, drag не начинается,
event прокидывается дальше (другие хитбоксы могут обработать). Press
внутри → drag-state стартует и swallow'ит pressed.

### Без `is_inside` (для apps где весь screen скроллится)

```lua
-- is_inside не указан
```

Любой press начинает drag. На `"tap"` ответе caller сам решает что делать
с координатами (обычно — fall-through к собственному hit-test'у).

Так сделано в `phone_messenger`: list view + chat view целиком scrollable,
а tap'ы по back/input/send/чат-row обрабатываются в fall-through ветке
после `handle() == "tap"`.

## Порог `threshold_px`

Защита от ложных drag'ов из-за дрожи пальца / шума мыши. Стандартное
значение `8` хорошо для всех случаев — мельче нет смысла. Если приложение
показывает большие быстрые жесты (например карта) — можно увеличить до
`16`–`24`, чтобы случайный сдвиг при тапе не считался drag'ом.

## `step_px` — гранулярность

Чем меньше `step_px`, тем «плавнее» листает (но чаще вызывается `on_step`
и больше нагрузка на `refresh`). Эмпирически:

- `28`–`34` для построчных списков (`phone_term`, `phone_mail`, `phone_call`)
- `48`–`64` для крупных карточек (`phone_sms`, `phone_messenger`, `phone_quests`)

`on_step` вызывается с `delta = ±1`, так что одна порция = `step_px`
пикселей сдвига = 1 строка/карточка.

## Wheel scroll

Модуль обрабатывает только touch. Mouse wheel и `wheel_up`/`wheel_down`
action_id'ы должны идти отдельно, до или после `drag_scroll.handle`:

```lua
local wheel_rows = wheel_rows_from_action(action_id, action)
if wheel_rows ~= 0 then return scroll_list(self, wheel_rows) end
if action_id ~= hash("touch") then return false end
local result = drag_scroll.handle(self.list_drag, action)
...
```

Так и сделано во всех phone-апках.

## Совместимость с armed-on-press паттернами

Если в gui_script есть кнопки которые работают через arm-on-press /
fire-on-release (например в `phone_messenger` send/input для side-dialogue),
они должны:

1. Делать arm в обычной tap-ветке (`if action.pressed then ...`).
2. **Дизармиться** когда drag перешёл порог: `if state.moved then disarm() end`.

Иначе игрок зажмёт кнопку, потащит свайп — release где-то вне кнопки
запустит armed-действие.

Пример из `phone_messenger`:

```lua
local result = drag_scroll.handle(self.chat_drag, action)
if result == "swallow" then
    if self.view == "chat" and self.chat_drag.moved then
        self.reply_tap_armed = false  -- drag отменяет arm
    end
    return true
end
```

## Куда ещё не применили

- `phone_notes` — данных мало, скролл не нужен (пока).
- `phone_map` — там собственная panning-механика для карты, не drag-list.
- ~~phone_cam~~ — удалён в мае 2026.

Если добавишь новое phone-app со списком — используй этот модуль.
