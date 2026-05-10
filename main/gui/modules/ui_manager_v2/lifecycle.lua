-- lifecycle.lua
-- Run-state lifecycle: старт нового run'а, сброс итерации, обновление
-- состояния меню. Раньше эти функции жили в ui_manager_v2.script —
-- большой god-object. Извлечены сюда чтобы не плодить логики ~70 строк
-- вперемешку с UI-оркестрацией.
--
-- Все функции принимают `ctx` — таблицу с зависимостями (компоненты, callback'и).
-- ctx ожидается с такими полями:
--
--   ctx.M                 — M-таблица из ui_manager_v2 (overlays, base_mode, components)
--   ctx.sync_modal_state  — () → ()
--   ctx.clear_armed_state — () → ()
--   ctx.reset_dialogue_backlog — () → ()
--   ctx.reset_runtime_state    — () → ()
--   ctx.handle_dialogue_update — () → ()
--   ctx.sync_ui_state          — () → ()
--   ctx.persist_run_state      — () → ()
--   ctx.show_menu              — () → ()

local sm = require "main.scripts.save_manager"
local meta = require "main.scripts.meta_state"
local dm = require "main.scripts.dialogue_manager_ink"
local run_state = require "main.gui.modules.ui_manager_v2.run_state"

local M = {}

-- Старт нового run'а с текущим chapter_01 ink. Сбрасывает все runtime
-- состояния, восстанавливает выбор персонажа из meta_state (при reset_iteration
-- meta.reset_all() вернёт nil → choose_character покажется снова).
function M.start_new_run(ctx, reset_iteration_progress)
    local bytes = run_state.load_main_story_bytes()
    if not bytes then
        return false
    end

    -- Сбросить armed-state на случай если игрок начал новую игру/итерацию
    -- из меню в момент когда был активен use-on-target.
    ctx.clear_armed_state()

    sm.load()
    meta.init()

    if reset_iteration_progress then
        meta.reset_all()
    end

    local UI = ctx.M
    UI.at_end = false
    UI.base_mode = "dialogue"
    UI.overlays.choice    = false
    UI.overlays.inventory = false
    UI.overlays.phone     = false
    UI.overlays.map       = false
    UI.overlays.backlog   = false
    ctx.sync_modal_state()

    ctx.reset_dialogue_backlog()
    msg.post(UI.components.choice,    "hide_choice")
    msg.post(UI.components.inventory, "hide_inventory")
    msg.post(UI.components.phone,     "close_phone")
    msg.post(UI.components.map,       "close_map")
    msg.post(UI.components.hotspots,  "hide_all")

    sm.new_game()
    -- Восстанавливаем выбор персонажа из meta_state (сохраняется между
    -- итерациями). meta.reset_all() ("СБРОСИТЬ ИТЕРАЦИЮ") вернёт nil →
    -- choose_character покажется снова.
    local saved_gender = meta.get("mc_gender")
    if saved_gender then
        sm.set_gender(saved_gender)
    end
    ctx.reset_runtime_state()

    dm.init(bytes)
    ctx.handle_dialogue_update()
    ctx.sync_ui_state()
    ctx.persist_run_state()
    return true
end

-- "СБРОСИТЬ ИТЕРАЦИЮ" из меню. Сбрасывает meta + стартует новый run
-- через 1 кадр чтобы UI успел отрисовать клик по кнопке.
function M.reset_iteration_and_restart(ctx)
    meta.init()
    meta.reset_all()

    timer.delay(0, false, function()
        M.start_new_run(ctx, false)
    end)
end

-- Обновляет state-данные main_menu_v2: номер итерации, awareness,
-- кол-во завершённых, есть ли save для "Продолжить".
function M.refresh_menu_state(ctx)
    sm.load()
    meta.init()

    msg.post(ctx.M.components.main_menu, "set_loop_state", {
        iteration       = meta.get("iteration_number", 1),
        iteration_label = meta.get_iteration_label(),
        awareness       = meta.get("loop_awareness", 0),
        completed       = meta.get("completed_iterations", 0),
        can_continue    = sm.has_save(),
    })
end

return M
