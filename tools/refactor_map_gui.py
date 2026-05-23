"""Refactor phone_map.gui: replace 8 hardcoded POI groups with one prototype."""

import re

PATH = r"C:\Users\GoldiM\novell1\AVOS\AVOS_G\main\gui\components_v2\phone_map.gui"

with open(PATH, "r", encoding="utf-8") as f:
    text = f.read()

# ---------------------------------------------------------------------------
# 1) Rename poi_home -> poi_proto and its children
# ---------------------------------------------------------------------------
text = text.replace('id: "poi_home"', 'id: "poi_proto"')
text = text.replace('parent: "poi_home"', 'parent: "poi_proto"')
text = text.replace('id: "poi_home_hitbox"', 'id: "poi_proto_hitbox"')
text = text.replace('id: "poi_home_stem"', 'id: "poi_proto_stem"')
text = text.replace('id: "poi_home_circle"', 'id: "poi_proto_circle"')
text = text.replace('id: "poi_home_center"', 'id: "poi_proto_center"')
text = text.replace('id: "poi_home_icon"', 'id: "poi_proto_icon"')

# Set prototype children colors to white (1,1,1) — script sets them per POI
# The stem color block
text = text.replace(
    '  color {\n    x: 0.714\n    y: 0.361\n  }\n  type: TYPE_BOX\n  texture: "map2/poi_stem"\n  id: "poi_proto_stem"',
    '  color {\n    x: 1\n    y: 1\n    z: 1\n  }\n  type: TYPE_BOX\n  texture: "map2/poi_stem"\n  id: "poi_proto_stem"'
)
# The circle color block
text = text.replace(
    '  color {\n    x: 0.714\n    y: 0.361\n  }\n  type: TYPE_BOX\n  texture: "map2/poi_circle"\n  id: "poi_proto_circle"',
    '  color {\n    x: 1\n    y: 1\n    z: 1\n  }\n  type: TYPE_BOX\n  texture: "map2/poi_circle"\n  id: "poi_proto_circle"'
)
# The center color block
text = text.replace(
    '  color {\n    x: 0.714\n    y: 0.361\n  }\n  type: TYPE_BOX\n  texture: "map2/poi_center_dark"\n  id: "poi_proto_center"',
    '  color {\n    x: 1\n    y: 1\n    z: 1\n  }\n  type: TYPE_BOX\n  texture: "map2/poi_center_dark"\n  id: "poi_proto_center"'
)
# The icon color block
text = text.replace(
    '  color {\n    x: 0.714\n    y: 0.361\n  }\n  type: TYPE_BOX\n  texture: "map2/poi_icon_home"\n  id: "poi_proto_icon"',
    '  color {\n    x: 1\n    y: 1\n    z: 1\n  }\n  type: TYPE_BOX\n  texture: "map2/poi_icon_home"\n  id: "poi_proto_icon"'
)

# Reset child y-offsets to 0 for prototype (script handles per-POI)
# hitbox stays at z:0.49 (no y)
# stem stays at y:-48 (all POIs have this)
# circle: was y:8 -> remove y offset, keep z:0.53
text = text.replace(
    '  position {\n    y: 8.0\n    z: 0.53\n  }\n  size {\n    x: 100.0\n    y: 100.0\n  }\n  color {\n    x: 1\n    y: 1\n    z: 1\n  }\n  type: TYPE_BOX\n  texture: "map2/poi_circle"\n  id: "poi_proto_circle"',
    '  position {\n    z: 0.53\n  }\n  size {\n    x: 100.0\n    y: 100.0\n  }\n  color {\n    x: 1\n    y: 1\n    z: 1\n  }\n  type: TYPE_BOX\n  texture: "map2/poi_circle"\n  id: "poi_proto_circle"'
)
# center: was y:8 -> remove y offset, keep z:0.54
text = text.replace(
    '  position {\n    y: 8.0\n    z: 0.54\n  }\n  size {\n    x: 110.0\n    y: 110.0\n  }\n  color {\n    x: 1\n    y: 1\n    z: 1\n  }\n  type: TYPE_BOX\n  texture: "map2/poi_center_dark"\n  id: "poi_proto_center"',
    '  position {\n    z: 0.54\n  }\n  size {\n    x: 110.0\n    y: 110.0\n  }\n  color {\n    x: 1\n    y: 1\n    z: 1\n  }\n  type: TYPE_BOX\n  texture: "map2/poi_center_dark"\n  id: "poi_proto_center"'
)
# icon: was y:12 -> remove y offset, keep z:0.55
text = text.replace(
    '  position {\n    y: 12.0\n    z: 0.55\n  }\n  size {\n    x: 50.0\n    y: 50.0\n  }\n  color {\n    x: 1\n    y: 1\n    z: 1\n  }\n  type: TYPE_BOX\n  texture: "map2/poi_icon_home"\n  id: "poi_proto_icon"',
    '  position {\n    z: 0.55\n  }\n  size {\n    x: 50.0\n    y: 50.0\n  }\n  color {\n    x: 1\n    y: 1\n    z: 1\n  }\n  type: TYPE_BOX\n  texture: "map2/poi_icon_home"\n  id: "poi_proto_icon"'
)

# ---------------------------------------------------------------------------
# 2) Remove 7 other POI groups: from poi_work through poi_archive_icon
#    Use the unique anchor after poi_proto_icon to poi_work transition
# ---------------------------------------------------------------------------
# After poi_proto_icon closes with "inherit_alpha: true\n}", the next
# line is "nodes {" which begins poi_work. Delete everything from
# that "nodes {" up through the end of poi_archive_icon
# (which is the last node before grp_confirm).

anchor_end = '''  texture: "map2/poi_icon_archive"
  id: "poi_archive_icon"
  adjust_mode: ADJUST_MODE_STRETCH
  parent: "poi_archive"
  layer: "ui"
  inherit_alpha: true
}
nodes {
  position {
    x: 32.0
    z: 0.1
  }
  type: TYPE_BOX
  id: "grp_confirm"'''

anchor_start = '''inherit_alpha: true
}
nodes {
  position {
    x: 703.0
    y: 314.0
  }
  size {
    x: 0.9
    y: 0.9
  }
  type: TYPE_BOX
  id: "poi_work"'''

# Find the block to delete: from the closing of poi_proto to grp_confirm
# The closing of poi_proto_icon looks like:
#   inherit_alpha: true
# }
# nodes {          <-- this is the start of poi_work

proto_end = '''  inherit_alpha: true
}
nodes {
  position {
    x: 703.0
    y: 314.0
  }'''

confirm_start = '''  texture: "map2/poi_icon_archive"
  id: "poi_archive_icon"
  adjust_mode: ADJUST_MODE_STRETCH
  parent: "poi_archive"
  layer: "ui"
  inherit_alpha: true
}
nodes {
  position {
    x: 32.0
    z: 0.1
  }
  type: TYPE_BOX
  id: "grp_confirm"'''

idx_start = text.find(proto_end)
idx_end = text.find(confirm_start)

if idx_start == -1:
    print("ERROR: proto_end anchor not found")
elif idx_end == -1:
    print("ERROR: confirm_start anchor not found")
else:
    # Delete from the "nodes {" after proto_icon closing through poi_archive_icon closing
    delete_from = idx_start + len("  inherit_alpha: true\n}\n")
    delete_to = idx_end + len('''  texture: "map2/poi_icon_archive"
  id: "poi_archive_icon"
  adjust_mode: ADJUST_MODE_STRETCH
  parent: "poi_archive"
  layer: "ui"
  inherit_alpha: true
}\n''')
    
    before = text[:delete_from]
    after = text[delete_to:]
    text = before + after
    print(f"Deleted {delete_to - delete_from} bytes ({idx_end - idx_start} chars of POI groups)")

# ---------------------------------------------------------------------------
# 3) Write back
# ---------------------------------------------------------------------------
with open(PATH, "w", encoding="utf-8") as f:
    f.write(text)

print("Done. New file size:", len(text), "bytes")
