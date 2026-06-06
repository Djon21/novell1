-- main/data/scenes/office_monday.lua
-- Сцены AVOS — раздел: office (понедельник).
-- scene_id'ы work_hub / office_workspace / office_meeting_room пока
-- shared между Mon/Tue (Tuesday office имеет только narrative-content,
-- собственные хотспоты не нужны). Если когда-то понадобится развести —
-- переименовываем здесь в *_monday и одной волной апдейтим ink-ссылки +
-- inventory knot names в 91_inventory_actions.ink.
-- См. _shared.lua для recipes.

local s = require "main.data.scenes._shared"
local office_bg = s.office_bg

return {

    -- =====================================================================
    -- ОФИС — универсальный hub день/ночь
    -- =====================================================================
    -- work_hub / office_workspace / office_meeting_room используют один набор
    -- hotspot'ов и переключают фон через bg = function(gs).
    -- День: bg_office_*_day.
    -- Ночь: bg_office_*_night, когда офисный день уже ушёл в вечерний слой.

    work_hub = {
        bg = office_bg("lobby"),
        label = "Офис — лобби",
        hotspots = {
            s.item_target{
                id = "office_turnstile",
                rect = { x = 885, y = 255, w = 135, h = 135 },
                label = "Турникет",
                knot = "office_turnstile_prompt",
                visible_when = function(gs)
                    return not gs.get_flag("monday_checked_in_office")
                end,
            },
            s.story{
                id = "office_to_workspace_locked",
                rect = { x = 785, y = 400, w = 190, h = 135 },
                label = "К рабочему месту",
                icon = "up",
                knot = "office_to_workspace_locked",
                visible_when = function(gs)
                    return not gs.get_flag("monday_checked_in_office")
                end,
            },
            s.nav_scene{
                id = "office_to_workspace",
                rect = { x = 785, y = 400, w = 190, h = 135 },
                label = "К рабочему месту",
                icon = "up",
                scene = "office_workspace",
                visible_when = function(gs)
                    return gs.get_flag("monday_checked_in_office")
                end,
            },
            s.story{
                id = "office_to_meeting_room_locked_turnstile",
                rect = { x = 390, y = 325, w = 150, h = 220 },
                label = "В переговорку",
                icon = "up",
                knot = "office_to_meeting_room_locked_turnstile",
                visible_when = function(gs)
                    return not gs.get_flag("monday_checked_in_office")
                end,
            },
            s.story{
                id = "office_to_meeting_room_locked_mail",
                rect = { x = 390, y = 325, w = 150, h = 220 },
                label = "В переговорку",
                icon = "up",
                knot = "office_to_meeting_room_locked_mail",
                visible_when = function(gs)
                    return gs.get_flag("monday_checked_in_office")
                       and not gs.get_flag("monday_mail_read")
                end,
            },
            s.nav_scene{
                id = "office_to_meeting_room",
                rect = { x = 390, y = 325, w = 150, h = 220 },
                label = "В переговорку",
                icon = "up",
                scene = "office_meeting_room",
                visible_when = function(gs)
                    return gs.get_flag("monday_checked_in_office")
                       and gs.get_flag("monday_mail_read")
                end,
            },
            s.leave{
                id = "leave_work",
                rect = { x = 0, y = 0, w = 170, h = 220 },
                knot = "leave_work",
            },
        },
    },

    office_workspace = {
        bg = office_bg("workspace"),
        label = "Рабочее место",
        npc = "npc",
        hotspots = {
            s.use{
                id = "work_desk_mail",
                rect = { x = 400, y = 170, w = 365, h = 330 },
                label = "Почта",
                knot = "work_desk_read_mail",
                visible_when = function(gs)
                    return not gs.get_flag("monday_mail_read")
                end,
            },
            s.inspect{
                id = "work_desk_waiting",
                rect = { x = 295, y = 210, w = 130, h = 130 },
                label = "Рабочий стол",
                knot = "work_desk_needs_case_file",
                visible_when = function(gs)
                    return gs.get_flag("monday_mail_read")
                       and not gs.get_flag("monday_case_file_assembled")
                end,
            },
            s.item_target{
                id = "work_desk_submit",
                rect = { x = 290, y = 205, w = 135, h = 135 },
                label = "Передать кейс",
                knot = "work_desk_case_file_prompt",
                visible_when = function(gs)
                    return gs.get_flag("monday_case_file_assembled")
                       and not gs.get_flag("monday_case_file_submitted")
                end,
            },
            s.inspect{
                id = "work_desk_done",
                rect = { x = 400, y = 170, w = 365, h = 330 },
                label = "Рабочий стол",
                knot = "work_desk_done",
                visible_when = function(gs)
                    return gs.get_flag("monday_case_file_submitted")
                end,
            },
            s.story{
                id = "workspace_to_meeting_room_locked",
                rect = { x = 635, y = 290, w = 95, h = 240 },
                label = "В переговорку",
                icon = "up",
                knot = "workspace_to_meeting_room_locked",
                visible_when = function(gs)
                    return not gs.get_flag("monday_mail_read")
                end,
            },
            s.nav_scene{
                id = "workspace_to_meeting_room",
                rect = { x = 635, y = 290, w = 95, h = 240 },
                label = "В переговорку",
                icon = "up",
                scene = "office_meeting_room",
                visible_when = function(gs)
                    return gs.get_flag("monday_mail_read")
                end,
            },
            s.nav_scene{
                id = "workspace_back_to_lobby",
                rect = { x = 480, y = 35, w = 395, h = 180 },
                label = "В лобби",
                icon = "down",
                scene = "work_hub",
            },
        },
    },

    office_meeting_room = {
        bg = office_bg("meeting_room"),
        label = "Переговорка",
        hotspots = {
            s.pickup{
                id = "meeting_room_table_folder",
                rect = { x = 515, y = 175, w = 200, h = 150 },
                label = "Папки",
                knot = "meeting_room_take_folder",
                visible_when = function(gs)
                    return not gs.get_flag("monday_folder_taken")
                       and not gs.get_flag("monday_case_file_assembled")
                end,
            },
            s.inspect{
                id = "meeting_room_table_after",
                rect = { x = 320, y = 135, w = 610, h = 315 },
                label = "Пустой стол",
                knot = "meeting_room_table_after",
                visible_when = function(gs)
                    return gs.get_flag("monday_folder_taken")
                        or gs.get_flag("monday_case_file_assembled")
                end,
            },
            s.nav_scene{
                id = "meeting_room_to_workspace",
                rect = { x = 900, y = 245, w = 110, h = 255 },
                label = "К рабочему месту",
                icon = "up",
                scene = "office_workspace",
            },
            s.nav_scene{
                id = "meeting_room_back_to_lobby",
                rect = { x = 1130, y = 170, w = 135, h = 410 },
                label = "В лобби",
                icon = "right",
                scene = "work_hub",
            },
        },
    },
}
