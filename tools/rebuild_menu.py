# -*- coding: utf-8 -*-
"""
Перестраивает секцию главного меню в main/gui/novel_ui.gui.

Находит диапазон нод от (menu_panel) до последней ноды меню
(menu_btn_continue_left_line включительно) и заменяет на новую
раскладку в стиле Claude Design/AVOS:
  • eyebrow «— ИТЕРАЦИЯ 001 · ПОВТОР —»  (jb_mono_stamp, циан)
  • большой лого АВОСЬ (unbounded_72) с RGB-глитч-слоями (цианов/магента)
  • советский штамп «СЕКРЕТНО · №17» (красный, повёрнут на -9°)
  • сабтайтл (JB Mono 14, paper-dim)
  • 4 кнопки меню: НОВАЯ ИТЕРАЦИЯ · ПРОДОЛЖИТЬ · ГАЛЕРЕЯ CG · ДОСТИЖЕНИЯ
  • досье-панель справа (ПЕТЛЯ/СЦЕНА/ПРОГРЕСС + рукописный Caveat)
  • HUD-линии сверху и снизу
"""
import re, io, sys, os

GUI_PATH = r"C:\Users\GoldiM\novell1\novell1\main\gui\novel_ui.gui"

# ------------------------------------------------------------
# Палитра (нормализованная 0..1 для Defold)
# ------------------------------------------------------------
PAPER     = (0.953, 0.925, 0.851)   # #f3ecd9
PAPER_DIM = (0.788, 0.753, 0.659)   # #c9c0a8
CYAN      = (0.490, 0.976, 1.000)   # #7df9ff
MAGENTA   = (1.000, 0.239, 0.498)   # #ff3d7f
AMBER     = (1.000, 0.702, 0.278)   # #ffb347
VIOLET    = (0.478, 0.361, 1.000)   # #7a5cff
STAMP_RED = (0.784, 0.078, 0.165)   # #c8142a
INK_BG    = (0.027, 0.024, 0.102)   # slightly lighter than #07061a for contrast

# ------------------------------------------------------------
# Генераторы нод
# ------------------------------------------------------------
def box(id_, x, y, w, h, parent="menu_panel", color=None, alpha=1.0, z=0.0,
        adjust="ADJUST_MODE_STRETCH", enabled=True, texture=None):
    c = color or (1.0, 1.0, 1.0)
    s = []
    s.append("nodes {")
    s.append(f"  position {{ x: {x:.1f} y: {y:.1f} z: {z:.3f} }}")
    s.append(f"  size {{ x: {w:.1f} y: {h:.1f} }}")
    s.append(f"  color {{ x: {c[0]:.4f} y: {c[1]:.4f} z: {c[2]:.4f} }}")
    s.append("  type: TYPE_BOX")
    if texture: s.append(f'  texture: "{texture}"')
    s.append(f'  id: "{id_}"')
    s.append(f"  adjust_mode: {adjust}")
    if parent: s.append(f'  parent: "{parent}"')
    s.append("  inherit_alpha: true")
    s.append(f"  alpha: {alpha:.3f}")
    s.append(f"  enabled: {'true' if enabled else 'false'}")
    s.append("}")
    return "\n".join(s) + "\n"

def text(id_, x, y, w, content, font="main", parent="menu_panel",
         color=None, alpha=1.0, z=0.0, pivot=None, rot_z=0.0,
         outline=0.0, adjust="ADJUST_MODE_STRETCH", enabled=True):
    c = color or PAPER
    s = []
    s.append("nodes {")
    s.append(f"  position {{ x: {x:.1f} y: {y:.1f} z: {z:.3f} }}")
    if rot_z != 0.0:
        s.append(f"  rotation {{ z: {rot_z:.2f} }}")
    s.append(f"  size {{ x: {w:.1f} y: 40.0 }}")
    s.append(f"  color {{ x: {c[0]:.4f} y: {c[1]:.4f} z: {c[2]:.4f} }}")
    s.append("  type: TYPE_TEXT")
    # В .gui строки сохраняются как UTF-8 с экранированием октетов.
    # Сделаем экранирование октет (\xxx) для безопасности.
    encoded = "".join(f"\\{b:03o}" if b > 127 else chr(b) for b in content.encode("utf-8"))
    s.append(f'  text: "{encoded}"')
    s.append(f'  font: "{font}"')
    s.append(f'  id: "{id_}"')
    s.append(f"  adjust_mode: {adjust}")
    if pivot: s.append(f"  pivot: {pivot}")
    if parent: s.append(f'  parent: "{parent}"')
    s.append("  inherit_alpha: true")
    s.append(f"  alpha: {alpha:.3f}")
    s.append(f"  outline_alpha: {outline:.3f}")
    s.append("  shadow_alpha: 0.0")
    s.append(f"  enabled: {'true' if enabled else 'false'}")
    s.append("}")
    return "\n".join(s) + "\n"

# ------------------------------------------------------------
# Сборка меню
# ------------------------------------------------------------
out = io.StringIO()

# Корневая панель меню — ПРОЗРАЧНАЯ, чтобы bg_menu был виден насквозь.
# Раньше alpha:0.5 ink-overlay перекрывал весь фон; теперь только
# левый столбик-виньетка для читаемости меню-текста.
out.write(box("menu_panel", 480, 320, 960, 640, parent="",
              color=(0.02, 0.02, 0.08), alpha=0.0, z=0.5))

# Левый столб-виньетка: от x=0 до x=540, тёмный градиент. В Defold
# нет CSS-градиента, эмулируем прямоугольником с низкой alpha.
out.write(box("menu_left_shade", -210, 0, 540, 640, parent="menu_panel",
              color=(0.022, 0.020, 0.082), alpha=0.55, z=0.0))

# Тонкая неоновая вертикальная линия-разделитель справа от столба
out.write(box("menu_divider_right", 60, 0, 2, 560, parent="menu_panel",
              color=CYAN, alpha=0.22, z=0.001))

# --- HUD top/bottom ---
out.write(text("menu_hud_top_left",  -440, 295, 500,
               "АВОСЬ // ИТЕРАЦИЯ 001  •  build 0.4",
               font="jb_mono_14", color=PAPER_DIM, alpha=0.60,
               pivot="PIVOT_W", z=0.02))
out.write(text("menu_hud_top_right", 440, 295, 500,
               "МОСКВА  •  07:12 MSK  •  ██ 62%",
               font="jb_mono_14", color=CYAN, alpha=0.60,
               pivot="PIVOT_E", z=0.02))
out.write(text("menu_hud_bot", 0, -295, 920,
               "АНОМАЛИЯ: «03:47» в логе совпадает.  //  Трамвай №7 опаздывает 3 мин.  //  temporal_sync.module — ожидает компиляции.",
               font="jb_mono_14", color=CYAN, alpha=0.45, z=0.02))

# --- Eyebrow над логотипом ---
out.write(text("menu_eyebrow", -370, 150, 420,
               "—  ИТЕРАЦИЯ 001  ·  ПОВТОР  ·  AVOS OS  —",
               font="jb_mono_stamp", color=CYAN, alpha=0.85,
               pivot="PIVOT_W", z=0.03))

# --- ЛОГО АВОСЬ: три наложенных текст-ноды (глитч B + R + чистый) ---
# Все с pivot W (лево), position x = -380 (слева в menu_panel -480..480)
LOGO_X = -370
LOGO_Y = 70
# B — cyan смещён на -3, alpha 0.55
out.write(text("menu_title_glitch_b", LOGO_X - 3, LOGO_Y - 1, 650, "АВОСЬ",
               font="unbounded_72", color=CYAN, alpha=0.55,
               pivot="PIVOT_W", z=0.04))
# R — magenta смещён на +3
out.write(text("menu_title_glitch_r", LOGO_X + 3, LOGO_Y + 1, 650, "АВОСЬ",
               font="unbounded_72", color=MAGENTA, alpha=0.55,
               pivot="PIVOT_W", z=0.05))
# Основной белый
out.write(text("menu_title", LOGO_X, LOGO_Y, 650, "АВОСЬ",
               font="unbounded_72", color=PAPER, alpha=1.0,
               pivot="PIVOT_W", z=0.06, outline=0.5))

# --- Советский штамп «СЕКРЕТНО · №17» — красный, повёрнут на -9° ---
# Контейнер-бокс как рамка штампа
out.write(box("menu_stamp_box", 70, 110, 160, 34, parent="menu_panel",
              color=STAMP_RED, alpha=0.08, z=0.05))
# Красная обводка (имитируем 4 тонкими бокс-линиями)
STAMP_CX, STAMP_CY = 70, 110
out.write(box("menu_stamp_bt", STAMP_CX,      STAMP_CY + 16, 160, 2,
              color=STAMP_RED, alpha=0.75, z=0.055))
out.write(box("menu_stamp_bb", STAMP_CX,      STAMP_CY - 16, 160, 2,
              color=STAMP_RED, alpha=0.75, z=0.055))
out.write(box("menu_stamp_bl", STAMP_CX - 79, STAMP_CY,        2, 34,
              color=STAMP_RED, alpha=0.75, z=0.055))
out.write(box("menu_stamp_br", STAMP_CX + 79, STAMP_CY,        2, 34,
              color=STAMP_RED, alpha=0.75, z=0.055))
out.write(text("menu_stamp_text", STAMP_CX, STAMP_CY, 160,
               "СЕКРЕТНО · №17",
               font="jb_mono_stamp", color=STAMP_RED, alpha=0.85,
               z=0.06))

# --- Сабтайтл под логотипом ---
out.write(text("menu_subtitle", -370, 20, 620,
               "пн · 07:12 мск · кофе не допит · петля в процессе",
               font="jb_mono_14", color=PAPER_DIM, alpha=0.75,
               pivot="PIVOT_W", z=0.03))

# Тонкий разделитель над пунктами меню
out.write(box("menu_divider_top", -370, -10, 420, 1,
              color=CYAN, alpha=0.30, z=0.03))
# Оставим старую ноду menu_divider, но скроем (legacy). А, мы её
# вообще дропнем в новой раскладке — но надо быть совместимым с
# gui_script. На всякий — не создаём её (gui_script её не ищет).

# --- 4 кнопки меню ---
# Каждая кнопка: bg-бокс (hit) + text-нода
BTN_X = -370
BTN_W = 420
BTN_H = 56
BTN_SPACING = 66

btn_defs = [
    ("menu_btn_new",     "menu_btn_new_text",      "01",  "НОВАЯ ИТЕРАЦИЯ",  "New game",   CYAN),
    ("menu_btn_continue","menu_btn_continue_text", "02",  "ПРОДОЛЖИТЬ",      "Continue",   AMBER),
    ("menu_btn_gallery", "menu_btn_gallery_text",  "03",  "ГАЛЕРЕЯ CG",      "Gallery",    VIOLET),
    ("menu_btn_awards",  "menu_btn_awards_text",   "04",  "ДОСТИЖЕНИЯ",      "Awards",     MAGENTA),
]
for i, (bid, tid, num, ru, en, accent) in enumerate(btn_defs):
    y = -50 - i * BTN_SPACING
    # hit-box (подложка): очень тёмный, edge glow через отдельные линии
    out.write(box(bid, BTN_X + BTN_W / 2, y, BTN_W, BTN_H,
                  color=(0.04, 0.03, 0.14), alpha=0.55, z=0.04))
    # Левая акцент-планка (цветная)
    out.write(box(bid + "_bar", BTN_X + 4, y, 4, BTN_H - 8,
                  color=accent, alpha=0.85, z=0.06))
    # Номер пункта слева (циан-моно)
    out.write(text(bid + "_num", BTN_X + 22, y, 50,
                   num, font="jb_mono_stamp", color=accent, alpha=0.9,
                   pivot="PIVOT_W", z=0.07))
    # RU-текст
    out.write(text(tid, BTN_X + 64, y + 8, 340,
                   ru, font="jb_mono_bold_22", color=PAPER, alpha=1.0,
                   pivot="PIVOT_W", z=0.07))
    # EN-дубляж (мельче, тусклее)
    out.write(text(bid + "_en", BTN_X + 64, y - 12, 340,
                   "// " + en, font="jb_mono_14", color=PAPER_DIM, alpha=0.55,
                   pivot="PIVOT_W", z=0.07))

# --- Досье-панель справа ---
DOS_X = 320
DOS_Y = 0
out.write(box("menu_dossier_bg", DOS_X, DOS_Y, 260, 360,
              color=(0.04, 0.03, 0.14), alpha=0.72, z=0.04))
# Рамка (4 линии)
out.write(box("menu_dossier_bt", DOS_X, DOS_Y + 180, 260, 1,
              color=CYAN, alpha=0.45, z=0.045))
out.write(box("menu_dossier_bb", DOS_X, DOS_Y - 180, 260, 1,
              color=CYAN, alpha=0.25, z=0.045))
out.write(box("menu_dossier_bl", DOS_X - 130, DOS_Y, 1, 360,
              color=CYAN, alpha=0.30, z=0.045))
out.write(box("menu_dossier_br", DOS_X + 130, DOS_Y, 1, 360,
              color=CYAN, alpha=0.30, z=0.045))

# eyebrow досье
out.write(text("menu_dossier_eyebrow", DOS_X - 116, DOS_Y + 150, 240,
               "— ДОСЬЕ // К.АВОСЬЕВ —",
               font="jb_mono_stamp", color=CYAN, alpha=0.80,
               pivot="PIVOT_W", z=0.06))

# Строки-статы
stat_lines = [
    ("ПЕТЛЯ:",     "017",                AMBER),
    ("СЦЕНА:",     "СПАЛЬНЯ",            PAPER),
    ("ВРЕМЯ:",     "07:12 МСК",          PAPER),
    ("ПРОГРЕСС:", "7%  ▓░░░░░░░░",       CYAN),
    ("ПОСЛ.ДЕЙСТ.:", "проснулся",        PAPER_DIM),
    ("АНОМАЛИИ:", "3 / 12",              MAGENTA),
]
for i, (label, value, col) in enumerate(stat_lines):
    y = DOS_Y + 110 - i * 34
    out.write(text(f"menu_dossier_label_{i}",
                   DOS_X - 116, y, 110, label,
                   font="jb_mono_stamp", color=PAPER_DIM, alpha=0.65,
                   pivot="PIVOT_W", z=0.06))
    out.write(text(f"menu_dossier_value_{i}",
                   DOS_X + 116, y, 240, value,
                   font="jb_mono_14", color=col, alpha=0.95,
                   pivot="PIVOT_E", z=0.06))

# Рукописный «hand» внизу досье
out.write(text("menu_dossier_hand", DOS_X, DOS_Y - 145, 240,
               "«не забыть про кофе»",
               font="caveat_28", color=AMBER, alpha=0.9, z=0.06))

# --- Большой лого нужно обновить: старые menu_title_* уже переопределены
# выше (мы заменяем весь диапазон). Ничего дополнительно.
# --- Подсказка ↑↓ Enter под кнопками ---
out.write(text("menu_hint", -370, -330, 420,
               "↑ ↓  выбор   •   ENTER  подтвердить   •   ESC  назад",
               font="jb_mono_14", color=PAPER_DIM, alpha=0.45,
               pivot="PIVOT_W", z=0.05))

new_menu_block = out.getvalue()

# ------------------------------------------------------------
# Находим диапазон в .gui и заменяем
# ------------------------------------------------------------
with open(GUI_PATH, "rb") as f:
    raw = f.read().decode("utf-8")
# Нормализуем переводы строк внутри этого скрипта, но запишем CRLF назад.
data = raw.replace("\r\n", "\n")

# Находим начало блока menu_panel
PAT_START = 'nodes {\n  position {\n    x: 480.0\n    y: 320.0\n    z: 0.5\n  }\n  size {\n    x: 960.0\n    y: 640.0\n  }\n  color {\n    x: 0.02\n    y: 0.02\n    z: 0.08\n  }\n  type: TYPE_BOX\n  id: "menu_panel"'
idx_start = data.find(PAT_START)
if idx_start < 0:
    print("FAIL: не нашли menu_panel")
    sys.exit(1)

# Находим ЗАКРЫТИЕ последнего старого меню-нода: ищем
# id: "menu_btn_continue_left_line" и за ним ближайшее "}"
PAT_END_ID = 'id: "menu_btn_continue_left_line"'
idx_end_id = data.find(PAT_END_ID, idx_start)
if idx_end_id < 0:
    print("FAIL: не нашли menu_btn_continue_left_line")
    sys.exit(1)
# от idx_end_id ищем следующее "\n}\n"
idx_end_close = data.find("\n}\n", idx_end_id)
if idx_end_close < 0:
    print("FAIL: не нашли закрывающую } для последней menu-ноды")
    sys.exit(1)
idx_end = idx_end_close + 3  # включая \n}\n

before = data[:idx_start]
after  = data[idx_end:]

new_data = before + new_menu_block + after

with open(GUI_PATH, "wb") as f:
    f.write(new_data.replace("\n", "\r\n").encode("utf-8"))

print(f"OK: заменено {idx_end - idx_start} байт → {len(new_menu_block)} байт нового меню")
