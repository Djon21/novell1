# -*- coding: utf-8 -*-
"""
Добавляет в novel_ui.gui ноды HUD-панели (4 слота инвентаря в right-top)
и модалку предмета (dim-overlay + карточка с описанием + кнопка закрыть).
"""
import io, re

GUI = r"C:\Users\GoldiM\novell1\novell1\main\gui\novel_ui.gui"
with io.open(GUI, "r", encoding="utf-8") as f:
    text = f.read()

if "hud_slot_1" in text:
    print("HUD уже добавлен, пропускаю.")
    raise SystemExit(0)

# Генерируем ноды HUD. z-индекс:
#   0.82 — dim-overlay модалки (ниже карточки, выше hotspot'ов)
#   0.83 — карточка-панель модалки
#   0.84 — текст в карточке
#   0.85 — кнопка «Закрыть»
#   0.90 — HUD-панель (всегда сверху)

HUD_BLOCK = []

# Слоты HUD справа-сверху. Расстояние между центрами 100px.
# Правый край 960, отступ 60 → центр первого слота x=900
# Сверху 640, отступ 60 → y=580
SLOT_SIZE = 80  # диаметр круглой кнопки-слота
for i in range(1, 5):
    cx = 900 - (i - 1) * 100
    cy = 580
    # Контейнер-box под texture круга (soft-edge)
    HUD_BLOCK.append(f'''nodes {{
  position {{
    x: {cx}.0
    y: {cy}.0
    z: 0.90
  }}
  size {{
    x: {SLOT_SIZE}.0
    y: {SLOT_SIZE}.0
  }}
  color {{
    x: 0.0
    y: 0.0
    z: 0.0
  }}
  type: TYPE_BOX
  texture: "backgrounds/hotspot_circle"
  id: "hud_slot_circle_{i}"
  adjust_mode: ADJUST_MODE_ZOOM
  alpha: 0.55
  enabled: false
}}''')
    # Кольцо
    HUD_BLOCK.append(f'''nodes {{
  position {{
    x: {cx}.0
    y: {cy}.0
    z: 0.91
  }}
  size {{
    x: {SLOT_SIZE + 18}.0
    y: {SLOT_SIZE + 18}.0
  }}
  color {{
    x: 1.0
    y: 1.0
    z: 1.0
  }}
  type: TYPE_BOX
  texture: "backgrounds/hotspot_ring"
  id: "hud_slot_ring_{i}"
  adjust_mode: ADJUST_MODE_ZOOM
  alpha: 0.9
  enabled: false
}}''')
    # Иконка (Material Icons) — белая
    HUD_BLOCK.append(f'''nodes {{
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
  text: ""
  font: "material_icons"
  id: "hud_slot_icon_{i}"
  adjust_mode: ADJUST_MODE_ZOOM
  outline_alpha: 0.0
  shadow_alpha: 0.0
  enabled: false
}}''')
    # Большой invisible hitbox поверх для клика (чтобы попадать пальцем на мобиле)
    HUD_BLOCK.append(f'''nodes {{
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
  id: "hud_slot_hit_{i}"
  adjust_mode: ADJUST_MODE_ZOOM
  alpha: 0.0
  enabled: false
}}''')

# --- Модалка: dim-overlay на весь экран, карточка, текст, кнопка закрытия ---
MODAL_BLOCK = ['''nodes {
  position {
    x: 480.0
    y: 320.0
    z: 0.82
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
  id: "item_modal_dim"
  adjust_mode: ADJUST_MODE_STRETCH
  alpha: 0.65
  enabled: false
}''',
'''nodes {
  position {
    x: 480.0
    y: 320.0
    z: 0.83
  }
  size {
    x: 560.0
    y: 340.0
  }
  color {
    x: 0.10
    y: 0.10
    z: 0.14
  }
  type: TYPE_BOX
  id: "item_modal_panel"
  adjust_mode: ADJUST_MODE_ZOOM
  alpha: 0.97
  enabled: false
}''',
# Заголовок (имя предмета)
'''nodes {
  position {
    x: 0.0
    y: 130.0
    z: 0.0
  }
  size {
    x: 520.0
    y: 40.0
  }
  color {
    x: 1.0
    y: 1.0
    z: 1.0
  }
  type: TYPE_TEXT
  text: "Название"
  font: "main"
  id: "item_modal_name"
  adjust_mode: ADJUST_MODE_ZOOM
  parent: "item_modal_panel"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}''',
# Большая иконка в карточке
'''nodes {
  position {
    x: -180.0
    y: 20.0
    z: 0.0
  }
  size {
    x: 160.0
    y: 160.0
  }
  color {
    x: 1.0
    y: 1.0
    z: 1.0
  }
  type: TYPE_TEXT
  text: ""
  font: "material_icons"
  id: "item_modal_icon"
  adjust_mode: ADJUST_MODE_ZOOM
  parent: "item_modal_panel"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}''',
# Описание (текст справа от иконки)
'''nodes {
  position {
    x: 80.0
    y: 40.0
    z: 0.0
  }
  size {
    x: 340.0
    y: 180.0
  }
  color {
    x: 0.88
    y: 0.88
    z: 0.92
  }
  type: TYPE_TEXT
  text: "Описание предмета..."
  font: "main"
  id: "item_modal_desc"
  adjust_mode: ADJUST_MODE_ZOOM
  parent: "item_modal_panel"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
  line_break: true
}''',
# Кнопка закрытия (по центру снизу карточки)
'''nodes {
  position {
    x: 0.0
    y: -130.0
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
  id: "item_modal_close_btn"
  adjust_mode: ADJUST_MODE_ZOOM
  parent: "item_modal_panel"
  inherit_alpha: true
  alpha: 0.9
}''',
'''nodes {
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
  id: "item_modal_close_text"
  adjust_mode: ADJUST_MODE_ZOOM
  parent: "item_modal_close_btn"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}''',
]

new_nodes = "\n".join(HUD_BLOCK + MODAL_BLOCK)

# Вставить перед финальной строкой `material: "/builtins/materials/gui.material"`
idx = text.rfind('material: "/builtins/materials/gui.material"')
if idx == -1:
    raise SystemExit("material line not found")

text = text[:idx] + new_nodes + "\n" + text[idx:]

with io.open(GUI, "w", encoding="utf-8") as f:
    f.write(text)

print("OK: добавлено %d HUD-нод" % (len(HUD_BLOCK) + len(MODAL_BLOCK)))
