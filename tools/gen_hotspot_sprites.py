# -*- coding: utf-8 -*-
"""
Генерирует 3 PNG-спрайта для круглых hotspot-кнопок:
  hotspot_circle.png — тёмная подложка, soft-edge
  hotspot_ring.png   — оранжевое кольцо с внешним halo-свечением
  hotspot_dot.png    — мягкая точка для орбиты
Кладёт в main/images/. Тонирование делаем через color node'а в .gui,
здесь рисуем в белом/с прозрачностью.
"""
from PIL import Image, ImageDraw, ImageFilter

OUT = r"C:\Users\GoldiM\novell1\novell1\main\images"

# --- circle_fill: белый круг с мягким краем (тонировать в dark в .gui) ---
def make_circle():
    SIZE = 256
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Чуть меньше размера с запасом под блюр
    margin = 14
    d.ellipse((margin, margin, SIZE - margin, SIZE - margin),
              fill=(255, 255, 255, 255))
    # Мягкий край через blur
    img = img.filter(ImageFilter.GaussianBlur(radius=3.5))
    img.save(f"{OUT}/hotspot_circle.png")

# --- ring_glow: оранжевое кольцо + снаружи мягкое свечение ---
def make_ring():
    SIZE = 256
    # База — оранжевое кольцо
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Внешний круг заливаем
    d.ellipse((24, 24, SIZE - 24, SIZE - 24),
              fill=(255, 255, 255, 255))
    # Вырезаем внутренний круг (делаем прозрачным)
    d.ellipse((42, 42, SIZE - 42, SIZE - 42),
              fill=(0, 0, 0, 0))
    # Размываем края кольца
    img = img.filter(ImageFilter.GaussianBlur(radius=2.5))

    # Добавим лёгкое наружное halo: другой слой с большим блюром и низкой альфой
    halo = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    hd = ImageDraw.Draw(halo)
    hd.ellipse((20, 20, SIZE - 20, SIZE - 20),
               fill=(255, 255, 255, 120))
    hd.ellipse((50, 50, SIZE - 50, SIZE - 50),
               fill=(0, 0, 0, 0))
    halo = halo.filter(ImageFilter.GaussianBlur(radius=14))

    # Комбинируем halo (снизу) + ring (сверху)
    combined = Image.alpha_composite(halo, img)
    combined.save(f"{OUT}/hotspot_ring.png")

# --- dot_soft: белая точка с мягким краем ---
def make_dot():
    SIZE = 64
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    margin = 8
    d.ellipse((margin, margin, SIZE - margin, SIZE - margin),
              fill=(255, 255, 255, 255))
    img = img.filter(ImageFilter.GaussianBlur(radius=2))
    img.save(f"{OUT}/hotspot_dot.png")

make_circle()
make_ring()
make_dot()
print("OK: circle/ring/dot PNG готовы в main/images/")
