-- l10n.lua
-- Локализация UI. Язык приходит из Яндекс SDK через window.__gameLang
-- (выставляется в engine_template.html ДО старта Defold).
--
-- Хранение строк: main/data/strings/{ru,en,tr}.json — каждый файл это
-- плоский dict { "key": "value" }. RU — мастер, EN/TR генерируются через
-- нейронку. Файлы должны быть в [project] custom_resources в game.project,
-- иначе sys.load_resource их не найдёт.
--
-- API:
--   M.detect()           — определить язык, выставить M.lang, вернуть его
--   M.init()             — загрузить ru.json + словарь текущего языка
--   M.t(key)             — получить строку (fallback на ru, потом "?key")
--   M.f(key, ...)        — то же + string.format
--   M.set_lang(lang)     — принудительно сменить язык (для тестов / debug)

local log = require "main.scripts.log"

local M = {
    lang     = "ru",
    strings  = {},
    initialized = false,
}

local SUPPORTED = { ru = true, en = true, tr = true }

local function load_lang(lang)
    -- sys.load_resource ждёт путь от корня проекта со слэшем
    local path = "/main/data/strings/" .. lang .. ".json"
    local data = sys.load_resource(path)
    if not data then
        log.warn("l10n", "cannot load " .. path)
        return nil
    end
    local ok, parsed = pcall(json.decode, data)
    if not ok or type(parsed) ~= "table" then
        log.warn("l10n", "cannot parse " .. path .. ": " .. tostring(parsed))
        return nil
    end
    return parsed
end

function M.detect()
    -- В нативной сборке html5 модуля нет → fallback на ru.
    if html5 and html5.run then
        local ok, lang = pcall(html5.run, "window.__gameLang || ''")
        if ok and lang and SUPPORTED[lang] then
            M.lang = lang
            return lang
        end
    end
    M.lang = "ru"
    return M.lang
end

function M.init()
    if M.initialized then return end
    M.detect()
    M.strings.ru = load_lang("ru") or {}
    if M.lang ~= "ru" then
        M.strings[M.lang] = load_lang(M.lang) or {}
    end
    M.initialized = true
    local ru_count = 0
    for _ in pairs(M.strings.ru or {}) do ru_count = ru_count + 1 end
    log.info("l10n", "init lang=" .. tostring(M.lang) .. " ru_keys=" .. tostring(ru_count))
end

function M.set_lang(lang)
    if not SUPPORTED[lang] then
        log.warn("l10n", "unsupported lang " .. tostring(lang))
        return
    end
    M.lang = lang
    if not M.strings[lang] then
        M.strings[lang] = load_lang(lang) or {}
    end
end

function M.t(key)
    if not M.initialized then M.init() end
    local cur = M.strings[M.lang]
    if cur and cur[key] then return cur[key] end
    local ru = M.strings.ru
    if ru and ru[key] then return ru[key] end
    return "?" .. tostring(key)
end

function M.f(key, ...)
    return string.format(M.t(key), ...)
end

return M
