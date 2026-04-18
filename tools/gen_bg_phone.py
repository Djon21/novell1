# -*- coding: utf-8 -*-
"""
Генерирует main/images/bg_phone.jpg 960×640 — фон сцены «главный экран
телефона». Композиция:
  • Внешняя рамка (тёмно-серая с лёгким градиентом) — имитация корпуса смартфона.
  • Экран посередине — тёмный фон с тонкой светящейся сеткой.
  • Сверху статус-бар (часы 09:42, батарея).
  • Снизу подпись «АВОСЬ // System».
Иконки приложений нарисуем уже в .gui как hotspot-круги (чтобы были кликабельны).
"""
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import os

OUT = r"C:\Users\GoldiM\novell1\novell1\main\images\bg_phone.jpg"

W, H = 960, 640

# Цвета
BODY_TOP    = (28, 28, 34)     # верхний край корпуса
BODY_BOTTOM = (18, 18, 22)     # нижний край
SCREEN_BG   = (14, 16, 22)     # цвет экрана
SCREEN_EDGE = (40, 45, 60)     # тонкая рамка экрана
GRID_LINE   = (40, 60, 90)     # линии сетки (слабые)
ACCENT      = (255, 110, 40)   # фирменный оранжевый
TEXT_DIM    = (180, 180, 200)

# Рисуем корпус: вертикальный градиент BODY_TOP→BODY_BOTTOM
img = Image.new("RGB", (W, H), BODY_TOP)
px = img.load()
for y in range(H):
    t = y / (H - 1)
    r = int(BODY_TOP[0] * (1 - t) + BODY_BOTTOM[0] * t)
    g = int(BODY_TOP[1] * (1 - t) + BODY_BOTTOM[1] * t)
    b = int(BODY_TOP[2] * (1 - t) + BODY_BOTTOM[2] * t)
    for x in range(W):
        px[x, y] = (r, g, b)

draw = ImageDraw.Draw(img)

# Экран — прямоугольник со скруглёнными углами в центре.
# Оставляем «рамку» 60px сверху/снизу (статусбар + подпись), 80px с боков.
SX, SY = 80, 60
EX, EY = W - 80, H - 60
RADIUS = 26
draw.rounded_rectangle((SX, SY, EX, EY), radius=RADIUS, fill=SCREEN_BG, outline=SCREEN_EDGE, width=2)

# Сетка на экране (как на terminal-hud): вертикали/горизонтали с шагом 48px.
STEP = 48
for x in range(SX + STEP, EX, STEP):
    draw.line([(x, SY + 4), (x, EY - 4)], fill=GRID_LINE, width=1)
for y in range(SY + STEP, EY, STEP):
    draw.line([(SX + 4, y), (EX - 4, y)], fill=GRID_LINE, width=1)

# Небольшой glow по краю экрана — дублируем рамку с блюром и наложим.
glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
gdraw = ImageDraw.Draw(glow)
gdraw.rounded_rectangle((SX - 4, SY - 4, EX + 4, EY + 4),
                        radius=RADIUS + 4, outline=(255, 110, 40, 70), width=3)
glow = glow.filter(ImageFilter.GaussianBlur(radius=6))
img.paste(glow, (0, 0), glow)

# ПОПРОБУЕМ подгрузить шрифт для текста. Fallback — дефолт PIL.
def load_font(size):
    candidates = [
        r"C:\Users\GoldiM\novell1\novell1\main\fonts\Inter-Regular.ttf",
        r"C:\Users\GoldiM\novell1\novell1\main\fonts\main.ttf",
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
font_title  = load_font(26)
font_footer = load_font(14)

# Статус-бар (над экраном, в «рамке» корпуса): 09:42 слева, АВОСЬ посередине, бат справа.
draw.text((28, 20), "09:42", font=font_status, fill=TEXT_DIM)
# Центр
txt = "АВОСЬ OS"
# Pillow 10+ uses textbbox, 9- uses textsize. Best to use textbbox.
try:
    bbox = draw.textbbox((0, 0), txt, font=font_status)
    tw = bbox[2] - bbox[0]
except Exception:
    tw = len(txt) * 8
draw.text(((W - tw) // 2, 20), txt, font=font_status, fill=ACCENT)
# Батарея справа — маленький прямоугольник
bx = W - 70
draw.rectangle((bx, 22, bx + 32, 36), outline=TEXT_DIM, width=1)
draw.rectangle((bx + 32, 26, bx + 36, 32), fill=TEXT_DIM)
draw.rectangle((bx + 2, 24, bx + 24, 34), fill=(120, 200, 140))  # заряд ~70%

# Заголовок поверх экрана, по центру сверху — «Главное меню».
title = "Главное меню"
try:
    bbox = draw.textbbox((0, 0), title, font=font_title)
    tw = bbox[2] - bbox[0]
except Exception:
    tw = len(title) * 14
draw.text(((W - tw) // 2, SY + 18), title, font=font_title, fill=TEXT_DIM)

# Подпись внизу — мелким оранжевым
footer = "PATCH temporal_sync.module"
try:
    bbox = draw.textbbox((0, 0), footer, font=font_footer)
    tw = bbox[2] - bbox[0]
except Exception:
    tw = len(footer) * 7
draw.text(((W - tw) // 2, H - 30), footer, font=font_footer, fill=(ACCENT[0], ACCENT[1], ACCENT[2]))

# Сохраняем как JPG — фоны всегда JPG (см. остальные bg_*.jpg).
img.save(OUT, quality=88, optimize=True)
print(f"OK: {OUT}")
