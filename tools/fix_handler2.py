"""Debug and fix the gui_script file."""
import re

PATH = r"C:\Users\GoldiM\novell1\AVOS\AVOS_G\main\gui\components_v2\phone_v2_root.gui_script"

with open(PATH, "rb") as f:
    data = f.read()

# Check for the exact bytes of the open_phone comment
comment_bytes = b'-- \xd0\x9e\xd1\x82\xd0\xba\xd1\x80\xd1\x8b\xd1\x82\xd1\x8c SMS \xd0\xbf\xd0\xbe \xd1\x83\xd0\xbc\xd0\xbe\xd0\xbb\xd1\x87\xd0\xb0\xd0\xbd\xd0\xb8\xd1\x8e'
idx = data.find(comment_bytes)
if idx >= 0:
    print(f"Found comment at byte {idx}")
else:
    print("Comment NOT found as exact bytes")
    # Try partial
    for part in [b'\xd0\x9e\xd1\x82\xd0\xba\xd1\x80\xd1\x8b\xd1\x82\xd1\x8c', b'SMS \xd0\xbf\xd0\xbe']:
        idx2 = data.find(part)
        if idx2 >= 0:
            print(f"  Found partial '{part[:10]}' at {idx2}: {data[idx2-20:idx2+60]}")

# Now do the replacements properly at byte level
# Replace CRLF with LF for text processing
text = data.decode("utf-8").replace("\r\n", "\n")

old_open = (
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
    '        dbg("[phone_v2_root] open_phone → sms")'
)

new_open = (
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

count = text.count(old_open)
print(f"old_open appears {count} times")
if count > 0:
    text = text.replace(old_open, new_open, 1)
    print("Replaced open_phone")

old_close = (
    '    elseif message_id == MSG.close_phone then\n'
    '        -- Просто скрыть — НЕ постить обратно в UI_MGR (иначе loop),\n'
    '        -- НЕ release_input_focus (держим фокус постоянно как phone_v2.gui_script)\n'
    '        close_active_app(self)\n'
    '        set_nodes_enabled(CHROME_NODES, false)\n'
    '        self.visible = false\n'
    '        dbg("[phone_v2_root] close_phone")'
)

new_close = (
    '    elseif message_id == MSG.close_phone then\n'
    '        close_active_app(self)\n'
    '        set_card_clones_enabled(false)\n'
    '        set_nodes_enabled(CHROME_NODES, false)\n'
    '        self.visible = false\n'
    '        dbg("[phone_v2_root] close_phone")'
)

count = text.count(old_close)
print(f"old_close appears {count} times")
if count > 0:
    text = text.replace(old_close, new_close, 1)
    print("Replaced close_phone")

old_tile = (
    '        for _, app in ipairs(APPS) do\n'
    '            local n = get_node(app.key .. "_bg")\n'
    '            if n and gui.is_enabled(n) and gui.pick_node(n, action.x, action.y) then'
)

new_tile = (
    '        for _, app in ipairs(APPS) do\n'
    '            local c = _card_clones[app.key]\n'
    '            local n = c and c.bg\n'
    '            if n and gui.is_enabled(n) and gui.pick_node(n, action.x, action.y) then'
)

count = text.count(old_tile)
print(f"old_tile appears {count} times")
if count > 0:
    text = text.replace(old_tile, new_tile, 1)
    print("Replaced tile handler")

# Write back with CRLF
with open(PATH, "wb") as f:
    f.write(text.replace("\n", "\r\n").encode("utf-8"))
print("Written")
