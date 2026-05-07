local meta = require "main.scripts.meta_state"
local scene_controller = require "main.scripts.scene_controller"
local ui_state = require "main.scripts.ui_state"

local M = {}

local BG_TEXTURE_KEY = "backgrounds"
local DEDICATED_BG_ANIMATION = "scene_bg"

function M.init_atlas_state(self, atlas_props)
    self.dialogue_bg_atlases = {}
    self.current_dialogue_bg_atlas = nil
    self.self_url = msg.url()

    for bg_name, prop_name in pairs(atlas_props or {}) do
        self.dialogue_bg_atlases[bg_name] = self[prop_name]
    end
end

local function resolve_visual(self, bg_name)
    if bg_name and self.dialogue_bg_atlases and self.dialogue_bg_atlases[bg_name] then
        return self.dialogue_bg_atlases[bg_name], DEDICATED_BG_ANIMATION
    end
    return nil, nil
end

function M.apply_dialogue_bg(self, components, bg_name)
    if not self or not components.dialogue then return end
    if not bg_name or bg_name == "" or bg_name == "none" then return end

    local atlas, animation_id = resolve_visual(self, bg_name)
    if not atlas then
        print("[ui_manager_v2] WARNING: no dedicated atlas for bg:", bg_name,
              "- register it in ui_manager_v2.script + main/images/backgrounds/")
        return
    end

    if self.current_dialogue_bg_atlas ~= atlas then
        go.set(components.dialogue, "textures", atlas, { key = BG_TEXTURE_KEY })
        self.current_dialogue_bg_atlas = atlas
    end

    msg.post(components.dialogue, "set_background", {
        name = bg_name,
        animation = animation_id,
    })
end

function M.post_dialogue_bg(self, bg_name)
    if not bg_name then return end
    local target = (self and self.self_url) or msg.url("#ui_manager_v2")
    msg.post(target, "apply_dialogue_bg", { name = bg_name })
end

function M.resolve_location_label(bg_name, scenes)
    local scene_id = scene_controller.get_current_scene_id and scene_controller.get_current_scene_id() or nil
    local scene_data = nil

    if scene_controller.get_current_scene_data then
        scene_data = scene_controller.get_current_scene_data()
    end
    if not scene_data and scene_id and scene_id ~= "" and scenes then
        if scenes.get then
            scene_data = scenes.get(scene_id)
        elseif scenes.scenes then
            scene_data = scenes.scenes[scene_id]
        end
    end

    local label = scene_data and scene_data.label or nil
    if label and tostring(label) ~= "" then
        return tostring(label)
    end

    if scene_id and tostring(scene_id) ~= "" then
        return tostring(scene_id)
    end

    if bg_name and tostring(bg_name) ~= "" then
        return tostring(bg_name)
    end

    return "—"
end

function M.post_location(components, location_label)
    local name = location_label or M.resolve_location_label(nil, nil)
    local loop_label = meta.get_iteration_label and meta.get_iteration_label() or nil

    ui_state.location_name = name
    ui_state.current_location_name = name
    ui_state.location_loop = loop_label
    ui_state.current_location_loop = loop_label

    msg.post(components.hud, "set_location", {
        name = name,
        loop = loop_label,
    })
    msg.post(components.choice, "set_location", {
        name = name,
        loop = loop_label,
    })
end

return M
