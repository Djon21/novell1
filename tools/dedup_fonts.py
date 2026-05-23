"""Remove duplicate manrope_16 font declarations from .gui files."""

import os

ROOT = r"C:\Users\GoldiM\novell1\AVOS\AVOS_G\main\gui\components_v2"
FILES = [
    "phone_sms_list_template.gui",
    "phone_sms_thread_template.gui",
    "phone_messenger_list_template.gui",
    "phone_messenger_chat_template.gui",
    "main_menu_v2.gui",
    "inventory_v2.gui",
    "hotspots_v2.gui",
]

for f in FILES:
    path = os.path.join(ROOT, f)
    with open(path, "r", encoding="utf-8") as fh:
        content = fh.read()

    first = content.find('name: "manrope_16"')
    second = content.find('name: "manrope_16"', first + 1)
    if second == -1:
        print(f"SKIP {f}: only one manrope_16")
        continue

    # Walk back to start of the fonts block
    start = content.rfind("fonts {", 0, second)
    # Find closing brace
    depth = 0
    end = start
    for i in range(start, len(content)):
        if content[i] == "{":
            depth += 1
        elif content[i] == "}":
            depth -= 1
            if depth == 0:
                end = i + 1
                break

    # Skip trailing whitespace/newlines
    after = end
    while after < len(content) and content[after] in " \t\r\n":
        after += 1

    content = content[:start] + content[after:]

    with open(path, "w", encoding="utf-8") as fh:
        fh.write(content)
    print(f"FIXED {f}")
