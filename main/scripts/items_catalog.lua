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
}

function M.get(id) return M.items[id] end

function M.get_runtime(id)
    local item = M.items[id]
    if item then
        return item
    end
    if not id or id == "" then
        return nil
    end
    return {
        name = tostring(id),
        type = "runtime",
        source = "game_state",
        iter = "?",
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
