-- drag_scroll.lua
-- Универсальная state-машина для drag-to-scroll по вертикали.
-- Используется в phone_sms / phone_messenger / любом другом списке внутри
-- gui_script где нужно листать содержимое пальцем (или мышью с зажатой ЛКМ).
--
-- Использование:
--
--   local drag_scroll = require "main.gui.modules.drag_scroll"
--
--   self.list_drag = drag_scroll.new({
--       step_px      = 64,         -- 1 шаг = 64 пикселя сдвига пальца
--       threshold_px = 8,          -- меньше — считаем тапом, не drag'ом
--       owner        = self,       -- передаётся первым аргументом в on_step
--       invert       = false,      -- true → перевернуть направление
--       is_inside    = function(x, y) return ... end,  -- опц. фильтр на press
--       on_step      = function(owner, delta) ... end, -- сдвинуть offset на delta
--   })
--
--   -- В обработчике touch input:
--   local result = drag_scroll.handle(self.list_drag, action)
--   if result == "swallow" then
--       return true               -- input поглощён (press внутри / drag / завершение drag'a)
--   end
--   if result == "tap" then
--       -- released без движения. Caller сам делает hit-test и обработку tap'а.
--   end
--   -- result == "ignore" → событие нас не касается, fall-through дальше
--
-- Возвращаемые значения handle():
--   "swallow"  — событие обработано (init drag / mid-drag / drag-end), верни true
--   "tap"      — released после press без движения; caller должен обработать tap
--   "ignore"   — событие не наше (press вне area, или нет touch фазы)

local M = {}

-- Создать новый state. Все опции опциональны, но без on_step модуль ничего
-- не даёт (некуда сообщать о шагах).
function M.new(opts)
    opts = opts or {}
    return {
        step_px      = opts.step_px or 64,
        threshold_px = opts.threshold_px or 8,
        on_step      = opts.on_step,
        is_inside    = opts.is_inside,
        owner        = opts.owner,
        invert       = opts.invert and true or false,
        -- runtime state
        dragging     = false,
        start_y      = 0,
        last_y       = 0,
        accum        = 0,
        moved        = false,
    }
end

-- Принудительный сброс — например при смене view.
function M.reset(state)
    if not state then return end
    state.dragging = false
    state.accum    = 0
    state.moved    = false
end

-- Был ли последний завершившийся жест drag'ом (а не tap'ом). Caller может
-- проверить ПОСЛЕ handle() == "tap" чтобы решить — но обычно "tap" сам
-- говорит «не было движения», так что это редко нужно.
function M.was_drag(state)
    return state and state.moved or false
end

local function fire_step(state, delta)
    if state.on_step then
        state.on_step(state.owner, delta)
    end
end

-- Обработать одно touch-событие.
function M.handle(state, action)
    if not state or not action then return "ignore" end
    local x = action.x or 0
    local y = action.y or 0

    if action.pressed then
        local inside = true
        if state.is_inside then
            inside = state.is_inside(x, y) and true or false
        end
        if not inside then
            state.dragging = false
            return "ignore"
        end
        state.dragging = true
        state.start_y  = y
        state.last_y   = y
        state.accum    = 0
        state.moved    = false
        return "swallow"
    end

    if action.released then
        local was   = state.dragging
        local moved = state.moved
        state.dragging = false
        state.accum    = 0
        state.moved    = false
        if not was then return "ignore" end
        if moved then return "swallow" end
        return "tap"
    end

    -- Промежуточная фаза — движение пальца / мыши без pressed/released.
    if not state.dragging then return "ignore" end

    local dy = y - state.last_y
    state.last_y = y
    state.accum  = state.accum + dy

    if math.abs(y - state.start_y) >= state.threshold_px then
        state.moved = true
    end

    local sign = state.invert and -1 or 1
    while state.accum >= state.step_px do
        fire_step(state, sign)
        state.accum = state.accum - state.step_px
    end
    while state.accum <= -state.step_px do
        fire_step(state, -sign)
        state.accum = state.accum + state.step_px
    end

    return "swallow"
end

return M
