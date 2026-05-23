"""Restore phone_v2_root.gui_script from pre-cards refactor + apply card clone changes."""

import subprocess, os

ROOT = r"C:\Users\GoldiM\novell1\AVOS\AVOS_G"
PATH = os.path.join(ROOT, "main", "gui", "components_v2", "phone_v2_root.gui_script")

# Get original file
result = subprocess.run(
    ["git", "show", "45873a5:main/gui/components_v2/phone_v2_root.gui_script"],
    capture_output=True, cwd=ROOT
)
text = result.stdout.decode("utf-8").replace("\r\n", "\n").replace("\r", "\n")

# Now apply the card clone refactor changes:

# 1. ROOT_CHROME: replace app1_card..app8_card with app_card_proto
text = text.replace(
    '    "app1_card", "app2_card", "app3_card", "app4_card",\n'
    '    "app5_card", "app6_card", "app7_card", "app8_card",',
    '    "app_card_proto",'
)

# 2. CHROME_NODES: remove per-app child nodes (bg, bg1, icon, label), keep badges
old_chrome = (
    '    "app1_badge_bg", "app1_badge_text",\n'
    '    "app7_badge_bg", "app7_badge_text",\n'
    '    "app_slot_vline_1"'
)
new_chrome = (
    '    "app_slot_vline_1"'
)
text = text.replace(old_chrome, new_chrome, 1)

# Remove the per-app bg/bg1/icon/label lines
old_lines = (
    '    "app1_bg", "app1_bg1", "app1_icon", "app1_label",\n'
    '    "app2_bg", "app2_bg1", "app2_icon", "app2_label",\n'
    '    "app3_bg", "app3_bg1", "app3_icon", "app3_label",\n'
    '    "app4_bg", "app4_bg1", "app4_icon", "app4_label",\n'
    '    "app5_bg", "app5_bg1", "app5_icon", "app5_label",\n'
    '    "app6_bg", "app6_bg1", "app6_icon", "app6_label",\n'
    '    "app7_bg", "app7_bg1", "app7_icon", "app7_label",\n'
    '    "app8_bg", "app8_bg1", "app8_icon", "app8_label",'
)
text = text.replace(old_lines, '')

# 3. Add _card_clones, APP_CARD_DATA, init_app_card_clones, set_card_clones_enabled, set_card_badge

# Insert _card_clones after APP_TITLES end
text = text.replace(
    '}\n\nlocal CHROME_NODES',
    '}\n\nlocal _card_clones = {}\n\nlocal APP_CARD_DATA = {\n'
    '    { key = "app1", id = "sms",    x = 143, y = 422, bg_r = 0.0,    bg_g = 0.239, bg_b = 0.498, icon = "icon_sms",     label = "СМС" },\n'
    '    { key = "app2", id = "call",   x = 245, y = 422, bg_r = 0.490,  bg_g = 0.976, bg_b = 0.0,   icon = "icon_call",    label = "Звонки" },\n'
    '    { key = "app3", id = "map",    x = 347, y = 422, bg_r = 0.0,    bg_g = 0.702, bg_b = 0.278, icon = "icon_map",     label = "Карта" },\n'
    '    { key = "app4", id = "notes",  x = 348, y = 303, bg_r = 0.953,  bg_g = 0.925, bg_b = 0.851, icon = "icon_notes",   label = "Улики" },\n'
    '    { key = "app5", id = "quests", x = 245, y = 303, bg_r = 0.478,  bg_g = 0.361, bg_b = 0.0,   icon = "icon_quests",  label = "Квесты" },\n'
    '    { key = "app6", id = "mail",   x = 142, y = 183, bg_r = 0.0,    bg_g = 0.239, bg_b = 0.498, icon = "icon_mail",    label = "Почта" },\n'
    '    { key = "app7", id = "messenger", x = 141, y = 303, bg_r = 0.282, bg_g = 0.961, bg_b = 0.0, icon = "icon_sms",   label = "Чаты" },\n'
    '    { key = "app8", id = "term",   x = 247, y = 183, bg_r = 0.0,    bg_g = 0.702, bg_b = 0.278, icon = "icon_terminal", label = "Терминал" },\n'
    '}\n\nlocal CHROME_NODES'
)

# 4. Add init_app_card_clones and set_card_clones_enabled before function init
text = text.replace(
    'local function forward_active_app_input(self, action_id, action)',
    'local function set_card_badge(key, n)\n'
    '    local c = _card_clones[key]\n'
    '    if not c then return end\n'
    '    local show = n > 0\n'
    '    if c.badge_bg then gui.set_enabled(c.badge_bg, show) end\n'
    '    if c.badge_text then\n'
    '        gui.set_enabled(c.badge_text, show)\n'
    '        gui.set_text(c.badge_text, tostring(n))\n'
    '    end\n'
    'end\n\n'
    'local function set_badge(self, key, value)\n'
    '    if not _card_clones[key] then return end\n'
    '    local n = tonumber(value) or 0\n'
    '    if (not self.visible) and n > 0 then n = 1 end\n'
    '    set_card_badge(key, n)\n'
    'end\n\n'
    'local function init_app_card_clones()\n'
    '    local proto = U.get_node("app_card_proto")\n'
    '    local root = gui.get_node("phone_root")\n'
    '    if not proto then return end\n'
    '\n'
    '    for _, app in ipairs(APP_CARD_DATA) do\n'
    '        local cmap = gui.clone_tree(proto)\n'
    '        if cmap then\n'
    '            local card = cmap["app_card_proto"]\n'
    '            local bg   = cmap["app_bg"]\n'
    '            local bg1  = cmap["app_bg1"]\n'
    '            local label = cmap["app_label"]\n'
    '            local badge_bg   = cmap["app_badge_bg"]\n'
    '            local badge_text = cmap["app_badge_text"]\n'
    '\n'
    '            gui.set_position(card, vmath.vector3(app.x, app.y, 0))\n'
    '            if root then gui.set_parent(card, root) end\n'
    '\n'
    '            gui.set_color(bg, vmath.vector4(app.bg_r, app.bg_g, app.bg_b, 1))\n'
    '            gui.set_text(label, app.label)\n'
    '\n'
    '            gui.set_enabled(badge_bg, false)\n'
    '            gui.set_enabled(badge_text, false)\n'
    '\n'
    '            local icon = U.get_node(app.key .. "_icon")\n'
    '            if icon then gui.set_parent(icon, card) end\n'
    '\n'
    '            _card_clones[app.key] = {\n'
    '                card = card, bg = bg, badge_bg = badge_bg, badge_text = badge_text,\n'
    '            }\n'
    '        end\n'
    '    end\n'
    'end\n\n'
    'local function set_card_clones_enabled(enabled)\n'
    '    for _, c in pairs(_card_clones) do\n'
    '        gui.set_enabled(c.card, enabled)\n'
    '    end\n'
    'end\n\n'
    'local function forward_active_app_input(self, action_id, action)'
)

# 5. Update set_badge calls: old is `set_badge(self, "app1", n)` current param order already matches
#    But the old `set_badge` had (self_or_prefix, prefix_or_value, maybe_value) signature.
#    Our new `set_badge(self, key, value)` should work with calls like `set_badge(self, "app1", sms_unread)`

# 6. Update init(): add init_app_card_clones() and set_card_clones_enabled
text = text.replace(
    'function init(self)\n'
    '    self.visible    = false\n'
    '    self.active_app = nil\n'
    '\n'
    '    local root = gui.get_node("phone_root")\n'
    '    if root then\n'
    '        for _, id in ipairs(ROOT_CHROME) do\n'
    '            local n = U.get_node(id)\n'
    '            if n then gui.set_parent(n, root) end\n'
    '        end\n'
    '        apply_adaptive_layout()\n'
    '    end\n'
    '\n'
    '    set_nodes_enabled(CHROME_NODES, false)\n'
    '    update_app_title("sms")\n'
    '    update_wall_calendar()\n'
    '    msg.post(".", "acquire_input_focus")\n'
    'end',
    'function init(self)\n'
    '    self.visible    = false\n'
    '    self.active_app = nil\n'
    '\n'
    '    local root = gui.get_node("phone_root")\n'
    '    if root then\n'
    '        for _, id in ipairs(ROOT_CHROME) do\n'
    '            local n = U.get_node(id)\n'
    '            if n then gui.set_parent(n, root) end\n'
    '        end\n'
    '        apply_adaptive_layout()\n'
    '    end\n'
    '\n'
    '    set_nodes_enabled(CHROME_NODES, false)\n'
    '    init_app_card_clones()\n'
    '    set_card_clones_enabled(false)\n'
    '    update_app_title("sms")\n'
    '    update_wall_calendar()\n'
    '    msg.post(".", "acquire_input_focus")\n'
    'end'
)

# 7. open_phone: add set_card_clones_enabled, remove comment
text = text.replace(
    '    elseif message_id == MSG.open_phone then\n'
    '        self.visible = true\n'
    '        set_nodes_enabled(CHROME_NODES, true)\n'
    '        update_notif(self)\n'
    '        update_wall_calendar()\n'
    '        -- Открыть SMS по умолчанию\n'
    '        local comp = APP_COMPONENT["sms"]\n'
    '        if comp then msg.post(comp, MSG.open_app) end\n'
    '        self.active_app = "sms"\n'
    '        update_app_title("sms")\n'
    '        dbg("[phone_v2_root] open_phone -> sms")',
    '    elseif message_id == MSG.open_phone then\n'
    '        self.visible = true\n'
    '        set_nodes_enabled(CHROME_NODES, true)\n'
    '        set_card_clones_enabled(true)\n'
    '        update_notif(self)\n'
    '        update_wall_calendar()\n'
    '        local comp = APP_COMPONENT["sms"]\n'
    '        if comp then msg.post(comp, MSG.open_app) end\n'
    '        self.active_app = "sms"\n'
    '        update_app_title("sms")\n'
    '        dbg("[phone_v2_root] open_phone -> sms")'
)

# 8. close_phone: add set_card_clones_enabled
text = text.replace(
    '    elseif message_id == MSG.close_phone then\n'
    '        -- Просто скрыть — НЕ постить обратно в UI_MGR (иначе loop),\n'
    '        -- НЕ release_input_focus (держим фокус постоянно как phone_v2.gui_script)\n'
    '        close_active_app(self)\n'
    '        set_nodes_enabled(CHROME_NODES, false)\n'
    '        self.visible = false\n'
    '        dbg("[phone_v2_root] close_phone")',
    '    elseif message_id == MSG.close_phone then\n'
    '        close_active_app(self)\n'
    '        set_card_clones_enabled(false)\n'
    '        set_nodes_enabled(CHROME_NODES, false)\n'
    '        self.visible = false\n'
    '        dbg("[phone_v2_root] close_phone")'
)

# 9. Tile handler: use _card_clones
text = text.replace(
    '        for _, app in ipairs(APPS) do\n'
    '            local n = get_node(app.key .. "_bg")\n'
    '            if n and gui.is_enabled(n) and gui.pick_node(n, action.x, action.y) then',
    '        for _, app in ipairs(APPS) do\n'
    '            local c = _card_clones[app.key]\n'
    '            local n = c and c.bg\n'
    '            if n and gui.is_enabled(n) and gui.pick_node(n, action.x, action.y) then'
)

with open(PATH, "w", encoding="utf-8") as f:
    f.write(text)
print("Written")
