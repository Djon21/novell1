"""Replace Manrope-Medium_16 → manrope_16 (Regular) in all .gui files."""

import os
import glob

ROOT = r"C:\Users\GoldiM\novell1\AVOS\AVOS_G"

files = [
    r"main\gui\components_v2\phone_sms_list_template.gui",
    r"main\gui\components_v2\phone_sms_thread_template.gui",
    r"main\gui\components_v2\phone_messenger_list_template.gui",
    r"main\gui\components_v2\phone_messenger_chat_template.gui",
    r"main\gui\components_v2\main_menu_v2.gui",
    r"main\gui\components_v2\inventory_v2.gui",
    r"main\gui\components_v2\hotspots_v2.gui",
]

replacements = [
    ('name: "Manrope-Medium_16"\n  font: "/main/fonts/Manrope-Medium_16.font"',
     'name: "manrope_16"\n  font: "/main/fonts/manrope_16.font"'),
    ('font: "Manrope-Medium_16"', 'font: "manrope_16"'),
]

for relpath in files:
    path = os.path.join(ROOT, relpath)
    if not os.path.exists(path):
        print(f"SKIP {relpath}: not found")
        continue
    with open(path, "r", encoding="utf-8") as f:
        text = f.read()
    orig = len(text)
    for old, new in replacements:
        text = text.replace(old, new)
    if len(text) != orig:
        print(f"OK   {relpath}: {orig} -> {len(text)} bytes")
    else:
        print(f"SAME {relpath}: no changes")
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)
