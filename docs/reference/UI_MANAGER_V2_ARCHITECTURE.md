# ui_manager_v2 архитектура

`ui_manager_v2.script` — оркестратор всех v2 GUI-компонентов: главное меню,
HUD, инвентарь, телефон, карта, диалог, выбор. Раньше был god-object'ом на
975 строк, постепенно разбит на flow-модули в `main/gui/modules/ui_manager_v2/`.

Этот файл — карта местности. Когда ищешь «где живёт логика X» — заглядывай
сюда.

## Структура

```
main/gui/
├── ui_manager_v2.script         (~975 строк — оркестратор + ctx-builders)
└── modules/ui_manager_v2/
    ├── background_flow.lua       — атласы фонов, resolve location label
    ├── dev_jump.lua              — dev-прыжки по сценам (F1 редактор)
    ├── dialogue_flow.lua         — autoplay, skip, backlog, toggle UI
    ├── dialogue_orchestrator.lua — handle_dialogue_update (главный обработчик)
    ├── dm_commands.lua           — apply ink-tag команд (#bg, #sms, #map, ...)
    ├── effects_flow.lua          — sfx/shake/pulse эффекты
    ├── inventory_flow.lua        — armed-state, use-on-target, verbs
    ├── lifecycle.lua             — start_new_run, reset_iteration, refresh_menu
    ├── message_flow.lua          — on_message router (по типам сообщений)
    ├── overlay_flow.lua          — show_menu/exploration/dialogue, open/close оверлеев
    ├── phone_flow.lua            — open_phone, open_phone_app, close_phone
    ├── run_state.lua             — persist/restore/reset save-state
    └── scene_flow.lua            — scene_controller integration setup
```

## Как взаимодействуют модули

```
        ┌─────────────────────────────────┐
        │     ui_manager_v2.script        │
        │   (state M, ctx-builders)       │
        └────────────────┬────────────────┘
                         │
        ┌────────────────┼────────────────┬─────────────────┐
        ▼                ▼                ▼                 ▼
   on_message()    handle_dialogue   start_new_run()   on_input()
   message_flow    dialogue_orch      lifecycle      (esc, music)
        │                │                │
        ▼                ▼                ▼
   роутит по        применяет dm     сбрасывает
   message_id       команды +        runtime, dm.init,
   в обработчики    рендерит ноду    handle_dialogue_update
```

`ui_manager_v2.script` — главный hub. Хранит `M.components` (URL'ы всех
GUI), `M.overlays` (что сейчас открыто), `M.base_mode` (menu/dialogue/
exploration), `M.SFX_URLS` и т.п. Сам почти ничего не делает — собирает
ctx-таблицы и делегирует во flow.

Каждый flow-модуль возвращает `M = {}` с публичными функциями. Принимают
параметром `ctx` — таблицу с зависимостями (компоненты, callback'и). Это
явный контракт «что нам нужно от ui_manager».

## Главные потоки

### Старт игры / iteration reset

```
btn "Начать игру" → main_menu → msg.post(UI_MGR, "start_game")
   ↓
ui_manager.on_message → message_flow.handle_menu("start_game")
   ↓
ctx.start_new_run(false) → lifecycle.start_new_run
   ↓
sm.load + meta.init + reset overlays + dm.init(bytes)
   ↓
handle_dialogue_update → dialogue_orchestrator.update
   ↓
показ первого узла story
```

### Игрок кликает «Дальше» в диалоге

```
btn_next → dialogue_v2 → msg.post(UI_MGR, "dialogue_next")
   ↓
message_flow.handle_dialogue("dialogue_next")
   ↓
ctx.cancel_dialogue_autoplay + dm.advance() + ctx.handle_dialogue_update
   ↓
dialogue_orchestrator.update:
   1. apply_dm_commands (ink-tags могут поменять сцену)
   2. если открыт map/phone → hide dialogue, return
   3. exploration vs dialogue: фон + show_*
   4. рендер node по типу (dialogue/choice/end)
```

### Игрок открывает телефон

```
HUD-кнопка → msg.post(UI_MGR, "open_phone")
   ↓
message_flow.handle_phone("open_phone") → ctx.open_phone()
   ↓
ui_manager.open_phone:
   notify_overlay_state("phone", true) → HUD pulse-hint pause + dialogue input gate
   phone_flow.open(phone_ctx())
   ↓
phone_v2 показывается, инпут идёт через phone_input
```

## Где живёт что

| Хочу понять | Смотри |
|---|---|
| Что показывается при изменении ink-state | `dialogue_orchestrator.lua` |
| Что делает «Сбросить итерацию» | `lifecycle.lua` |
| Что обрабатывает ink-тег `# sms:add:...` | `dm_commands.lua` |
| Куда роутится `msg.post("dialogue_skip")` | `message_flow.lua` (handle_dialogue) |
| Логика skip / auto / autoplay timer | `dialogue_flow.lua` |
| Show_menu / show_exploration / open_inventory | `overlay_flow.lua` |
| save/load mid-dialogue, persist | `run_state.lua` |
| Атласы фонов и резолв названия локации | `background_flow.lua` |
| Verb-knot цепочка для use/give/combine | `inventory_flow.lua` |
| sfx/shake/pulse | `effects_flow.lua` |
| scene_controller callback'и | `scene_flow.lua` |
| Phone карта: pin'ы и переходы | `message_flow.lua` (map_travel), `phone_flow.lua` |

## Контракт ctx

Каждый flow-модуль принимает `ctx` — таблицу с зависимостями. Это
сделано чтобы:
- модули не зависели глобально от ui_manager (тестируемы);
- ui_manager явно объявлял что он отдаёт каждому flow.

Пример (из `lifecycle.lua`):
```lua
-- ctx ожидается с полями:
--   M                       — таблица состояния (overlays, base_mode, components)
--   sync_modal_state        — () → ()
--   clear_armed_state       — () → ()
--   reset_dialogue_backlog  — () → ()
--   reset_runtime_state     — () → ()
--   handle_dialogue_update  — () → ()
--   sync_ui_state           — () → ()
--   persist_run_state       — () → ()
--   show_menu               — () → ()
```

В `ui_manager_v2.script` есть builder'ы вроде `lifecycle_ctx(self)`,
`overlay_ctx(self)`, `phone_ctx()`, `inventory_ctx(self)`,
`dialogue_ctx()`, `dialogue_update_ctx()`, `message_ctx(self)`. Каждый
собирает таблицу с нужными для своего flow callback'ами.

Когда добавляешь новую функцию во flow и ей нужно что-то от ui_manager —
добавь поле в соответствующий ctx-builder. Не глобал.

## Когда что менять (рецепты)

### Новый fullscreen background

В `ui_manager_v2.script` (потому что `go.property` живёт только в `.script`):
1. `go.property("bg_<name>_atlas", resource.atlas("/main/images/backgrounds/bg_<name>.atlas"))`
2. Строка в `DEDICATED_BG_ATLAS_PROPS`

Логика переключения — в `background_flow.lua`, обычно её трогать не нужно.

### Новый SFX из Ink

В `M.SFX_URLS` в `ui_manager_v2.script`:
```lua
M.SFX_URLS = {
    door_open = "/sfx_player#door_open",
}
```
Воспроизведение — `effects_flow.lua`.

### Новый ink-тег

См. чек-лист ниже.

### Новое сообщение `msg.post(UI_MGR, ...)`

См. чек-лист ниже.

### Новый стиль/поле хотспота

1. В `scene_flow.lua` — добавить в clean-copy данных
2. В `hotspots_v2.gui_script` — принять и применить
3. В `docs/guides/HOTSPOTS.md` — описать

### Новое действие предмета (verb)

1. Добавить verb в `ENABLED_VERBS` в `inventory_flow.lua`
2. Добавить поведение в `M.handle_verb`
3. Описать ink-knot-цепочку в `docs/reference/INVENTORY_SYSTEM.md`

### Новое приложение телефона

1. Создать `phone_<app>.gui` + `phone_<app>.gui_script`
2. Добавить в `phone_v2_root.gui_script` (`APP_COMPONENT`, `APP_TITLES`, `APPS`)
3. Если особое открытие — `phone_flow.lua`
4. Если приложение шлёт сообщения в UI_MGR — `message_flow.lua`

### Что специально оставлено в `ui_manager_v2.script`

Намеренно не вынесено:
- `go.property(...)` для атласов фонов
- `M.components`, `M.overlays`, `M.SFX_URLS`
- Context-builders (`dialogue_ctx`, `inventory_ctx`, `overlay_ctx`, `message_ctx`)
- `start_new_run`, `reset_iteration_and_restart`, `refresh_menu_state`
- `handle_dialogue_update`
- `on_input`

Возможный будущий рефакторинг: `input_flow.lua` (для `on_input`), дробление `handle_dialogue_update`. Последнее связано с Ink/scene_controller/dialogue/choice/exploration и трогается осторожно.

## Чек-лист добавления нового сообщения

1. Добавить hash в `main/gui/modules/messages.lua` (см. `MESSAGES.md`).
2. Решить какой flow его обрабатывает: phone / map / inventory / etc.
3. В `message_flow.lua` найти соответствующий handler (handle_phone,
   handle_inventory, ...) и добавить ветку.
4. В handler позвать нужную функцию через `ctx.foo(...)`.
5. Если ctx ещё не имеет `foo` — добавить в `message_ctx(self)` в
   ui_manager_v2.script.
6. Реализовать `foo` либо в новом flow-модуле, либо локально в
   ui_manager_v2.script (если совсем тонкая).

## Чек-лист добавления нового ink-тега

1. В `dialogue_manager_ink.lua` → `apply_tags` добавить ветку:
   ```lua
   elseif key == "newtag" then
       table.insert(pending_commands, { type = "newtag", payload = value })
   ```
2. В `dm_commands.lua` → `apply_single` добавить:
   ```lua
   elseif cmd.type == "newtag" then
       ctx.do_newtag(cmd.payload)
   ```
3. В `apply_dm_commands` (ui_manager_v2.script) пробросить `do_newtag` в
   ctx.
4. Реализовать что делает `do_newtag` (обычно через flow-модуль).

## История рефакторинга

- **изначально:** ui_manager_v2.script ~1100 строк, всё в одном
- **этап 1:** вынесены `dm_commands`, `dialogue_flow`,
  `phone_flow`, `inventory_flow`, `effects_flow`,
  `background_flow`, `scene_flow`, `overlay_flow`, `message_flow`,
  `run_state`. Скрипт ужался до ~875 строк.
- **этап 2:** `lifecycle.lua`, `dialogue_orchestrator.lua`,
  `dev_jump.lua`. Скрипт ~975 строк за счёт новых фич.

## См. также

- `docs/guides/MESSAGES.md` — реестр сообщений msg.post
- `docs/guides/GUI_UTILS.md` — общие GUI-хелперы
- `docs/guides/DRAG_SCROLL.md` — модуль drag-to-scroll для phone-app'ов
- `docs/guides/PHONE_SYSTEM.md` — архитектура phone overlay
- `docs/guides/HOW_TO_WRITE_INK.md` — список всех ink-тегов и их обработчиков
