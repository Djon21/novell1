#!/usr/bin/env python3
"""
Скрипт для автоматического обновления разрешения в .gui файлах
960×640 → 1280×720
"""

import re
import os
import sys
from pathlib import Path

def update_gui_file(filepath):
    """Обновляет разрешение в одном .gui файле"""
    print(f"Processing: {filepath}")
    
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original = content
    
    # Replace 960.0 with 1280.0
    content = re.sub(r'\bx: 960\.0\b', 'x: 1280.0', content)
    
    # Replace 640.0 with 720.0
    content = re.sub(r'\by: 640\.0\b', 'y: 720.0', content)
    
    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"  [OK] Updated: {filepath}")
        return True
    else:
        print(f"  [-] No changes: {filepath}")
        return False

def main():
    # Путь к папке с GUI компонентами
    base_path = Path(__file__).parent.parent / "main" / "gui" / "components_v2"
    
    if not base_path.exists():
        print(f"Error: Path not found: {base_path}")
        sys.exit(1)
    
    # Найти все .gui файлы
    gui_files = list(base_path.glob("**/*.gui"))
    
    print(f"Found {len(gui_files)} .gui files")
    print("-" * 60)
    
    updated_count = 0
    for gui_file in gui_files:
        if update_gui_file(gui_file):
            updated_count += 1
    
    print("-" * 60)
    print(f"Updated {updated_count} / {len(gui_files)} files")

if __name__ == "__main__":
    main()
