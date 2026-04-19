# -*- coding: utf-8 -*-
"""
gen_bg_phone_v2.py — bg_phone.jpg v2 под новый дизайн HUD:
  * Тёмно-синий INK фон
  * Корпус смартфона скруглённый с notch сверху
  * Статус-бар "07:12" слева + иконки сети/батареи справа
  * Обои: крупные часы 07:12, подпись "понедельник . 23 апреля"
  * 8 ячеек приложений в сетке 4x2 (placeholder-квадраты)
"""
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import os

OUT = r"C:\Users\GoldiM\novell1\novell1\main\images\bg_phone.jpg"

W, H = 960, 640

INK      = (6, 3, 12)          # #06030c
INK_SOFT = (20, 14, 36)        # чуть светлее для корпуса
SCREEN_BG= (14, 12, 28)
PAPER    = (235, 233, 222)
ACCENT   = (125, 249, 255)
AMBER    = (255, 179, 71)
DIM      = (160, 162, 177)

img = Image.new("RGB", (W, H), INK)
draw = ImageDraw.Draw(img)

# Корпус смартфона (occupying large area, with rounded corners and notch)
BODY_X0, BODY_Y0 = 100, 20
BODY_X1, BODY_Y1 = 860, 620
draw.rounded_rectangle((BODY_X0, BODY_Y0, BODY_X1, BODY_Y1),
                       radius=40, fill=INK_SOFT,
                       outline=(50, 44, 80), width=2)

# Экран
SX0, SY0 = BODY_X0 + 20, BODY_Y0 + 40
SX1, SY1 = BODY_X1 - 20, BODY_Y1 - 40
draw.rounded_rectangle((SX0, SY0, SX1, SY1),
                       radius=26, fill=SCREEN_BG,
                       outline=(60, 52, 96), width=1)

# Notch (сверху по центру экрана)
NOTCH_W = 180
NOTCH_H = 26
NOTCH_X0 = (W - NOTCH_W) // 2
NOTCH_Y0 = SY0 - 2
draw.rounded_rectangle(
    (NOTCH_X0, NOTCH_Y0, NOTCH_X0 + NOTCH_W, NOTCH_Y0 + NOTCH_H),
    radius=13, fill=INK_SOFT)

# Шрифты
def load_font(size, bold=False):
    candidates = []
    if bold:
        candidates += [
            r"C:\Users\GoldiM\novell1\novell1\main\fonts\JetBrainsMono-Bold.ttf",
            r"C:\Users\GoldiM\novell1\novell1\main\fonts\Unbounded-Black.ttf",
            r"C:\Windows\Fonts\consolab.ttf",
            r"C:\Windows\Fonts\arialbd.ttf",
        ]
    candidates += [
        r"C:\Users\GoldiM\novell1\novell1\main\fonts\JetBrainsMono-Regular.ttf",
        r"C:\Windows\Fonts\consola.ttf",
        r"C:\Windows\Fonts\segoeui.ttf",
        r"C:\Windows\Fonts\arial.ttf",
    ]
    for p in candidates:
        if os.path.exists(p):
            try:
                return ImageFont.truetype(p, size)
            except Exception:
                pass
    return ImageFont.load_default()

font_status = load_font(16)
font_clock  = load_font(64, bold=True)
font_date   = load_font(18)
font_app    = load_font(13)
font_lbl    = load_font(11)

def textw(draw, txt, font):
    try:
        bbox = draw.textbbox((0, 0), txt, font=font)
        return bbox[2] - bbox[0]
    except Exception:
        return len(txt) * 8

# Статус-бар (внутри экрана, под notch-ом)
STATUS_Y = SY0 + 40
draw.text((SX0 + 30, STATUS_Y), "07:12", font=font_status, fill=PAPER)
# Иконки справа: net / battery
# Сеть — три палки
nx = SX1 - 110
for i in range(3):
    h = 4 + i * 3
    draw.rectangle((nx + i * 6, STATUS_Y + 14 - h, nx + i * 6 + 4, STATUS_Y + 14),
                   fill=PAPER)
# Батарея
bx = SX1 - 70
draw.rectangle((bx, STATUS_Y + 2, bx + 32, STATUS_Y + 16), outline=PAPER, width=1)
draw.rectangle((bx + 32, STATUS_Y + 6, bx + 36, STATUS_Y + 12), fill=PAPER)
draw.rectangle((bx + 2, STATUS_Y + 4, bx + 24, STATUS_Y + 14), fill=(130, 210, 150))

# Обои: крупные часы + подпись (выше верхнего ряда приложений)
CLOCK_Y = SY0 + 80
clock_txt = "07:12"
cw = textw(draw, clock_txt, font_clock)
draw.text(((W - cw) // 2, CLOCK_Y), clock_txt, font=font_clock, fill=PAPER)
date_txt = "понедельник . 23 апреля"
dw = textw(draw, date_txt, font_date)
draw.text(((W - dw) // 2, CLOCK_Y + 74), date_txt, font=font_date, fill=DIM)

# Сетка приложений 4x2.
# Координаты центров должны совпадать с hotspot'ами в scenes.lua:
#   Row 1 centers: y_gui=400 (→ pix y = H-400 = 240), x=160,360,560,760
#   Row 2 centers: y_gui=240 (→ pix y = H-240 = 400), x=160,360,560,760
ROW1_Y = H - 400
ROW2_Y = H - 240
CELL = 90  # размер placeholder-квадрата
APP_COLS = [160, 360, 560, 760]
APP_LABELS = [
    ("SMS", ACCENT),
    ("Звонки", DIM),
    ("Карта", DIM),
    ("Улики", ACCENT),
    ("День", DIM),
    ("Почта", ACCENT),
    ("Камера", DIM),
    ("Термн.", AMBER),
]
for i, cx in enumerate(APP_COLS):
    # row 1
    cy = ROW1_Y
    label, col = APP_LABELS[i]
    draw.rounded_rectangle(
        (cx - CELL // 2, cy - CELL // 2, cx + CELL // 2, cy + CELL // 2),
        radius=18, fill=(30, 24, 52), outline=col, width=1)
    # label под ячейкой
    lw = textw(draw, label, font_lbl)
    draw.text((cx - lw // 2, cy + CELL // 2 + 6), label, font=font_lbl, fill=DIM)

for i, cx in enumerate(APP_COLS):
    cy = ROW2_Y
    label, col = APP_LABELS[4 + i]
    draw.rounded_rectangle(
        (cx - CELL // 2, cy - CELL // 2, cx + CELL // 2, cy + CELL // 2),
        radius=18, fill=(30, 24, 52), outline=col, width=1)
    lw = textw(draw, label, font_lbl)
    draw.text((cx - lw // 2, cy + CELL // 2 + 6), label, font=font_lbl, fill=DIM)

# Нижний хинт — home-indicator
HINT_Y = BODY_Y1 - 20
draw.rounded_rectangle((W // 2 - 60, HINT_Y - 3, W // 2 + 60, HINT_Y + 3),
                       radius=3, fill=DIM)

# Лёгкий glow по краю экрана
glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
gdraw = ImageDraw.Draw(glow)
gdraw.rounded_rectangle((SX0 - 3, SY0 - 3, SX1 + 3, SY1 + 3),
                        radius=28, outline=(125, 249, 255, 45), width=2)
glow = glow.filter(ImageFilter.GaussianBlur(radius=5))
img.paste(glow, (0, 0), glow)

img.save(OUT, quality=90, optimize=True)
print(f"OK: {OUT}")
