# -*- coding: utf-8 -*-
"""
Генерирует main/images/bg_menu.jpg 960×640 — главный фон стартового
меню «АВОСЬ». Эстетика по дизайн-бандлу Claude Design:
  • Ночное небо с фиолет-индиго градиентом и звёздной пылью.
  • Силуэт Москвы (МГУ, Москва-Сити, церковный купол) на среднем плане.
  • Дымка/туман над городом.
  • Стол программиста с CRT-монитором, клавиатурой и чашкой кофе.
  • Неоновые блики (циан/магента/янтарь).
  • Скан-линии CRT поверх, лёгкая виньетка.

Текст логотипа, меню, штамп и досье рисуются gui-нодами поверх.
"""
from PIL import Image, ImageDraw, ImageFilter
import os, random, math

OUT = r"C:\Users\GoldiM\novell1\novell1\main\images\bg_menu.jpg"

W, H = 960, 640

# Палитра (из menu.html)
INK_0     = (7, 6, 26)        # #07061a — самый тёмный низ
INK_1     = (12, 10, 36)      # #0c0a24
INK_2     = (23, 18, 50)      # #171232
PURPLE_LO = (26, 16, 64)      # #1a1040 — свечение неба
PURPLE_HI = (42, 18, 86)      # #2a1256 — свечение неба
CYAN      = (125, 249, 255)   # #7df9ff
MAGENTA   = (255, 61, 127)    # #ff3d7f
AMBER     = (255, 179, 71)    # #ffb347
VIOLET    = (122, 92, 255)    # #7a5cff
PAPER     = (243, 236, 217)

random.seed(42)


def lerp(a, b, t):
    return tuple(int(a[i] * (1 - t) + b[i] * t) for i in range(3))


def mix(c, other, t):
    return tuple(int(c[i] * (1 - t) + other[i] * t) for i in range(3))


# --------------------------------------------------------------------
# 1. Небо с градиентом + «свечением» по углам
# --------------------------------------------------------------------
img = Image.new("RGB", (W, H), INK_1)
px = img.load()
for y in range(H):
    t = y / (H - 1)
    # базовый вертикальный градиент
    base = lerp(INK_2, INK_0, t)
    for x in range(W):
        # радиальное свечение индиго снизу-центре
        dx = (x - W * 0.5) / W
        dy = (y - H * 1.1) / H
        d1 = math.sqrt(dx * dx + dy * dy)
        glow1 = max(0.0, 1.0 - d1 / 0.7) ** 2 * 0.55

        # радиальное свечение магенты сверху-справа
        dx = (x - W * 0.85) / W
        dy = (y - 0) / H
        d2 = math.sqrt(dx * dx + dy * dy)
        glow2 = max(0.0, 1.0 - d2 / 0.55) ** 2 * 0.35

        col = base
        col = mix(col, PURPLE_LO, glow1)
        col = mix(col, PURPLE_HI, glow2)
        px[x, y] = col

draw = ImageDraw.Draw(img)

# --------------------------------------------------------------------
# 2. Звёздная пыль в верхней трети
# --------------------------------------------------------------------
for _ in range(140):
    x = random.randint(0, W - 1)
    y = random.randint(0, int(H * 0.38))
    r = random.choice([1, 1, 1, 2])
    a = random.uniform(0.25, 0.95)
    col = random.choice([
        (207, 232, 255), (255, 255, 255), (125, 249, 255), (207, 232, 255)
    ])
    draw.ellipse([x - r, y - r, x + r, y + r], fill=tuple(int(c * a) + int(30 * (1 - a)) for c in col))

# --------------------------------------------------------------------
# 3. Силуэт Москвы на среднем плане (≈ y от H*0.55 до H*0.78)
# --------------------------------------------------------------------
# Базовая линия силуэта — очень тёмный индиго
SKY_BASE_Y = int(H * 0.72)

# Дальний слой (размытый, прозрачный)
far_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
fdraw = ImageDraw.Draw(far_layer)

# Несколько панельных домов-коробок
for i in range(14):
    bx = i * 70 + random.randint(-10, 10)
    bw = random.randint(40, 90)
    bh = random.randint(40, 110)
    by = SKY_BASE_Y - bh
    fdraw.rectangle([bx, by, bx + bw, SKY_BASE_Y], fill=(8, 6, 28, 200))
    # подсвеченные окна
    for _ in range(random.randint(3, 9)):
        wx = bx + random.randint(4, max(4, bw - 8))
        wy = by + random.randint(4, max(4, bh - 10))
        col = random.choice([
            (255, 200, 110, 180), (125, 200, 255, 140),
            (255, 120, 160, 120), (40, 50, 80, 60),
        ])
        fdraw.rectangle([wx, wy, wx + 3, wy + 5], fill=col)

# Лёгкий блюр дальнего слоя
far_layer = far_layer.filter(ImageFilter.GaussianBlur(radius=1.2))
img.paste(far_layer, (0, 0), far_layer)

# Средний слой: характерные силуэты — МГУ, Москва-Сити, купол
mid_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
mdraw = ImageDraw.Draw(mid_layer)

def tower(x, base_w, total_h, spire_h, color=(4, 3, 18, 240)):
    """Сталинка/МГУ: ступенчатая башня со шпилем."""
    by = SKY_BASE_Y
    # основание
    mdraw.rectangle([x - base_w // 2, by - total_h * 0.4, x + base_w // 2, by],
                    fill=color)
    # средняя секция
    w2 = int(base_w * 0.65)
    mdraw.rectangle([x - w2 // 2, by - total_h * 0.7, x + w2 // 2, by - total_h * 0.4],
                    fill=color)
    # верхняя секция
    w3 = int(base_w * 0.38)
    mdraw.rectangle([x - w3 // 2, by - total_h * 0.95, x + w3 // 2, by - total_h * 0.7],
                    fill=color)
    # шпиль
    mdraw.polygon([
        (x - 3, by - total_h * 0.95),
        (x + 3, by - total_h * 0.95),
        (x, by - total_h * 0.95 - spire_h),
    ], fill=color)
    # звезда на шпиле — маленькая неоновая точка
    star_y = by - total_h * 0.95 - spire_h + 2
    mdraw.ellipse([x - 2, star_y - 2, x + 2, star_y + 2], fill=(255, 100, 140, 230))

def skyscraper(x, w, h, tilt=0.0, color=(3, 2, 16, 250)):
    """Москва-Сити: стеклянный параллелепипед с наклоном."""
    by = SKY_BASE_Y
    top_x = x + int(h * tilt)
    mdraw.polygon([
        (x - w // 2, by),
        (x + w // 2, by),
        (top_x + w // 2, by - h),
        (top_x - w // 2, by - h),
    ], fill=color)
    # окна-полосы
    for i in range(1, 8):
        ly = by - int(h * i / 8)
        dx = int(h * tilt * i / 8)
        mdraw.line([(x - w // 2 + dx + 3, ly), (x + w // 2 + dx - 3, ly)],
                   fill=(30, 40, 70, 140), width=1)

def church_dome(x, base_w, color=(4, 3, 18, 240)):
    """Церковный купол."""
    by = SKY_BASE_Y
    h = int(base_w * 1.4)
    # основание
    mdraw.rectangle([x - base_w // 2, by - h * 0.5, x + base_w // 2, by], fill=color)
    # барабан
    bw = int(base_w * 0.55)
    mdraw.rectangle([x - bw // 2, by - h * 0.75, x + bw // 2, by - h * 0.5], fill=color)
    # купол (эллипс)
    dw = int(base_w * 0.7)
    mdraw.ellipse([x - dw // 2, by - h * 1.05, x + dw // 2, by - h * 0.6], fill=color)
    # крест
    cy = by - h * 1.05
    mdraw.line([(x, cy - 8), (x, cy)], fill=(255, 200, 120, 230), width=2)
    mdraw.line([(x - 4, cy - 4), (x + 4, cy - 4)], fill=(255, 200, 120, 230), width=2)

# Москва-Сити слева
skyscraper(x=130, w=44, h=230, tilt=-0.04)
skyscraper(x=175, w=54, h=270, tilt=0.03)
skyscraper(x=225, w=40, h=210, tilt=0.0)

# Церковь по центру
church_dome(x=360, base_w=52)

# МГУ-сталинка
tower(x=500, base_w=110, total_h=240, spire_h=50)

# Ещё пара низких зданий
mdraw.rectangle([600, SKY_BASE_Y - 100, 720, SKY_BASE_Y], fill=(4, 3, 18, 240))
mdraw.rectangle([720, SKY_BASE_Y - 140, 820, SKY_BASE_Y], fill=(4, 3, 18, 240))
# окна у правых зданий
for i in range(12):
    for j in range(3):
        wx = 608 + i * 9
        wy = SKY_BASE_Y - 20 - j * 22
        if random.random() < 0.6:
            mdraw.rectangle([wx, wy, wx + 4, wy + 7],
                            fill=random.choice([
                                (255, 200, 110, 180),
                                (120, 200, 255, 140),
                                (20, 25, 50, 80),
                            ]))

# Правая высотка
skyscraper(x=870, w=70, h=290, tilt=-0.02)

img.paste(mid_layer, (0, 0), mid_layer)

# --------------------------------------------------------------------
# 4. Туман/дымка над городом
# --------------------------------------------------------------------
haze = Image.new("RGBA", (W, H), (0, 0, 0, 0))
hdraw = ImageDraw.Draw(haze)
for y in range(int(H * 0.5), H):
    t = (y - H * 0.5) / (H * 0.5)
    a = int(min(220, t * 240))
    hdraw.rectangle([0, y, W, y + 1], fill=(6, 5, 26, a))
haze = haze.filter(ImageFilter.GaussianBlur(radius=2))
img.paste(haze, (0, 0), haze)

# --------------------------------------------------------------------
# 5. Неоновые блики (circular glow)
# --------------------------------------------------------------------
def neon_dot(cx, cy, col, r=4, glow_r=22):
    g = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(g)
    gd.ellipse([cx - glow_r, cy - glow_r, cx + glow_r, cy + glow_r],
               fill=(*col, 70))
    g = g.filter(ImageFilter.GaussianBlur(radius=6))
    gd2 = ImageDraw.Draw(g)
    gd2.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(*col, 255))
    img.paste(g, (0, 0), g)

neon_dot(170, 380, CYAN)
neon_dot(715, 360, MAGENTA)
neon_dot(520, 400, AMBER, r=3, glow_r=16)
neon_dot(820, 420, CYAN, r=3, glow_r=14)

# --------------------------------------------------------------------
# 6. Стол программиста (нижние ~30% кадра)
# --------------------------------------------------------------------
DESK_TOP = int(H * 0.72)
# градиентное полотно стола от тёмного к почти чёрному
for y in range(DESK_TOP, H):
    t = (y - DESK_TOP) / (H - DESK_TOP)
    col = lerp((8, 6, 24), (0, 0, 0), t)
    draw.rectangle([0, y, W, y + 1], fill=col)

# Тонкая циан-линия — край стола
draw.line([(0, DESK_TOP), (W, DESK_TOP)], fill=(125, 249, 255), width=1)

# --------------------------------------------------------------------
# 7. CRT-монитор справа
# --------------------------------------------------------------------
MX, MY = 700, 480
MW, MH = 230, 135
# корпус
draw.rectangle([MX, MY, MX + MW, MY + MH], fill=(10, 8, 34))
draw.rectangle([MX + 8, MY + 8, MX + MW - 8, MY + MH - 8], fill=(2, 1, 18))
# сканлайны на экране
for y in range(MY + 10, MY + MH - 10, 3):
    draw.line([(MX + 10, y), (MX + MW - 10, y)], fill=(125, 249, 255, 20), width=1)
# «код» на экране — просто рандомные тире/точки циан
mon = Image.new("RGBA", (W, H), (0, 0, 0, 0))
mdraw2 = ImageDraw.Draw(mon)
for i in range(14):
    ly = MY + 14 + i * 9
    # случайная строка из точек/тире
    s_x = MX + 14
    for _ in range(random.randint(6, 22)):
        w = random.choice([2, 4, 6, 10, 14])
        col = random.choice([
            (125, 249, 255, 160),
            (255, 111, 163, 140),
            (255, 209, 102, 140),
            (106, 122, 160, 120),
        ])
        mdraw2.line([(s_x, ly), (s_x + w, ly)], fill=col, width=1)
        s_x += w + random.choice([3, 4, 6])
        if s_x > MX + MW - 16:
            break
img.paste(mon, (0, 0), mon)

# Виньетка у экрана монитора
mv = Image.new("RGBA", (W, H), (0, 0, 0, 0))
mvd = ImageDraw.Draw(mv)
mvd.ellipse([MX - 40, MY - 30, MX + MW + 40, MY + MH + 30],
            fill=(0, 0, 0, 0), outline=None)
# радиальное затемнение по краям экрана
inner = Image.new("RGBA", (MW - 20, MH - 20), (0, 0, 0, 0))
idr = ImageDraw.Draw(inner)
for r in range(30, 0, -1):
    a = int(120 * (1 - r / 30))
    idr.rectangle([r, r, (MW - 20) - r, (MH - 20) - r],
                  outline=(0, 0, 0, a))
img.paste(inner, (MX + 10, MY + 10), inner)

# подставка монитора
draw.rectangle([MX + MW // 2 - 30, MY + MH, MX + MW // 2 + 30, MY + MH + 14],
               fill=(10, 8, 34))
draw.rectangle([MX + MW // 2 - 60, MY + MH + 14, MX + MW // 2 + 60, MY + MH + 20],
               fill=(10, 8, 34))

# --------------------------------------------------------------------
# 8. Клавиатура слева от монитора
# --------------------------------------------------------------------
KX, KY, KW, KH = 470, 620, 220, 12
draw.rectangle([KX, KY, KX + KW, KY + KH], fill=(11, 8, 32))
# клавиши — мелкие циан-полоски
for i in range(26):
    x = KX + 6 + i * 8
    draw.line([(x, KY + 3), (x + 5, KY + 3)], fill=(125, 249, 255, 90), width=1)
    draw.line([(x, KY + 8), (x + 5, KY + 8)], fill=(125, 249, 255, 60), width=1)

# --------------------------------------------------------------------
# 9. Чашка кофе слева
# --------------------------------------------------------------------
CX, CY = 140, 610
draw.rounded_rectangle([CX, CY - 60, CX + 44, CY], radius=4, fill=(26, 20, 48))
draw.rounded_rectangle([CX + 4, CY - 52, CX + 40, CY - 44], radius=2, fill=(42, 34, 71))
# пар (мелкие белые штрихи)
for i in range(3):
    dy = i * 8
    draw.ellipse([CX + 15 - i, CY - 78 - dy, CX + 29 + i, CY - 66 - dy],
                 fill=(255, 255, 255, 30))

# --------------------------------------------------------------------
# 10. CRT сканлайны поверх всего (лёгкие)
# --------------------------------------------------------------------
scan = Image.new("RGBA", (W, H), (0, 0, 0, 0))
sdr = ImageDraw.Draw(scan)
for y in range(0, H, 3):
    sdr.line([(0, y), (W, y)], fill=(255, 255, 255, 12), width=1)
img.paste(scan, (0, 0), scan)

# --------------------------------------------------------------------
# 11. Виньетка
# --------------------------------------------------------------------
vg = Image.new("RGBA", (W, H), (0, 0, 0, 0))
vgd = ImageDraw.Draw(vg)
for r in range(0, 180, 2):
    a = int(1.1 * r)
    if a > 200: a = 200
    vgd.rectangle([r, r, W - r, H - r], outline=(0, 0, 0, a))
vg = vg.filter(ImageFilter.GaussianBlur(radius=8))
img.paste(vg, (0, 0), vg)

# --------------------------------------------------------------------
img.save(OUT, quality=90, optimize=True)
print(f"OK: {OUT}  ({os.path.getsize(OUT)} bytes)")
