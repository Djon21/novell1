"""Fix open_phone/close_phone handlers in the gui_script."""

PATH = r"C:\Users\GoldiM\novell1\AVOS\AVOS_G\main\gui\components_v2\phone_v2_root.gui_script"

with open(PATH, "r", encoding="utf-8") as f:
    text = f.read()

# Normalize line endings
text = text.replace("\r\n", "\n")

old_open = """    elseif message_id == MSG.open_phone then
        self.visible = true
        set_nodes_enabled(CHROME_NODES, true)
        update_notif(self)
        update_wall_calendar()
        -- Открыть SMS по умолчанию
        local comp = APP_COMPONENT["sms"]
        if comp then msg.post(comp, MSG.open_app) end
        self.active_app = "sms"
        update_app_title("sms")
        dbg("[phone_v2_root] open_phone → sms")"""

new_open = """    elseif message_id == MSG.open_phone then
        self.visible = true
        set_nodes_enabled(CHROME_NODES, true)
        set_card_clones_enabled(true)
        update_notif(self)
        update_wall_calendar()
        local comp = APP_COMPONENT["sms"]
        if comp then msg.post(comp, MSG.open_app) end
        self.active_app = "sms"
        update_app_title("sms")
        dbg("[phone_v2_root] open_phone -> sms")"""

if old_open in text:
    text = text.replace(old_open, new_open, 1)
    print("OK: open_phone replaced")
else:
    print("FAIL: open_phone not found")
    idx = text.find("MSG.open_phone")
    if idx >= 0:
        print(repr(text[idx : idx + 300]))

old_close = """    elseif message_id == MSG.close_phone then
        -- Просто скрыть — НЕ постить обратно в UI_MGR (иначе loop),
        -- НЕ release_input_focus (держим фокус постоянно как phone_v2.gui_script)
        close_active_app(self)
        set_nodes_enabled(CHROME_NODES, false)
        self.visible = false
        dbg("[phone_v2_root] close_phone")"""

new_close = """    elseif message_id == MSG.close_phone then
        close_active_app(self)
        set_card_clones_enabled(false)
        set_nodes_enabled(CHROME_NODES, false)
        self.visible = false
        dbg("[phone_v2_root] close_phone")"""

if old_close in text:
    text = text.replace(old_close, new_close, 1)
    print("OK: close_phone replaced")
else:
    print("FAIL: close_phone not found")
    idx = text.find("MSG.close_phone")
    if idx >= 0:
        print(repr(text[idx : idx + 300]))

old_tile = """        -- Тайлы приложений
        for _, app in ipairs(APPS) do
            local n = get_node(app.key .. "_bg")
            if n and gui.is_enabled(n) and gui.pick_node(n, action.x, action.y) then"""

new_tile = """        -- Тайлы приложений
        for _, app in ipairs(APPS) do
            local c = _card_clones[app.key]
            local n = c and c.bg
            if n and gui.is_enabled(n) and gui.pick_node(n, action.x, action.y) then"""

if old_tile in text:
    text = text.replace(old_tile, new_tile, 1)
    print("OK: tile handler replaced")
else:
    print("FAIL: tile handler not found")

with open(PATH, "w", encoding="utf-8") as f:
    f.write(text)
print("Done")
