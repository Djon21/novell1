"""Debug and fix the gui_script file - v3."""
PATH = r"C:\Users\GoldiM\novell1\AVOS\AVOS_G\main\gui\components_v2\phone_v2_root.gui_script"

import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

with open(PATH, "rb") as f:
    data = f.read()

text = data.decode("utf-8").replace("\r\n", "\n")

# Check for the round-trip fidelity: find the comment and extract surrounding text
idx = text.find("Открыть SMS по умолчанию")
if idx >= 0:
    # Get the 10 lines around this
    lines = text[:idx].split("\n")
    print(f"Comment is on line {len(lines)}")
    # Show lines around 8 before
    context_lines = text.split("\n")[len(lines)-3:len(lines)+5]
    for i, line in enumerate(context_lines):
        print(f"  {i}: {repr(line)}")
    
    # Now reconstruct old_open from the ACTUAL text
    start_line = len(lines) - 3  # number of lines before 'Открыть'
    all_lines = text.split("\n")
    # The handler starts at 'elseif message_id == MSG.open_phone'
    for i in range(start_line, 0, -1):
        if all_lines[i].startswith("    elseif message_id == MSG.open_phone"):
            start_line = i
            break
    
    # Build old_open from actual lines (from elseif through dbg line)
    actual_lines = []
    i = start_line
    while i < len(all_lines):
        line = all_lines[i]
        actual_lines.append(line)
        i += 1
        if line.strip().startswith('dbg'):
            break
    
    old_open_actual = "\n".join(actual_lines)
    print(f"Actual old_open ({len(old_open_actual)} chars):")
    print(repr(old_open_actual[:200]))
    
    # Now build new_open from it
    new_open_actual = old_open_actual.replace(
        "        set_nodes_enabled(CHROME_NODES, true)\n"
        "        update_notif(self)",
        "        set_nodes_enabled(CHROME_NODES, true)\n"
        "        set_card_clones_enabled(true)\n"
        "        update_notif(self)"
    )
    new_open_actual = new_open_actual.replace(
        "        -- Открыть SMS по умолчанию\n",
        ""
    )
    new_open_actual = new_open_actual.replace(
        '        dbg("[phone_v2_root] open_phone → sms")',
        '        dbg("[phone_v2_root] open_phone -> sms")'
    )
    
    print(f"\nReplacing old_open with new_open ({len(new_open_actual)} chars)")
    text = text.replace(old_open_actual, new_open_actual, 1)
    print(f"  old_open count after replace: {text.count(old_open_actual)}")

# Close phone
idx2 = text.find("MSG.close_phone then")
if idx2 >= 0:
    lines_before = text[:idx2].count("\n")
    all_lines = text.split("\n")
    print(f"\nclose_phone at line {lines_before}")
    
    # Find start of handler
    start = lines_before
    for i in range(lines_before, 0, -1):
        if all_lines[i].startswith("    elseif message_id"):
            start = i
            break
    
    # Collect lines until next elseif or function end
    actual_close = []
    i = start
    while i < len(all_lines):
        line = all_lines[i]
        if actual_close and (line.startswith("    elseif") or line.startswith("end")):
            break
        actual_close.append(line)
        i += 1
        if line.strip().startswith('dbg("[phone_v2_root] close'):
            break
    
    old_close_actual = "\n".join(actual_close)
    print(f"Actual old_close ({len(old_close_actual)} chars):")
    print(repr(old_close_actual[:200]))
    
    if "set_card_clones_enabled" in old_close_actual:
        print("  close_phone already updated, skipping")
    else:
        new_close_actual = old_close_actual.replace(
            "        -- Просто скрыть — НЕ постить обратно в UI_MGR (иначе loop),\n"
            "        -- НЕ release_input_focus (держим фокус постоянно как phone_v2.gui_script)\n"
            "        close_active_app(self)\n"
            "        set_nodes_enabled(CHROME_NODES, false)",
            "        close_active_app(self)\n"
            "        set_card_clones_enabled(false)\n"
            "        set_nodes_enabled(CHROME_NODES, false)"
        )
        text = text.replace(old_close_actual, new_close_actual, 1)
        print(f"  replaced")

# Tile handler
if '_card_clones[app.key]' in text:
    print("Tile handler already updated, skipping")
elif 'get_node(app.key .. "_bg")' in text:
    old_tile_actual = (
        '        for _, app in ipairs(APPS) do\n'
        '            local n = get_node(app.key .. "_bg")\n'
        '            if n and gui.is_enabled(n) and gui.pick_node(n, action.x, action.y) then'
    )
    new_tile_actual = (
        '        for _, app in ipairs(APPS) do\n'
        '            local c = _card_clones[app.key]\n'
        '            local n = c and c.bg\n'
        '            if n and gui.is_enabled(n) and gui.pick_node(n, action.x, action.y) then'
    )
    text = text.replace(old_tile_actual, new_tile_actual, 1)
    print("Tile handler replaced")

with open(PATH, "wb") as f:
    f.write(text.replace("\n", "\r\n").encode("utf-8"))
print("\nWritten")
