# UI Manager V2 Modules

Актуально на `2026-05-07`.

`main/gui/ui_manager_v2.script` больше не хранит всю UI-логику в одном файле. Сейчас это центральный Defold-адаптер: он объявляет `go.property(...)`, хранит ссылки на GUI-компоненты, принимает `on_message`/`on_input` и передаёт работу в модули из `main/gui/modules/ui_manager_v2/`.

## Главная Идея

`ui_manager_v2.script` отвечает за:

- регистрацию fullscreen background atlas через `go.property`;
- сбор URL компонентов `main_menu_v2`, `hud_v2`, `dialogue_v2`, `inventory_v2`, `phone_v2`, `map_v2`, `hotspots_v2`, `effects`;
- создание маленьких context-таблиц для модулей;
- lifecycle Defold: `init`, `final`, `on_message`, `on_input`;
- первый запуск `l10n`, `save_manager`, `meta_state`, `yandex_ads`;
- центральный сценарный поток `handle_dialogue_update`.

Всё, что можно было отделить без изменения поведения, вынесено в flow-модули.

## Список Модулей

| Модуль | За что отвечает |
|---|---|
| `background_flow.lua` | Dedicated atlas фонов, безопасный `go.set` из `.script`, подпись текущей локации в HUD/choice. |
| `dialogue_flow.lua` | `AUTO`, `SKIP`, таймер автопрокрутки, read-only backlog/log диалогов. |
| `dm_commands.lua` | Выполнение команд из Ink-тегов: сцены, телефон, карта, реклама, flags/items/quests/SMS/mail/calls/clues/camera/terminal. |
| `effects_flow.lua` | One-shot эффекты Ink: `sfx`, `shake`, `pulse`. |
| `inventory_flow.lua` | Verbs инвентаря, armed-state для `use`, поиск inventory Ink-knot. |
| `map_flow.lua` | Логика `map_v2`: выбранный pin, тексты dossier/log, route/save/share, hub-mode helpers. |
| `message_flow.lua` | Маршрутизация `on_message` по группам: меню, концовки, диалог, choice, inventory, phone, map. |
| `overlay_flow.lua` | Режимы и модалки: menu, exploration, dialogue, inventory, map, choice, `ui_state.modal_open`. |
| `phone_flow.lua` | Открыть/закрыть телефон, открыть приложение телефона, доступность телефона. |
| `run_state.lua` | Сохранение/восстановление `game_state + scene_controller`, загрузка `chapter_01.json`, reset runtime. |
| `scene_flow.lua` | Адаптер `scene_controller -> hotspots_v2`: scene objects, hotspots, стили хотспотов, callbacks Ink/use-on-hotspot. |

## Как Идёт Сообщение

Пример: игрок нажал BAG в HUD.

```text
hud_v2.gui_script
  -> msg.post("#ui_manager_v2", "open_inventory")
ui_manager_v2.script
  -> message_flow.handle(...)
message_flow.lua
  -> ctx.open_inventory()
ui_manager_v2.script wrapper
  -> overlay_flow.open_inventory(...)
overlay_flow.lua
  -> M.overlays.inventory = true
  -> ui_state.modal_open = true
  -> msg.post(inventory_v2, "show_inventory")
```

Главный принцип: внешний мир всё ещё пишет сообщения в `#ui_manager_v2`, но обработка уже разложена по модулям.

## Что Где Менять

### Новый fullscreen background

Менять нужно в `ui_manager_v2.script`, потому что `go.property(...)` должен жить в `.script`:

1. Добавить `go.property("bg_<name>_atlas", resource.atlas("/main/images/backgrounds/bg_<name>.atlas"))`.
2. Добавить строку в `DEDICATED_BG_ATLAS_PROPS`.

Рабочая логика переключения atlas находится в `background_flow.lua`, но обычно её трогать не нужно.

### Новый SFX из Ink

Менять нужно `M.SFX_URLS` в `ui_manager_v2.script`:

```lua
M.SFX_URLS = {
    door_open = "/sfx_player#door_open",
}
```

Воспроизведение делает `effects_flow.lua`.

### Новый Ink-тег-команда

Если тег должен менять состояние игры или открывать UI, основной файл:

- `dialogue_manager_ink.lua` — распарсить тег и положить command/effect;
- `dm_commands.lua` — выполнить command;
- при необходимости добавить callback в `apply_dm_commands(self)` внутри `ui_manager_v2.script`.

Примеры существующих команд: `phone:map`, `adv:fullscreen`, `goto_scene`, `return_to_scene`, `add_item`, `sms`, `quest`.

### Новое сообщение GUI

Если какой-то GUI-компонент отправляет новое `msg.post("#ui_manager_v2", "...")`, искать обработку в `message_flow.lua`.

Там сообщения сгруппированы:

- menu/continue/endings;
- dialogue/backlog;
- choice;
- inventory;
- phone/SMS/map travel;
- map/map hub.

Если сообщение должно вызвать функцию из `ui_manager_v2.script`, добавь callback в `message_ctx(self)`.

### Новый стиль/поле хотспота

Данные хотспота копируются в `scene_flow.lua`, а рисуются в `hotspots_v2.gui_script`.

Если в `scenes.lua` добавляется новое поле, например `pulse_speed`, его нужно:

1. Добавить в clean-copy внутри `scene_flow.lua`.
2. Принять и применить в `hotspots_v2.gui_script`.
3. Описать в `docs/guides/HOTSPOT_VISUALS.md`.

### Новое действие предмета

Основная логика в `inventory_flow.lua`.

Если добавляется новый verb:

1. Добавить verb в `ENABLED_VERBS`.
2. Добавить поведение в `M.handle_verb`.
3. Описать цепочку Ink-knot в `docs/reference/INVENTORY_SYSTEM.md`.

### Новое приложение телефона

Обычно меняются:

- `phone_v2_root.gui_script` — приложение в телефоне;
- нужный `phone_*.gui` / `phone_*.gui_script`;
- `phone_flow.lua`, если нужно особое открытие;
- `message_flow.lua`, если приложение шлёт новое сообщение в `#ui_manager_v2`.

## Что Пока Осталось В `ui_manager_v2.script`

Это нормально и специально оставлено там:

- `go.property(...)` для atlas;
- `M.components`, `M.overlays`, `M.SFX_URLS`;
- context-функции `dialogue_ctx`, `inventory_ctx`, `overlay_ctx`, `message_ctx`;
- `start_new_run`, `reset_iteration_and_restart`, `refresh_menu_state`;
- `handle_dialogue_update`;
- `on_input`.

Следующий возможный рефакторинг, если понадобится: вынести `on_input` в `input_flow.lua` или аккуратно дробить `handle_dialogue_update`. Но `handle_dialogue_update` связывает Ink, scene_controller, dialogue, choice и exploration, поэтому его лучше трогать только отдельным осторожным этапом.
