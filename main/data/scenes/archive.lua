-- main/data/scenes/archive.lua
-- Сцены AVOS — раздел: archive.
-- См. main/data/scenes/_shared.lua для recipes.

local s = require "main.data.scenes._shared"

return {

    -- Минимальный хаб архива: один фон, осмотр стеллажей, выход через карту.
    archive_hub = {
        bg = "bg_archive_day",
        label = "Архив",
        hotspots = {
            s.inspect{
                id = "archive_shelves",
                rect = { x = 150, y = 100, w = 900, h = 400 },
                label = "Стеллажи",
                icon = "",
                knot = "archive_shelves_interact",
            },
            s.leave{
                id = "leave_archive",
                rect = { x = 0, y = 0, w = 150, h = 200 },
                knot = "leave_archive",
            },
        },
    },

}
