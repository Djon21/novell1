# Messages модуль

Централизованный реестр всех `msg.post` / `on_message` сообщений в проекте.
Заменяет россыпь `hash("foo")` по коду на `MSG.foo`.

**Файл:** `main/gui/modules/messages.lua`

## Зачем нужен

В Defold `msg.post(url, hash("foo"))` и `if message_id == hash("foo")` —
основа inter-script коммуникации. С ростом проекта появляются проблемы:

1. **Опечатки молчат.** `hash("dialouge_next")` — никакой ошибки, просто
   сообщение никогда не сматчится. Баг проявится в runtime «почему диалог
   не листается».
2. **Сложно искать.** «Где постится `set_overlay_state`?» — приходится
   grep'ать по `hash("set_overlay_state")` и проверять что не съел
   опечатку.
3. **Нет автокомплита** в IDE — приходится помнить точные имена.
4. **Нет единой точки** что вообще за сообщения есть в проекте.

Модуль `messages.lua` решает всё это:

```lua
local MSG = require "main.gui.modules.messages"

msg.post("#ui_manager_v2", MSG.open_phone)
if message_id == MSG.dialogue_next then ... end
```

Опечатался → `MSG.dialouge_next` это `nil`, сравнение `message_id == nil`
не сматчит — но в IDE тут же видно что поля нет (autocomplete + LSP).

## Использование

### Подключение

Идиома: alias `MSG`, по аналогии с `gs`, `dm`, `U`.

```lua
local MSG = require "main.gui.modules.messages"
```

### Вместо `hash(...)`

| Было | Стало |
|------|-------|
| `msg.post(URL, hash("open_phone"))` | `msg.post(URL, MSG.open_phone)` |
| `if message_id == hash("dialogue_next") then` | `if message_id == MSG.dialogue_next then` |

`hash("foo")` и `MSG.foo` дают **одинаковое** значение (Defold's hash
deterministic), так что миграция безопасная — старый и новый код
взаимозаменяемы и работают вместе.

### Массовая замена

Самый быстрый путь:

```bash
sed -i -E 's/hash\("([a-z_]+)"\)/MSG.\1/g' path/to/file.script
```

После замены — добавить `local MSG = require "main.gui.modules.messages"`
в начало файла. Visual проверкой убедиться что все имена в `messages.lua`
есть (если нет — добавить туда сначала).

## Категории сообщений

Все сообщения в `messages.lua` сгруппированы по разделам:

- **Lifecycle** — open_app/close_app/refresh_app (для phone-apps).
- **Phone** — open_phone, close_phone, phone_input, phone_app_clicked,
  set_phone_notif/time/enabled, sms_open_contact, messenger_open_chat и т.д.
- **Dialogue** — dialogue_next/skip/auto, render_dialogue, typewriter_done,
  show/hide_dialogue, set_skip/auto, apply_dialogue_bg.
- **Choice** — show_choice, hide_choice, choice_picked, choice_timeout,
  choice_cancelled.
- **Inventory** — open/close, refresh, inventory_verb, armed banner.
- **Map** — open/close, map_hub_route, map_travel, map_verb, select_pin.
- **HUD** — set_hud_hint, set_overlay_state, set_log/progress/points/loop_state,
  set_location.
- **Menu** — show_menu, start_game, continue_game, reset_iteration, gallery,
  achievements.
- **Backgrounds / эффекты** — set_background, show/hide_bg, play_pulse,
  play_shake, set_effects.
- **Loop / story** — chapter_finished, false_ending, true_ending.
- **Backlog** — open/close/clear_backlog.
- **Hotspots / scene** — set_hotspot, set_scene_object, hide_all,
  layout_changed, toggle_scan.
- **Editor (dev)** — edit_* (F1-редактор хотспотов).
- **Input** — touch, key_esc, scroll/wheel/mouse_wheel.

Когда добавляешь новое сообщение — добавь его в подходящий раздел в
`messages.lua`, затем используй через `MSG.foo`.

## Что мигрировано

В качестве proof-of-concept мигрирован `message_flow.lua` (34 хеша →
MSG.* константы). Остальные файлы используют `hash("foo")` напрямую —
переключатся на `MSG.*` постепенно при следующем касании файла.

Уже мигрированы (0 `hash()` вызовов):

- `main/gui/modules/ui_manager_v2/dm_commands.lua`
- `main/gui/modules/ui_manager_v2/overlay_flow.lua`
- `main/gui/modules/ui_manager_v2/dialogue_flow.lua`
- `main/gui/components_v2/phone_v2_root.gui_script`

Остались для миграции:

- `main/gui/components_v2/dialogue_v2.gui_script` (~20 хешей)
- `main/gui/components_v2/hud_v2.gui_script` (~14 хешей)

Правило: **«при следующем редактировании файла — заодно мигрируй на MSG.*»**.

## Когда НЕ использовать

- Если сообщение **только локальное** в одном файле (никто извне не
  слушает) — можно оставить `hash("foo")`. Особенно если оно
  синтетическое (внутренние таймеры, `play_pulse` для своей
  анимации). Решение по вкусу.
- Если сообщение приходит от Defold-системы и не от нашего кода
  (`layout_changed` приходит от engine). Можно занести, можно нет —
  вопрос вкуса. В `messages.lua` уже занесены `touch`, `key_esc`,
  `wheel_*` для удобства.

## См. также

- `docs/guides/GUI_UTILS.md` — общие GUI-хелперы.
- `docs/guides/DRAG_SCROLL.md` — модуль drag-to-scroll.
- `main/gui/modules/messages.lua` — сам реестр.
