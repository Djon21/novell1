local scene_controller = require "main.scripts.scene_controller"

local M = {}

local function copy_color(c)
    if type(c) ~= "table" then return nil end
    return {
        r = c.r, g = c.g, b = c.b, a = c.a,
        c[1], c[2], c[3], c[4],
    }
end

local function copy_hotspot_style(style)
    if type(style) ~= "table" then return nil end
    return {
        circle_color = copy_color(style.circle_color),
        ring_color = copy_color(style.ring_color),
        icon_color = copy_color(style.icon_color),
        circle_alpha = style.circle_alpha,
        ring_alpha = style.ring_alpha,
        icon_alpha = style.icon_alpha,
        scale = style.scale,
        hotspot_scale = style.hotspot_scale,
        circle_scale = style.circle_scale,
        ring_scale = style.ring_scale,
        icon_scale = style.icon_scale,
        icon_offset_x = style.icon_offset_x,
        icon_offset_y = style.icon_offset_y,
        circle_texture = style.circle_texture,
        ring_texture = style.ring_texture,
    }
end

function M.setup(ctx)
    scene_controller.set_ui({
        max_hotspots = function() return 6 end,
        max_scene_objects = function() return 4 end,

        set_background = function(bg_name)
            ctx.set_background(bg_name)
        end,

        set_scene_object = function(i, obj)
            local clean = nil
            if obj then
                clean = {
                    id    = obj.id,
                    image = obj.image,
                    pos   = obj.pos and { x = obj.pos.x, y = obj.pos.y } or nil,
                    size  = obj.size and { w = obj.size.w, h = obj.size.h } or nil,
                }
            end
            msg.post(ctx.components.hotspots, "set_scene_object", { index = i, obj = clean })
        end,

        set_hotspot = function(i, data)
            local clean = nil
            if data then
                clean = {
                    rect   = data.rect and { x = data.rect.x, y = data.rect.y, w = data.rect.w, h = data.rect.h } or nil,
                    label  = data.label,
                    icon   = data.icon,
                    locked = data.locked and true or false,
                    circle_color = copy_color(data.circle_color),
                    ring_color = copy_color(data.ring_color),
                    icon_color = copy_color(data.icon_color),
                    circle_alpha = data.circle_alpha,
                    ring_alpha = data.ring_alpha,
                    icon_alpha = data.icon_alpha,
                    hotspot_scale = data.hotspot_scale,
                    circle_scale = data.circle_scale,
                    ring_scale = data.ring_scale,
                    icon_scale = data.icon_scale,
                    icon_offset_x = data.icon_offset_x,
                    icon_offset_y = data.icon_offset_y,
                    circle_texture = data.circle_texture,
                    ring_texture = data.ring_texture,
                    hotspot_style = copy_hotspot_style(data.hotspot_style or data.style),
                }
            end
            msg.post(ctx.components.hotspots, "set_hotspot", { index = i, data = clean })
        end,

        request_ink_knot = function(knot_name, keep_bg)
            ctx.request_ink_knot(knot_name, keep_bg)
        end,

        request_use_on_hotspot = function(hotspot_id)
            return ctx.request_use_on_hotspot(hotspot_id)
        end,
    })

    ctx.dbg("[ui_manager_v2] scene_controller UI настроен")
end

return M
