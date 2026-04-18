-- items.lua
-- Каталог всех предметов инвентаря. Данные, не код.
--
-- Поля:
--   name        — отображаемое название в модалке
--   icon        — Material Icons символ (UTF-8, codepoint из fonts.google.com/icons)
--   description — текст в модалке при клике по иконке в инвентаре
--   verbs       — список кнопок-действий в модалке.
--                 Каждая: { label, action = { type, ... } }
--                 action.type:
--                   "close"     — просто закрыть модалку
--                   "ink_knot"  — прыгнуть в ink-узел (knot = "...")
--                   "set_flag"  — gs.set_flag(flag, value)
--
-- Чтобы предмет появился в инвентаре игрока, вызвать gs.add_item("<id>")
-- из ink (тег # item:add:id) или из scene-hotspot action:
--   action = { type = "add_item", item = "<id>" }
--
-- NB: телефон в инвентаре НЕ лежит — он отдельная иконка HUD,
-- появляющаяся по флагу has_phone.

local M = {}

M.items = {
    -- Пока пусто. Предметы добавятся в Спринте 4+.
}

function M.get(id) return M.items[id] end

return M
