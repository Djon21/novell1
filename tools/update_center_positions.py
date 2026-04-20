#!/usr/bin/env python3
"""
Скрипт для обновления центральных позиций в GUI файлах
Старый центр: (480, 320) для 960×640
Новый центр: (640, 360) для 1280×720
"""

import re
from pathlib import Path

def update_center_positions(filepath):
    """Обновляет позиции (480, 320) на (640, 360)"""
    print(f"Processing: {filepath}")
    
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original = content
    
    # Replace x: 480.0 with x: 640.0
    content = re.sub(r'\bx: 480\.0\b', 'x: 640.0', content)
    
    # Replace y: 320.0 with y: 360.0
    content = re.sub(r'\by: 320\.0\b', 'y: 360.0', content)
    
    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"  [OK] Updated center positions")
        return True
    else:
        print(f"  [-] No center positions found")
        return False

def main():
    base_path = Path("main/gui/components_v2")
    
    if not base_path.exists():
        print(f"Error: {base_path} not found")
        return
    
    gui_files = list(base_path.glob("**/*.gui"))
    
    print(f"Found {len(gui_files)} .gui files")
    print("-" * 60)
    
    updated_count = 0
    for gui_file in gui_files:
        if update_center_positions(gui_file):
            updated_count += 1
    
    print("-" * 60)
    print(f"Updated {updated_count} / {len(gui_files)} files")

if __name__ == "__main__":
    main()
