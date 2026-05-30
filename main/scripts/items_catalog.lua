-- items_catalog.lua
-- Каталог предметов (новый дизайн HUD — см. .design_hud.html).
-- Поля item:
--   name, type, source, iter, clue ("да"/"нет"), desc
--   verbs = { "use" | "inspect" | "combine" | "read" | "give" }
--   icon — Material Icons (UTF-8 через string.char, Lua 5.1 не поддерживает \u{})
--   qty  — число для badge
--
-- Backwards-compat: старый items.lua отдавал поле `description` — тут оно
-- дублируется как `desc`; и старый рендер item_modal'ки использует оба.

local M = {}
local meta = require "main.scripts.meta_state"

-- Material Icons codepoints (UTF-8 3-byte encoding)
-- кружка (coffee) U+E541 -> EE 95 81
local ICON_MUG     = string.char(0xEE, 0x95, 0x81)
-- смартфон U+E32C -> EE 8C AC, но в HUD уже используется E913 smartphone:
local ICON_PHONE   = string.char(0xEE, 0xA4, 0x93)
-- ключ U+E73C vpn_key -> EE 9C BC
local ICON_KEY     = string.char(0xEE, 0x9C, 0xBC)
-- чашка (local_cafe) U+E541 — используем другое: coffee U+EFEF
local ICON_CUP     = string.char(0xEE, 0xBF, 0xAF)
-- записка (note) U+E06F -> EE 81 AF
local ICON_NOTE    = string.char(0xEE, 0x81, 0xAF)
-- карточка (credit_card) U+E870 -> EE A1 B0
local ICON_CARD    = string.char(0xEE, 0xA1, 0xB0)
-- usb U+E1E0 -> EE 87 A0
local ICON_USB     = string.char(0xEE, 0x87, 0xA0)
-- сигарета (smoking_rooms) U+E7F5 -> EE 9F B5
local ICON_CIG     = string.char(0xEE, 0x9F, 0xB5)
-- деньги (payments) U+EF63 -> EE BD A3
local ICON_CASH    = string.char(0xEE, 0xBD, 0xA3)
-- папка (folder) U+E2C7 -> EE 8B 87
local ICON_FOLDER  = string.char(0xEE, 0x8B, 0x87)
-- щётка / паста: используем близкие Material Icons из приватного диапазона;
-- если в шрифте не окажется глифа, UI всё равно покажет fallback-символ.
local ICON_BRUSH   = string.char(0xEE, 0xA3, 0x8B)
local ICON_PASTE   = string.char(0xEE, 0x90, 0xA9)
-- вода / мусор: близкие Material Icons, fallback допустим
local ICON_WATER   = string.char(0xEE, 0x95, 0x84)
local ICON_TRASH   = string.char(0xEE, 0xA1, 0xB2)
-- Подарки воскресенья. Пока inventory отображает Material Icons, поэтому
-- используем близкие существующие глифы. PNG-иконки — отдельный UI/asset этап.
local ICON_GIFT    = ICON_KEY
local ICON_DRINK   = ICON_WATER
local ICON_SNACK   = ICON_CUP
local ICON_BROOM   = ICON_BRUSH
local ICON_NAPKINS = ICON_NOTE

M.items = {
    mug = {
        name   = "Кружка",
        type   = "расход.",
        source = "кухня",
        iter   = "#017",
        clue   = "нет",
        desc   = "Белая, с трещиной. Выдаётся каждый раз, будто новая.",
        description = "Белая кружка с трещиной. Ты уже брал её сегодня — и вчера.",
        verbs  = { "use", "inspect" },
        icon   = ICON_MUG,
        qty    = 1,
    },
    phone = {
        name   = "Телефон",
        type   = "ключ",
        source = "тумбочка",
        iter   = "#017",
        clue   = "да",
        desc   = "Мой. Вибрирует. Три непрочитанных.",
        description = "Смартфон. Вибрирует от новых сообщений.",
        verbs  = { "use", "inspect", "read" },
        icon   = ICON_PHONE,
        qty    = 1,
    },
    key = {
        name   = "Ключ от квартиры",
        type   = "ключ",
        source = "карман",
        iter   = "#017",
        clue   = "нет",
        desc   = "Металлический. Слегка тёплый — будто только что был в руке.",
        description = "Ключ от квартиры. Тёплый.",
        verbs  = { "use", "inspect" },
        icon   = ICON_KEY,
        qty    = 1,
    },
    cup = {
        name   = "Стакан",
        type   = "расход.",
        source = "кухня",
        iter   = "#017",
        clue   = "нет",
        desc   = "Пустой. Вода. Кажется, ты уже пил из него.",
        description = "Пустой стакан.",
        verbs  = { "use", "inspect" },
        icon   = ICON_CUP,
        qty    = 1,
    },
    note = {
        name   = "Записка",
        type   = "улика",
        source = "стол",
        iter   = "#017",
        clue   = "да",
        desc   = "Мой почерк. Одна строка: \"не выходи до звонка\".",
        description = "Записка твоим почерком: не выходи до звонка.",
        verbs  = { "inspect", "read" },
        icon   = ICON_NOTE,
        qty    = 1,
    },
    card = {
        name   = "Пропуск",
        type   = "ключ",
        source = "карман",
        iter   = "#017",
        clue   = "нет",
        desc   = "«АВОСЬ Системы». Магнитная полоса затёрта до черноты.",
        description = "Рабочий пропуск в офис.",
        verbs  = { "use", "inspect" },
        icon   = ICON_CARD,
        qty    = 1,
    },
    usb = {
        name   = "USB-флешка",
        type   = "улика",
        source = "?",
        iter   = "#017",
        clue   = "да",
        desc   = "Без подписи. На корпусе маркером: «017». Откуда она у меня?",
        description = "Безымянная флешка с цифрой 017.",
        verbs  = { "inspect", "combine" },
        icon   = ICON_USB,
        qty    = 1,
    },
    cig = {
        name   = "Сигарета",
        type   = "расход.",
        source = "кухня",
        iter   = "#017",
        clue   = "нет",
        desc   = "Последняя в пачке. Ты вроде бросил.",
        description = "Одна сигарета.",
        verbs  = { "use", "give" },
        icon   = ICON_CIG,
        qty    = 1,
    },
    cash = {
        name   = "Наличные",
        type   = "расход.",
        source = "бумажник",
        iter   = "#017",
        clue   = "нет",
        desc   = "Примерно 1200 рублей. На метро хватит.",
        description = "Несколько купюр.",
        verbs  = { "use", "give" },
        icon   = ICON_CASH,
        qty    = 1200,
    },

    report_page = {
        name   = "Распечатка кейса",
        type   = "документ",
        source = "рабочий стол",
        iter   = "#017",
        clue   = "нет",
        desc   = "Лист с кратким описанием кейса. Поля заполнены неровно, часть подтверждений отсутствует.",
        description = "Распечатка рабочего кейса с неполными входными данными.",
        verbs  = { "inspect", "read", "combine" },
        icon   = ICON_NOTE,
        qty    = 1,
    },

    folder = {
        name   = "Папка",
        type   = "документ",
        source = "переговорка",
        iter   = "#017",
        clue   = "нет",
        desc   = "Плотная офисная папка для кейсов. Внутри только разделители и слишком аккуратные стикеры.",
        description = "Пустая папка для сборки рабочего кейса.",
        verbs  = { "inspect", "combine" },
        icon   = ICON_FOLDER,
        qty    = 1,
    },


    toothbrush = {
        name   = "Зубная щётка",
        type   = "расход.",
        source = "ванная",
        iter   = "#017",
        clue   = "нет",
        desc   = "Обычная щётка. Самое честное устройство утренней перезагрузки.",
        description = "Зубная щётка из стакана у раковины.",
        verbs  = { "inspect", "combine" },
        icon   = ICON_BRUSH,
        qty    = 1,
    },

    toothpaste = {
        name   = "Зубная паста",
        type   = "расход.",
        source = "ванная",
        iter   = "#017",
        clue   = "нет",
        desc   = "Мятная. Тюбик смят так, будто утро уже пытались начать без тебя.",
        description = "Зубная паста. Почти закончилась, но ещё держится.",
        verbs  = { "inspect", "combine" },
        icon   = ICON_PASTE,
        qty    = 1,
    },

    toothbrush_pasted = {
        name   = "Щётка с пастой",
        type   = "расход.",
        source = "ванная",
        iter   = "#017",
        clue   = "нет",
        desc   = "Готова к самому героическому действию утра.",
        description = "Зубная щётка с пастой.",
        verbs  = { "inspect", "use" },
        icon   = ICON_BRUSH,
        qty    = 1,
    },

    park_trash_cup = {
        name   = "Пустой стаканчик",
        type   = "мусор",
        source = "лавочка у реки",
        iter   = "#017",
        clue   = "нет",
        desc   = "Чужой бумажный стаканчик. Не улика, просто повод не сидеть рядом с мусором.",
        description = "Пустой бумажный стаканчик с лавочки.",
        verbs  = { "use", "inspect" },
        icon   = ICON_TRASH,
        qty    = 1,
    },

    water_bottle = {
        name   = "Бутылка воды",
        type   = "расход.",
        source = "магазин",
        iter   = "#017",
        clue   = "нет",
        desc   = "Холодная вода из магазина. Маленькая забота, если вовремя вспомнить.",
        description = "Бутылка воды.",
        verbs  = { "inspect" },
        icon   = ICON_WATER,
        qty    = 1,
    },

    gift_iced_tea = {
        name   = "Холодный чай",
        type   = "подарок",
        source = "магазин",
        iter   = "#017",
        clue   = "нет",
        desc   = "Бутылка холодного чая. Почти забота, если не говорить слишком уверенно.",
        description = "Холодный чай из магазина перед встречей.",
        verbs  = { "inspect" },
        icon   = ICON_DRINK,
        qty    = 1,
    },

    gift_berry_soda = {
        name   = "Ягодная газировка",
        type   = "подарок",
        source = "магазин",
        iter   = "#017",
        clue   = "нет",
        desc   = "Слишком яркая бутылка. Выглядит как попытка сделать день легче.",
        description = "Ягодная газировка из магазина.",
        verbs  = { "inspect" },
        icon   = ICON_DRINK,
        qty    = 1,
    },

    gift_coffee_can = {
        name   = "Кофе в банке",
        type   = "подарок",
        source = "магазин",
        iter   = "#017",
        clue   = "нет",
        desc   = "Холодный кофе в банке. Удобный, бодрый и немного безличный.",
        description = "Кофе в банке из магазина.",
        verbs  = { "inspect" },
        icon   = ICON_DRINK,
        qty    = 1,
    },

    gift_energy_drink = {
        name   = "Печенье",
        type   = "подарок",
        source = "магазин",
        iter   = "#017",
        clue   = "нет",
        desc   = "Банка печенья. Тёплый подарок, который точно не оставит равнодушным.",
        description = "Печенье из магазина.",
        verbs  = { "inspect" },
        icon   = ICON_DRINK,
        qty    = 1,
    },

    gift_crackers = {
        name   = "Солёные крекеры",
        type   = "подарок",
        source = "магазин",
        iter   = "#017",
        clue   = "нет",
        desc   = "Маленькая пачка крекеров. Слишком практично, чтобы быть романтично, но не бесполезно.",
        description = "Солёные крекеры из магазина.",
        verbs  = { "inspect" },
        icon   = ICON_SNACK,
        qty    = 1,
    },

    gift_chips = {
        name   = "Маленькие чипсы",
        type   = "подарок",
        source = "магазин",
        iter   = "#017",
        clue   = "нет",
        desc   = "Пачка чипсов. Хрустит ещё до того, как её открыли.",
        description = "Маленькая пачка чипсов.",
        verbs  = { "inspect" },
        icon   = ICON_SNACK,
        qty    = 1,
    },

    gift_nuts = {
        name   = "Орешки",
        type   = "подарок",
        source = "магазин",
        iter   = "#017",
        clue   = "нет",
        desc   = "Пакетик орешков. Вежливо маскируется под взрослый выбор.",
        description = "Пакетик орешков из магазина.",
        verbs  = { "inspect" },
        icon   = ICON_SNACK,
        qty    = 1,
    },

    gift_dark_chocolate = {
        name   = "Тёмный шоколад",
        type   = "подарок",
        source = "магазин",
        iter   = "#017",
        clue   = "нет",
        desc   = "Плитка тёмного шоколада. Нормальный подарок, почти слишком нормальный.",
        description = "Тёмный шоколад из магазина.",
        verbs  = { "inspect" },
        icon   = ICON_SNACK,
        qty    = 1,
    },

    gift_milk_chocolate = {
        name   = "Молочный шоколад",
        type   = "подарок",
        source = "магазин",
        iter   = "#017",
        clue   = "нет",
        desc   = "Плитка молочного шоколада. Добрый, простой и немного школьный выбор.",
        description = "Молочный шоколад из магазина.",
        verbs  = { "inspect" },
        icon   = ICON_SNACK,
        qty    = 1,
    },

    gift_waffle_bar = {
        name   = "Вафельный батончик",
        type   = "подарок",
        source = "магазин",
        iter   = "#017",
        clue   = "нет",
        desc   = "Вафельный батончик. Самый короткий путь от неловкости к сахару.",
        description = "Вафельный батончик из магазина.",
        verbs  = { "inspect" },
        icon   = ICON_SNACK,
        qty    = 1,
    },

    gift_keychain_flashlight = {
        name   = "Фонарик-брелок",
        type   = "ключ",
        source = "магазин",
        iter   = "#017",
        clue   = "да",
        desc   = "Маленький фонарик на кольце. Странный подарок, зато с очень ясной функцией: не потеряться.",
        description = "Маленький фонарик-брелок из бытового отдела.",
        verbs  = { "inspect" },
        icon   = ICON_GIFT,
        qty    = 1,
    },

    gift_small_broom = {
        name   = "Веник",
        type   = "подарок",
        source = "магазин",
        iter   = "#017",
        clue   = "нет",
        desc   = "Небольшой веник. Социально рискованный предмет для первого свидания.",
        description = "Небольшой веник из бытового отдела.",
        verbs  = { "inspect" },
        icon   = ICON_BROOM,
        qty    = 1,
    },

    gift_wet_wipes = {
        name   = "Влажные салфетки",
        type   = "подарок",
        source = "магазин",
        iter   = "#017",
        clue   = "нет",
        desc   = "Упаковка влажных салфеток. Забота, которая очень старается выглядеть практично.",
        description = "Влажные салфетки из магазина.",
        verbs  = { "inspect" },
        icon   = ICON_NAPKINS,
        qty    = 1,
    },

    gift_paper_napkins = {
        name   = "Бумажные салфетки",
        type   = "подарок",
        source = "магазин",
        iter   = "#017",
        clue   = "нет",
        desc   = "Пачка бумажных салфеток. На случай, если у дня будут крошки.",
        description = "Бумажные салфетки из магазина.",
        verbs  = { "inspect" },
        icon   = ICON_NAPKINS,
        qty    = 1,
    },

    case_file = {
        name   = "Папка по кейсу",
        type   = "ключ",
        source = "офис",
        iter   = "#017",
        clue   = "нет",
        desc   = "Собранный кейс: распечатка, разделитель, место для решения. Выглядит готово — хотя данных всё ещё мало.",
        description = "Собранная папка по рабочему кейсу.",
        verbs  = { "inspect", "read", "use", "give" },
        icon   = ICON_FOLDER,
        qty    = 1,
    },
}

local function clone_item(item)
    local copy = {}
    for k, v in pairs(item) do
        copy[k] = v
    end
    return copy
end

local function current_iteration_tag()
    local label = meta.get_iteration_label and meta.get_iteration_label() or "001"
    return "#" .. tostring(label)
end

function M.get(id) return M.items[id] end

function M.get_runtime(id)
    local item = M.items[id]
    if item then
        local runtime = clone_item(item)
        if runtime.iter == "#017" then
            runtime.iter = current_iteration_tag()
        end
        return runtime
    end
    if not id or id == "" then
        return nil
    end
    return {
        name = tostring(id),
        type = "runtime",
        source = "game_state",
        iter = current_iteration_tag(),
        clue = "нет",
        desc = "Предмет есть в inventory state, но для него нет описания в items_catalog.lua.",
        description = "Добавьте item_id '" .. tostring(id) .. "' в main/scripts/items_catalog.lua.",
        verbs = { "inspect" },
        icon = "?",
        qty = 1,
        missing = true,
    }
end

return M
