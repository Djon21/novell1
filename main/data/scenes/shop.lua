-- main/data/scenes/shop.lua
-- Сцены AVOS — раздел: shop. См. main/data/scenes/_shared.lua для recipes.
--
-- Магазин 24/7 состоит из трёх exploration-сцен:
--   shop_street    — улица у магазина
--   shop_front     — входная часть, касса, напитки, снеки
--   shop_household — бытовой отдел в глубине магазина
--
-- shop_hub оставлен как backwards-compatible alias на shop_street,
-- чтобы не ломать poi_shop, старые сейвы и старые Ink-переходы.

local s = require "main.data.scenes._shared"

-- Пока есть только day-фоны. Когда появятся night-атласы,
-- эту функцию можно расширить по флагам времени суток.
local function shop_bg(zone)
    return "bg_shop_" .. zone .. "_day"
end

local shop_street = {
    bg = shop_bg("street"),
    label = "У магазина",
    on_enter = {
        knot = "sunday_shop_street_arrival",
        condition = function(gs)
            return (not gs.get_flag("met_npc_sunday") and not gs.get_flag("sunday_shop_street_pre_date_seen"))
                or (gs.get_flag("sunday_after_date_active") and not gs.get_flag("sunday_second_stop_done") and not gs.get_flag("sunday_shop_street_with_npc_seen"))
        end,
    },
    hotspots = {
        s.nav_scene{
            id = "shop_enter",
            rect = { x = 520, y = 210, w = 250, h = 300 },
            label = "Войти",
            icon = "up",
            scene = "shop_front",
        },
        s.inspect{
            id = "shop_window",
            rect = { x = 270, y = 250, w = 230, h = 230 },
            label = "Витрина",
            knot = "shop_window_interact",
        },
        s.inspect{
            id = "shop_sign",
            rect = { x = 280, y = 520, w = 710, h = 110 },
            label = "Вывеска",
            knot = "shop_sign_interact",
        },
        s.leave{
            id = "leave_shop_area",
            rect = { x = 40, y = 120, w = 190, h = 430 },
            label = "Уйти",
            icon = "up",
            knot = "leave_shop",
        },
    },
}

local shop_front = {
    bg = shop_bg("front"),
    label = "Магазин 24/7",
    on_enter = {
        knot = "sunday_shop_arrival",
        condition = function(gs)
            return (not gs.get_flag("met_npc_sunday") and not gs.get_flag("sunday_shop_pre_date_visited"))
                or (gs.get_flag("sunday_after_date_active") and not gs.get_flag("sunday_second_stop_done") and not gs.get_flag("sunday_shop_with_npc_seen"))
        end,
    },
    hotspots = {
        s.pickup{
            id = "shop_drinks",
            rect = { x = 930, y = 365, w = 135, h = 135 },
            label = "Напитки",
            knot = "shop_drinks_interact",
            visible_when = function(gs)
                return not gs.get_flag("sunday_shop_done")
            end,
        },
        s.pickup{
            id = "shop_snacks",
            rect = { x = 705, y = 245, w = 135, h = 135 },
            label = "Снеки",
            knot = "shop_snacks_interact",
            visible_when = function(gs)
                return not gs.get_flag("sunday_shop_done")
            end,
        },
        s.inspect{
            id = "shop_counter",
            rect = { x = 160, y = 405, w = 135, h = 135 },
            label = "Прилавок",
            knot = "shop_counter_interact",
        },
        s.nav_scene{
            id = "to_shop_household",
            rect = { x = 1010, y = 190, w = 170, h = 260 },
            label = "Вглубь",
            icon = "up",
            scene = "shop_household",
        },
        s.nav_scene{
            id = "to_shop_street",
            rect = { x = 500, y = 315, w = 120, h = 210 },
            label = "На улицу",
            icon = "up",
            scene = "shop_street",
        },
    },
}

local shop_household = {
    bg = shop_bg("household"),
    label = "Бытовой отдел",
    hotspots = {
        s.inspect{
            id = "shop_household_goods",
            rect = { x = 710, y = 205, w = 420, h = 315 },
            label = "Хозтовары",
            knot = "shop_household_goods_interact",
        },
        s.inspect{
            id = "shop_cleaning_supplies",
            rect = { x = 60, y = 130, w = 230, h = 470 },
            label = "Уборка",
            knot = "shop_cleaning_supplies_interact",
        },
        s.inspect{
            id = "shop_paper_goods",
            rect = { x = 430, y = 315, w = 270, h = 240 },
            label = "Бумага",
            knot = "shop_paper_goods_interact",
        },
        s.nav_scene{
            id = "to_shop_front",
            rect = { x = 260, y = 250, w = 190, h = 300 },
            label = "К кассе",
            icon = "up",
            scene = "shop_front",
        },
    },
}

return {
    shop_street = shop_street,
    shop_front = shop_front,
    shop_household = shop_household,

    -- Backwards compatibility: poi_shop сейчас может вести в shop_hub.
    shop_hub = shop_street,
}
