-- main/data/scenes/office_tuesday.lua
-- Stub: офис во вторник пока использует те же scene_id'ы что и понедельник
-- (work_hub / office_workspace / office_meeting_room из office_monday.lua).
-- Tuesday-контент сейчас чисто narrative (см. locations/office_tuesday.ink),
-- собственных хотспот-наборов не требует.
--
-- Когда понадобятся Tuesday-only хотспоты:
--   1. Если переиспользовать scene_id'ы Monday — не получится (merge перезатрёт).
--   2. Завести новые scene_id'ы work_hub_tuesday / office_workspace_tuesday и т.д.
--      Дублировать структуру из office_monday.lua, изменить hotspot visible_when.
--   3. Обновить ink-ссылки в locations/office_tuesday.ink: # explore:work_hub_tuesday.
--   4. Обновить inventory knot names в 91_inventory_actions.ink под новый scene_id.

return {}
