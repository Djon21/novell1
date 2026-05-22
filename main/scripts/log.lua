-- log.lua
-- Единый логгер проекта. Заменяет россыпь print("[system] msg") и
-- per-file `local DEBUG_LOG = false`-флагов.
--
-- Уровни (от высокого к низкому): error → warn → info → debug → trace
-- По умолчанию: info (debug/trace off).
--
-- Использование:
--
--   local log = require "main.scripts.log"
--
--   log.info("ui_manager", "open_phone()")
--   log.warn("phone", "no atlas for bg:", name)
--   log.error("dm", "knot not found:", knot_name)
--   log.debug("dm", "tag", key, value)        -- по умолчанию заглушено
--
-- Управление:
--
--   log.set_level("debug")               — глобальный уровень
--   log.set_filter({"phone", "msg"})     — оставить только эти системы
--   log.set_filter(nil)                  — снять фильтр (все системы)
--   log.silence("game_state")            — заглушить одну систему
--   log.unsilence("game_state")
--
-- Формат вывода:
--   [INFO  ui_manager] open_phone()
--   [WARN  phone] no atlas for bg: bg_foo
--   [ERROR dm] knot not found: foo
--   [DEBUG dm] tag bg apartment_morning

local M = {}

-- ---------------------------------------------------------------------------
-- Levels
-- ---------------------------------------------------------------------------

local LEVELS = {
    error = 1,
    warn  = 2,
    info  = 3,
    debug = 4,
    trace = 5,
}

local LEVEL_LABELS = {
    [1] = "ERROR",
    [2] = "WARN ",
    [3] = "INFO ",
    [4] = "DEBUG",
    [5] = "TRACE",
}

-- Текущий пороговый уровень: всё что выше не печатается.
-- info — разумный default: видно что важно, без debug-spam'а.
local current_level = LEVELS.info

-- Фильтр по системам. nil = пропускать всё. table = whitelist.
local system_filter = nil
local silenced = {}

-- ---------------------------------------------------------------------------
-- Public API: уровни и фильтры
-- ---------------------------------------------------------------------------

function M.set_level(level_name)
    local lvl = LEVELS[level_name]
    if lvl then
        current_level = lvl
    end
end

function M.get_level()
    for name, lvl in pairs(LEVELS) do
        if lvl == current_level then return name end
    end
    return "info"
end

-- whitelist систем; nil/{} = пропускать всё.
function M.set_filter(systems)
    if not systems or (type(systems) == "table" and #systems == 0) then
        system_filter = nil
        return
    end
    if type(systems) == "string" then systems = { systems } end
    local set = {}
    for _, s in ipairs(systems) do set[s] = true end
    system_filter = set
end

function M.silence(system)
    silenced[system] = true
end

function M.unsilence(system)
    silenced[system] = nil
end

-- ---------------------------------------------------------------------------
-- Internal: format + print
-- ---------------------------------------------------------------------------

local function should_emit(level_num, system)
    if level_num > current_level then return false end
    if silenced[system] then return false end
    if system_filter and not system_filter[system] then return false end
    return true
end

local function format_args(...)
    local n = select("#", ...)
    if n == 0 then return "" end
    local parts = {}
    for i = 1, n do
        local v = select(i, ...)
        parts[i] = tostring(v)
    end
    return table.concat(parts, " ")
end

local function emit(level_num, system, ...)
    if not should_emit(level_num, system) then return end
    print(string.format("[%s %s] %s",
        LEVEL_LABELS[level_num] or "?",
        tostring(system or "?"),
        format_args(...)))
end

-- ---------------------------------------------------------------------------
-- Public API: log levels (вызовы)
-- ---------------------------------------------------------------------------

function M.error(system, ...) emit(LEVELS.error, system, ...) end
function M.warn (system, ...) emit(LEVELS.warn,  system, ...) end
function M.info (system, ...) emit(LEVELS.info,  system, ...) end
function M.debug(system, ...) emit(LEVELS.debug, system, ...) end
function M.trace(system, ...) emit(LEVELS.trace, system, ...) end

-- Удобный helper: создаёт scoped logger с заранее заданной системой.
-- Полезно в больших файлах: `local log = require("...").for_system("phone")`
-- → потом log.info("...") вместо log.info("phone", "...").
function M.for_system(system)
    return {
        error = function(...) emit(LEVELS.error, system, ...) end,
        warn  = function(...) emit(LEVELS.warn,  system, ...) end,
        info  = function(...) emit(LEVELS.info,  system, ...) end,
        debug = function(...) emit(LEVELS.debug, system, ...) end,
        trace = function(...) emit(LEVELS.trace, system, ...) end,
    }
end

return M
