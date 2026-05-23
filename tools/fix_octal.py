"""Replace Lua octal escapes with actual UTF-8 chars in phone_v2_root.gui_script."""

import re

PATH = r"C:\Users\GoldiM\novell1\AVOS\AVOS_G\main\gui\components_v2\phone_v2_root.gui_script"

with open(PATH, "rb") as f:
    data = f.read()

text = data.decode("utf-8")

# Match Lua string literals containing octal escapes like "\320\241..."
# Pattern: a double-quoted string where the content is entirely octal sequences
def replace_octal_str(m):
    content = m.group(1)
    # Extract all \NNN sequences
    octals = re.findall(r"\\(\d{3})", content)
    if not octals:
        return m.group(0)
    raw = bytes(int(o, 8) for o in octals)
    try:
        decoded = raw.decode("utf-8")
    except UnicodeDecodeError:
        return m.group(0)
    return '"' + decoded + '"'

text = re.sub(r'"((?:\\\d{3})+)"', replace_octal_str, text)

with open(PATH, "wb") as f:
    f.write(text.encode("utf-8"))

# Verify no octal escapes remain
if "\\3" in text or "\\2" in text:
    print("WARNING: some octal escapes may remain")
else:
    print("OK: all octal escapes replaced")
