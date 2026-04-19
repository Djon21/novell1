-- gui_animations.lua
-- Модуль анимаций для GUI элементов

local M = {}

-- ============================================
-- FADE ANIMATIONS (Затухание/появление)
-- ============================================

-- Плавное появление (fade in)
function M.fade_in(node, duration, delay, callback)
    if not node then return end
    
    duration = duration or 0.3
    delay = delay or 0
    
    local color = gui.get_color(node)
    color.w = 0
    gui.set_color(node, color)
    gui.set_enabled(node, true)
    
    gui.animate(node, "color.w", 1, gui.EASING_OUTQUAD, duration, delay, callback)
end

-- Плавное исчезновение (fade out)
function M.fade_out(node, duration, delay, callback)
    if not node then return end
    
    duration = duration or 0.3
    delay = delay or 0
    
    gui.animate(node, "color.w", 0, gui.EASING_INQUAD, duration, delay, function()
        gui.set_enabled(node, false)
        if callback then callback() end
    end)
end

-- Crossfade между двумя нодами
function M.crossfade(node_out, node_in, duration, callback)
    if not node_out or not node_in then return end
    
    duration = duration or 0.35
    
    M.fade_out(node_out, duration)
    M.fade_in(node_in, duration, 0, callback)
end

-- ============================================
-- SLIDE ANIMATIONS (Скольжение)
-- ============================================

-- Въезд слева
function M.slide_in_from_left(node, distance, duration, delay, callback)
    if not node then return end
    
    distance = distance or 200
    duration = duration or 0.5
    delay = delay or 0
    
    local pos = gui.get_position(node)
    local start_pos = vmath.vector3(pos.x - distance, pos.y, pos.z)
    
    gui.set_position(node, start_pos)
    gui.set_enabled(node, true)
    
    gui.animate(node, "position.x", pos.x, gui.EASING_OUTQUAD, duration, delay, callback)
end

-- Въезд справа
function M.slide_in_from_right(node, distance, duration, delay, callback)
    if not node then return end
    
    distance = distance or 200
    duration = duration or 0.5
    delay = delay or 0
    
    local pos = gui.get_position(node)
    local start_pos = vmath.vector3(pos.x + distance, pos.y, pos.z)
    
    gui.set_position(node, start_pos)
    gui.set_enabled(node, true)
    
    gui.animate(node, "position.x", pos.x, gui.EASING_OUTQUAD, duration, delay, callback)
end

-- Въезд сверху
function M.slide_in_from_top(node, distance, duration, delay, callback)
    if not node then return end
    
    distance = distance or 200
    duration = duration or 0.5
    delay = delay or 0
    
    local pos = gui.get_position(node)
    local start_pos = vmath.vector3(pos.x, pos.y + distance, pos.z)
    
    gui.set_position(node, start_pos)
    gui.set_enabled(node, true)
    
    gui.animate(node, "position.y", pos.y, gui.EASING_OUTQUAD, duration, delay, callback)
end

-- Въезд снизу
function M.slide_in_from_bottom(node, distance, duration, delay, callback)
    if not node then return end
    
    distance = distance or 200
    duration = duration or 0.5
    delay = delay or 0
    
    local pos = gui.get_position(node)
    local start_pos = vmath.vector3(pos.x, pos.y - distance, pos.z)
    
    gui.set_position(node, start_pos)
    gui.set_enabled(node, true)
    
    gui.animate(node, "position.y", pos.y, gui.EASING_OUTQUAD, duration, delay, callback)
end

-- Выезд влево
function M.slide_out_to_left(node, distance, duration, delay, callback)
    if not node then return end
    
    distance = distance or 200
    duration = duration or 0.5
    delay = delay or 0
    
    local pos = gui.get_position(node)
    
    gui.animate(node, "position.x", pos.x - distance, gui.EASING_INQUAD, duration, delay, function()
        gui.set_enabled(node, false)
        gui.set_position(node, pos) -- восстанавливаем позицию
        if callback then callback() end
    end)
end

-- ============================================
-- SCALE ANIMATIONS (Масштабирование)
-- ============================================

-- Появление с увеличением
function M.scale_in(node, duration, delay, callback)
    if not node then return end
    
    duration = duration or 0.3
    delay = delay or 0
    
    gui.set_scale(node, vmath.vector3(0, 0, 1))
    gui.set_enabled(node, true)
    
    gui.animate(node, "scale", vmath.vector3(1, 1, 1), gui.EASING_OUTBACK, duration, delay, callback)
end

-- Исчезновение с уменьшением
function M.scale_out(node, duration, delay, callback)
    if not node then return end
    
    duration = duration or 0.3
    delay = delay or 0
    
    gui.animate(node, "scale", vmath.vector3(0, 0, 1), gui.EASING_INBACK, duration, delay, function()
        gui.set_enabled(node, false)
        gui.set_scale(node, vmath.vector3(1, 1, 1)) -- восстанавливаем масштаб
        if callback then callback() end
    end)
end

-- Пульсация (bounce)
function M.pulse(node, scale, duration, callback)
    if not node then return end
    
    scale = scale or 1.2
    duration = duration or 0.3
    
    gui.animate(node, "scale", vmath.vector3(scale, scale, 1), gui.EASING_OUTQUAD, duration * 0.5, 0, function()
        gui.animate(node, "scale", vmath.vector3(1, 1, 1), gui.EASING_INQUAD, duration * 0.5, 0, callback)
    end)
end

-- ============================================
-- SPECIAL EFFECTS (Специальные эффекты)
-- ============================================

-- Вспышка (flash)
function M.flash(node, duration, r, g, b, intensity)
    if not node then return end
    
    duration = duration or 0.5
    intensity = intensity or 0.6
    r = r or 1
    g = g or 1
    b = b or 1
    
    local color = vmath.vector4(r, g, b, 0)
    gui.set_color(node, color)
    gui.set_enabled(node, true)
    
    local up_time = duration * 0.3
    local down_time = duration * 0.7
    
    gui.animate(node, "color.w", intensity, gui.EASING_OUTQUAD, up_time, 0, function()
        gui.animate(node, "color.w", 0, gui.EASING_INQUAD, down_time, 0, function()
            gui.set_enabled(node, false)
        end)
    end)
end

-- Тряска (shake) - применяется к позиции
function M.shake(node, intensity, duration, callback)
    if not node then return end
    
    intensity = intensity or 10
    duration = duration or 0.5
    
    local original_pos = gui.get_position(node)
    local shake_count = math.floor(duration * 30) -- ~30 FPS
    local shake_interval = duration / shake_count
    
    local function do_shake(count)
        if count <= 0 then
            gui.set_position(node, original_pos)
            if callback then callback() end
            return
        end
        
        local offset_x = (math.random() - 0.5) * intensity * 2
        local offset_y = (math.random() - 0.5) * intensity * 2
        local shake_pos = vmath.vector3(
            original_pos.x + offset_x,
            original_pos.y + offset_y,
            original_pos.z
        )
        
        gui.set_position(node, shake_pos)
        
        timer.delay(shake_interval, false, function()
            do_shake(count - 1)
        end)
    end
    
    do_shake(shake_count)
end

-- Мигание (blink)
function M.blink(node, count, interval, callback)
    if not node then return end
    
    count = count or 3
    interval = interval or 0.2
    
    local function do_blink(remaining)
        if remaining <= 0 then
            gui.set_enabled(node, true)
            if callback then callback() end
            return
        end
        
        gui.set_enabled(node, false)
        timer.delay(interval * 0.5, false, function()
            gui.set_enabled(node, true)
            timer.delay(interval * 0.5, false, function()
                do_blink(remaining - 1)
            end)
        end)
    end
    
    do_blink(count)
end

-- Вращение (rotate)
function M.rotate(node, angle, duration, delay, callback)
    if not node then return end
    
    duration = duration or 0.5
    delay = delay or 0
    
    local current_rotation = gui.get_rotation(node)
    local target_rotation = vmath.quat_rotation_z(math.rad(angle))
    
    gui.animate(node, "rotation", target_rotation, gui.EASING_INOUTQUAD, duration, delay, callback)
end

-- ============================================
-- COMBINED ANIMATIONS (Комбинированные)
-- ============================================

-- Появление с fade + slide
function M.fade_slide_in(node, direction, distance, duration, delay, callback)
    if not node then return end
    
    direction = direction or "left"
    distance = distance or 200
    duration = duration or 0.5
    delay = delay or 0
    
    -- Устанавливаем начальную прозрачность
    local color = gui.get_color(node)
    color.w = 0
    gui.set_color(node, color)
    
    -- Запускаем fade in
    M.fade_in(node, duration, delay)
    
    -- Запускаем slide in
    if direction == "left" then
        M.slide_in_from_left(node, distance, duration, delay, callback)
    elseif direction == "right" then
        M.slide_in_from_right(node, distance, duration, delay, callback)
    elseif direction == "top" then
        M.slide_in_from_top(node, distance, duration, delay, callback)
    elseif direction == "bottom" then
        M.slide_in_from_bottom(node, distance, duration, delay, callback)
    end
end

-- Появление с fade + scale
function M.fade_scale_in(node, duration, delay, callback)
    if not node then return end
    
    duration = duration or 0.3
    delay = delay or 0
    
    -- Устанавливаем начальную прозрачность и масштаб
    local color = gui.get_color(node)
    color.w = 0
    gui.set_color(node, color)
    gui.set_scale(node, vmath.vector3(0.5, 0.5, 1))
    gui.set_enabled(node, true)
    
    -- Запускаем fade in
    gui.animate(node, "color.w", 1, gui.EASING_OUTQUAD, duration, delay)
    
    -- Запускаем scale in
    gui.animate(node, "scale", vmath.vector3(1, 1, 1), gui.EASING_OUTBACK, duration, delay, callback)
end

-- ============================================
-- UTILITY FUNCTIONS (Вспомогательные)
-- ============================================

-- Отменить все анимации на ноде
function M.cancel_all(node)
    if not node then return end
    
    gui.cancel_animation(node, "position")
    gui.cancel_animation(node, "position.x")
    gui.cancel_animation(node, "position.y")
    gui.cancel_animation(node, "position.z")
    gui.cancel_animation(node, "color")
    gui.cancel_animation(node, "color.w")
    gui.cancel_animation(node, "scale")
    gui.cancel_animation(node, "rotation")
end

return M
