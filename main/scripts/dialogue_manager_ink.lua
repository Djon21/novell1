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
local log = require "main.scripts.log"
local sm  = require "main.scripts.save_manager"
local meta = require "main.scripts.meta_state"

local M = {}
local _tag_handlers = {}
local set_story_value

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
local is_story_end     = false
local pending_loop_intro = nil
-- Тип концовки, найденный тегом # loop:end:* до достижения END.
-- nil = обычный chapter_finished (iter 001 и всё что без тега)
-- { type = "false", id = "ending_a" }  или  { type = "true" }
local pending_end_type = nil
local story_knot_index = {}
-- Временные/боковые knot'ы (хотспоты, SMS) запускаются через jump_to_knot.
-- Их обычный -> DONE не должен считаться концом главы. Для сюжетных
-- маршрутов карты можно передать { allow_chapter_end = true }.
local side_knot_active = false

local META_NUMERIC_KEYS = {
    iteration_number     = true,
    completed_iterations = true,
    loop_awareness       = true,
    false_endings_count  = true,
}

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
local restore_scene_transitions = false

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

local function parse_scalar_value(raw)
    if raw == nil then return nil end
    local value = tostring(raw):gsub("^%s+", ""):gsub("%s+$", "")
    if value == "true" then return true end
    if value == "false" then return false end
    if tonumber(value) then return tonumber(value) end
    return value
end

local function current_meta_value(name, default_value)
    if story and story.variables and story.variables[name] ~= nil then
        return story.variables[name]
    end
    if name == "iteration_label" then
        return meta.get_iteration_label()
    end
    return meta.get(name, default_value)
end

local function current_story_day_order()
    if story and story.variables then
        if story.variables.tuesday_started then return 2 end
        if story.variables.monday_started then return 1 end
    end
    return 7 -- Sunday is the base day for initial phone seeds.
end

local function sync_meta_story_value(name, value)
    if not set_story_value or name == "iteration_label" then return end
    set_story_value(name, value, true)
    if name == "iteration_number" then
        local label = string.format("%03d", tonumber(value) or 1)
        set_story_value("iteration_label", label, true)
    end
end

local function resolve_speaker(value)
    if not value or value == "" or value == "none" then return "" end
    if value == "mc"  then return sm.get_mc_name()  end
    if value == "npc" then return sm.get_npc_name() end
    return value   -- literal name
end

local function name_case_forms_for_gender(gender)
    if gender == "female" then
        return {
            mc_name_gen   = "Милы",
            npc_name_gen  = "Артёма",
            mc_name_dat   = "Миле",
            npc_name_dat  = "Артёму",
            mc_name_acc   = "Милу",
            npc_name_acc  = "Артёма",
            mc_name_ins   = "Милой",
            npc_name_ins  = "Артёмом",
            mc_name_prep  = "Миле",
            npc_name_prep = "Артёме",
        }
    end

    return {
        mc_name_gen   = "Артёма",
        npc_name_gen  = "Милы",
        mc_name_dat   = "Артёму",
        npc_name_dat  = "Миле",
        mc_name_acc   = "Артёма",
        npc_name_acc  = "Милу",
        mc_name_ins   = "Артёмом",
        npc_name_ins  = "Милой",
        mc_name_prep  = "Артёме",
        npc_name_prep = "Миле",
    }
end

local function push_name_case_forms(gender, track_in_state)
    if not set_story_value then return end
    for key, value in pairs(name_case_forms_for_gender(gender)) do
        set_story_value(key, value, track_in_state)
    end
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
        elseif (key == "flag" or key == "set_flag") and value and not suppress_effects then
            -- # flag:NAME=VALUE  или  # set_flag:NAME=VALUE
            -- (value: true/false → bool, число → number, иначе string)
            local name, val = value:match("([^=]+)=(.+)")
            if name then
                name = name:gsub("^%s+", ""):gsub("%s+$", "")
                val  = val:gsub("^%s+", ""):gsub("%s+$", "")
                local parsed = parse_scalar_value(val)
                table.insert(pending_commands, { type = "set_flag", flag = name, value = parsed })
            end
        elseif key == "add_item" and value and not suppress_effects then
            -- # add_item:ID  — сокращённый синтаксис для удобства авторов
            local id = value:gsub("^%s+", ""):gsub("%s+$", "")
            if id ~= "" then
                table.insert(pending_commands, { type = "add_item", item = id })
            end
        elseif key == "remove_item" and value and not suppress_effects then
            -- # remove_item:ID  — сокращённый синтаксис
            local id = value:gsub("^%s+", ""):gsub("%s+$", "")
            if id ~= "" then
                table.insert(pending_commands, { type = "remove_item", item = id })
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
            local op, rest = value:match("([%w_]+)%s*:%s*(.+)")
            if (op == "add" or op == "add_hot") and rest then
                local contact, text = rest:match("([^:]+)%s*:%s*(.+)")
                if contact and text then
                    contact = contact:gsub("^%s+", ""):gsub("%s+$", "")
                    -- Убираем крайние кавычки, если автор их поставил.
                    text = text:gsub('^%s*"(.*)"%s*$', "%1")
                               :gsub("^%s*'(.*)'%s*$", "%1")
                    table.insert(pending_commands, {
                        type    = "add_sms",
                        contact = contact,
                        text    = text,
                        opts    = { hot = (op == "add_hot"), current_day = current_story_day_order() },
                    })
                end
            elseif op == "add_old" and rest then
                -- # sms:add_old:CONTACT:TIME:TEXT  — pre-existing message
                -- (уже прочитанное, с готовым временем "пн"/"вчера"/"03:17").
                -- Для seed телефонной истории на старте игры.
                local contact, rest2 = rest:match("([^:]+)%s*:%s*(.+)")
                if contact and rest2 then
                    local time, text = rest2:match("([^:]+)%s*:%s*(.+)")
                    if time and text then
                        contact = contact:gsub("^%s+", ""):gsub("%s+$", "")
                        time    = time:gsub("^%s+", ""):gsub("%s+$", "")
                        text = text:gsub('^%s*"(.*)"%s*$', "%1")
                                   :gsub("^%s*'(.*)'%s*$", "%1")
                        table.insert(pending_commands, {
                            type    = "add_sms",
                            contact = contact,
                            text    = text,
                            opts    = { unread = false, time = time, current_day = current_story_day_order() },
                        })
                    end
                end
            elseif op == "reply_old" and rest then
                -- # sms:reply_old:CONTACT:TIME:TEXT — старое исходящее сообщение
                -- для seed-истории. Не ставит sms_<contact>_replied.
                local contact, rest2 = rest:match("([^:]+)%s*:%s*(.+)")
                if contact and rest2 then
                    local time, text = rest2:match("([^:]+)%s*:%s*(.+)")
                    if time and text then
                        contact = contact:gsub("^%s+", ""):gsub("%s+$", "")
                        time    = time:gsub("^%s+", ""):gsub("%s+$", "")
                        text = text:gsub('^%s*"(.*)"%s*$', "%1")
                                   :gsub("^%s*'(.*)'%s*$", "%1")
                        table.insert(pending_commands, {
                            type    = "reply_old_sms",
                            contact = contact,
                            text    = text,
                            opts    = { time = time, current_day = current_story_day_order() },
                        })
                    end
                end
            elseif op == "reply" and rest then
                -- # sms:reply:contact:текст  — ГГ отвечает на сообщение.
                -- Автоматически ставит sms_<contact>_replied = true.
                local contact, text = rest:match("([^:]+)%s*:%s*(.+)")
                if contact and text then
                    contact = contact:gsub("^%s+", ""):gsub("%s+$", "")
                    text = text:gsub('^%s*"(.*)"%s*$', "%1")
                                :gsub("^%s*'(.*)'%s*$", "%1")
                    table.insert(pending_commands, {
                        type = "reply_sms", contact = contact, text = text,
                        current_day = current_story_day_order(),
                    })
                end
            elseif op == "read" and rest then
                local contact = rest:gsub("^%s+", ""):gsub("%s+$", "")
                if contact ~= "" then
                    table.insert(pending_commands, { type = "mark_sms_read", contact = contact })
                end
            elseif op == "tag" and rest then
                -- # sms:tag:CONTACT:TONE:LABEL  — поставить pin-тег на чат
                -- # sms:tag:CONTACT:TONE       — тег без подписи (просто цвет)
                -- # sms:tag:CONTACT:clear      — снять тег
                -- TONE ∈ {hot, amber, danger, warn, need_reply, clear, none}.
                local contact, tone, label = rest:match("([^:]+)%s*:%s*([^:]+)%s*:%s*(.+)")
                if not contact then
                    contact, tone = rest:match("([^:]+)%s*:%s*(.+)")
                    label = nil
                end
                if contact and tone then
                    contact = contact:gsub("^%s+", ""):gsub("%s+$", "")
                    tone    = tone:gsub("^%s+", ""):gsub("%s+$", "")
                    if label then
                        label = label:gsub('^%s*"(.*)"%s*$', "%1")
                                     :gsub("^%s*'(.*)'%s*$", "%1")
                                     :gsub("^%s+", ""):gsub("%s+$", "")
                    end
                    table.insert(pending_commands, {
                        type    = "set_sms_tag",
                        contact = contact,
                        tone    = tone,
                        label   = label,
                    })
                end
            elseif op == "need_reply" and rest then
                -- # sms:need_reply:CONTACT[:LABEL]  — пин «ждёт ответа».
                -- LABEL опционален (дефолт "ОТВЕТЬ"). Авто-снимается при # sms:reply.
                local contact, label = rest:match("([^:]+)%s*:%s*(.+)")
                if not contact then contact = rest end
                contact = contact:gsub("^%s+", ""):gsub("%s+$", "")
                if label then
                    label = label:gsub('^%s*"(.*)"%s*$', "%1")
                                 :gsub("^%s*'(.*)'%s*$", "%1")
                                 :gsub("^%s+", ""):gsub("%s+$", "")
                end
                if contact ~= "" then
                    table.insert(pending_commands, {
                        type    = "set_sms_tag",
                        contact = contact,
                        tone    = "need_reply",
                        label   = (label and label ~= "") and label or "ОТВЕТЬ",
                    })
                end
            end
        elseif key == "bank" and value and not suppress_effects then
            -- # bank:set:272229
            -- # bank:charge:980:Кофейня «петля»
            -- Баланс и текст SMS банка считает Lua runtime, не Ink.
            local op, rest = value:match("([%w_]+)%s*:%s*(.+)")
            if op == "set" and rest then
                local amount = tonumber((rest:gsub("%s+", "")))
                if amount then
                    table.insert(pending_commands, { type = "bank_set_balance", amount = amount })
                end
            elseif op == "charge" and rest then
                local amount_raw, merchant = rest:match("([^:]+)%s*:%s*(.+)")
                local amount = amount_raw and tonumber((amount_raw:gsub("%s+", ""))) or nil
                if amount and merchant then
                    merchant = merchant:gsub('^%s*"(.*)"%s*$', "%1")
                                       :gsub("^%s*'(.*)'%s*$", "%1")
                                       :gsub("^%s+", ""):gsub("%s+$", "")
                    table.insert(pending_commands, {
                        type = "bank_charge",
                        amount = amount,
                        merchant = merchant,
                    })
                end
            end
        elseif key == "msg" and value and not suppress_effects then
            -- # msg:add:<chat>:<text> | # msg:add_old:<chat>:<time>:<text>
            -- # msg:reply:<chat>:<text> | # msg:reply_old:<chat>:<time>:<text>
            -- # msg:read:<chat>
            -- Параллельный канал к sms — отдельный storage в game_state.
            local op, rest = value:match("([%w_]+)%s*:%s*(.+)")
            if op == "add" and rest then
                local chat, text = rest:match("([^:]+)%s*:%s*(.+)")
                if chat and text then
                    chat = chat:gsub("^%s+", ""):gsub("%s+$", "")
                    text = text:gsub('^%s*"(.*)"%s*$', "%1")
                               :gsub("^%s*'(.*)'%s*$", "%1")
                    table.insert(pending_commands, { type = "add_msg", chat = chat, text = text })
                end
            elseif op == "add_old" and rest then
                -- # msg:add_old:CHAT:TIME:TEXT  — pre-existing message (already read, custom time).
                local chat, rest2 = rest:match("([^:]+)%s*:%s*(.+)")
                if chat and rest2 then
                    local time, text = rest2:match("([^:]+)%s*:%s*(.+)")
                    if time and text then
                        chat = chat:gsub("^%s+", ""):gsub("%s+$", "")
                        time = time:gsub("^%s+", ""):gsub("%s+$", "")
                        text = text:gsub('^%s*"(.*)"%s*$', "%1")
                                   :gsub("^%s*'(.*)'%s*$", "%1")
                        table.insert(pending_commands, {
                            type = "add_msg",
                            chat = chat,
                            text = text,
                            opts = { unread = false, time = time },
                        })
                    end
                end
            elseif op == "reply_old" and rest then
                -- # msg:reply_old:CHAT:TIME:TEXT — старое исходящее сообщение.
                -- Не ставит msg_<chat>_replied и не очищает prompt.
                local chat, rest2 = rest:match("([^:]+)%s*:%s*(.+)")
                if chat and rest2 then
                    local time, text = rest2:match("([^:]+)%s*:%s*(.+)")
                    if time and text then
                        chat = chat:gsub("^%s+", ""):gsub("%s+$", "")
                        time = time:gsub("^%s+", ""):gsub("%s+$", "")
                        text = text:gsub('^%s*"(.*)"%s*$', "%1")
                                   :gsub("^%s*'(.*)'%s*$", "%1")
                        table.insert(pending_commands, {
                            type = "reply_old_msg",
                            chat = chat,
                            text = text,
                            opts = { time = time },
                        })
                    end
                end
            elseif op == "reply" and rest then
                local chat, text = rest:match("([^:]+)%s*:%s*(.+)")
                if chat and text then
                    chat = chat:gsub("^%s+", ""):gsub("%s+$", "")
                    text = text:gsub('^%s*"(.*)"%s*$', "%1")
                               :gsub("^%s*'(.*)'%s*$", "%1")
                    table.insert(pending_commands, { type = "reply_msg", chat = chat, text = text })
                end
            elseif op == "read" and rest then
                local chat = rest:gsub("^%s+", ""):gsub("%s+$", "")
                if chat ~= "" then
                    table.insert(pending_commands, { type = "mark_msg_read", chat = chat })
                end
            elseif op == "tag" and rest then
                -- # msg:tag:CHAT:TONE:LABEL  — pin-тег для мессенджера
                -- # msg:tag:CHAT:clear       — снять тег
                local chat, tone, label = rest:match("([^:]+)%s*:%s*([^:]+)%s*:%s*(.+)")
                if not chat then
                    chat, tone = rest:match("([^:]+)%s*:%s*(.+)")
                    label = nil
                end
                if chat and tone then
                    chat = chat:gsub("^%s+", ""):gsub("%s+$", "")
                    tone = tone:gsub("^%s+", ""):gsub("%s+$", "")
                    if label then
                        label = label:gsub('^%s*"(.*)"%s*$', "%1")
                                     :gsub("^%s*'(.*)'%s*$", "%1")
                                     :gsub("^%s+", ""):gsub("%s+$", "")
                    end
                    table.insert(pending_commands, {
                        type  = "set_msg_tag",
                        chat  = chat,
                        tone  = tone,
                        label = label,
                    })
                end
            elseif op == "need_reply" and rest then
                -- # msg:need_reply:CHAT[:LABEL]  — пин «ждёт ответа», авто-снимается
                -- при # msg:reply:CHAT:...
                local chat, label = rest:match("([^:]+)%s*:%s*(.+)")
                if not chat then chat = rest end
                chat = chat:gsub("^%s+", ""):gsub("%s+$", "")
                if label then
                    label = label:gsub('^%s*"(.*)"%s*$', "%1")
                                 :gsub("^%s*'(.*)'%s*$", "%1")
                                 :gsub("^%s+", ""):gsub("%s+$", "")
                end
                if chat ~= "" then
                    table.insert(pending_commands, {
                        type  = "set_msg_tag",
                        chat  = chat,
                        tone  = "need_reply",
                        label = (label and label ~= "") and label or "ОТВЕТЬ",
                    })
                end
            elseif op == "prompt" and rest then
                -- # msg:prompt:CHAT:KNOT[:LABEL]  — открыть «инициативу» в чате:
                -- pin-бейдж + игнор msg_<chat>_replied + диверт на KNOT при тапе
                -- input'а в чате. LABEL опционален (дефолт "НАПИСАТЬ").
                -- # msg:prompt:CHAT:clear  — снять prompt вручную.
                -- Авто-снимается когда внутри KNOT происходит # msg:reply:CHAT:...
                local chat, knot_or_clear, label = rest:match("([^:]+)%s*:%s*([^:]+)%s*:%s*(.+)")
                if not chat then
                    chat, knot_or_clear = rest:match("([^:]+)%s*:%s*(.+)")
                    label = nil
                end
                if chat and knot_or_clear then
                    chat = chat:gsub("^%s+", ""):gsub("%s+$", "")
                    knot_or_clear = knot_or_clear:gsub("^%s+", ""):gsub("%s+$", "")
                    if label then
                        label = label:gsub('^%s*"(.*)"%s*$', "%1")
                                     :gsub("^%s*'(.*)'%s*$", "%1")
                                     :gsub("^%s+", ""):gsub("%s+$", "")
                    end
                    if knot_or_clear == "clear" or knot_or_clear == "none" then
                        table.insert(pending_commands, {
                            type = "set_msg_prompt", chat = chat, knot = nil,
                        })
                        table.insert(pending_commands, {
                            type = "set_msg_tag", chat = chat, tone = "clear",
                        })
                    else
                        local final_label = (label and label ~= "") and label or "НАПИСАТЬ"
                        table.insert(pending_commands, {
                            type = "set_msg_prompt", chat = chat,
                            knot = knot_or_clear, label = final_label,
                        })
                        table.insert(pending_commands, {
                            type = "set_msg_tag", chat = chat,
                            tone = "need_reply", label = final_label,
                        })
                    end
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
        elseif key == "mail" and value and not suppress_effects then
            -- # mail:add:from:subject        — письмо с темой
            -- # mail:add:from:subject:body   — письмо с отдельным телом
            -- # mail:read                    — пометить все прочитанными
            -- # mail:read:INDEX              — пометить одно (1 = самое свежее)
            local op, rest = value:match("(%a+)%s*:?%s*(.*)")
            if op == "add" and rest and rest ~= "" then
                local from, after = rest:match("([^:]+)%s*:%s*(.+)")
                if from and after then
                    from = from:gsub("^%s+", ""):gsub("%s+$", "")
                    local subject, body = after:match("([^:]+)%s*:%s*(.+)")
                    if not subject then
                        subject = after
                        body    = ""
                    end
                    subject = subject:gsub("^%s+", ""):gsub("%s+$", "")
                                     :gsub('^"(.*)"$', "%1")
                                     :gsub("^'(.*)'$", "%1")
                    body = (body or ""):gsub('^%s*"(.*)"%s*$', "%1")
                                       :gsub("^%s*'(.*)'%s*$", "%1")
                    table.insert(pending_commands, {
                        type    = "add_mail",
                        from    = from,
                        subject = subject,
                        body    = body,
                    })
                end
            elseif op == "read" then
                local rest_trim = (rest or ""):gsub("^%s+", ""):gsub("%s+$", "")
                local idx = tonumber(rest_trim)
                if idx then
                    table.insert(pending_commands, { type = "mark_mail_read", index = idx })
                else
                    table.insert(pending_commands, { type = "mark_all_mail_read" })
                end
            end
        elseif key == "call" and value and not suppress_effects then
            -- # call:in:who      — входящий
            -- # call:out:who     — исходящий
            -- # call:missed:who  — пропущенный (пополняет бейдж)
            -- # call:seen        — «журнал отсмотрен», сброс missed-счётчика
            local op, rest = value:match("(%a+)%s*:?%s*(.*)")
            if op == "seen" then
                table.insert(pending_commands, { type = "mark_all_calls_seen" })
            elseif op and (op == "in" or op == "out" or op == "missed") and rest and rest ~= "" then
                local who = rest:gsub("^%s+", ""):gsub("%s+$", "")
                                :gsub('^"(.*)"$', "%1")
                                :gsub("^'(.*)'$", "%1")
                if who ~= "" then
                    table.insert(pending_commands, {
                        type = "add_call",
                        who  = who,
                        kind = op,
                    })
                end
            end
        elseif key == "clue" and value and not suppress_effects then
            -- # clue:add:id:Label
            local op, rest = value:match("(%a+)%s*:%s*(.+)")
            if op == "add" and rest then
                local id, label = rest:match("([^:]+)%s*:%s*(.+)")
                if id and label then
                    id = id:gsub("^%s+", ""):gsub("%s+$", "")
                    label = label:gsub('^%s*"(.*)"%s*$', "%1")
                                 :gsub("^%s*'(.*)'%s*$", "%1")
                    table.insert(pending_commands, {
                        type  = "add_clue",
                        id    = id,
                        label = label,
                    })
                end
            end
        elseif key == "term" and value and not suppress_effects then
            -- # term:LEVEL:text           — добавить строку
            -- # term:clear                — очистить
            -- # term:defaults             — заново залить дефолтный лог
            -- LEVEL ∈ ok|warn|err|info|prompt|plain
            local op, rest = value:match("(%a+)%s*:?%s*(.*)")
            if op == "clear" then
                table.insert(pending_commands, { type = "clear_terminal" })
            elseif op == "defaults" then
                table.insert(pending_commands, { type = "reset_terminal" })
            elseif op and rest and rest ~= ""
                   and (op == "ok" or op == "warn" or op == "err"
                        or op == "info" or op == "prompt" or op == "plain") then
                local text = rest:gsub("^%s+", ""):gsub("%s+$", "")
                                 :gsub('^"(.*)"$', "%1"):gsub("^'(.*)'$", "%1")
                if text ~= "" then
                    table.insert(pending_commands, {
                        type  = "add_terminal_line",
                        level = op,
                        text  = text,
                    })
                end
            end
        elseif key == "meta" and value and not suppress_effects then
            local op, rest = value:match("(%a+)%s*:%s*(.+)")
            if op == "add" and rest then
                local name, raw_delta = rest:match("([^:]+)%s*:%s*(.+)")
                if name and raw_delta then
                    name = name:gsub("^%s+", ""):gsub("%s+$", "")
                    local delta = tonumber(raw_delta)
                    if delta and META_NUMERIC_KEYS[name] then
                        local current = tonumber(current_meta_value(name, 0)) or 0
                        local next_value = current + delta
                        sync_meta_story_value(name, next_value)
                        table.insert(pending_commands, { type = "meta_add", key = name, delta = delta })
                    end
                end
            elseif op == "set" and rest then
                local name, raw_value = rest:match("([^:]+)%s*:%s*(.+)")
                if name and raw_value then
                    name = name:gsub("^%s+", ""):gsub("%s+$", "")
                    local parsed = parse_scalar_value(raw_value)
                    if META_NUMERIC_KEYS[name] then
                        parsed = tonumber(parsed)
                    end
                    if parsed ~= nil and META_NUMERIC_KEYS[name] then
                        sync_meta_story_value(name, parsed)
                        table.insert(pending_commands, { type = "meta_set", key = name, value = parsed })
                    end
                end
            end
        elseif key == "loop" and value and not suppress_effects then
            -- # loop:end:false:ending_a  — ложная концовка (перезапуск итерации)
            -- # loop:end:true            — истинная концовка (переход в следующую итерацию)
            local op, rest = value:match("^(%a+)%s*:?%s*(.*)")
            if op == "end" and rest then
                local end_type, end_id = rest:match("^(%a+)%s*:?%s*(.*)")
                if end_type == "false" then
                    end_id = end_id:gsub("^%s+", ""):gsub("%s+$", "")
                    pending_end_type = { type = "false", id = (end_id ~= "" and end_id or "unknown") }
                elseif end_type == "true" then
                    pending_end_type = { type = "true" }
                end
            end
        elseif (key == "adv" or key == "ad") and value and not suppress_effects then
            local kind, rest = value:match("([%w_]+)%s*:?%s*(.*)")
            kind = kind or value
            rest = rest and rest:gsub("^%s+", ""):gsub("%s+$", "") or nil
            if kind == "fullscreen" or kind == "interstitial" then
                table.insert(scene_bucket, { type = "show_ad", ad_kind = "fullscreen" })
            elseif kind == "rewarded" then
                table.insert(scene_bucket, {
                    type = "show_ad",
                    ad_kind = "rewarded",
                    reward_flag = rest and rest ~= "" and rest or nil,
                })
            end
        elseif key == "phone" and value == "map" and (not suppress_effects or restore_scene_transitions) then
            table.insert(scene_bucket, { type = "open_phone_app", app = "map" })
        elseif key == "phone" and value == "loop_reset" and not suppress_effects then
            -- # phone:loop_reset — очистить телефонный runtime-слой новой петли.
            -- Не трогает meta-state/выбор персонажа; seed-события вызываются Ink'ом.
            table.insert(pending_commands, { type = "phone_loop_reset" })
        elseif key == "phone" and value and value:match("^app%s*:") and (not suppress_effects or restore_scene_transitions) then
            local app = value:gsub("^app%s*:%s*", ""):gsub("^%s+", ""):gsub("%s+$", "")
                             :gsub('^"(.*)"$', "%1"):gsub("^'(.*)'$", "%1")
            if app ~= "" then
                table.insert(scene_bucket, { type = "open_phone_app", app = app })
            end
        elseif key == "phone" and value == "close" and (not suppress_effects or restore_scene_transitions) then
            -- # phone:close — закрыть телефон и вернуться в сцену-вызыватель.
            table.insert(scene_bucket, { type = "phone_close" })
        elseif key == "hud" and value and not suppress_effects then
            -- # hud:hint:phone   — пульсирует кнопка телефона в HUD
            -- # hud:hint:bag     — пульсирует кнопка инвентаря
            -- # hud:hint:reset   — снимает оба пульса
            local hint = value:match("^hint%s*:%s*(.+)$")
            if hint then
                hint = hint:gsub("^%s+", ""):gsub("%s+$", "")
                table.insert(pending_commands, { type = "hud_hint", target = hint })
            end
        elseif key == "day_transition" and value and not suppress_effects then
            -- Backward-compat: # day_transition:to:DAY переадресуем в новый
            -- splash:day. См. # splash:day:DAY ниже.
            local to_day = value:match("^to%s*:%s*([%w_]+)")
            if to_day then
                to_day = to_day:gsub("^%s+", ""):gsub("%s+$", "")
                table.insert(pending_commands, {
                    type = "splash",
                    variant = "day",
                    day = to_day,
                })
            end
        elseif key == "splash" and value and not suppress_effects then
            -- # splash:day:DAY                 — день: terminal-лог + название
            -- # splash:location:SCENE_ID       — локация: eyebrow + название места
            -- # splash:text:TITLE              — нейтральный title-only
            -- # splash:text:TITLE:SUBTITLE     — title + subtitle
            -- # splash:memory:TEXT             — воспоминание (тёплая палитра)
            -- # splash:alarm:TEXT              — тревога (hot-палитра)
            --
            -- ВАЖНО: пишем в pending_commands напрямую (не в scene_bucket).
            -- Иначе при тегах в knot'е без текста (trailing=true) splash
            -- уехал бы в deferred и сработал ПОСЛЕ текста следующей сцены.
            local op, rest = value:match("^([%w_]+)%s*:?%s*(.*)$")
            op = op and op:gsub("^%s+", ""):gsub("%s+$", "")
            rest = rest and rest:gsub("^%s+", ""):gsub("%s+$", "")

            if op == "day" and rest and rest ~= "" then
                table.insert(pending_commands, {
                    type = "splash", variant = "day", day = rest,
                })
            elseif op == "location" and rest and rest ~= "" then
                table.insert(pending_commands, {
                    type = "splash", variant = "location", scene_id = rest,
                })
            elseif (op == "text" or op == "memory" or op == "alarm" or op == "generic")
                   and rest and rest ~= "" then
                -- text/memory/alarm/generic могут иметь "TITLE:SUBTITLE" формат
                local title, subtitle = rest:match("^([^:]+):(.+)$")
                if not title then title = rest end
                title = title:gsub("^%s+", ""):gsub("%s+$", "")
                if subtitle then subtitle = subtitle:gsub("^%s+", ""):gsub("%s+$", "") end
                local variant = (op == "text") and "generic" or op
                table.insert(pending_commands, {
                    type = "splash",
                    variant = variant,
                    title = title,
                    subtitle = subtitle,
                })
            end
        elseif key == "transit" and value and not suppress_effects then
            -- # transit:start:TITLE[:SUBTITLE[:EYEBROW]]  — атмосферный overlay
            -- который висит ПОВЕРХ bg сцены, но НЕ закрывает dialogue. Не блокирует
            -- ink — текст продолжает идти. Закрывается тегом `# transit:end`.
            -- Использовать для дорог, монтажей, флешбэков-перебивок.
            local op, rest = value:match("^([%w_]+)%s*:?%s*(.*)$")
            op = op and op:gsub("^%s+", ""):gsub("%s+$", "")
            rest = rest and rest:gsub("^%s+", ""):gsub("%s+$", "")
            if op == "start" and rest and rest ~= "" then
                -- Разбираем title[:subtitle[:eyebrow]]
                local title, after = rest:match("^([^:]+):(.+)$")
                if not title then title = rest end
                local subtitle, eyebrow = nil, nil
                if after then
                    subtitle, eyebrow = after:match("^([^:]+):(.+)$")
                    if not subtitle then subtitle = after end
                end
                title = title:gsub("^%s+", ""):gsub("%s+$", "")
                if subtitle then subtitle = subtitle:gsub("^%s+", ""):gsub("%s+$", "") end
                if eyebrow then eyebrow = eyebrow:gsub("^%s+", ""):gsub("%s+$", "") end
                table.insert(pending_commands, {
                    type = "transit_start",
                    title = title,
                    subtitle = subtitle,
                    eyebrow = eyebrow,
                })
            elseif op == "end" then
                table.insert(pending_commands, { type = "transit_end" })
            end
        elseif key == "scene_char" and value and not suppress_effects then
            -- # scene_char:show:SCENE:CHAR   — показать персонажа на фоне сцены
            -- # scene_char:hide:SCENE:CHAR   — спрятать
            -- # scene_char:hide_all          — спрятать всех
            local op, rest = value:match("^([%w_]+)%s*:?%s*(.*)$")
            if op == "hide_all" then
                table.insert(pending_commands, { type = "scene_char_hide_all" })
            elseif (op == "show" or op == "hide") and rest and rest ~= "" then
                local scene_id, char_id = rest:match("^([%w_]+)%s*:%s*([%w_]+)$")
                if scene_id and char_id then
                    table.insert(pending_commands, {
                        type = "scene_char_" .. op,
                        scene = scene_id,
                        char  = char_id,
                    })
                end
            end
        elseif key == "map" and value and (not suppress_effects or restore_scene_transitions) then
            -- # map:allow:poi_cafe       — добавить POI в allow-set phone_map'а
            -- # map:allow:reset          — очистить allow-set (все POI разрешены)
            -- # map:lock_to:poi_cafe     — clear + добавить (только этот разрешён)
            -- # map:lock_all             — заблокировать все POI
            -- # map:lock:all             — то же самое, более читаемый вариант
            -- # map:hub: больше не поддерживается (standalone map_v2 удалён).
            local op, rest = value:match("([%w_]+)%s*:?%s*(.*)")
            if op == "allow" and rest then
                local target = rest:gsub("^%s+", ""):gsub("%s+$", "")
                if target == "reset" or target == "" then
                    table.insert(pending_commands, { type = "map_allow_reset" })
                else
                    table.insert(pending_commands, { type = "map_allow", poi = target })
                end
            elseif op == "lock_to" and rest then
                local target = rest:gsub("^%s+", ""):gsub("%s+$", "")
                table.insert(pending_commands, { type = "map_lock_to", poi = target })
            elseif op == "lock_all" or (op == "lock" and rest and rest:gsub("^%s+", ""):gsub("%s+$", "") == "all") then
                table.insert(pending_commands, { type = "map_lock_all" })
            end
        elseif (key == "goto_scene" or key == "explore") and value and (not suppress_effects or restore_scene_transitions) then
            -- # goto_scene:SCENE_ID  или  # explore:SCENE_ID
            -- Inline (у текстового параграфа) → сразу. Висячий → deferred.
            table.insert(scene_bucket, { type = "enter_scene", scene = value })
        elseif key == "return_to_scene" and (not suppress_effects or restore_scene_transitions) then
            -- # return_to_scene — вернуть управление в последнюю exploration-сцену.
            -- Обычно висит в конце knot'а → попадает в deferred и срабатывает
            -- когда игрок прочитает все параграфы монолога.
            table.insert(scene_bucket, { type = "return_to_scene" })
        else
            local h = _tag_handlers[key]
            if h then
                h(value, trailing, {
                    pending_commands = pending_commands,
                    pending_effects  = pending_effects,
                    scene_bucket     = scene_bucket,
                    deferred_commands = deferred_commands,
                })
            end
        end
    end
end

-- -------------------------------------------------------
-- Синхронизация переменных с save_manager
-- -------------------------------------------------------

set_story_value = function(name, value, track_in_state)
    if not story then return end
    if track_in_state and story.assign_value then
        story.assign_value(name, value)
    else
        story.variables[name] = value
    end
end

-- Выставляет внешние Ink-переменные из save/meta state.
-- track_in_state=true нужен при старте новой игры: тогда значения попадут
-- в story.get_state() через defold-ink replay history и не потеряются на Continue.
local function push_vars_to_ink(track_in_state)
    if not story then return end

    local gender = sm.get_gender() or "male"
    set_story_value("mc_gender", gender, track_in_state)
    set_story_value("mc_name", sm.get_mc_name(), track_in_state)
    set_story_value("npc_name", sm.get_npc_name(), track_in_state)
    push_name_case_forms(gender, track_in_state)
    set_story_value("iteration_number",    meta.get("iteration_number", 1),    track_in_state)
    set_story_value("iteration_label",     meta.get_iteration_label(),          track_in_state)
    set_story_value("loop_awareness",      meta.get("loop_awareness", 0),       track_in_state)
    set_story_value("completed_iterations",meta.get("completed_iterations", 0), track_in_state)
    set_story_value("false_endings_count", meta.get_false_endings_count(),      track_in_state)
end

local function set_inventory_story_context(ctx)
    if not story or not set_story_value then
        return
    end
    ctx = ctx or {}
    set_story_value("inventory_item_id", ctx.item_id or "", true)
    set_story_value("inventory_item_name", ctx.item_name or "", true)
    set_story_value("inventory_item_verb", ctx.verb or "", true)
    set_story_value("inventory_scene_id", ctx.scene_id or "", true)
    set_story_value("inventory_target_id", ctx.target_id or "", true)
    set_story_value("inventory_target_kind", ctx.target_kind or "", true)
end

-- Для старых сейвов (созданных до фикса assign_value) обогащаем replay history
-- внешними переменными перед restore(). Так restore построит текущую пачку
-- параграфов уже с правильными meta/run vars, а не с дефолтами из .ink.
local function build_restore_history(saved_state)
    local history = {
        input = {},
        randoms = saved_state and saved_state.randoms or {},
    }

    local injected = {
        { name = "mc_gender", value = sm.get_gender() or "male" },
        { name = "mc_name", value = sm.get_mc_name() },
        { name = "npc_name", value = sm.get_npc_name() },
        { name = "iteration_number",    value = meta.get("iteration_number", 1) },
        { name = "iteration_label",     value = meta.get_iteration_label() },
        { name = "loop_awareness",      value = meta.get("loop_awareness", 0) },
        { name = "completed_iterations",value = meta.get("completed_iterations", 0) },
        { name = "false_endings_count", value = meta.get_false_endings_count() },
    }

    local form_values = name_case_forms_for_gender(sm.get_gender() or "male")
    for key, value in pairs(form_values) do
        table.insert(injected, { name = key, value = value })
    end

    for _, entry in ipairs(injected) do
        table.insert(history.input, entry)
    end

    if saved_state and saved_state.input then
        for _, entry in ipairs(saved_state.input) do
            table.insert(history.input, entry)
        end
    end

    return history
end

-- Читает mc_gender из Ink обратно в save_manager, если там изменилось
-- (после выбора пола в .ink — `~ mc_gender = "female"`).
-- Также сохраняет выбор в meta_state, чтобы он пережил sm.new_game()
-- при переходе на следующую итерацию.
local function pull_gender_from_ink()
    if not story then return end
    local ink_gender = story.variables.mc_gender
    if ink_gender and ink_gender ~= sm.get_gender() then
        sm.set_gender(ink_gender)
        meta.set("mc_gender", ink_gender)   -- сохраняем навсегда (между итерациями)
        -- Пол изменился → подменяем имена в Ink (mc_name/npc_name
        -- пересчитываются save_manager'ом автоматически).
        story.variables.mc_name  = sm.get_mc_name()
        story.variables.npc_name = sm.get_npc_name()
        push_name_case_forms(ink_gender, false)
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
        -- bg_image хранится в локальном состоянии wrapper'а и не входит
        -- в ink.get_state(). Если игрок сохранился через несколько пачек
        -- после `# bg:`-тега, replay при load_saved не восстановит фон
        -- (re-apply идёт только для текущей пачки). Сохраняем явно.
        bg_image = bg_image,
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

local function build_story_knot_index(json_bytes)
    local index = {}
    local ok, decoded = pcall(json.decode, json_bytes)
    if not ok or type(decoded) ~= "table" then
        log.warn("dm", "failed to decode story JSON for knot index")
        return index
    end

    local root = decoded.root
    local knot_map = type(root) == "table" and root[3] or nil
    if type(knot_map) ~= "table" then
        log.warn("dm", "story JSON has no top-level knot map")
        return index
    end

    for key, _ in pairs(knot_map) do
        if type(key) == "string" then
            index[key] = true
        end
    end

    return index
end

function M.init(json_bytes)
    json_source       = json_bytes
    story             = create_story(json_bytes)
    story_knot_index  = build_story_knot_index(json_bytes)
    paragraph_queue   = {}
    current_index     = 1
    current_answers   = nil
    pending_question  = nil
    finished          = false
    is_story_end      = false
    pending_end_type  = nil
    side_knot_active  = false
    bg                = { r = 0, g = 0, b = 0 }
    bg_image          = nil
    current_speaker   = ""

    pending_effects   = {}
    pending_commands  = {}
    deferred_commands = {}

    sm.load()
    meta.init()
    pending_loop_intro = build_loop_intro()
    push_vars_to_ink(true)
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
    --   новый: { ink = <state>, index = <n>, bg_image = <name> }
    --   старый (до фикса позиции): сам <state>
    local ink_history, saved_index, saved_bg_image
    if saved.ink then
        ink_history = saved.ink
        saved_index = saved.index or 1
        saved_bg_image = saved.bg_image
    else
        ink_history = saved
        saved_index = 1
        saved_bg_image = nil
    end
    local saved_index_raw = saved_index

    json_source       = json_bytes
    story             = create_story(json_bytes)
    story_knot_index  = build_story_knot_index(json_bytes)
    paragraph_queue   = {}
    current_index     = 1
    current_answers   = nil
    pending_question  = nil
    finished          = false
    is_story_end      = false
    pending_end_type  = nil
    side_knot_active  = false
    bg                = { r = 0, g = 0, b = 0 }
    bg_image          = nil
    current_speaker   = ""

    -- Восстанавливаем ink по истории input'ов. Во время restore apply_tags
    -- будет срабатывать на всех параграфах старой пачки — глушим эффекты,
    -- чтобы не сыпались sfx/shake от прошлых сцен.
    suppress_effects = true
    restore_scene_transitions = true
    local restore_history = build_restore_history(ink_history)
    local ok, paragraphs, answers = pcall(story.restore, restore_history, false)
    if not ok then
        suppress_effects = false
        restore_scene_transitions = false
        log.info("dm", "restore failed: " .. tostring(paragraphs) .. " — начинаем сначала")
        M.init(json_bytes)
        return
    end

    pull_gender_from_ink()
    push_vars_to_ink(false)
    consume_continue(paragraphs, answers)

    -- ink.restore() возвращает в начало последней пачки. Чтобы попасть
    -- ровно на тот параграф, где игрок остановился — прокручиваем
    -- current_index до saved_index, попутно применяя теги.
    if saved_index > 1 then
        local max_idx = #paragraph_queue
        local replay_to = saved_index
        if replay_to > max_idx then replay_to = max_idx end
        for i = 2, replay_to do
            if paragraph_queue[i] then
                apply_tags(paragraph_queue[i].tags)
            end
        end
        current_index = saved_index_raw
    end
    suppress_effects = false
    restore_scene_transitions = false
    pending_effects  = {}  -- на всякий случай

    -- Если replay тегов текущей пачки не выставил bg_image (тег `# bg:` был
    -- в предыдущей пачке до сейв-точки) — берём сохранённое значение явно.
    -- Иначе диалог после загрузки идёт без фона до следующего `# bg:`.
    if (not bg_image or bg_image == "") and saved_bg_image and saved_bg_image ~= "" then
        bg_image = saved_bg_image
    end

    if saved_index_raw > #paragraph_queue then
        for _, cmd in ipairs(deferred_commands) do
            table.insert(pending_commands, cmd)
        end
        deferred_commands = {}
    else
        pending_commands = {}
    end

    -- Синхронизируем лог-флаги (чтобы первое изменение после рестарта
    -- корректно залоггировалось).
    last_logged_flags.TRUST   = story.variables.TRUST   or 0
    last_logged_flags.INSIGHT = story.variables.INSIGHT or 0
    last_logged_flags.SYNC    = story.variables.SYNC    or 0
end

function M.has_knot(knot_name)
    return story_knot_index[knot_name] == true
end

-- Регистрирует кастомный обработчик Ink-тега.
-- handler(value, trailing, ctx) где ctx = {
--   pending_commands, pending_effects, scene_bucket, deferred_commands
-- }
function M.register_tag(key, handler)
    if type(key) ~= "string" or key == "" then
        log.warn("dm", "register_tag: invalid key", tostring(key))
        return
    end
    if type(handler) ~= "function" then
        log.warn("dm", "register_tag: handler must be a function for key", key)
        return
    end
    _tag_handlers[key] = handler
end

-- Dev/testing helper: принудительно выставить Ink-переменную перед прыжком
-- в checkpoint. В обычном сценарии переменные меняет только Ink.
function M.set_var(name, value, track_in_state)
    if not name or name == "" then return false end
    local ok, err = pcall(set_story_value, name, value, track_in_state == true)
    if not ok then
        log.warn("dm", "dev set_var failed:", tostring(name), tostring(err))
        return false
    end
    return true
end

function M.save_state()
    save_ink_state()
end

function M.set_inventory_action_context(ctx)
    set_inventory_story_context(ctx)
end

-- Возвращает true, если текущий параграф — последний в текущей пачке
-- из Continue(). Используется ui_manager_v2 для паузы SKIP-режима
-- на последней реплике перед сменой контекста (choice / end / следующая
-- пачка), чтобы дать игроку время выключить SKIP вручную.
function M.is_last_in_queue()
    return current_index >= #paragraph_queue
end

function M.is_story_end()
    return is_story_end
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

        local et = pending_end_type
        pending_end_type = nil  -- сбрасываем сразу

        if et and et.type == "false" then
            side_knot_active = false
            log.info("dm", "END: false ending '" .. tostring(et.id) .. "'")
            msg.post("#ui_manager_v2", "false_ending", { id = et.id })
        elseif et and et.type == "true" then
            side_knot_active = false
            log.info("dm", "END: true ending")
            msg.post("#ui_manager_v2", "true_ending")
        elseif side_knot_active then
            side_knot_active = false
            log.info("dm", "END: side knot DONE, chapter finish suppressed")
        else
            -- Нет тега — обычный конец (итерация 001 или неразмеченный knot)
            log.info("dm", "END: chapter_finished")
            msg.post("#ui_manager_v2", "chapter_finished")
        end
    end

    return false
end

function M.choose(option_index)
    if not current_answers then return false end
    local ans = current_answers[option_index]
    if not ans then return false end

    -- Лог выбранного варианта — удобно отслеживать ветвления в консоли.
    log.info("dm", "выбор: [" .. option_index .. "] " .. tostring(ans.text))

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
    side_knot_active = false
    if json_source then M.init(json_source) end
end

-- Прыжок в ink-узел (knot) по имени. Используется scene_controller'ом
-- через request_ink_knot — когда игрок кликает по hotspot с
-- { type="ink_knot", knot="..." } и надо показать короткий монолог.
function M.jump_to_knot(knot_name, opts)
    if not story then return end
    opts = opts or {}
    side_knot_active = not opts.allow_chapter_end
    is_story_end = false
    pending_end_type = nil
    local paragraphs, answers = story.jump(knot_name)
    pull_gender_from_ink()
    consume_continue(paragraphs, answers)
    log_flags_if_changed()
    save_ink_state()
end

return M
