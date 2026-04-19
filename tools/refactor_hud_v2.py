# -*- coding: utf-8 -*-
"""
refactor_hud_v2.py — новый дизайн HUD + инвентарь из .design_hud.html.

Изменения в main/gui/novel_ui.gui:
  1. К каждой HUD-иконке (backpack, phone) добавляем 6 декоративных нод:
       _decal / _decal_text / _badge / _badge_text / _tag / _caption
     — цветные плашки, badge-кружки с цифрой, маленькие лейблы.
  2. Расширяем inv_modal_panel с 720×480 до 900×540 (панель сдвигается
     компактнее), обновляем координаты 12 слотов.
  3. Для каждого слота добавляем coord / name / qty ноды.
  4. Добавляем целый блок details-панели справа внутри inv_modal_panel:
       cap / name / preview_bg / preview_icon / stamp / desc
       + 8 stat нод + 5 verb-кнопок (rect + text каждая).
  5. Добавляем eyebrow + 3 stat-надписи (slots/weight/loop) в верху панели.

Скрипт идемпотентен: при повторном запуске пропускает уже добавленные
ноды (проверка по маркерным id).
"""
import io, re, sys

GUI = r"C:\Users\GoldiM\novell1\novell1\main\gui\novel_ui.gui"

with io.open(GUI, "r", encoding="utf-8") as f:
    text = f.read()

added_total = 0


def insert_before(src, marker_id, new_block):
    """Вставляет new_block прямо перед блоком ноды с id=marker_id."""
    id_marker = f'id: "{marker_id}"'
    idx_id = src.find(id_marker)
    if idx_id == -1:
        raise SystemExit(f"marker id '{marker_id}' not found")
    block_start = src.rfind("nodes {", 0, idx_id)
    if block_start == -1:
        raise SystemExit(f"nodes {{ before '{marker_id}' not found")
    return src[:block_start] + new_block + src[block_start:]


def replace_in_block(src, node_id, old, new):
    """Заменяет old→new внутри одного блока с данным id."""
    id_marker = f'id: "{node_id}"'
    idx_id = src.find(id_marker)
    if idx_id == -1:
        raise SystemExit(f"id {node_id} not found")
    block_start = src.rfind("nodes {", 0, idx_id)
    block_end = src.find("}\n", idx_id)
    if block_end == -1:
        raise SystemExit(f"block end for {node_id} not found")
    block_end += 2
    block = src[block_start:block_end]
    if old not in block:
        raise SystemExit(f"replace_in_block: '{old[:30]}' not found in {node_id}")
    new_block = block.replace(old, new, 1)
    return src[:block_start] + new_block + src[block_end:]


# ========== 1. HUD decal / badge / tag / caption ==========
# Палитра цветов (RGB 0..1)
ACCENT_R, ACCENT_G, ACCENT_B = 0.490, 0.976, 1.000
HOT_R, HOT_G, HOT_B = 1.000, 0.239, 0.498
AMBER_R, AMBER_G, AMBER_B = 1.000, 0.702, 0.278
PAPER_R, PAPER_G, PAPER_B = 0.922, 0.914, 0.871
INK_R, INK_G, INK_B = 0.024, 0.012, 0.047
DIM_R, DIM_G, DIM_B = 0.627, 0.635, 0.694


def hud_extras(id_prefix, cx, cy, col_r, col_g, col_b, decal_text, badge_text,
               tag_text, caption_text, enabled):
    """Возвращает 6 блоков: decal (плашка), decal_text, badge (круг), badge_text,
    tag (под иконкой), caption (подпись клавиши ниже)."""
    en = "true" if enabled else "false"
    blocks = []
    # Decal rect (top-right)
    blocks.append(f'''nodes {{
  position {{
    x: {cx + 30}.0
    y: {cy + 26}.0
    z: 0.935
  }}
  size {{
    x: 36.0
    y: 20.0
  }}
  color {{
    x: {INK_R}
    y: {INK_G}
    z: {INK_B}
  }}
  type: TYPE_BOX
  id: "{id_prefix}_decal"
  adjust_mode: ADJUST_MODE_ZOOM
  alpha: 0.85
  enabled: {en}
}}''')
    # Decal text
    blocks.append(f'''nodes {{
  position {{
    x: {cx + 30}.0
    y: {cy + 26}.0
    z: 0.936
  }}
  size {{
    x: 40.0
    y: 22.0
  }}
  color {{
    x: {col_r}
    y: {col_g}
    z: {col_b}
  }}
  type: TYPE_TEXT
  text: "{decal_text}"
  font: "jb_mono_14"
  id: "{id_prefix}_decal_text"
  adjust_mode: ADJUST_MODE_ZOOM
  outline_alpha: 0.0
  shadow_alpha: 0.0
  enabled: {en}
}}''')
    # Badge (bottom-right circle)
    blocks.append(f'''nodes {{
  position {{
    x: {cx + 28}.0
    y: {cy - 28}.0
    z: 0.935
  }}
  size {{
    x: 28.0
    y: 28.0
  }}
  color {{
    x: {HOT_R if id_prefix.endswith("backpack") else AMBER_R}
    y: {HOT_G if id_prefix.endswith("backpack") else AMBER_G}
    z: {HOT_B if id_prefix.endswith("backpack") else AMBER_B}
  }}
  type: TYPE_BOX
  texture: "backgrounds/hotspot_circle"
  id: "{id_prefix}_badge"
  adjust_mode: ADJUST_MODE_ZOOM
  alpha: 1.0
  enabled: {en}
}}''')
    # Badge text
    blocks.append(f'''nodes {{
  position {{
    x: {cx + 28}.0
    y: {cy - 28}.0
    z: 0.937
  }}
  size {{
    x: 30.0
    y: 30.0
  }}
  color {{
    x: {INK_R}
    y: {INK_G}
    z: {INK_B}
  }}
  type: TYPE_TEXT
  text: "{badge_text}"
  font: "jb_mono_bold_22"
  id: "{id_prefix}_badge_text"
  adjust_mode: ADJUST_MODE_ZOOM
  outline_alpha: 0.0
  shadow_alpha: 0.0
  enabled: {en}
}}''')
    # Tag (под иконкой)
    blocks.append(f'''nodes {{
  position {{
    x: {cx}.0
    y: {cy - 36}.0
    z: 0.934
  }}
  size {{
    x: 80.0
    y: 20.0
  }}
  color {{
    x: {col_r}
    y: {col_g}
    z: {col_b}
  }}
  type: TYPE_TEXT
  text: "{tag_text}"
  font: "jb_mono_14"
  id: "{id_prefix}_tag"
  adjust_mode: ADJUST_MODE_ZOOM
  outline_alpha: 0.0
  shadow_alpha: 0.0
  enabled: {en}
}}''')
    # Caption (подпись с клавишей, ниже tag)
    blocks.append(f'''nodes {{
  position {{
    x: {cx}.0
    y: {cy - 58}.0
    z: 0.934
  }}
  size {{
    x: 160.0
    y: 20.0
  }}
  color {{
    x: {DIM_R}
    y: {DIM_G}
    z: {DIM_B}
  }}
  type: TYPE_TEXT
  text: "{caption_text}"
  font: "jb_mono_14"
  id: "{id_prefix}_caption"
  adjust_mode: ADJUST_MODE_ZOOM
  outline_alpha: 0.0
  shadow_alpha: 0.0
  enabled: {en}
}}''')
    return blocks


if "hud_backpack_decal" not in text:
    bk_blocks = hud_extras("hud_backpack", 900, 580,
                           ACCENT_R, ACCENT_G, ACCENT_B,
                           "N7", "7", "BAG", "рюкзак . B",
                           enabled=True)
    ph_blocks = hud_extras("hud_phone", 800, 580,
                           AMBER_R, AMBER_G, AMBER_B,
                           "TEL", "3", "PHN", "телефон . P",
                           enabled=False)
    hud_all = "\n".join(bk_blocks + ph_blocks) + "\n"
    text = insert_before(text, "inv_modal_dim", hud_all)
    added_total += 12
    print(f"[hud] added 12 decal/badge/tag/caption nodes")
else:
    print("[hud] already extended — skip")


# ========== 2. Перекрашиваем HUD circles (accent / amber) ==========
# backpack circle fill → accent, phone circle → amber
if "BK_RECOLOR_V2" not in text:
    # Проставляем цвет для hud_backpack_circle: 0.0 0.0 0.0 → accent
    try:
        text = replace_in_block(text, "hud_backpack_circle",
            "color {\n    x: 0.0\n    y: 0.0\n    z: 0.0\n  }",
            f"color {{\n    x: {ACCENT_R}\n    y: {ACCENT_G}\n    z: {ACCENT_B}\n  }}")
        text = replace_in_block(text, "hud_phone_circle",
            "color {\n    x: 0.0\n    y: 0.0\n    z: 0.0\n  }",
            f"color {{\n    x: {AMBER_R}\n    y: {AMBER_G}\n    z: {AMBER_B}\n  }}")
        # Оставляем маркер-комментарий нельзя — protobuf, но следим по цвету
        print("[hud] recolored backpack=accent, phone=amber")
    except SystemExit as e:
        print(f"[hud] recolor skip: {e}")


# ========== 3. Расширение inv_modal_panel до 900×540 ==========
# Исходно size { x: 720.0, y: 480.0 } — меняем на 900×540.
# Применяем только один раз.
def panel_size_block(w, h):
    return f"size {{\n    x: {w}.0\n    y: {h}.0\n  }}"

if "# INV_V2_RESIZED" not in text:
    # Дешёвая маркировка через проверку текущего размера панели
    try:
        text = replace_in_block(text, "inv_modal_panel",
            panel_size_block(720, 480),
            panel_size_block(900, 540))
        print("[inv] panel 720x480 -> 900x540")
    except SystemExit as e:
        print(f"[inv] panel resize skip: {e}")


# ========== 4. Пересчёт координат слотов на новую сетку ==========
# Старые: COLS [-240,-80,80,240], ROWS [100,-30,-160]
# Новые:  COLS [-340,-220,-100,20], ROWS [120, 0, -120]
OLD_COLS = [-240, -80, 80, 240]
OLD_ROWS = [100, -30, -160]
NEW_COLS = [-340, -220, -100, 20]
NEW_ROWS = [120, 0, -120]


def move_slot(src, node_id, old_x, old_y, new_x, new_y):
    """Меняет позицию внутри блока node_id."""
    id_marker = f'id: "{node_id}"'
    idx_id = src.find(id_marker)
    if idx_id == -1:
        return src  # нода отсутствует — скип
    block_start = src.rfind("nodes {", 0, idx_id)
    block_end = src.find("}\n", idx_id) + 2
    block = src[block_start:block_end]

    old_pos = f"position {{\n    x: {old_x}.0\n    y: {old_y}.0"
    new_pos = f"position {{\n    x: {new_x}.0\n    y: {new_y}.0"
    if old_pos not in block:
        return src  # уже перемещено или другое расположение
    new_block = block.replace(old_pos, new_pos, 1)
    return src[:block_start] + new_block + src[block_end:]


# Слот 1 в старой сетке был на (-240, 100) — используем как маркер
if "position {\n    x: -340.0\n    y: 120.0" not in text:
    moved = 0
    for idx in range(12):
        row = idx // 4
        col = idx % 4
        ox = OLD_COLS[col]; oy = OLD_ROWS[row]
        nx = NEW_COLS[col]; ny = NEW_ROWS[row]
        n = idx + 1
        # 4 ноды каждого слота: circle / ring / icon / hit (icon имеет +4 offset по Y)
        for suffix, dy in [("circle", 0), ("ring", 0), ("icon", 4), ("hit", 0)]:
            node_id = f"inv_slot_{suffix}_{n}"
            before = text
            text = move_slot(text, node_id, ox, oy + dy, nx, ny + dy)
            if text != before:
                moved += 1
    print(f"[inv] moved slot coords: {moved} nodes")
else:
    print("[inv] slot coords already migrated — skip")


# ========== 5. Добавление coord / name / qty для каждого слота ==========
LETTERS = ["A", "B", "C", "D"]

if "inv_slot_coord_1" not in text:
    slot_extras = []
    for idx in range(12):
        row = idx // 4
        col = idx % 4
        x = NEW_COLS[col]
        y = NEW_ROWS[row]
        n = idx + 1
        coord = f"{LETTERS[col]}{row + 1}"
        # coord (top-left corner of slot)
        slot_extras.append(f'''nodes {{
  position {{
    x: {x - 45}.0
    y: {y + 45}.0
    z: 0.01
  }}
  size {{
    x: 50.0
    y: 18.0
  }}
  color {{
    x: {ACCENT_R}
    y: {ACCENT_G}
    z: {ACCENT_B}
  }}
  type: TYPE_TEXT
  text: "{coord}"
  font: "jb_mono_14"
  id: "inv_slot_coord_{n}"
  adjust_mode: ADJUST_MODE_ZOOM
  parent: "inv_modal_panel"
  inherit_alpha: true
  alpha: 0.6
  outline_alpha: 0.0
  shadow_alpha: 0.0
}}''')
        # name (under icon)
        slot_extras.append(f'''nodes {{
  position {{
    x: {x}.0
    y: {y - 38}.0
    z: 0.01
  }}
  size {{
    x: 110.0
    y: 18.0
  }}
  color {{
    x: {PAPER_R}
    y: {PAPER_G}
    z: {PAPER_B}
  }}
  type: TYPE_TEXT
  text: ""
  font: "jb_mono_14"
  id: "inv_slot_name_{n}"
  adjust_mode: ADJUST_MODE_ZOOM
  parent: "inv_modal_panel"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}}''')
        # qty (bottom-right of slot)
        slot_extras.append(f'''nodes {{
  position {{
    x: {x + 35}.0
    y: {y - 35}.0
    z: 0.01
  }}
  size {{
    x: 30.0
    y: 22.0
  }}
  color {{
    x: {HOT_R}
    y: {HOT_G}
    z: {HOT_B}
  }}
  type: TYPE_TEXT
  text: ""
  font: "jb_mono_bold_22"
  id: "inv_slot_qty_{n}"
  adjust_mode: ADJUST_MODE_ZOOM
  parent: "inv_modal_panel"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}}''')
    # Вставляем в конец inv_modal_panel группы — перед item_modal_dim
    text = insert_before(text, "item_modal_dim", "\n".join(slot_extras) + "\n")
    added_total += 36
    print(f"[inv] added coord/name/qty: 36 nodes")
else:
    print("[inv] slot extras already present — skip")


# ========== 6. Eyebrow + 3 stat-надписи + details-панель ==========
if "inv_modal_eyebrow" not in text:
    extras = []
    # eyebrow (top-left of panel)
    extras.append(f'''nodes {{
  position {{
    x: -320.0
    y: 240.0
    z: 0.01
  }}
  size {{
    x: 400.0
    y: 20.0
  }}
  color {{
    x: {DIM_R}
    y: {DIM_G}
    z: {DIM_B}
  }}
  type: TYPE_TEXT
  text: "inventory . рюкзак . N7"
  font: "jb_mono_14"
  id: "inv_modal_eyebrow"
  adjust_mode: ADJUST_MODE_ZOOM
  parent: "inv_modal_panel"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}}''')
    # 3 stat надписи (top-right)
    for (i, (label, txt, col)) in enumerate([
        ("slots", "слотов: 0/12", (ACCENT_R, ACCENT_G, ACCENT_B)),
        ("weight", "вес: 0.0 кг", (PAPER_R, PAPER_G, PAPER_B)),
        ("loop", "петля: #017", (AMBER_R, AMBER_G, AMBER_B)),
    ]):
        extras.append(f'''nodes {{
  position {{
    x: 340.0
    y: {250 - i * 20}.0
    z: 0.01
  }}
  size {{
    x: 200.0
    y: 18.0
  }}
  color {{
    x: {col[0]}
    y: {col[1]}
    z: {col[2]}
  }}
  type: TYPE_TEXT
  text: "{txt}"
  font: "jb_mono_14"
  id: "inv_modal_stat_{label}"
  adjust_mode: ADJUST_MODE_ZOOM
  parent: "inv_modal_panel"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}}''')

    # --- Details-панель справа (offset x=280) ---
    DET_X = 320  # центр details области
    # cap
    extras.append(f'''nodes {{
  position {{
    x: {DET_X}.0
    y: 210.0
    z: 0.01
  }}
  size {{
    x: 240.0
    y: 20.0
  }}
  color {{
    x: {ACCENT_R}
    y: {ACCENT_G}
    z: {ACCENT_B}
  }}
  type: TYPE_TEXT
  text: "details . предмет"
  font: "jb_mono_14"
  id: "inv_details_cap"
  adjust_mode: ADJUST_MODE_ZOOM
  parent: "inv_modal_panel"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}}''')
    # name (main font, big)
    extras.append(f'''nodes {{
  position {{
    x: {DET_X}.0
    y: 175.0
    z: 0.01
  }}
  size {{
    x: 240.0
    y: 30.0
  }}
  color {{
    x: {PAPER_R}
    y: {PAPER_G}
    z: {PAPER_B}
  }}
  type: TYPE_TEXT
  text: ""
  font: "main"
  id: "inv_details_name"
  adjust_mode: ADJUST_MODE_ZOOM
  parent: "inv_modal_panel"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}}''')
    # preview_bg
    extras.append(f'''nodes {{
  position {{
    x: {DET_X}.0
    y: 70.0
    z: 0.01
  }}
  size {{
    x: 240.0
    y: 150.0
  }}
  color {{
    x: {PAPER_R}
    y: {PAPER_G}
    z: {PAPER_B}
  }}
  type: TYPE_BOX
  id: "inv_details_preview_bg"
  adjust_mode: ADJUST_MODE_ZOOM
  parent: "inv_modal_panel"
  inherit_alpha: true
  alpha: 0.08
}}''')
    # preview_icon (big material icon)
    extras.append(f'''nodes {{
  position {{
    x: {DET_X}.0
    y: 78.0
    z: 0.02
  }}
  size {{
    x: 120.0
    y: 120.0
  }}
  color {{
    x: {PAPER_R}
    y: {PAPER_G}
    z: {PAPER_B}
  }}
  type: TYPE_TEXT
  text: ""
  font: "material_icons"
  id: "inv_details_preview_icon"
  adjust_mode: ADJUST_MODE_ZOOM
  parent: "inv_modal_panel"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}}''')
    # stamp (bottom-right of preview)
    extras.append(f'''nodes {{
  position {{
    x: {DET_X + 80}.0
    y: 10.0
    z: 0.02
  }}
  size {{
    x: 110.0
    y: 22.0
  }}
  color {{
    x: {ACCENT_R}
    y: {ACCENT_G}
    z: {ACCENT_B}
  }}
  type: TYPE_TEXT
  text: "ОСМОТРЕТЬ"
  font: "jb_mono_bold_22"
  id: "inv_details_stamp"
  adjust_mode: ADJUST_MODE_ZOOM
  parent: "inv_modal_panel"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}}''')
    # desc (4 lines)
    extras.append(f'''nodes {{
  position {{
    x: {DET_X}.0
    y: -40.0
    z: 0.01
  }}
  size {{
    x: 240.0
    y: 80.0
  }}
  color {{
    x: {PAPER_R}
    y: {PAPER_G}
    z: {PAPER_B}
  }}
  type: TYPE_TEXT
  text: ""
  font: "main"
  id: "inv_details_desc"
  adjust_mode: ADJUST_MODE_ZOOM
  parent: "inv_modal_panel"
  inherit_alpha: true
  line_break: true
  alpha: 0.85
  outline_alpha: 0.0
  shadow_alpha: 0.0
}}''')
    # 4 stat pairs (source / iter / type / clue)
    stat_rows = [
        ("source", "источник",  "", (DIM_R, DIM_G, DIM_B),   (PAPER_R, PAPER_G, PAPER_B)),
        ("iter",   "итерация",  "", (DIM_R, DIM_G, DIM_B),   (ACCENT_R, ACCENT_G, ACCENT_B)),
        ("type",   "тип",       "", (DIM_R, DIM_G, DIM_B),   (PAPER_R, PAPER_G, PAPER_B)),
        ("clue",   "улика",     "", (DIM_R, DIM_G, DIM_B),   (HOT_R, HOT_G, HOT_B)),
    ]
    for (i, (key, label, val, kcol, vcol)) in enumerate(stat_rows):
        y = -110 - i * 22
        extras.append(f'''nodes {{
  position {{
    x: {DET_X - 100}.0
    y: {y}.0
    z: 0.01
  }}
  size {{
    x: 120.0
    y: 18.0
  }}
  color {{
    x: {kcol[0]}
    y: {kcol[1]}
    z: {kcol[2]}
  }}
  type: TYPE_TEXT
  text: "{label}"
  font: "jb_mono_14"
  id: "inv_details_stat_{key}_key"
  adjust_mode: ADJUST_MODE_ZOOM
  parent: "inv_modal_panel"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}}''')
        extras.append(f'''nodes {{
  position {{
    x: {DET_X + 40}.0
    y: {y}.0
    z: 0.01
  }}
  size {{
    x: 140.0
    y: 18.0
  }}
  color {{
    x: {vcol[0]}
    y: {vcol[1]}
    z: {vcol[2]}
  }}
  type: TYPE_TEXT
  text: ""
  font: "jb_mono_14"
  id: "inv_details_stat_{key}_value"
  adjust_mode: ADJUST_MODE_ZOOM
  parent: "inv_modal_panel"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}}''')
    # 5 verb-buttons (rect + text пара на каждую)
    VERBS = [
        ("use",     "Использовать E"),
        ("inspect", "Осмотреть Q"),
        ("combine", "Соединить C"),
        ("read",    "Прочитать R"),
        ("give",    "Отдать G"),
    ]
    # Ряд в низу details-панели (y = -215..-240)
    VERB_Y = -225
    VERB_W = 90
    VERB_H = 26
    # Пять кнопок в ряд: 5*90 + 4*6 = 474 > 240, значит 2 ряда по 3 и 2
    # Упакуем в 2 ряда: row 0 — use/inspect/combine (y=-210); row 1 — read/give (y=-240)
    for (i, (key, label)) in enumerate(VERBS):
        if i < 3:
            row = 0
            col = i
            cols_in_row = 3
        else:
            row = 1
            col = i - 3
            cols_in_row = 2
        total_w = cols_in_row * VERB_W + (cols_in_row - 1) * 6
        start_x = DET_X - total_w / 2 + VERB_W / 2
        x = start_x + col * (VERB_W + 6)
        y = -210 - row * 32
        # button rect
        extras.append(f'''nodes {{
  position {{
    x: {float(x):g}
    y: {float(y):g}
    z: 0.01
  }}
  size {{
    x: {VERB_W}.0
    y: {VERB_H}.0
  }}
  color {{
    x: {INK_R}
    y: {INK_G}
    z: {INK_B}
  }}
  type: TYPE_BOX
  id: "inv_verb_{key}"
  adjust_mode: ADJUST_MODE_ZOOM
  parent: "inv_modal_panel"
  inherit_alpha: true
  alpha: 0.85
}}''')
        extras.append(f'''nodes {{
  position {{
    x: {float(x):g}
    y: {float(y):g}
    z: 0.02
  }}
  size {{
    x: {VERB_W}.0
    y: {VERB_H}.0
  }}
  color {{
    x: {ACCENT_R}
    y: {ACCENT_G}
    z: {ACCENT_B}
  }}
  type: TYPE_TEXT
  text: "{label}"
  font: "jb_mono_14"
  id: "inv_verb_{key}_text"
  adjust_mode: ADJUST_MODE_ZOOM
  parent: "inv_modal_panel"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}}''')

    text = insert_before(text, "item_modal_dim", "\n".join(extras) + "\n")
    added_total += len(extras)
    print(f"[inv] added eyebrow + stats + details panel: {len(extras)} nodes")
else:
    print("[inv] eyebrow/details already present — skip")


with io.open(GUI, "w", encoding="utf-8") as f:
    f.write(text)

print(f"\nOK: total nodes added this run = {added_total}")
