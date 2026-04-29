# АВОСь GUI split stage 1

Это практический набор для разделения `phone_v2.gui`.

## Что внутри

- `phone_v2_root.gui` — только корпус телефона, chrome, launcher/icons.
- `phone_v2_root.gui_script` — root-скрипт: open/close phone + клики по приложениям.
- `phone_sms.gui`, `phone_call.gui`, `phone_notes.gui`, `phone_quests.gui`, `phone_mail.gui`, `phone_cam.gui`, `phone_term.gui` — экраны, вынесенные из старого `phone_v2.gui`.
- `phone_map_beautiful.gui` — копия твоего красивого `phone_map.gui`, без изменения дизайна.
- `phone_map.gui_script` — visibility wrapper для красивой карты.
- `ui_manager_v2_split_router_snippet.lua` — роутинг кликов launcher -> нужный GUI component.

## Важно

Это stage 1 split-kit: файлы уже разрезаны, id сохранены, но live-refresh данных надо переносить во view scripts по одному экрану.
Зато больше не нужно ковырять один `.gui` на 6000+ строк.

## Подключение

Добавь GUI components в collection:
- phone root -> `phone_v2_root.gui`
- sms -> `phone_sms.gui`
- call -> `phone_call.gui`
- map -> `phone_map_beautiful.gui` + script `phone_map.gui_script`
- notes -> `phone_notes.gui`
- quests -> `phone_quests.gui`
- mail -> `phone_mail.gui`
- cam -> `phone_cam.gui`
- term -> `phone_term.gui`

Имена компонентов в collection должны совпасть с router snippet:
`#phone_sms`, `#phone_call`, `#phone_map`, `#phone_notes`, `#phone_quests`, `#phone_mail`, `#phone_cam`, `#phone_term`.

## Почему это безопаснее

Файлы разрезаны через brace-aware parser по целым `nodes { ... }` блокам, а не regex-удалением середины.
