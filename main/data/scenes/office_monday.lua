-- main/data/scenes/office_monday.lua
-- Сцены AVOS — раздел: office (понедельник).
-- scene_id'ы work_hub / office_workspace / office_meeting_room пока
-- shared между Mon/Tue (Tuesday office имеет только narrative-content,
-- собственные хотспоты не нужны). Если когда-то понадобится развести —
-- переименовываем здесь в *_monday и одной волной апдейтим ink-ссылки +
-- inventory knot names в 91_inventory_actions.ink.
-- См. main/data/scenes/_shared.lua для STYLE_* и helper'ов.

local s = require "main.data.scenes._shared"
local STYLE_NAV         = s.STYLE_NAV
local STYLE_INSPECT     = s.STYLE_INSPECT
local STYLE_PICKUP      = s.STYLE_PICKUP
local STYLE_USE         = s.STYLE_USE
local STYLE_ITEM_TARGET = s.STYLE_ITEM_TARGET
local STYLE_STORY       = s.STYLE_STORY
local STYLE_NEUTRAL     = s.STYLE_NEUTRAL
local apartment_bg      = s.apartment_bg
local office_bg         = s.office_bg
local is_apartment_night = s.is_apartment_night
local is_office_night   = s.is_office_night
local is_sunday_apartment_night = s.is_sunday_apartment_night
local is_monday_apartment_night = s.is_monday_apartment_night

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
            {
                id = "office_turnstile",
                rect = { x = 885, y = 255, w = 135, h = 135 },
                label = "Турникет",
                icon = "left_click",
                hotspot_style = STYLE_USE,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "ink_knot", knot = "office_turnstile_prompt" },
                visible_when = function(gs)
                    return not gs.get_flag("monday_checked_in_office")
                end,
            },
            {
                id = "office_to_workspace",
                rect = { x = 785, y = 400, w = 190, h = 135 },
                label = "К рабочему месту",
                icon = "arrow_up",
                hotspot_style = STYLE_NAV,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "goto_scene", scene = "office_workspace" },
                condition = function(gs)
                    return gs.get_flag("monday_checked_in_office")
                end,
            },
            {
                id = "office_to_meeting_room",
                rect = { x = 390, y = 325, w = 150, h = 220 },
                label = "В переговорку",
                icon = "arrow_up",
                hotspot_style = STYLE_NAV,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "goto_scene", scene = "office_meeting_room" },
                condition = function(gs)
                    return gs.get_flag("monday_checked_in_office")
                        and gs.get_flag("monday_mail_read")
                end,
            },
            {
                id = "leave_work",
                rect = { x = 0, y = 0, w = 170, h = 220 },
                label = "Выйти",
                icon = "arrow_back",
                hotspot_style = STYLE_NAV,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "ink_knot", knot = "leave_work" },
            },
        },
    },

    office_workspace = {
        bg = office_bg("workspace"),
        label = "Рабочее место",
        npc = "npc",
        hotspots = {
            {
                id = "work_desk_mail",
                rect = { x = 400, y = 170, w = 365, h = 330 },
                label = "Рабочий стол",
                icon = "left_click",
                hotspot_style = STYLE_USE,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "ink_knot", knot = "work_desk_read_mail" },
                visible_when = function(gs)
                    return not gs.get_flag("monday_mail_read")
                end,
            },
            {
                id = "work_desk_waiting",
                rect = { x = 295, y = 210, w = 130, h = 130 },
                label = "Рабочий стол",
                icon = "left_click",
                hotspot_style = STYLE_INSPECT,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "ink_knot", knot = "work_desk_needs_case_file" },
                visible_when = function(gs)
                    return gs.get_flag("monday_mail_read")
                        and not gs.get_flag("monday_case_file_assembled")
                end,
            },
            {
                id = "work_desk_submit",
                rect = { x = 290, y = 205, w = 135, h = 135 },
                label = "Рабочий стол",
                icon = "left_click",
                hotspot_style = STYLE_USE,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "ink_knot", knot = "work_desk_case_file_prompt" },
                visible_when = function(gs)
                    return gs.get_flag("monday_case_file_assembled")
                        and not gs.get_flag("monday_case_file_submitted")
                end,
            },
            {
                id = "work_desk_done",
                rect = { x = 400, y = 170, w = 365, h = 330 },
                label = "Рабочий стол",
                icon = "left_click",
                hotspot_style = STYLE_INSPECT,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "ink_knot", knot = "work_desk_done" },
                visible_when = function(gs)
                    return gs.get_flag("monday_case_file_submitted")
                end,
            },
            {
                id = "workspace_to_meeting_room",
                rect = { x = 635, y = 290, w = 95, h = 240 },
                label = "В переговорку",
                icon = "arrow_up",
                hotspot_style = STYLE_NAV,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "goto_scene", scene = "office_meeting_room" },
                condition = function(gs)
                    return gs.get_flag("monday_mail_read")
                end,
            },
            {
                id = "workspace_back_to_lobby",
                rect = { x = 480, y = 35, w = 395, h = 180 },
                label = "В лобби",
                icon = "arrow_down",
                hotspot_style = STYLE_NAV,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "goto_scene", scene = "work_hub" },
            },
        },
    },

    office_meeting_room = {
        bg = office_bg("meeting_room"),
        label = "Переговорка",
        hotspots = {
            {
                id = "meeting_room_table_folder",
                rect = { x = 515, y = 175, w = 200, h = 150 },
                label = "Стол",
                icon = "left_click",
                hotspot_style = STYLE_PICKUP,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "ink_knot", knot = "meeting_room_take_folder" },
                visible_when = function(gs)
                    return not gs.get_flag("monday_folder_taken")
                        and not gs.get_flag("monday_case_file_assembled")
                end,
            },
            {
                id = "meeting_room_table_after",
                rect = { x = 320, y = 135, w = 610, h = 315 },
                label = "Стол",
                icon = "left_click",
                hotspot_style = STYLE_INSPECT,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "ink_knot", knot = "meeting_room_table_after" },
                visible_when = function(gs)
                    return gs.get_flag("monday_folder_taken")
                        or gs.get_flag("monday_case_file_assembled")
                end,
            },
            {
                id = "meeting_room_to_workspace",
                rect = { x = 900, y = 245, w = 110, h = 255 },
                label = "К рабочему месту",
                icon = "arrow_up",
                hotspot_style = STYLE_NAV,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "goto_scene", scene = "office_workspace" },
            },
            {
                id = "meeting_room_back_to_lobby",
                rect = { x = 1130, y = 170, w = 135, h = 410 },
                label = "В лобби",
                icon = "arrow_forward",
                hotspot_style = STYLE_NAV,
                icon_offset_x = -4,
                icon_offset_y = 0,
                action = { type = "goto_scene", scene = "work_hub" },
            },
        },
    },
}
