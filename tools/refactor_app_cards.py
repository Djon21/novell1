"""Refactor phone_v2_root.gui: one app card prototype + 8 static icons + badges."""

PATH = r"C:\Users\GoldiM\novell1\AVOS\AVOS_G\main\gui\components_v2\phone_v2_root.gui"

with open(PATH, "r", encoding="utf-8") as f:
    text = f.read()

# Split at known landmarks: card section starts at app1_card, ends at side_panel
start_marker = 'id: "app_card_proto"'
end_marker = 'id: "app1_badge_bg"'

start_idx = text.find(start_marker)
end_idx = text.find(end_marker)

if start_idx == -1 or end_idx == -1:
    print("ERROR: markers not found")
    exit(1)

# Go back to beginning of app1_card's 'nodes {' block
block_start = text.rfind("nodes {", 0, start_idx)
# Go back to beginning of side_panel's 'nodes {' block
block_end = text.rfind("nodes {", 0, end_idx)

# Keep everything before card section + everything from side_panel onward
prefix = text[:block_start]
suffix = text[block_end:]

# Build replacement card section
CARD_PROTO = """\
nodes {
  position {
    x: 143.0
    y: 422.0
  }
  size {
    x: 82.0
    y: 76.0
  }
  type: TYPE_BOX
  id: "app_card_proto"
  pivot: PIVOT_SW
  adjust_mode: ADJUST_MODE_STRETCH
  alpha: 0.0
}
nodes {
  position {
    z: 0.55
  }
  size {
    x: 62.0
    y: 62.0
  }
  color {
    y: 0.23921569
    z: 0.49803922
  }
  type: TYPE_BOX
  texture: "icon_phone/ico_fon"
  id: "app_bg"
  adjust_mode: ADJUST_MODE_STRETCH
  parent: "app_card_proto"
  slice9 {
    x: 0.1
    y: 0.1
    z: 0.1
    w: 0.1
  }
}
nodes {
  position {
    z: 0.55
  }
  size {
    x: 62.0
    y: 62.0
  }
  color {
    x: 0.07058824
    y: 0.047058824
    z: 0.15686275
  }
  type: TYPE_BOX
  texture: "icon_phone/ico_fon"
  id: "app_bg1"
  adjust_mode: ADJUST_MODE_STRETCH
  parent: "app_card_proto"
  slice9 {
    x: 0.1
    y: 0.1
    z: 0.1
    w: 0.1
  }
  alpha: 0.75
}
nodes {
  position {
    y: -44.0
    z: 0.574
  }
  size {
    x: 82.0
    y: 14.0
  }
  color {
    x: 0.953
    y: 0.925
    z: 0.851
  }
  type: TYPE_TEXT
  text: "\\320\\241\\320\\234\\320\\241"
  font: "jb_mono_bold_14"
  id: "app_label"
  adjust_mode: ADJUST_MODE_STRETCH
  parent: "app_card_proto"
  alpha: 0.82
  outline_alpha: 0.0
  shadow_alpha: 0.0
}
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

# Icon nodes (static, no parent — will be reparented in script)
ICONS = {}
ICONS["app1"] = (0.0, 0.239, 0.498, "icon_phone/icon_sms")
ICONS["app2"] = (0.282, 0.961, 0.0, "icon_phone/icon_call")
ICONS["app3"] = (0.0, 0.702, 0.278, "icon_phone/icon_map")
ICONS["app4"] = (0.953, 0.925, 0.851, "icon_phone/icon_notes")
ICONS["app5"] = (0.478, 0.361, 0.0, "icon_phone/icon_quests")
ICONS["app6"] = (0.0, 0.239, 0.498, "icon_phone/icon_mail")
ICONS["app7"] = (0.282, 0.961, 0.0, "icon_phone/icon_sms")
ICONS["app8"] = (0.0, 0.702, 0.278, "icon_phone/icon_terminal")

icon_blocks = []
for k, (r, g, b, tex) in ICONS.items():
    icon_blocks.append(f"""\
nodes {{
  position {{
    z: 0.568
  }}
  size {{
    x: 36.0
    y: 36.0
  }}
  color {{
    x: {r}
    y: {g}
    z: {b}
  }}
  type: TYPE_BOX
  texture: "{tex}"
  id: "{k}_icon"
  adjust_mode: ADJUST_MODE_STRETCH
}}
""")

# Badge nodes (app1 and app7 only)
BADGE = """\
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
  id: "app1_badge_bg"
  adjust_mode: ADJUST_MODE_STRETCH
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
  id: "app1_badge_text"
  adjust_mode: ADJUST_MODE_STRETCH
  outline_alpha: 0.0
  shadow_alpha: 0.0
}
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
    x: 0.282
    y: 0.961
  }
  type: TYPE_BOX
  texture: "icon_phone/ico_fon"
  id: "app7_badge_bg"
  adjust_mode: ADJUST_MODE_STRETCH
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
  id: "app7_badge_text"
  adjust_mode: ADJUST_MODE_STRETCH
  outline_alpha: 0.0
  shadow_alpha: 0.0
}
"""

new_section = CARD_PROTO + "\n".join(icon_blocks)
result = prefix + new_section + suffix

orig_len = len(text)
print(f"{orig_len} -> {len(result)} bytes ({len(result) - orig_len:+d})")

with open(PATH, "w", encoding="utf-8") as f:
    f.write(result)
