-- Dev checkpoints for fast manual testing.
-- Works only in debug builds:
--   F3 — выбрать следующий пресет (циклически)
--   F4 — применить выбранный пресет
--   F5 — переключить пол ГГ (male ↔ female). Применится при следующем F4.
--   F6 — записать текущее состояние игры как "live snapshot" (последний
--        виртуальный пресет в списке). F3 циклит до него, F4 загружает.
--        Снапшот живёт только в памяти процесса — после рестарта пропадает.

local dm = require "main.scripts.dialogue_manager_ink"
local gs = require "main.scripts.game_state"
local log = require "main.scripts.log"
local scene_controller = require "main.scripts.scene_controller"
local sm = require "main.scripts.save_manager"

local M = {}

local selected_index = 0
local selected_gender = "male"   -- F5 toggle; preset.gender override всё равно побеждает
local recorded_snapshot = nil    -- F6 → in-memory snapshot текущей игры. См. record_snapshot.

-- Полный набор падежных форм для каждого пола. choose_character ink-knot
-- ставит их сам, но dev_jump его пропускает — поэтому ставим вручную.
local NAME_FORMS = {
    male = {
        mc_name = "Артём", npc_name = "Мила",
        mc_name_gen = "Артёма",  npc_name_gen = "Милы",
        mc_name_dat = "Артёму",  npc_name_dat = "Миле",
        mc_name_acc = "Артёма",  npc_name_acc = "Милу",
        mc_name_ins = "Артёмом", npc_name_ins = "Милой",
        mc_name_prep = "Артёме", npc_name_prep = "Миле",
    },
    female = {
        mc_name = "Мила", npc_name = "Артём",
        mc_name_gen = "Милы",   npc_name_gen = "Артёма",
        mc_name_dat = "Миле",   npc_name_dat = "Артёму",
        mc_name_acc = "Милу",   npc_name_acc = "Артёма",
        mc_name_ins = "Милой",  npc_name_ins = "Артёмом",
        mc_name_prep = "Миле",  npc_name_prep = "Артёме",
    },
}

local function is_debug_build()
    if not sys or not sys.get_engine_info then return false end
    local info = sys.get_engine_info()
    return info and info.is_debug == true
end

local BASE_PHONE_MESSAGES = {
    sms = {
        { "mama", "Не забудь позавтракать. И не сиди весь день дома." },
        { "bank", "Карта *4821: списание 349 ₽. Кофе и выпечка. 08:41." },
        { "prod", "Напоминание: в понедельник до 11:00 подтвердите статус по кейсу 017." },
    },
    msg = {
        { "friends", "Доброе утро, выжившие. Кто сегодня не отменяет планы в последний момент?" },
        { "work_team", "Понедельничная планёрка перенесена на 10:40. Да, в воскресенье. Нет, я тоже не рад." },
        { "prod_bot", "CASE-017 создан." },
    },
}

local function clone_message_list(list)
    local out = {}
    for i, entry in ipairs(list or {}) do
        out[i] = { entry[1], entry[2] }
    end
    return out
end

local function common_phone_state()
    return {
        flags = {
            phone_active = true,
            phone_taken = true,
        },
        vars = {
            phone_active = true,
            phone_taken = true,
        },
        items = { "phone" },
        sms = clone_message_list(BASE_PHONE_MESSAGES.sms),
        msg = clone_message_list(BASE_PHONE_MESSAGES.msg),
    }
end

-- place: "park" | "cafe". Где договорились встретиться (date_place_<place>).
local function sunday_ready_state(place)
    place = place or "park"
    local place_flag = "date_place_" .. place
    local state = common_phone_state()
    state.flags.got_out_of_bed = true
    state.flags.bathroom_morning_seen = true
    state.flags.toothbrush_taken = true
    state.flags.toothpaste_taken = true
    state.flags.toothbrush_pasted_ready = true
    state.flags.teeth_brushed = true
    state.flags.washed_up = true
    state.flags.mug_taken = true
    state.flags.coffee_drunk = true
    state.flags.sunday_morning_routine_seen = true
    state.flags.sunday_messenger_invite_sent = true
    state.flags.date_agreed = true
    state.flags[place_flag] = true
    state.flags.sunday_dressed = true
    state.flags.sunday_ready_to_leave = true

    state.vars.got_out_of_bed = true
    state.vars.bathroom_morning_seen = true
    state.vars.toothbrush_taken = true
    state.vars.toothpaste_taken = true
    state.vars.toothbrush_pasted_ready = true
    state.vars.teeth_brushed = true
    state.vars.washed_up = true
    state.vars.mug_taken = true
    state.vars.coffee_drunk = true
    state.vars.sunday_morning_routine_seen = true
    state.vars.sunday_messenger_invite_sent = true
    state.vars.date_agreed = true
    state.vars[place_flag] = true
    state.vars.sunday_dressed = true
    state.vars.sunday_ready_to_leave = true

    table.insert(state.items, "mug")
    table.insert(state.items, "toothbrush_pasted")

    state.quests = {
        make_coffee = "done",
        reply_npc = "done",
        meet_npc = "active",
    }

    local npc_chat = place == "cafe" and "mila" or "mila"
    table.insert(state.msg, { npc_chat, "Ты сегодня вообще живой?" })
    table.insert(state.msg, { npc_chat, "Я уже второй кофе пью." })
    table.insert(state.msg, { npc_chat, "Выберемся куда-нибудь, пока день не стал совсем домашним?" })
    return state
end

local function park_state()
    local state = sunday_ready_state("park")
    state.flags.park_arrived = true
    state.flags.park_entrance_seen = true
    state.flags.park_where_message_sent = true
    state.flags.park_npc_at_bench = true
    state.flags.park_npc_bench_shown = true
    state.flags.park_npc_greeted = true
    state.flags.park_place_chosen = true
    state.flags.park_talk_place_bench = true
    state.flags.park_bench_trash_seen = true
    state.flags.park_bench_cleared = true
    state.flags.park_path_seen = true

    state.vars.park_arrived = true
    state.vars.park_entrance_seen = true
    state.vars.park_where_message_sent = true
    state.vars.park_npc_greeted = true
    state.vars.park_place_chosen = true
    state.vars.park_talk_place_bench = true
    state.vars.park_bench_trash_seen = true
    state.vars.park_bench_cleared = true
    state.vars.park_path_seen = true
    return state
end

-- После завершённого свидания (park или cafe). Игрок уже встретил NPC,
-- сейчас в "after-date" окне когда доступны второстепенные точки
-- (смотровая, магазин). sunday_second_stop_done = false, чтобы on_enter
-- arrival-knot'а второй локации мог отыграться.
local function after_date_state(place)
    local state = sunday_ready_state(place)
    state.flags.met_npc_sunday = true
    state.flags.sunday_after_date_active = true
    state.flags.date_route_chosen = true
    state.vars.met_npc_sunday = true
    state.vars.sunday_after_date_active = true
    state.vars.date_route_chosen = true

    if place == "park" then
        -- Подменяем park-флаги чтобы не упасть в недоигранный диалог.
        state.flags.park_arrived = true
        state.flags.park_entrance_seen = true
        state.flags.park_where_message_sent = true
        state.flags.park_npc_greeted = true
        state.flags.park_npc_at_bench = true
        state.flags.park_place_chosen = true
        state.flags.park_talk_place_bench = true
        state.flags.park_bench_trash_seen = true
        state.flags.park_bench_cleared = true
        state.flags.park_path_seen = true
        state.vars.park_arrived = true
        state.vars.park_entrance_seen = true
        state.vars.park_where_message_sent = true
        state.vars.park_npc_greeted = true
        state.vars.park_place_chosen = true
        state.vars.park_talk_place_bench = true
        state.vars.park_bench_trash_seen = true
        state.vars.park_bench_cleared = true
        state.vars.park_path_seen = true
    end

    state.quests = state.quests or {}
    state.quests.meet_npc = "done"
    state.quests.spend_sunday = "active"

    state.map_allow = { "poi_home", "poi_shop", "poi_view" }
    return state
end

local function monday_state()
    local state = common_phone_state()
    state.flags.sunday_finished = true
    state.flags.monday_started = true
    state.flags.monday_morning_started = true

    state.vars.sunday_finished = true
    state.vars.monday_started = true
    state.vars.monday_morning_started = true
    state.vars.iteration_number = 1

    state.items = { "phone" }
    state.quests = {
        go_to_office = "active",
    }
    return state
end

local function monday_office_state()
    local state = monday_state()
    state.flags.monday_dressed = true
    state.flags.work_card_taken = true
    state.flags.monday_checked_in_office = true
    state.flags.monday_mail_read = true
    state.flags.monday_report_page_taken = true
    state.flags.monday_folder_taken = true
    state.flags.monday_case_file_assembled = true
    state.flags.monday_case_file_submitted = true
    state.flags.mon_office_started = true
    state.flags.reached_office = true

    table.insert(state.items, "card")
    table.insert(state.items, "report_page")
    table.insert(state.items, "folder")
    state.quests.go_to_office = "done"
    state.quests.work_monday_case = "done"
    return state
end

local function tuesday_state()
    local state = common_phone_state()
    state.flags.sunday_finished = true
    state.flags.monday_started = true
    state.flags.tuesday_started = true
    state.flags.tuesday_morning_started = true
    state.flags.tuesday_phone_checked = true
    state.flags.tuesday_left_home = true
    state.flags.tuesday_consequence_seen = true
    state.flags.tuesday_investigation_done = true

    state.vars.sunday_finished = true
    state.vars.monday_started = true
    state.vars.iteration_number = 1

    state.quests = {
        follow_monday_trace = "done",
    }
    return state
end

local function loop2_wednesday_state()
    local state = common_phone_state()
    state.flags.loop2_fake_wednesday_started = true

    state.vars.iteration_number = 2

    state.items = { "phone" }
    state.meta = { iteration_number = 2 }
    state.quests = {
        check_the_loop = "active",
    }
    return state
end

local PRESETS = {
    {
        id = "sunday_start_bedroom",
        label = "Sunday: bedroom start",
        scene = "apartment_bedroom",
        state = {},
    },
    {
        id = "sunday_ready_to_leave_park",
        label = "Sunday: apartment ready to leave (park)",
        scene = "apartment_hub",
        state = sunday_ready_state("park"),
    },
    {
        id = "sunday_ready_to_leave_cafe",
        label = "Sunday: apartment ready to leave (cafe)",
        scene = "apartment_hub",
        state = sunday_ready_state("cafe"),
    },
    {
        id = "sunday_park_route",
        label = "Sunday: route to park",
        knot = "sunday_date_go_park",
        state = sunday_ready_state("park"),
        allow_chapter_end = true,
    },
    {
        id = "sunday_cafe_route",
        label = "Sunday: route to cafe",
        knot = "sunday_date_go_cafe",
        state = sunday_ready_state("cafe"),
        allow_chapter_end = true,
    },
    {
        id = "sunday_park_bench",
        label = "Sunday: park bench exploration",
        scene = "park_riverside_bench",
        state = park_state(),
    },
    {
        id = "sunday_viewpoint_after_park",
        label = "Sunday: viewpoint after park date",
        scene = "view_hub",
        state = after_date_state("park"),
        skip_on_enter = false,
    },
    {
        id = "sunday_viewpoint_after_cafe",
        label = "Sunday: viewpoint after cafe date",
        scene = "view_hub",
        state = after_date_state("cafe"),
        skip_on_enter = false,
    },
    {
        id = "sunday_shop_after_park",
        label = "Sunday: shop after park date",
        scene = "shop_street",
        state = after_date_state("park"),
        skip_on_enter = false,
    },
    {
        id = "sunday_shop_after_cafe",
        label = "Sunday: shop after cafe date",
        scene = "shop_street",
        state = after_date_state("cafe"),
        skip_on_enter = false,
    },
    {
        id = "monday_home",
        label = "Monday: apartment morning",
        scene = "monday_apartment_bedroom_morning",
        state = monday_state(),
    },
    {
        id = "monday_office_choice",
        label = "Monday: office core choice",
        knot = "mon_office_core_choice",
        state = monday_office_state(),
        allow_chapter_end = true,
    },
    {
        id = "tuesday_home",
        label = "Tuesday: apartment morning",
        scene = "tuesday_apartment_bedroom_morning",
        state = tuesday_state(),
    },
    {
        id = "tuesday_rooftop",
        label = "Tuesday: rooftop finale",
        knot = "tue_rooftop_entry",
        state = tuesday_state(),
        allow_chapter_end = true,
    },
    {
        id = "loop2_wednesday",
        label = "Loop 2: fake Wednesday (bedroom)",
        scene = "apartment_bedroom",
        state = loop2_wednesday_state(),
    },
}

-- Виртуальный пресет для live-snapshot — собирается из recorded_snapshot.
-- Появляется в конце списка только когда snapshot записан. Помечен
-- kind="snapshot", apply_selected раздвоится по этому полю.
local function snapshot_preset()
    if not recorded_snapshot then return nil end
    local label = "Live snapshot @ " .. (recorded_snapshot.ts or "?")
    if recorded_snapshot.scene_id then
        label = label .. " [" .. recorded_snapshot.scene_id .. "]"
    elseif recorded_snapshot.knot then
        label = label .. " [knot=" .. recorded_snapshot.knot .. "]"
    end
    return {
        id    = "live_snapshot",
        label = label,
        kind  = "snapshot",
    }
end

local function effective_preset_count()
    return #PRESETS + (recorded_snapshot and 1 or 0)
end

local function current_preset()
    local index = selected_index
    if index < 1 then index = 1 end
    if index <= #PRESETS then
        return PRESETS[index]
    end
    return snapshot_preset()
end

local function notify(text)
    log.info("dev_jump", text)
    print("[dev_jump] " .. text)
end

local function set_story_var(name, value)
    if dm.set_var then
        dm.set_var(name, value, true)
    end
end

local function save_story_state()
    if dm.save_state then
        dm.save_state()
    end
end

local function merge_state(dst, src)
    if not src then return dst end
    for key, value in pairs(src) do
        if type(value) == "table" then
            dst[key] = dst[key] or {}
            if #value > 0 then
                for _, item in ipairs(value) do table.insert(dst[key], item) end
            else
                for k, v in pairs(value) do dst[key][k] = v end
            end
        else
            dst[key] = value
        end
    end
    return dst
end

local function apply_state(state)
    state = state or {}

    for name, value in pairs(state.flags or {}) do
        gs.set_flag(name, value)
    end

    for name, value in pairs(state.vars or {}) do
        set_story_var(name, value)
    end

    if state.meta then
        local ms = require "main.scripts.meta_state"
        for k, v in pairs(state.meta) do
            ms.set(k, v)
        end
    end

    for _, item_id in ipairs(state.items or {}) do
        gs.add_item(item_id)
    end

    for id, status in pairs(state.quests or {}) do
        gs.set_quest(id, status)
    end

    for _, entry in ipairs(state.sms or {}) do
        gs.add_sms(entry[1], entry[2])
    end

    for _, entry in ipairs(state.msg or {}) do
        gs.add_msg(entry[1], entry[2])
    end

    if state.map_lock_all then
        gs.map_lock_all()
    elseif state.map_lock_to then
        gs.map_lock_to(state.map_lock_to)
    elseif state.map_allow then
        gs.map_allow_reset()
        for _, poi_id in ipairs(state.map_allow) do
            gs.map_allow(poi_id)
        end
    end
end

local function reset_ui(ctx, base_mode)
    local UI = ctx.M
    UI.at_end = false
    UI.base_mode = base_mode
    UI.overlays.choice = false
    UI.overlays.inventory = false
    UI.overlays.phone = false
    UI.overlays.backlog = false

    ctx.sync_modal_state()
    ctx.reset_dialogue_backlog()

    msg.post(UI.components.choice, "hide_choice")
    msg.post(UI.components.inventory, "hide_inventory")
    msg.post(UI.components.phone, "close_phone")
    msg.post(UI.components.hotspots, "hide_all")
end

local function show_mode_after_scene_enter(ctx)
    if scene_controller.is_active and scene_controller.is_active() then
        ctx.show_exploration()
    end
end

function M.is_enabled()
    return is_debug_build()
end

function M.select_next()
    if not M.is_enabled() then return false end
    local total = effective_preset_count()
    selected_index = selected_index + 1
    if selected_index > total then selected_index = 1 end

    local p = current_preset()
    local gender = (p and p.gender) or selected_gender
    notify(("selected %d/%d: %s [%s] (mc=%s)"):format(
        selected_index, total, p.label, p.id, gender))
    return true
end

-- F6: записать текущее состояние игры как live snapshot.
-- Снапшот в памяти — переживает гибель/новую игру, но не рестарт процесса.
-- После записи в списке появится виртуальный пресет «Live snapshot @ HH:MM:SS»,
-- который можно выбрать F3 и применить F4 — он восстановит ink + game_state
-- + сцену через стандартный save/load механизм.
function M.record_snapshot(ctx)
    if not M.is_enabled() then return false end
    -- Принудительно проталкиваем ink-state в sm перед чтением.
    if dm.save_state then dm.save_state() end
    local scene_id = nil
    if scene_controller.get_current_scene_id then
        scene_id = scene_controller.get_current_scene_id()
    end
    recorded_snapshot = {
        gender     = sm.get_gender() or selected_gender,
        scene_id   = scene_id,
        ink_state  = sm.get_ink_state(),
        game_state = gs.serialize and gs.serialize() or nil,
        ts         = os.date("%H:%M:%S"),
    }
    notify(("snapshot recorded @ %s [scene=%s, gender=%s]"):format(
        recorded_snapshot.ts,
        recorded_snapshot.scene_id or "<dialogue>",
        recorded_snapshot.gender))
    return true
end

-- F5: переключить пол ГГ. Применится при следующем F4. Если у пресета
-- есть свой preset.gender override — он всё равно победит.
function M.toggle_gender()
    if not M.is_enabled() then return false end
    selected_gender = (selected_gender == "female") and "male" or "female"
    local p = current_preset()
    local applied = p and (p.gender or selected_gender) or selected_gender
    notify(("gender → %s (preset will use: %s)"):format(selected_gender, applied))
    return true
end

-- Применить live-snapshot: использует штатный save/load механизм.
-- Записываем сохранённые ink_state + game_state обратно в sm, потом
-- dm.load_saved(bytes) восстанавливает ink. game_state.deserialize()
-- подтягивает флаги/items/sms/msg/pin-теги. Сцена возвращается через
-- scene_controller.enter (если snapshot был сделан в exploration).
local function apply_snapshot(ctx, snap, bytes)
    sm.new_game()
    sm.set_gender(snap.gender or "male")
    sm.set_ink_state(snap.ink_state)
    sm.set_game_state(snap.game_state)

    ctx.reset_runtime_state()
    if gs.deserialize and snap.game_state then
        gs.deserialize(snap.game_state)
    end

    dm.load_saved(bytes)
    reset_ui(ctx, snap.scene_id and "exploration" or "dialogue")

    -- Падежные формы перезаписываем — load_saved их может не восстановить
    -- если ink-state был зафиксирован до choose_character.
    local forms = NAME_FORMS[snap.gender] or NAME_FORMS.male
    for name, value in pairs(forms) do
        set_story_var(name, value)
    end
    set_story_var("mc_gender", snap.gender or "male")
    set_story_var("npc_gender", (snap.gender == "female") and "male" or "female")

    if snap.scene_id then
        scene_controller.enter(snap.scene_id, { skip_on_enter = true })
        show_mode_after_scene_enter(ctx)
    else
        ctx.handle_dialogue_update()
    end

    save_story_state()
    ctx.sync_ui_state()
    ctx.persist_run_state()
    notify(("jumped to snapshot @ %s [scene=%s]"):format(
        snap.ts or "?", snap.scene_id or "<dialogue>"))
    return true
end

function M.apply_selected(ctx)
    if not M.is_enabled() then return false end
    local preset = current_preset()
    if not preset then return false end

    local bytes = ctx.load_main_story_bytes()
    if not bytes then return false end

    -- Live snapshot — отдельная ветка через save/load, не через preset.state.
    if preset.kind == "snapshot" and recorded_snapshot then
        return apply_snapshot(ctx, recorded_snapshot, bytes)
    end

    local gender = preset.gender or selected_gender
    sm.new_game()
    sm.set_gender(gender)

    ctx.reset_runtime_state()
    dm.init(bytes)
    reset_ui(ctx, preset.scene and "exploration" or "dialogue")

    local state = merge_state({}, preset.state)
    apply_state(state)
    set_story_var("mc_gender", gender)
    set_story_var("npc_gender", gender == "female" and "male" or "female")
    -- Полный набор падежных форм — иначе фразы вида {npc_name_dat} в ink
    -- будут рендериться пустотой/мужским дефолтом.
    local forms = NAME_FORMS[gender] or NAME_FORMS.male
    for name, value in pairs(forms) do
        set_story_var(name, value)
    end

    if preset.scene then
        scene_controller.enter(preset.scene, { skip_on_enter = preset.skip_on_enter ~= false })
        show_mode_after_scene_enter(ctx)
    elseif preset.knot then
        dm.jump_to_knot(preset.knot, { allow_chapter_end = preset.allow_chapter_end == true })
        ctx.handle_dialogue_update()
    end

    save_story_state()
    ctx.sync_ui_state()
    ctx.persist_run_state()
    notify(("jumped to: %s [%s]"):format(preset.label, preset.id))
    return true
end

function M.get_presets()
    return PRESETS
end

return M
