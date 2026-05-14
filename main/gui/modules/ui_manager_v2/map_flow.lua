local gs = require "main.scripts.game_state"
local meta = require "main.scripts.meta_state"
local scene_controller = require "main.scripts.scene_controller"
local l10n = require "main.scripts.l10n"

local M = {}

-- Все scene_id квартиры (sunday hub + monday/tuesday flow). Используется
-- для подсветки пина "home" на карте: игрок дома → home selected.
-- Aliases вроде apartment_hall_morning через scenes.lua резолвятся в
-- apartment_hub, но scene_controller возвращает alias-имя, так что
-- перечисляем явно.
local HOME_SCENES = {
    -- Sunday hub
    apartment_hub                    = true,
    apartment_bedroom                = true,
    apartment_kitchen                = true,
    apartment_hall_morning           = true,  -- alias
    apartment_bedroom_morning        = true,  -- alias
    apartment_kitchen_morning        = true,  -- alias
    sunday_apartment_bedroom_night   = true,  -- alias
    -- Monday morning-flow
    monday_apartment_hall_morning    = true,
    monday_apartment_bedroom_morning = true,
    monday_apartment_kitchen_morning = true,
    -- Tuesday consequences-flow
    tuesday_apartment_hall_morning   = true,
    tuesday_apartment_bedroom_morning = true,
    tuesday_apartment_kitchen_morning = true,
}

local PIN_LABEL_KEYS = {
    home = "map_home",
    work = "map_work",
    cafe = "map_cafe",
    metro = "map_metro",
    shop = "map_shop",
    clue = "map_clue",
    gov = "map_gov",
}

local function current_scene_id()
    return scene_controller.get_current_scene_id and scene_controller.get_current_scene_id() or nil
end

local function get_pin_label(pin_id)
    local key = PIN_LABEL_KEYS[pin_id]
    return key and l10n.t(key) or pin_id
end

function M.resolve_selected_pin()
    local scene_id = current_scene_id()
    if scene_id and HOME_SCENES[scene_id] then
        return "home"
    end
    if gs.get_flag and gs.get_flag("reached_office") then
        return "work"
    end
    if gs.get_flag and gs.get_flag("reached_metro") then
        return "metro"
    end
    if gs.get_quest and gs.get_quest("go_to_office") == "active" then
        return "metro"
    end
    return "home"
end

local function build_point_overrides()
    local iteration = "#" .. tostring(meta.get_iteration_label and meta.get_iteration_label() or "001")
    local loop_awareness = meta.get and (meta.get("loop_awareness", 0) or 0) or 0
    local scene_id = current_scene_id()
    local at_home = scene_id and HOME_SCENES[scene_id] == true or false
    local reached_metro = gs.get_flag and gs.get_flag("reached_metro") == true or false
    local reached_office = gs.get_flag and gs.get_flag("reached_office") == true or false
    local go_to_office_status = gs.get_quest and gs.get_quest("go_to_office") or nil
    local current_route = gs.get_flag and gs.get_flag("map_route_target") or nil

    return {
        home = {
            iter = iteration,
            stat = at_home and "текущая" or "исходная",
            clue = gs.has_item and gs.has_item("phone") and "телефон" or "—",
        },
        metro = {
            iter = iteration,
            stat = reached_metro and "пройдено"
                or (current_route == "metro" and "маршрут отмечен")
                or (go_to_office_status == "active" and "следующая точка")
                or "узел",
            clue = gs.get_flag and gs.get_flag("map_shared_metro") and "да" or "—",
        },
        work = {
            iter = iteration,
            stat = reached_office and "достигнуто"
                or (current_route == "work" and "маршрут отмечен")
                or (go_to_office_status == "active" and "цель дня")
                or "ожидают",
            clue = gs.get_flag and gs.get_flag("map_shared_work") and "да" or "—",
        },
        cafe = {
            iter = iteration,
            stat = current_route == "cafe" and "маршрут отмечен"
                or (gs.get_flag and gs.get_flag("map_saved_cafe") and "в заметках" or "ориентир"),
            clue = gs.get_flag and gs.get_flag("map_shared_cafe") and "да" or "—",
        },
        shop = {
            iter = iteration,
            stat = current_route == "shop" and "маршрут отмечен"
                or (gs.get_flag and gs.get_flag("map_saved_shop") and "в заметках" or "открыто 24/7"),
            clue = gs.get_flag and gs.get_flag("map_shared_shop") and "да" or "—",
        },
        clue = {
            iter = iteration,
            stat = loop_awareness > 0 and "аномалия" or "скрытый след",
            clue = loop_awareness > 0 and "да" or "—",
            visible = loop_awareness > 0,
        },
        gov = {
            iter = iteration,
            stat = current_route == "gov" and "маршрут отмечен"
                or (loop_awareness > 1 and "интерес" or "ч/п 9:00-18:00"),
            clue = gs.get_flag and gs.get_flag("map_shared_gov") and "да" or "—",
        },
    }
end

function M.sync_overlay(map_url, selected_id, log_text)
    msg.post(map_url, "set_points", {
        points = build_point_overrides(),
        selected_id = selected_id or M.resolve_selected_pin(),
    })
    if log_text then
        msg.post(map_url, "set_log", { text = log_text or "" })
    end
end

local function add_note_once(flag_name, title, body)
    if gs.get_flag and gs.get_flag(flag_name) then
        return false
    end
    if gs.set_flag then
        gs.set_flag(flag_name, true)
    end
    if gs.add_note then
        gs.add_note(title, body)
    end
    return true
end

function M.handle_verb(map_url, pin_id, verb)
    if not pin_id or not verb then
        return
    end

    local label = get_pin_label(pin_id)
    local iteration = tostring(meta.get_iteration_label and meta.get_iteration_label() or "001")
    local log_text = nil

    if verb == "route" then
        if gs.set_flag then
            gs.set_flag("map_route_target", pin_id)
        end
        local body = "Маршрут до точки \"" .. label .. "\" отмечен в планировщике. Петля #" .. iteration .. "."
        if pin_id == "metro" then
            body = body .. "\nСледующая сюжетная опора: метро."
        elseif pin_id == "work" then
            body = body .. "\nЦель рабочего дня закреплена в маршруте."
        end
        local added = add_note_once("map_note_route_" .. pin_id, "Маршрут: " .. label, body)
        log_text = added and ("> маршрут сохранён: " .. label .. " _") or ("> маршрут уже сохранён: " .. label .. " _")

    elseif verb == "save" then
        if gs.set_flag then
            gs.set_flag("map_saved_" .. pin_id, true)
        end
        local body = "Досье по точке \"" .. label .. "\" добавлено в заметки. Это быстрый якорь для текущей петли #" .. iteration .. "."
        local added = add_note_once("map_note_saved_" .. pin_id, "Досье: " .. label, body)
        log_text = added and ("> досье сохранено: " .. label .. " _") or ("> досье уже было сохранено: " .. label .. " _")

    elseif verb == "share" then
        if gs.set_flag then
            gs.set_flag("map_shared_" .. pin_id, true)
        end
        local body = "Точка \"" .. label .. "\" помечена как важная для петли #" .. iteration .. "."
        local added = add_note_once("map_note_shared_" .. pin_id, "Отметка: " .. label, body)
        log_text = added and ("> маркер отмечен: " .. label .. " _") or ("> маркер уже отмечен: " .. label .. " _")
    end

    M.sync_overlay(map_url, pin_id, log_text)
end

return M
