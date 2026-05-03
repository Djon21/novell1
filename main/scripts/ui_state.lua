-- ui_state.lua
-- Разделяемое состояние UI-слоя.
-- ui_manager_v2 пишет сюда при открытии/закрытии оверлеев.
-- hotspots_v2 и hud_v2 читают чтобы не пропускать клики под модалками.

local M = {}

-- true когда поверх сцены открыт хотя бы один модальный оверлей
-- (телефон, инвентарь, карта). Обновляется из ui_manager_v2.
M.modal_open = false

-- Armed-режим инвентаря: игрок выбрал предмет в инвентаре с verb=use,
-- инвентарь закрылся, и теперь следующий клик по hotspot'у должен
-- сработать как inv_use_<item>_on_<hotspot> (а не как обычный action).
-- При armed=nil используется обычный hotspot.action.
M.armed_inventory = nil  -- { item_id = "key", verb = "use" } или nil

function M.set_armed(item_id, verb)
    if not item_id or not verb then
        M.armed_inventory = nil
        return
    end
    M.armed_inventory = { item_id = item_id, verb = verb }
end

function M.clear_armed()
    M.armed_inventory = nil
end

function M.get_armed()
    return M.armed_inventory
end

return M
