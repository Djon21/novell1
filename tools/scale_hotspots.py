#!/usr/bin/env python3
"""
Скрипт для пересчёта hotspot координат из 960×640 в 1280×720
"""

import re
from pathlib import Path

SCALE_X = 1280 / 960  # 1.333
SCALE_Y = 720 / 640   # 1.125

def scale_rect(x, y, w, h):
    """Пересчитывает координаты прямоугольника"""
    return (
        round(x * SCALE_X),
        round(y * SCALE_Y),
        round(w * SCALE_X),
        round(h * SCALE_Y)
    )

def replace_rect(match):
    """Заменяет rect = { x = ..., y = ..., w = ..., h = ... }"""
    x = int(match.group(1))
    y = int(match.group(2))
    w = int(match.group(3))
    h = int(match.group(4))
    
    new_x, new_y, new_w, new_h = scale_rect(x, y, w, h)
    
    return f"rect = {{ x = {new_x}, y = {new_y}, w = {new_w}, h = {new_h} }}"

def main():
    scenes_path = Path("main/scripts/scenes.lua")
    
    if not scenes_path.exists():
        print(f"Error: {scenes_path} not found")
        return
    
    # Читаем файл
    with open(scenes_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Обновляем комментарий
    content = content.replace(
        "в коорд. системе .gui (960×640",
        "в коорд. системе .gui (1280×720"
    )
    
    # Заменяем все rect = { x = ..., y = ..., w = ..., h = ... }
    pattern = r'rect = \{ x = (\d+), y = (\d+), w = (\d+), h = (\d+) \}'
    content = re.sub(pattern, replace_rect, content)
    
    # Сохраняем
    with open(scenes_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"[OK] Updated {scenes_path}")
    print(f"  Scale factors: X={SCALE_X:.3f}, Y={SCALE_Y:.3f}")
    print(f"  All hotspot rectangles have been recalculated")

if __name__ == "__main__":
    main()
