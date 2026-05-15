-- dialogue_orchestrator.lua
-- Сердце ui_manager_v2: разруливает что показывать игроку после изменения
-- состояния ink (новый параграф / choice / end). Раньше функция жила в
-- ui_manager_v2.script на 125 строк и была самой запутанной частью.
--
-- Что делает:
--   1) cancel autoplay если он был запланирован
--   2) применяет накопленные dm-команды (могут поменять сцену / phone / map)
--   3) если открыт map/phone — прячет dialogue+choice (модалки поверх)
--   4) если в exploration — фон от scene_controller, иначе берём из dm
--   5) consume effects (sfx/shake/pulse)
--   6) рендерит current node:
--      - dialogue: render_dialogue + nudge skip
--      - choice  : show_choice (или авто-выбор персонажа в iter 2+)
--      - end     : шлёт chapter_finished если это не финал story
--
-- Контракт ctx:
--
--   ctx.M                      — таблица состояния (overlays/at_end/components/base_mode)
--   ctx.dbg                    — function(...)
--   ctx.cancel_autoplay        — function(self)
--   ctx.reset_autoplay_state   — function(self)
--   ctx.apply_dm_commands      — function(self) → bool (true = scene поменялась)
--   ctx.consume_dm_effects     — function()
--   ctx.hide_choice            — function(self)
--   ctx.show_dialogue          — function(self)
--   ctx.show_exploration       — function(self)
--   ctx.show_choice            — function(self, opts, timer_sec, title)
--   ctx.post_dialogue_bg       — function(self, bg_name)
--   ctx.post_location_to_ui    — function(label)
--   ctx.resolve_location_label — function(bg_name) → string
--   ctx.append_dialogue_backlog — function(self, entry)
--   ctx.nudge_dialogue_skip    — function(self)

local dm = require "main.scripts.dialogue_manager_ink"
local sm = require "main.scripts.save_manager"
local meta = require "main.scripts.meta_state"
local scene_controller = require "main.scripts.scene_controller"

local M = {}

-- Авто-выбор персонажа: если пол уже сохранён (итерация 2+), пропускаем
-- choose_character без показа игроку. Определяем по наличию вариантов
-- "Артём" и "Мила" (ровно 2 варианта).
local function try_auto_pick_character(node)
    local saved_gender = sm.get_gender()
    if not saved_gender then return false end
    if (meta.get("iteration_number", 1) or 1) <= 1 then return false end

    local opts = node.options or {}
    if #opts ~= 2 then return false end

    local has_artem = (opts[1].text == "Артём" or opts[2].text == "Артём")
    local has_mila  = (opts[1].text == "Мила"  or opts[2].text == "Мила")
    if not (has_artem and has_mila) then return false end

    for i, opt in ipairs(opts) do
        local is_female_opt = (opt.text == "Мила")
        if (saved_gender == "female") == is_female_opt then
            dm.choose(i)
            return true
        end
    end
    return false
end

function M.update(self, ctx)
    ctx.cancel_autoplay(self)

    -- 1) Применить команды из ink-тегов (могут поменять сцену / открыть модалку)
    local cmds_paused_render = ctx.apply_dm_commands(self)

    -- 1a) Проверить overlay-состояние ПОСЛЕ apply_dm_commands: команды могли
    -- открыть phone/map. Нужно сделать ДО early-return на cmds_paused_render —
    -- иначе при цепочке `# phone:app:X` + `# return_to_scene` мы возвращаемся,
    -- не спрятав dialogue/hotspots, и они остаются торчать на фоне модалки.
    local UI = ctx.M
    if UI.overlays.map then
        UI.at_end = false
        msg.post(UI.components.dialogue, "hide_dialogue")
        ctx.hide_choice(self)
        msg.post(UI.components.hotspots, "hide_all")
        return
    end
    if UI.overlays.phone then
        UI.at_end = false
        msg.post(UI.components.dialogue, "hide_dialogue")
        ctx.hide_choice(self)
        msg.post(UI.components.hotspots, "hide_all")
        return
    end

    if cmds_paused_render then
        return
    end

    -- 2) Проверить режим ПЕРЕД обновлением фона
    local in_exploration = scene_controller.is_active and scene_controller.is_active()

    -- 3) Обновить фон только если НЕ в exploration (в exploration фон идёт
    -- из scene_controller).
    if not in_exploration then
        local bg = dm.get_background_image and dm.get_background_image()
        ctx.dbg("[ui_manager_v2] dm bg=", bg)
        if bg then
            ctx.post_dialogue_bg(self, bg)
            -- HUD scene_name обновляется только из set_background callback
            -- scene_controller'а — в диалоге (без exploration) надо
            -- продублировать вручную, иначе там висит "—" до конца диалога.
            ctx.post_location_to_ui(ctx.resolve_location_label(bg))
        end
    else
        ctx.dbg("[ui_manager_v2] in exploration mode, bg from scene_controller")
    end

    -- 4) Выбрать режим по scene_controller + отрендерить ноду
    ctx.consume_dm_effects()

    local node = dm.get_current_node and dm.get_current_node()
    ctx.dbg("[ui_manager_v2] dm node=",
        node and node.type, "char=", node and node.character,
        "text=", node and node.text and node.text:sub(1, 40))

    if in_exploration then
        UI.at_end = false
        ctx.show_exploration(self)
        ctx.hide_choice(self)
        return
    end

    if not node then
        UI.at_end = false
        ctx.reset_autoplay_state(self)
        ctx.show_dialogue(self)
        return
    end

    if node.type == "dialogue" then
        UI.at_end = false
        self.dialogue_node_type = "dialogue"
        self.dialogue_waiting_for_typewriter = true
        self.dialogue_current_text = node.text or ""
        self.current_choice_question = nil
        self.current_choice_options = nil
        ctx.append_dialogue_backlog(self, {
            kind = "dialogue",
            speaker = node.character,
            fallback_speaker = "НАРРАТОР",
            text = node.text or "",
        })
        ctx.show_dialogue(self)
        ctx.hide_choice(self)
        msg.post(UI.components.dialogue, "render_dialogue", {
            speaker    = node.character,
            name       = node.character and tostring(node.character):upper() or "—",
            text       = node.text or "",
            loop       = meta.get("iteration_number", 1),
            loop_label = meta.get_iteration_label(),
        })
        ctx.nudge_dialogue_skip(self)

    elseif node.type == "choice" then
        if try_auto_pick_character(node) then
            -- Авто-выбор персонажа (iter 2+, gender уже сохранён).
            M.update(self, ctx)
            return
        end
        UI.at_end = false
        self.dialogue_node_type = "choice"
        self.dialogue_waiting_for_typewriter = false
        self.dialogue_current_text = ""
        self.current_choice_question = node.question or "КАК ПОСТУПИТЬ?"
        self.current_choice_options = node.options or {}
        ctx.show_dialogue(self)
        ctx.show_choice(self, node.options or {}, 18, node.question or "КАК ПОСТУПИТЬ?")

    elseif node.type == "end" then
        UI.at_end = false
        ctx.reset_autoplay_state(self)
        if not (dm.is_story_end and dm.is_story_end()) then
            msg.post("#ui_manager_v2", "chapter_finished")
        end
        return
    end
end

return M
