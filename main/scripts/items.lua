-- items.lua
-- Тонкий фасад, делегирует в items_catalog.lua (новый каталог под Спринт 4+).
-- Сохранён по имени, т.к. на него уже ссылаются novel_ui.gui_script
-- (require "main.scripts.items") и возможные ink-модули.

local catalog = require "main.scripts.items_catalog"

local M = {}
M.items = catalog.items

function M.get(id) return catalog.get(id) end

return M
