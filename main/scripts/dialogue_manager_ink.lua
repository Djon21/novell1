-- dialogue_manager_ink.lua
-- Движок диалогов на базе defold-ink. Оборачивает ink.story в интерфейс,
-- который ждёт novel_ui.gui_script (тот же API, что был у старого
-- dialogue_manager.lua на story_data.lua), чтобы UI-скрипт не пришлось
-- переписывать при миграции на Ink.
--
-- Интерфейс (совместим с dialogue_manager.lua):
--   M.init(json_bytes)          — начать новую игру
--   M.load_saved(json_bytes)    — восстановить сохранение
--   M.get_current_node()        — текущий узел UI: { type, character, text, question, options }
--   M.get_background()          — { r, g, b }
--   M.get_background_image()    — имя атласа фона или nil
--   M.advance()                 — перейти к следующему параграфу/узлу
--   M.choose(i)                 — выбрать вариант (1-based)
--   M.restart()                 — начать сначала (тот же json)
--
-- ВАЖНО: require top-level, БЕЗ pcall — см. memory/defold_vn_setup.md
-- «КРИТИЧНО: require из зависимостей — ТОЛЬКО top-level».

local ink = require "ink.story"
local sm  = require "main.scripts.save_manager"

local M = {}

-- -------------------------------------------------------
-- Внутреннее состояние
-- -------------------------------------------------------
local story            = nil       -- ink story object
local json_source      = nil       -- байты .json для restart()
local paragraph_queue  = {}        -- пул параграфов из последнего continue()
local current_index    = 1         -- индекс текущего параграфа в queue
local current_answers  = nil       -- массив вариантов (если есть choice)
local pending_question = nil       -- текст-вопрос перед choice (последний paragraph)
local finished         = false     -- Ink истёк до END

-- Состояние, накапливаемое из тегов
local bg               = { r = 0, g = 0, b = 0 }
local bg_image         = nil
local current_speaker  = ""        -- имя говорящего (или "" для нарратива)

-- -------------------------------------------------------
-- Парсинг тегов
-- Поддерживаемые теги в параграфах:
--   # bg:NAME           — картинка фона (bg_metro, bg_bedroom, ...)
--   # color:R,G,B       — цвет фона под картинкой (0..1)
--   # speaker:NAME      — имя говорящего. Спец-значения:
--                           mc   → подставляется sm.get_mc_name()
--                           npc  → подставляется sm.get_npc_name()
--                           none → очистить (нарратив)
-- -------------------------------------------------------
local function parse_tag(raw)
    if not raw then return nil, nil end
    local s = raw:gsub("^%s+", ""):gsub("%s+$", "")
    local colon = s:find(":")
    if not colon then return s, nil end
    local key = s:sub(1, colon - 1):gsub("%s+$", "")
    local val = s:sub(colon + 1):gsub("^%s+", ""):gsub("%s+$", "")
    return key, val
end

local function resolve_speaker(value)
    if not value or value == "" or value == "none" then return "" end
    if value == "mc"  then return sm.get_mc_name()  end
    if value == "npc" then return sm.get_npc_name() end
    return value   -- литеральное имя
end

-- Применяет теги к текущему состоянию (bg/color/speaker)
local function apply_tags(tags)
    if not tags then return end
    for _, raw in ipairs(tags) do
        local key, value = parse_tag(raw)
        if key == "bg" then
            bg_image = (value == "" or value == "none") and nil or value
        elseif key == "color" and value then
            local r, g, b = value:match("([%d%.%-]+)%s*,%s*([%d%.%-]+)%s*,%s*([%d%.%-]+)")
            if r then
                bg = { r = tonumber(r), g = tonumber(g), b = tonumber(b) }
            end
        elseif key == "speaker" then
            current_speaker = resolve_speaker(value)
        end
    end
end

-- -------------------------------------------------------
-- Синхронизация переменных с save_manager
-- -------------------------------------------------------

-- Выставляет Ink-переменные из save_manager (при init / load / после рестарта)
local function push_vars_to_ink()
    if not story then return end
    story.variables.mc_gender = sm.get_gender() or "male"
    story.variables.mc_name   = sm.get_mc_name()
    story.variables.npc_name  = sm.get_npc_name()
end

-- Читает mc_gender из Ink обратно в save_manager, если там изменилось
-- (после выбора пола в .ink — `~ mc_gender = "female"`).
local function pull_gender_from_ink()
    if not story then return end
    local ink_gender = story.variables.mc_gender
    if ink_gender and ink_gender ~= sm.get_gender() then
        sm.set_gender(ink_gender)
        -- Пол изменился → подменяем имена в Ink (mc_name/npc_name
        -- пересчитываются save_manager'ом автоматически).
        story.variables.mc_name  = sm.get_mc_name()
        story.variables.npc_name = sm.get_npc_name()
    end
end

-- Сохраняет состояние Ink-истории в save_manager.
-- Вместе с ink-state сохраняем и `index` — индекс непрочитанного параграфа
-- внутри текущей пачки, потому что ink.restore() возвращает к началу
-- пачки, а нам надо попасть ровно туда, где игрок остановился.
local function save_ink_state()
    if not story then return end
    sm.set_ink_state({
        ink   = story.get_state(),
        index = current_index,
    })
end

-- Логируем изменения драм-флагов (аналог старого [Save] TRUST=.. INSIGHT=.. SYNC=..)
local last_logged_flags = { TRUST = 0, INSIGHT = 0, SYNC = 0 }
local function log_flags_if_changed()
    if not story then return end
    local t = story.variables.TRUST   or 0
    local i = story.variables.INSIGHT or 0
    local s = story.variables.SYNC    or 0
    if t ~= last_logged_flags.TRUST
    or i ~= last_logged_flags.INSIGHT
    or s ~= last_logged_flags.SYNC then
        print(string.format("[DM-Ink] TRUST=%d  INSIGHT=%d  SYNC=%d", t, i, s))
        last_logged_flags.TRUST, last_logged_flags.INSIGHT, last_logged_flags.SYNC = t, i, s
    end
end

-- -------------------------------------------------------
-- Тяга следующей порции из Ink
-- -------------------------------------------------------

-- Удаляет из конца списка синтетические "пустые параграфы"
-- (defold-ink оборачивает висящие теги в paragraph с text="") — мы
-- применяем их теги и выкидываем из очереди, чтобы не показывать пустые
-- dialogue-узлы игроку.
local function absorb_trailing_tag_paragraphs(paragraphs)
    while #paragraphs > 0 do
        local last = paragraphs[#paragraphs]
        if last.text == "" or last.text == nil then
            -- теги «висячие» — применим к состоянию и выкинем
            apply_tags(last.tags)
            paragraphs[#paragraphs] = nil
        else
            break
        end
    end
end

-- После вызова ink.continue() — раскладывает результат
local function consume_continue(paragraphs, answers)
    paragraphs = paragraphs or {}
    answers    = answers or {}

    -- Висячие теги в конце — поглощаем
    absorb_trailing_tag_paragraphs(paragraphs)

    -- Если есть варианты ответа И последний параграф непустой —
    -- трактуем его как «вопрос» для choice-экрана.
    if #answers > 0 and #paragraphs > 0 then
        local q = paragraphs[#paragraphs]
        pending_question = q
        paragraphs[#paragraphs] = nil
        -- Теги вопроса тоже могут переключать фон/спикера
        -- (применим их уже в момент показа choice)
    else
        pending_question = nil
    end

    paragraph_queue  = paragraphs
    current_index    = 1
    current_answers  = (#answers > 0) and answers or nil
    finished         = (#paragraph_queue == 0) and (current_answers == nil)

    -- Применяем теги первого показываемого узла сразу,
    -- чтобы get_background() уже на рендере вернул актуальное.
    if paragraph_queue[1] then
        apply_tags(paragraph_queue[1].tags)
    elseif pending_question then
        apply_tags(pending_question.tags)
    end
end

-- Обёртка: первый вызов continue() без аргумента — после choice с индексом
local function pull_from_ink(answer)
    if not story then return end

    local paragraphs, answers
    if answer then
        paragraphs, answers = story.continue(answer)
    else
        paragraphs, answers = story.continue()
    end

    -- ВАЖНО: сначала синхронизируем пол из Ink в save_manager, и только
    -- ПОТОМ применяем теги параграфов. Иначе `# speaker:mc` разрезолвится
    -- через sm.get_mc_name() на устаревшем поле и имя «прилипнет» к Артёму,
    -- даже если игрок выбрал Милу (Ink уже успел сменить mc_gender телом
    -- выбора, а save_manager ещё нет).
    pull_gender_from_ink()

    consume_continue(paragraphs, answers)
    log_flags_if_changed()
    save_ink_state()
end

-- -------------------------------------------------------
-- Публичный API
-- -------------------------------------------------------

-- Создать story из сырого JSON (строка, полученная через sys.load_resource)
local function create_story(json_bytes)
    assert(type(json_bytes) == "string" and #json_bytes > 0,
        "[DM-Ink] json_bytes должен быть непустой строкой")
    return ink.create(json_bytes)
end

function M.init(json_bytes)
    json_source       = json_bytes
    story             = create_story(json_bytes)
    paragraph_queue   = {}
    current_index     = 1
    current_answers   = nil
    pending_question  = nil
    finished          = false
    bg                = { r = 0, g = 0, b = 0 }
    bg_image          = nil
    current_speaker   = ""

    sm.load()
    push_vars_to_ink()
    last_logged_flags.TRUST, last_logged_flags.INSIGHT, last_logged_flags.SYNC = 0, 0, 0
    pull_from_ink()           -- первая пачка параграфов
end

function M.load_saved(json_bytes)
    sm.load()
    local saved = sm.get_ink_state()
    if not saved then
        -- нет сохранения — начинаем сначала
        M.init(json_bytes)
        return
    end

    -- Поддерживаем два формата сохранения:
    --   новый: { ink = <state>, index = <n> }
    --   старый (до фикса позиции): сам <state>
    local ink_history, saved_index
    if saved.ink then
        ink_history = saved.ink
        saved_index = saved.index or 1
    else
        ink_history = saved
        saved_index = 1
    end

    json_source       = json_bytes
    story             = create_story(json_bytes)
    paragraph_queue   = {}
    current_index     = 1
    current_answers   = nil
    pending_question  = nil
    finished          = false
    bg                = { r = 0, g = 0, b = 0 }
    bg_image          = nil
    current_speaker   = ""

    push_vars_to_ink()

    -- Восстанавливаем ink по истории input'ов. restore() проигрывает
    -- все выборы/jump'ы/присваивания и возвращает текущую пачку
    -- параграфов + варианты.
    local ok, paragraphs, answers = pcall(story.restore, ink_history, false, true)
    if not ok then
        print("[DM-Ink] restore failed: " .. tostring(paragraphs) .. " — начинаем сначала")
        M.init(json_bytes)
        return
    end

    pull_gender_from_ink()
    consume_continue(paragraphs, answers)

    -- ink.restore() возвращает в начало последней пачки. Чтобы попасть
    -- ровно на тот параграф, где игрок остановился — прокручиваем
    -- current_index до saved_index, попутно применяя теги.
    if saved_index > 1 then
        local max_idx = #paragraph_queue
        if saved_index > max_idx then saved_index = max_idx end
        for i = 2, saved_index do
            if paragraph_queue[i] then
                apply_tags(paragraph_queue[i].tags)
            end
        end
        current_index = saved_index
    end

    -- Синхронизируем лог-флаги (чтобы первое изменение после рестарта
    -- корректно залоггировалось).
    last_logged_flags.TRUST   = story.variables.TRUST   or 0
    last_logged_flags.INSIGHT = story.variables.INSIGHT or 0
    last_logged_flags.SYNC    = story.variables.SYNC    or 0
end

function M.get_current_node()
    -- 1) Есть ещё непоказанные параграфы → dialogue
    if paragraph_queue[current_index] then
        local p = paragraph_queue[current_index]
        return {
            type      = "dialogue",
            character = current_speaker,
            text      = p.text or "",
        }
    end

    -- 2) Параграфы кончились, но есть choice → выводим вопрос + варианты
    if current_answers then
        local question_text = pending_question and pending_question.text or ""
        local options = {}
        for i, a in ipairs(current_answers) do
            options[i] = { text = a.text or "" }
        end
        return {
            type     = "choice",
            question = question_text,
            options  = options,
        }
    end

    -- 3) Ничего нет — END
    return {
        type      = "end",
        character = "",
        text      = "Конец главы",
    }
end

function M.get_background()         return bg       end
function M.get_background_image()   return bg_image end

function M.advance()
    -- Dialogue: идём к следующему параграфу
    if paragraph_queue[current_index] then
        current_index = current_index + 1
        -- применяем теги нового текущего параграфа
        if paragraph_queue[current_index] then
            apply_tags(paragraph_queue[current_index].tags)
        end
        -- Сохраняем позицию внутри пачки — иначе при «Продолжить»
        -- игрок окажется на начале сцены, а не там где вышел.
        save_ink_state()
        return true
    end

    -- Если в этой точке choice — UI должен вызывать M.choose, не M.advance
    if current_answers then
        return false
    end

    -- END — по клику уходим в меню (UI сам это делает)
    return false
end

function M.choose(option_index)
    if not current_answers then return false end
    local ans = current_answers[option_index]
    if not ans then return false end

    -- Лог выбранного варианта — удобно отслеживать ветвления в консоли.
    print("[DM-Ink] выбор: [" .. option_index .. "] " .. tostring(ans.text))

    -- Единственный источник правды — тело выбора в .ink (например:
    --   * [Мила]
    --       ~ mc_gender = "female"
    --       ...
    -- ). После story.continue(i) pull_gender_from_ink() увидит новое
    -- значение Ink-переменной и синхронизирует save_manager.
    pull_from_ink(option_index)
    return true
end

function M.restart()
    if json_source then M.init(json_source) end
end

return M
