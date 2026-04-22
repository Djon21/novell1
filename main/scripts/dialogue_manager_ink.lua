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
local meta = require "main.scripts.meta_state"

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
local is_story_end = false
local pending_loop_intro = nil
local warned_missing_loop_vars = false

-- Состояние, накапливаемое из тегов
local bg               = { r = 0, g = 0, b = 0 }
local bg_image         = nil
local current_speaker  = ""        -- имя говорящего (или "" для нарратива)

-- Очередь одноразовых эффектов: { { type="sfx", name=... }, { type="shake", ... }, ... }
-- UI забирает через M.get_effects() и сразу очищает.
local pending_effects  = {}
-- Очередь команд game_state: { {type="set_flag",...}, {type="enter_scene",...} }
-- UI забирает через M.get_commands() и применяет к game_state/scene_controller.
-- В отличие от effects, это не одноразовый визуальный эффект — это команды
-- которые должны исполниться СРАЗУ при обработке параграфа.
local pending_commands = {}
-- «Отложенные» команды смены сцены: enter_scene / return_to_scene из
-- ВИСЯЧИХ тегов (в конце knot'а). Их нельзя применять сразу — игрок
-- не успеет прочитать параграфы монолога. Переливаем в pending_commands
-- в advance() когда paragraph_queue исчерпан.
local deferred_commands = {}
-- Если true — apply_tags не пушит эффекты в очередь. Нужно при
-- load_saved replay'е, чтобы не проигрывать sfx/shake от старых параграфов.
local suppress_effects = false

-- -------------------------------------------------------
-- Парсинг тегов
-- Поддерживаемые теги в параграфах:
--   # bg:NAME            — картинка фона (bg_metro, bg_bedroom, ...)
--   # color:R,G,B        — цвет фона под картинкой (0..1)
--   # speaker:NAME       — имя говорящего. Спец-значения:
--                            mc   → подставляется sm.get_mc_name()
--                            npc  → подставляется sm.get_npc_name()
--                            none → очистить (нарратив)
--   # sfx:NAME           — одноразовый звуковой эффект
--   # shake:INT,DUR      — тряска экрана (интенсивность 0..1, длительность, сек)
--   # pulse:DUR,R,G,B    — вспышка-оверлей (длительность сек, цвет 0..255)
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
    return value   -- literal name
end

local function build_loop_intro()
    local awareness = tonumber(meta.get("loop_awareness", 0)) or 0
    if awareness <= 0 then
        return nil
    end

    local lines = {
        "На секунду приходит ощущение повтора.",
    }

    if awareness >= 2 then
        table.insert(lines, "Память цепляется за это утро раньше, чем должна.")
    end

    return table.concat(lines, "\n")
end

local function apply_meta_text_overrides(text)
    if not text or text == "" then
        return text
    end

    return text:gsub("ИТЕРАЦИЯ%s+001", "ИТЕРАЦИЯ " .. meta.get_iteration_label())
end
-- Применяет теги к текущему состоянию (bg/color/speaker) и кладёт
-- одноразовые эффекты (sfx/shake/pulse) в pending_effects.
-- trailing=true означает что теги взяты из ВИСЯЧЕГО параграфа (в конце
-- knot'а после всех текстовых параграфов). В этом случае команды смены
-- сцены (enter_scene/return_to_scene) откладываются в deferred_commands
-- и выполняются только после того как игрок прочитает все параграфы —
-- иначе монолог не будет показан.
local function apply_tags(tags, trailing)
    if not tags then return end
    local scene_bucket = trailing and deferred_commands or pending_commands
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
        elseif key == "sfx" and value and value ~= "" and not suppress_effects then
            table.insert(pending_effects, { type = "sfx", name = value })
        elseif key == "shake" and value and not suppress_effects then
            local i, d = value:match("([%d%.]+)%s*,%s*([%d%.]+)")
            if i and d then
                table.insert(pending_effects, {
                    type = "shake",
                    intensity = tonumber(i),
                    duration  = tonumber(d),
                })
            end
        elseif key == "pulse" and value and not suppress_effects then
            local d, r, g, b = value:match("([%d%.]+)%s*,%s*([%d%.]+)%s*,%s*([%d%.]+)%s*,%s*([%d%.]+)")
            if d and r and g and b then
                table.insert(pending_effects, {
                    type     = "pulse",
                    duration = tonumber(d),
                    r = tonumber(r) / 255,
                    g = tonumber(g) / 255,
                    b = tonumber(b) / 255,
                })
            end
        elseif key == "flag" and value and not suppress_effects then
            -- # flag:NAME=VALUE  (value: true/false → bool, число → number, иначе string)
            local name, val = value:match("([^=]+)=(.+)")
            if name then
                name = name:gsub("^%s+", ""):gsub("%s+$", "")
                val  = val:gsub("^%s+", ""):gsub("%s+$", "")
                local parsed
                if val == "true" then parsed = true
                elseif val == "false" then parsed = false
                elseif tonumber(val) then parsed = tonumber(val)
                else parsed = val end
                table.insert(pending_commands, { type = "set_flag", flag = name, value = parsed })
            end
        elseif key == "item" and value and not suppress_effects then
            -- # item:add:ID  или  # item:remove:ID
            local op, id = value:match("(%a+)%s*:%s*(.+)")
            if op and id then
                id = id:gsub("^%s+", ""):gsub("%s+$", "")
                if op == "add" then
                    table.insert(pending_commands, { type = "add_item", item = id })
                elseif op == "remove" then
                    table.insert(pending_commands, { type = "remove_item", item = id })
                end
            end
        elseif key == "quest" and value and not suppress_effects then
            -- Поддерживаем два формата:
            --   # quest:ID=STATUS    — задать статус напрямую
            --   # quest:start:ID     — удобный шорткат для active
            --   # quest:done:ID      — шорткат для done
            local op, id = value:match("(%a+)%s*:%s*(.+)")
            if op and id and (op == "start" or op == "done" or op == "fail") then
                id = id:gsub("^%s+", ""):gsub("%s+$", "")
                local status = op == "start" and "active"
                            or op == "done"  and "done"
                            or "failed"
                table.insert(pending_commands, { type = "set_quest", quest = id, status = status })
            else
                local qid, status = value:match("([^=]+)=(.+)")
                if qid then
                    qid    = qid:gsub("^%s+", ""):gsub("%s+$", "")
                    status = status:gsub("^%s+", ""):gsub("%s+$", "")
                    table.insert(pending_commands, { type = "set_quest", quest = qid, status = status })
                end
            end
        elseif key == "sms" and value and not suppress_effects then
            -- # sms:add:contact:текст сообщения
            -- Текст может содержать двоеточия — берём contact и остаток.
            local op, rest = value:match("(%a+)%s*:%s*(.+)")
            if op == "add" and rest then
                local contact, text = rest:match("([^:]+)%s*:%s*(.+)")
                if contact and text then
                    contact = contact:gsub("^%s+", ""):gsub("%s+$", "")
                    -- Убираем крайние кавычки, если автор их поставил.
                    text = text:gsub('^%s*"(.*)"%s*$', "%1")
                               :gsub("^%s*'(.*)'%s*$", "%1")
                    table.insert(pending_commands, { type = "add_sms", contact = contact, text = text })
                end
            end
        elseif key == "note" and value and not suppress_effects then
            -- # note:add:Заголовок:Тело
            local op, rest = value:match("(%a+)%s*:%s*(.+)")
            if op == "add" and rest then
                local title, body = rest:match("([^:]+)%s*:%s*(.+)")
                if title and body then
                    title = title:gsub("^%s+", ""):gsub("%s+$", "")
                    body  = body:gsub('^%s*"(.*)"%s*$', "%1")
                                :gsub("^%s*'(.*)'%s*$", "%1")
                    table.insert(pending_commands, { type = "add_note", title = title, body = body })
                end
            end
        elseif key == "phone" and value == "close" and not suppress_effects then
            -- # phone:close — закрыть телефон и вернуться в сцену-вызыватель.
            table.insert(scene_bucket, { type = "phone_close" })
        elseif (key == "goto_scene" or key == "explore") and value and not suppress_effects then
            -- # goto_scene:SCENE_ID  или  # explore:SCENE_ID
            -- Inline (у текстового параграфа) → сразу. Висячий → deferred.
            table.insert(scene_bucket, { type = "enter_scene", scene = value })
        elseif key == "return_to_scene" and not suppress_effects then
            -- # return_to_scene — вернуть управление в последнюю exploration-сцену.
            -- Обычно висит в конце knot'а → попадает в deferred и срабатывает
            -- когда игрок прочитает все параграфы монолога.
            table.insert(scene_bucket, { type = "return_to_scene" })
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

    local ok = pcall(function()
        story.variables.iteration_number = meta.get("iteration_number", 1)
        story.variables.iteration_label = meta.get_iteration_label()
        story.variables.loop_awareness = meta.get("loop_awareness", 0)
        story.variables.completed_iterations = meta.get("completed_iterations", 0)
    end)

    if not ok and not warned_missing_loop_vars then
        warned_missing_loop_vars = true
        print("[DM-Ink] loop vars are missing in compiled Ink JSON; using runtime fallback text only")
    end
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
            -- теги «висячие» — применим к состоянию и выкинем.
            -- trailing=true → enter_scene/return_to_scene уедут в deferred,
            -- чтобы сработать только после прочтения всех текстовых параграфов.
            apply_tags(last.tags, true)
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

    if pending_loop_intro and paragraph_queue[1] then
        paragraph_queue[1].text = pending_loop_intro .. "\n" .. (paragraph_queue[1].text or "")
        pending_loop_intro = nil
    end

    -- Применяем теги первого показываемого узла сразу,
    -- чтобы get_background() уже на рендере вернул актуальное.
    if paragraph_queue[1] then
        apply_tags(paragraph_queue[1].tags)
    elseif pending_question then
        apply_tags(pending_question.tags)
    end

    -- Если после continue/choose ни параграфов, ни вариантов не осталось
    -- (тело выбора = только висячий тег + -> DONE, напр. `# return_to_scene`
    -- в phone_tasks), нормальный advance() не вызовется и deferred-команды
    -- так и останутся лежать. Переливаем их в pending прямо сейчас, чтобы
    -- ближайший render() подхватил scene_controller.enter/return и не
    -- проскочил в show_end_mode.
    if finished and #deferred_commands > 0 then
        for _, cmd in ipairs(deferred_commands) do
            table.insert(pending_commands, cmd)
        end
        deferred_commands = {}
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
    is_story_end      = false
    bg                = { r = 0, g = 0, b = 0 }
    bg_image          = nil
    current_speaker   = ""

    pending_effects   = {}
    pending_commands  = {}
    deferred_commands = {}

    sm.load()
    meta.init()
    pending_loop_intro = build_loop_intro()
    push_vars_to_ink()
    last_logged_flags.TRUST, last_logged_flags.INSIGHT, last_logged_flags.SYNC = 0, 0, 0
    pull_from_ink()           -- первая пачка параграфов
end

function M.load_saved(json_bytes)
    sm.load()
    meta.init()
    pending_loop_intro = nil
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
    is_story_end      = false
    bg                = { r = 0, g = 0, b = 0 }
    bg_image          = nil
    current_speaker   = ""

    push_vars_to_ink()

    -- Восстанавливаем ink по истории input'ов. Во время restore apply_tags
    -- будет срабатывать на всех параграфах старой пачки — глушим эффекты,
    -- чтобы не сыпались sfx/shake от прошлых сцен.
    suppress_effects = true
    local ok, paragraphs, answers = pcall(story.restore, ink_history, false, true)
    if not ok then
        suppress_effects = false
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
    suppress_effects = false
    pending_effects  = {}  -- на всякий случай
    pending_commands = {}
    deferred_commands = {}

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
            text      = apply_meta_text_overrides(p.text or ""),
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
            question = apply_meta_text_overrides(question_text),
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

-- Принудительно выставить текущий фон. Нужен при knot-jump из сцены
-- point-and-click: чтобы монолог играл на фоне сцены-источника, а не
-- на «последнем ink-фоне» (обычно это apartment_hub/коридор).
function M.override_bg(bg_image_name)
    if bg_image_name then bg_image = bg_image_name end
end

-- Возвращает и очищает очередь одноразовых эффектов. UI должен вызывать
-- этот метод после set_background в каждом render()/advance().
function M.get_effects()
    local e = pending_effects
    pending_effects = {}
    return e
end

-- Возвращает и очищает очередь команд game_state (flag/item/quest/enter_scene).
-- UI забирает в render() и применяет к game_state / scene_controller.
function M.get_commands()
    local c = pending_commands
    pending_commands = {}
    return c
end

function M.advance()
    -- Dialogue: идём к следующему параграфу
    if paragraph_queue[current_index] then
        current_index = current_index + 1
        if paragraph_queue[current_index] then
            -- применяем теги нового текущего параграфа
            apply_tags(paragraph_queue[current_index].tags)
        else
            -- Все параграфы прочитаны — переливаем deferred scene-change
            -- команды в pending. UI подхватит в render() и scene_controller
            -- вернётся в exploration / перейдёт в новую сцену.
            if #deferred_commands > 0 then
                for _, c in ipairs(deferred_commands) do
                    table.insert(pending_commands, c)
                end
                deferred_commands = {}
            end
        end
        -- Сохраняем позицию внутри пачки — иначе при «Продолжить»
        -- игрок окажется на начале сцены, а не там где вышел.
        save_ink_state()
        return true
    end

    -- Если есть выбор — это НЕ конец
    if current_answers then
        return false
    end

    -- Если нет текста и нет выборов → это END
    if not is_story_end then
        is_story_end = true

        print("[DM-Ink] END detected")
        print("[DM-Ink] chapter_finished SENT")
        msg.post("#ui_manager_v2", "chapter_finished")
    end

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
    is_story_end = false
    if json_source then M.init(json_source) end
end

-- Прыжок в ink-узел (knot) по имени. Используется scene_controller'ом
-- через request_ink_knot — когда игрок кликает по hotspot с
-- { type="ink_knot", knot="..." } и надо показать короткий монолог.
function M.jump_to_knot(knot_name)
    if not story then return end
    local paragraphs, answers = story.jump(knot_name)
    pull_gender_from_ink()
    consume_continue(paragraphs, answers)
    log_flags_if_changed()
    save_ink_state()
end

return M
