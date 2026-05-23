"""Add badges to prototype, remove top-level badge nodes from phone_v2_root.gui."""

PATH = r"C:\Users\GoldiM\novell1\AVOS\AVOS_G\main\gui\components_v2\phone_v2_root.gui"

with open(PATH, "r", encoding="utf-8") as f:
    text = f.read()

# 1. Insert badge nodes into prototype after app_label closing brace
badge_insert = """\
nodes {
  position {
    x: 30.0
    y: 30.0
    z: 0.585
  }
  size {
    x: 18.0
    y: 18.0
  }
  color {
    y: 0.239
    z: 0.498
  }
  type: TYPE_BOX
  texture: "icon_phone/ico_fon"
  id: "app_badge_bg"
  adjust_mode: ADJUST_MODE_STRETCH
  parent: "app_card_proto"
  slice9 {
    x: 0.1
    y: 0.1
    z: 0.1
    w: 0.1
  }
  alpha: 0.98
}
nodes {
  position {
    x: 30.0
    y: 30.0
    z: 0.59
  }
  size {
    x: 18.0
    y: 11.0
  }
  color {
    x: 0.102
    y: 0.024
    z: 0.063
  }
  type: TYPE_TEXT
  text: "0"
  font: "jb_mono_10"
  id: "app_badge_text"
  adjust_mode: ADJUST_MODE_STRETCH
  parent: "app_card_proto"
  outline_alpha: 0.0
  shadow_alpha: 0.0
}
"""

# Insert after app_label closing brace and before the icon section
insert_point = '  shadow_alpha: 0.0\n}\n'
next_section = '\nnodes {\n  position {\n    z: 0.568\n  }\n  size {\n    x: 36.0\n    y: 36.0\n  }\n  color {\n    x: 0.0\n    y: 0.239\n    z: 0.498\n  }\n  type: TYPE_BOX\n  texture: "icon_phone/icon_sms"\n  id: "app1_icon"\n'

old = insert_point + next_section
new = insert_point + badge_insert + next_section
text = text.replace(old, new, 1)

# 2. Remove top-level badge nodes (app1_badge_bg through app7_badge_text)
start_marker = 'id: "app1_badge_bg"'
end_marker = 'id: "app7_badge_text"'

start_idx = text.find(start_marker)
end_idx = text.find(end_marker)

if start_idx == -1 or end_idx == -1:
    print("ERROR: badge markers not found")
    exit(1)

# Walk back to start of app1_badge_bg's 'nodes {' block
block_start = text.rfind("nodes {", 0, start_idx)
# Walk forward from end of app7_badge_text to find its closing '}'
search_start = end_idx + len(end_marker)
depth = 0
block_end = search_start
for i in range(search_start, len(text)):
    if text[i] == "{":
        depth += 1
    elif text[i] == "}":
        if depth == 0:
            block_end = i + 1
            break
        depth -= 1

# Remove from the nodes { before app1_badge_bg through the } after app7_badge_text
text = text[:block_start] + text[block_end:]

orig_len = len(text)  # approximate
with open(PATH, "w", encoding="utf-8") as f:
    f.write(text)

# Also need to remove the second batch of badge nodes if they exist
# Let's check if app7 badge nodes are still there
if 'app7_badge_bg' in text:
    print("WARNING: app7_badge_bg still present in file")

print(f"File written")
