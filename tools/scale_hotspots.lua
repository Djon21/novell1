-- scale_hotspots.lua
-- Скрипт для пересчёта hotspot координат из 960×640 в 1280×720
-- Использование: lua tools/scale_hotspots.lua

local SCALE_X = 1280 / 960  -- 1.333
local SCALE_Y = 720 / 640   -- 1.125

local function scale_rect(rect)
    return {
        x = math.floor(rect.x * SCALE_X + 0.5),
        y = math.floor(rect.y * SCALE_Y + 0.5),
        w = math.floor(rect.w * SCALE_X + 0.5),
        h = math.floor(rect.h * SCALE_Y + 0.5)
    }
end

local function scale_position(x, y)
    return math.floor(x * SCALE_X + 0.5), math.floor(y * SCALE_Y + 0.5)
end

-- Читаем scenes.lua
local file = io.open("main/scripts/scenes.lua", "r")
if not file then
    print("Error: Cannot open main/scripts/scenes.lua")
    os.exit(1)
end

local content = file:read("*all")
file:close()

-- Обновляем комментарий в начале файла
content = content:gsub(
    "rect = { x, y, w, h } %-%- x/y это ЛЕВЫЙ%-НИЖНИЙ угол прямоугольника\n%-%- в коорд%. системе %.gui %(960×640",
    "rect = { x, y, w, h } -- x/y это ЛЕВЫЙ-НИЖНИЙ угол прямоугольника\n-- в коорд. системе .gui (1280×720"
)

-- Функция для замены rect = { x = ..., y = ..., w = ..., h = ... }
local function replace_rect(match)
    local x, y, w, h = match:match("x = ([%d%.]+), y = ([%d%.]+), w = ([%d%.]+), h = ([%d%.]+)")
    if x and y and w and h then
        local old_rect = {x = tonumber(x), y = tonumber(y), w = tonumber(w), h = tonumber(h)}
        local new_rect = scale_rect(old_rect)
        return string.format("x = %d, y = %d, w = %d, h = %d", 
            new_rect.x, new_rect.y, new_rect.w, new_rect.h)
    end
    return match
end

-- Заменяем все rect = { ... }
content = content:gsub("rect = { (x = [^}]+) }", function(inner)
    return "rect = { " .. replace_rect(inner) .. " }"
end)

-- Сохраняем результат
local out = io.open("main/scripts/scenes.lua", "w")
out:write(content)
out:close()

print("✓ Updated main/scripts/scenes.lua")
print("  Scale factors: X=" .. SCALE_X .. ", Y=" .. SCALE_Y)
print("  All hotspot rectangles have been recalculated")
