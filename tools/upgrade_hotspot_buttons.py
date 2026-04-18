# -*- coding: utf-8 -*-
"""
Преобразует hotspot_badge_N (квадратная плашка) в профессиональную
кнопку: круглый PIE-бейдж + glow-ring + orbit-parent с 6 точками.
Также добавляет fonts-блок для material_icons, если его нет.
"""
import re
import sys
import io

GUI = r"C:\Users\GoldiM\novell1\novell1\main\gui\novel_ui.gui"

with io.open(GUI, "r", encoding="utf-8") as f:
    text = f.read()

# --- 1. Добавим fonts { material_icons } после fonts { icons } ---
if "material_icons" not in text:
    text = text.replace(
        'fonts {\n  name: "icons"\n  font: "/main/fonts/icons.font"\n}',
        'fonts {\n  name: "icons"\n  font: "/main/fonts/icons.font"\n}\n'
        'fonts {\n  name: "material_icons"\n  font: "/main/fonts/material_icons.font"\n}',
    )

# --- 2. Для каждого hotspot N (1..6) найти hotspot_badge_N блок и
#        заменить его на круг+кольцо+орбиту+точки ---
# Блок hotspot_badge_N выглядит так:
#   nodes {
#     position { x: 480 y: 320 z: 0.069 }
#     size { x: 72 y: 72 }
#     color { x: 0.08 y: 0.08 z: 0.12 }
#     type: TYPE_BOX
#     id: "hotspot_badge_N"
#     adjust_mode: ADJUST_MODE_ZOOM
#     alpha: 0.72
#     enabled: false
#   }

def build_block(n):
    parts = []
    # Круглый бейдж (тёмная подложка) — z=0.068
    parts.append(f'''nodes {{
  position {{
    x: 480.0
    y: 320.0
    z: 0.068
  }}
  size {{
    x: 96.0
    y: 96.0
  }}
  color {{
    x: 0.06
    y: 0.06
    z: 0.10
  }}
  type: TYPE_PIE
  id: "hotspot_circle_{n}"
  perimeterVertices: 48
  outerBounds: PIEBOUNDS_ELLIPSE
  adjust_mode: ADJUST_MODE_ZOOM
  alpha: 0.78
  enabled: false
}}''')
    # Glow-кольцо (оранжевый свет вокруг) — z=0.067, inner_radius чтобы было кольцом
    parts.append(f'''nodes {{
  position {{
    x: 480.0
    y: 320.0
    z: 0.067
  }}
  size {{
    x: 120.0
    y: 120.0
  }}
  color {{
    x: 1.0
    y: 0.65
    z: 0.28
  }}
  type: TYPE_PIE
  id: "hotspot_ring_{n}"
  perimeterVertices: 48
  innerRadius: 52.0
  outerBounds: PIEBOUNDS_ELLIPSE
  adjust_mode: ADJUST_MODE_ZOOM
  alpha: 0.90
  enabled: false
}}''')
    # Orbit parent — невидимый узел-якорь, вокруг которого крутятся точки
    parts.append(f'''nodes {{
  position {{
    x: 480.0
    y: 320.0
    z: 0.066
  }}
  size {{
    x: 1.0
    y: 1.0
  }}
  color {{
    x: 0.0
    y: 0.0
    z: 0.0
  }}
  type: TYPE_BOX
  id: "hotspot_orbit_{n}"
  adjust_mode: ADJUST_MODE_ZOOM
  alpha: 0.0
  enabled: false
}}''')
    # 6 точек вокруг на радиусе 72
    import math
    for i in range(6):
        angle = i * 60.0  # градусов
        rad = math.radians(angle)
        rx = 72.0 * math.cos(rad)
        ry = 72.0 * math.sin(rad)
        parts.append(f'''nodes {{
  position {{
    x: {rx:.2f}
    y: {ry:.2f}
    z: 0.0
  }}
  size {{
    x: 14.0
    y: 14.0
  }}
  color {{
    x: 1.0
    y: 0.80
    z: 0.40
  }}
  type: TYPE_PIE
  id: "hotspot_dot_{n}_{i+1}"
  perimeterVertices: 16
  outerBounds: PIEBOUNDS_ELLIPSE
  parent: "hotspot_orbit_{n}"
  adjust_mode: ADJUST_MODE_ZOOM
  alpha: 1.0
  inherit_alpha: false
  enabled: false
}}''')
    return "\n".join(parts)

# Регэксп для hotspot_badge_N блока
for n in range(1, 7):
    pattern = re.compile(
        r'nodes \{\n'
        r'  position \{\n'
        r'    x: 480\.0\n'
        r'    y: 320\.0\n'
        r'    z: 0\.069\n'
        r'  \}\n'
        r'  size \{\n'
        r'    x: 72\.0\n'
        r'    y: 72\.0\n'
        r'  \}\n'
        r'  color \{\n'
        r'    x: 0\.08\n'
        r'    y: 0\.08\n'
        r'    z: 0\.12\n'
        r'  \}\n'
        r'  type: TYPE_BOX\n'
        r'  id: "hotspot_badge_' + str(n) + r'"\n'
        r'  adjust_mode: ADJUST_MODE_ZOOM\n'
        r'  alpha: 0\.72\n'
        r'  enabled: false\n'
        r'\}'
    )
    new_block = build_block(n)
    new_text, count = pattern.subn(new_block, text, count=1)
    if count != 1:
        print(f"[WARN] hotspot_badge_{n}: найдено совпадений = {count}")
    text = new_text

# --- 3. Меняем у hotspot_icon_N шрифт "icons" → "material_icons" ---
# Но только в блоках hotspot_icon_N, не везде!
# Находим блоки по id: "hotspot_icon_N" и меняем font в них.
def fix_icon_font(m):
    block = m.group(0)
    # Заменим font: "icons" на font: "material_icons"
    block = re.sub(r'font: "icons"', 'font: "material_icons"', block)
    return block

text = re.sub(
    r'nodes \{[^{}]*?id: "hotspot_icon_\d+"[^{}]*?\}',
    fix_icon_font,
    text,
    flags=re.DOTALL
)

with io.open(GUI, "w", encoding="utf-8") as f:
    f.write(text)

print("[OK] hotspot buttons upgraded to circle+ring+orbit")
