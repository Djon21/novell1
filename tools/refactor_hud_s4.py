# -*- coding: utf-8 -*-
"""
Рефакторинг HUD под Спринт 4.

Изменения в novel_ui.gui:
  1. Удаляем 4 слота hud_slot_*_1..4 (16 нод) — старый «рюкзак внутри HUD».
  2. Добавляем 2 постоянные HUD-иконки:
        hud_backpack_* — рюкзак (дипломат U+E8F9), всегда виден
        hud_phone_*    — телефон (U+E32C), enabled по флагу has_phone
     Каждая как stack: circle (bg) + ring + icon + hit (hitbox).
  3. Добавляем инвентарную модалку inv_modal_*:
        dim (z=0.94) + panel 720×480 (z=0.945) + title + close_btn/text
        + сетка slot_1..slot_12 (4 cols × 3 rows): circle/ring/icon/hit
     Слоты — дети panel, поэтому следуют его enabled.
  4. Поднимаем z у item_modal_dim и item_modal_panel, чтобы карточка
     описания предмета была поверх инвентарной модалки:
        item_modal_dim: 0.95 → 0.97
        item_modal_panel: 0.96 → 0.98
  5. Обновляем иконку модалки item_modal_icon (должна лежать ПОД
     item_modal_panel чтобы наследовать его enabled).
"""
import io, re

GUI = r"C:\Users\GoldiM\novell1\novell1\main\gui\novel_ui.gui"
with io.open(GUI, "r", encoding="utf-8") as f:
    text = f.read()

# --- 1. Удаляем hud_slot_* блоки ---------------------------------------
# Блоки nodes { ... id: "hud_slot_<kind>_<i>" ... } подряд 16 штук.
# Удаляем по маркеру — каждый блок начинается с "nodes {" и заканчивается "}".
# Используем regex с non-greedy.
pattern_hud_old = re.compile(
    r'nodes \{\n(?:[^{}]|\{[^{}]*\})*?id: "hud_slot_(?:circle|ring|icon|hit)_\d+"[^}]*\}\n',
    re.DOTALL
)
removed = len(pattern_hud_old.findall(text))
text = pattern_hud_old.sub("", text)
print(f"Removed old hud_slot blocks: {removed}")

# --- 2. Поднимаем z item_modal_dim/panel -------------------------------
# item_modal_dim: z 0.95 → 0.97
def bump_z_in_block(src, node_id, old_z, new_z):
    id_marker = f'id: "{node_id}"'
    idx_id = src.find(id_marker)
    if idx_id == -1:
        raise SystemExit(f"id {node_id} not found")
    block_start = src.rfind("nodes {", 0, idx_id)
    block = src[block_start:idx_id]
    new_block = block.replace(f"z: {old_z}", f"z: {new_z}", 1)
    if new_block == block:
        raise SystemExit(f"z: {old_z} not found in block of {node_id}")
    return src[:block_start] + new_block + src[idx_id:]

text = bump_z_in_block(text, "item_modal_dim",   "0.95", "0.97")
text = bump_z_in_block(text, "item_modal_panel", "0.96", "0.98")

# --- 3. Строим новый HUD -----------------------------------------------
def hud_icon(id_prefix, cx, cy, icon_char, enabled=True):
    """Возвращает 4 ноды для HUD-иконки: circle/ring/icon/hit."""
    en = "true" if enabled else "false"
    # В .gui дефолт enabled=true, пишем только если false. Но чтобы быть
    # явными — зададим поле для hit всегда (cat: true by default, но
    # для единообразия оставим как есть: не пишем → default true).
    blocks = []
    blocks.append(f'''nodes {{
  position {{
    x: {cx}.0
    y: {cy}.0
    z: 0.90
  }}
  size {{
    x: 80.0
    y: 80.0
  }}
  color {{
    x: 0.0
    y: 0.0
    z: 0.0
  }}
  type: TYPE_BOX
  texture: "backgrounds/hotspot_circle"
  id: "{id_prefix}_circle"
  adjust_mode: ADJUST_MODE_ZOOM
  alpha: 0.55
  enabled: {en}
}}''')
    blocks.append(f'''nodes {{
  position {{
    x: {cx}.0
    y: {cy}.0
    z: 0.91
  }}
  size {{
    x: 98.0
    y: 98.0
  }}
  color {{
    x: 1.0
    y: 1.0
    z: 1.0
  }}
  type: TYPE_BOX
  texture: "backgrounds/hotspot_ring"
  id: "{id_prefix}_ring"
  adjust_mode: ADJUST_MODE_ZOOM
  alpha: 0.9
  enabled: {en}
}}''')
    blocks.append(f'''nodes {{
  position {{
    x: {cx}.0
    y: {cy + 4}.0
    z: 0.92
  }}
  size {{
    x: 100.0
    y: 100.0
  }}
  color {{
    x: 1.0
    y: 1.0
    z: 1.0
  }}
  type: TYPE_TEXT
  text: "{icon_char}"
  font: "material_icons"
  id: "{id_prefix}_icon"
  adjust_mode: ADJUST_MODE_ZOOM
  outline_alpha: 0.0
  shadow_alpha: 0.0
  enabled: {en}
}}''')
    blocks.append(f'''nodes {{
  position {{
    x: {cx}.0
    y: {cy}.0
    z: 0.93
  }}
  size {{
    x: 110.0
    y: 110.0
  }}
  color {{
    x: 1.0
    y: 0.0
    z: 0.0
  }}
  type: TYPE_BOX
  id: "{id_prefix}_hit"
  adjust_mode: ADJUST_MODE_ZOOM
  alpha: 0.0
  enabled: {en}
}}''')
    return blocks

# Material Icons codepoints (literal UTF-8)
ICON_BACKPACK  = chr(0xE8F9)  # work/briefcase — дипломат
ICON_PHONE     = chr(0xE32C)  # smartphone

HUD_NEW = []
# Рюкзак: правый край, всегда виден
HUD_NEW += hud_icon("hud_backpack", 900, 580, ICON_BACKPACK, enabled=True)
# Телефон: левее рюкзака, скрыт пока не has_phone
HUD_NEW += hud_icon("hud_phone", 800, 580, ICON_PHONE, enabled=False)

# --- 4. Инвентарная модалка -------------------------------------------
INV_BLOCK = []
# Dim
INV_BLOCK.append('''nodes {
  position {
    x: 480.0
    y: 320.0
    z: 0.94
  }
  size {
    x: 1280.0
    y: 720.0
  }
  color {
    x: 0.0
    y: 0.0
    z: 0.0
  }
  type: TYPE_BOX
  id: "inv_modal_dim"
  adjust_mode: ADJUST_MODE_STRETCH
  alpha: 0.65
  enabled: false
}''')
# Panel
INV_BLOCK.append('''nodes {
  position {
    x: 480.0
    y: 320.0
    z: 0.945
  }
  size {
    x: 720.0
    y: 480.0
  }
  color {
    x: 0.10
    y: 0.10
    z: 0.14
  }
  type: TYPE_BOX
  id: "inv_modal_panel"
  adjust_mode: ADJUST_MODE_ZOOM
  alpha: 0.97
  enabled: false
}''')
# Title
INV_BLOCK.append('''nodes {
  position {
    x: 0.0
    y: 200.0
    z: 0.0
  }
  size {
    x: 680.0
    y: 40.0
  }
  color {
    x: 1.0
    y: 1.0
    z: 1.0
  }
  type: TYPE_TEXT
  text: "Инвентарь"
  font: "main"
  id: "inv_modal_title"
  adjust_mode: ADJUST_MODE_ZOOM
  parent: "inv_modal_panel"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}''')
# Close button
INV_BLOCK.append('''nodes {
  position {
    x: 0.0
    y: -200.0
    z: 0.01
  }
  size {
    x: 220.0
    y: 50.0
  }
  color {
    x: 0.22
    y: 0.22
    z: 0.30
  }
  type: TYPE_BOX
  id: "inv_modal_close_btn"
  adjust_mode: ADJUST_MODE_ZOOM
  parent: "inv_modal_panel"
  inherit_alpha: true
  alpha: 0.9
}''')
INV_BLOCK.append('''nodes {
  position {
    x: 0.0
    y: 0.0
    z: 0.01
  }
  size {
    x: 200.0
    y: 40.0
  }
  color {
    x: 1.0
    y: 1.0
    z: 1.0
  }
  type: TYPE_TEXT
  text: "Закрыть"
  font: "main"
  id: "inv_modal_close_text"
  adjust_mode: ADJUST_MODE_ZOOM
  parent: "inv_modal_close_btn"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}''')

# Grid 4×3, 12 slots. Panel 720×480, centered, so relative coords:
# col x: -240, -80, 80, 240  (step 160, margin 40)
# row y: 100, -30, -160  (step 130, from top of content area)
COLS_X = [-240, -80, 80, 240]
ROWS_Y = [100, -30, -160]
for idx in range(12):
    row = idx // 4
    col = idx % 4
    x = COLS_X[col]
    y = ROWS_Y[row]
    n = idx + 1
    # Circle (bg)
    INV_BLOCK.append(f'''nodes {{
  position {{
    x: {x}.0
    y: {y}.0
    z: 0.0
  }}
  size {{
    x: 110.0
    y: 110.0
  }}
  color {{
    x: 0.0
    y: 0.0
    z: 0.0
  }}
  type: TYPE_BOX
  texture: "backgrounds/hotspot_circle"
  id: "inv_slot_circle_{n}"
  adjust_mode: ADJUST_MODE_ZOOM
  parent: "inv_modal_panel"
  inherit_alpha: true
  alpha: 0.6
}}''')
    # Ring
    INV_BLOCK.append(f'''nodes {{
  position {{
    x: {x}.0
    y: {y}.0
    z: 0.0
  }}
  size {{
    x: 128.0
    y: 128.0
  }}
  color {{
    x: 1.0
    y: 1.0
    z: 1.0
  }}
  type: TYPE_BOX
  texture: "backgrounds/hotspot_ring"
  id: "inv_slot_ring_{n}"
  adjust_mode: ADJUST_MODE_ZOOM
  parent: "inv_modal_panel"
  inherit_alpha: true
  alpha: 0.9
}}''')
    # Icon
    INV_BLOCK.append(f'''nodes {{
  position {{
    x: {x}.0
    y: {y + 4}.0
    z: 0.01
  }}
  size {{
    x: 120.0
    y: 120.0
  }}
  color {{
    x: 1.0
    y: 1.0
    z: 1.0
  }}
  type: TYPE_TEXT
  text: ""
  font: "material_icons"
  id: "inv_slot_icon_{n}"
  adjust_mode: ADJUST_MODE_ZOOM
  parent: "inv_modal_panel"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}}''')
    # Hit
    INV_BLOCK.append(f'''nodes {{
  position {{
    x: {x}.0
    y: {y}.0
    z: 0.02
  }}
  size {{
    x: 140.0
    y: 140.0
  }}
  color {{
    x: 1.0
    y: 0.0
    z: 0.0
  }}
  type: TYPE_BOX
  id: "inv_slot_hit_{n}"
  adjust_mode: ADJUST_MODE_ZOOM
  parent: "inv_modal_panel"
  inherit_alpha: true
  alpha: 0.0
}}''')

new_nodes = "\n".join(HUD_NEW + INV_BLOCK)

# Вставляем перед item_modal_dim (найдём его блок)
marker = 'nodes {\n  position {\n    x: 480.0\n    y: 320.0\n    z: 0.97'
idx = text.find(marker)
if idx == -1:
    # Попробуем альтернативный поиск
    m = re.search(r'nodes \{\s*position \{\s*x: 480\.0\s*y: 320\.0\s*z: 0\.97[^}]*id: "item_modal_dim"', text, re.DOTALL)
    if not m:
        raise SystemExit("item_modal_dim not found (check z bump earlier)")
    idx = m.start()

text = text[:idx] + new_nodes + "\n" + text[idx:]

with io.open(GUI, "w", encoding="utf-8") as f:
    f.write(text)

print(f"OK: добавлено {len(HUD_NEW)} HUD + {len(INV_BLOCK)} inventory-модалки нод")
