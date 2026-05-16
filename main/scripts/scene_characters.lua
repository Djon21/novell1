-- scene_characters.lua
-- Конфиг и API для отрисовки персонажей на фоне сцены.
--
-- Не путать с диалоговыми портретами (dialogue_v2 portrait_bg). Это другая
-- система: scene_character'ы появляются на ФОНЕ сцены в полный рост, как
-- часть композиции (Persona/Doki Doki стиль).
--
-- Архитектура — стандартный VN-подход:
--   * Каждый персонаж рисуется ОДИН раз на однородном фоне (любая поза)
--   * Спрайт хранится в main/images/characters/<name>/<pose>.png
--   * Атлас одного персонажа: main/images/characters/<name>/<name>.atlas
--   * Texture binding "char_<name>" в dialogue_v2.gui
--   * SCENES конфиг ниже определяет ГДЕ и КАК БОЛЬШИМ показывать в каждой сцене
--   * Один и тот же спрайт переиспользуется в разных сценах с разными
--     size/position
--
-- SCENE_GROUPS объединяет sub-сцены одной локации (park_hub, park_riverside_*)
-- в одну группу "park". Внутри группы персонаж следует за игроком, при
-- выходе из группы (park → apartment) — прячется автоматически.
--
-- SCENES[group][key] = sprite-info. Key — обычно "<char>_<pose>" например
-- "mila_idle" или "mila_sitting". Один персонаж может иметь несколько
-- entries в одной сцене с разными позами.
--
-- Public API:
--   M.set_ui(iface)                       — регистрирует callbacks от ui_manager
--   M.show(group, key)                    — показать персонажа
--   M.hide(group, key)                    — спрятать
--   M.hide_all()                          — спрятать всех
--   M.on_scene_changed(new_scene_id)      — авто-hide при смене группы

local M = {}

-- scene_id → group. Sub-сцены одной локации мапятся в одну группу.
local SCENE_GROUPS = {
    park_hub             = "park",
    park_riverside_bench = "park",
    park_riverside_path  = "park",
    -- Добавлять по мере появления сценических персонажей в других локациях.
}

-- Конфиг персонажей по сценам.
-- Ключ внутри group — обычно "<char>_<pose>" (mila_idle, mila_sitting).
-- atlas/sprite — texture binding и image id в этом атласе.
-- x, y — top-left в game coords 1280×720.
-- w, h — размер sprite'а в game coords.
local SCENES = {
    park = {
        mila_idle = {
            atlas  = "char_mila",
            sprite = "idle",
            -- ~50% game-высоты, на дорожке справа от центра
            x = 820, y = 340, w = 95, h = 340,
            -- Клик по спрайту работает как хотспот — запускает ink-knot.
            -- Поле необязательное: если не задано, персонаж декоративный.
            action = { type = "ink_knot", knot = "park_npc_arrives" },
            -- Условие кликабельности: после приветствия Mila остаётся видна,
            -- но клик уже не запускает greeting-диалог повторно.
            -- (visible_when для авто-скрытия по флагу — TODO когда понадобится.)
            clickable_when = function(gs)
                return not gs.get_flag("park_npc_greeted")
            end,
        },
        -- Когда добавится другая поза:
        -- mila_sitting = { atlas="char_mila", sprite="sitting", x=..., y=..., w=..., h=... },
    },
    -- Другие локации:
    -- cafe = { mila_sitting = { atlas="char_mila", sprite="sitting", x=..., y=..., w=..., h=... } },
}

local MAX_SLOTS = 2

local _slot_occupants = {}
local _ui = nil
local _current_group = nil

function M.set_ui(iface) _ui = iface end

local function group_of(scene_id)
    return SCENE_GROUPS[scene_id] or scene_id
end

function M.get(group, key)
    local g = SCENES[group]
    return g and g[key]
end

local function find_free_slot()
    for i = 1, MAX_SLOTS do
        if not _slot_occupants[i] then return i end
    end
    return nil
end

local function find_slot_of(group, key)
    for i = 1, MAX_SLOTS do
        local o = _slot_occupants[i]
        if o and o.group == group and o.key == key then return i end
    end
    return nil
end

function M.show(group, key)
    if not _ui then return end
    local cfg = M.get(group, key)
    if not cfg then
        if _ui.log then _ui.log("scene_char unknown:", group, key) end
        return
    end
    if find_slot_of(group, key) then return end  -- идемпотентно
    local slot = find_free_slot()
    if not slot then
        if _ui.log then _ui.log("scene_char no free slot") end
        return
    end
    _slot_occupants[slot] = { group = group, key = key }
    if _ui.set_character_slot then
        _ui.set_character_slot(slot, cfg)
    end
end

function M.hide(group, key)
    if not _ui then return end
    local slot = find_slot_of(group, key)
    if not slot then return end
    _slot_occupants[slot] = nil
    if _ui.clear_character_slot then
        _ui.clear_character_slot(slot)
    end
end

function M.hide_all()
    if not _ui then return end
    for i = 1, MAX_SLOTS do
        if _slot_occupants[i] then
            _slot_occupants[i] = nil
            if _ui.clear_character_slot then _ui.clear_character_slot(i) end
        end
    end
end

-- Авто-hide при смене группы. Внутри одной группы (park_hub →
-- park_riverside_bench) персонаж остаётся, при выходе (park → apartment)
-- прячется.
-- Первый вход в группу (nil → group) НЕ считается выходом — иначе
-- scene_char:show + return_to_scene в одном knot'е стёр бы только что
-- показанного персонажа.
function M.on_scene_changed(new_scene_id)
    local new_group = new_scene_id and group_of(new_scene_id) or nil
    if _current_group ~= nil and new_group ~= _current_group then
        M.hide_all()
    end
    _current_group = new_group
end

function M.max_slots() return MAX_SLOTS end

-- Возвращает action для текущего occupant'а в slot или nil.
-- Учитывает clickable_when(gs) — если задано и вернуло false, action не
-- активен (клик игнорируется, hover-эффект тоже не сработает).
-- Используется dialogue_v2 при клике на scene_character_<slot> ноду.
function M.get_action(slot)
    local o = _slot_occupants[slot]
    if not o then return nil end
    local cfg = M.get(o.group, o.key)
    if not cfg or not cfg.action then return nil end
    if cfg.clickable_when then
        local gs = require "main.scripts.game_state"
        if not cfg.clickable_when(gs) then return nil end
    end
    return cfg.action
end

return M
