"""
normalize_sources.py — нормализует исходники от нейронки:
  1) Конвертирует .webp / .jpg / .jpeg → .png
  2) Ресайзит до квадратного size×size (default 512×512)
  3) Сохраняет рядом, исходники НЕ трогает (за исключением совпадающих имён,
     но обычно расширение разное, и .png кладётся новый файл)

Usage:
    python tools/normalize_sources.py <folder> [--size 512]

Example:
    python tools/normalize_sources.py tools/port_p/raw_a1
        → 1.png остаётся 512×512 (если уже квадратный, иначе ресайзит)
        → 2.webp / 3.webp / 4.webp → 2.png / 3.png / 4.png 512×512
"""
import argparse
import os
import sys
from PIL import Image


SUPPORTED_EXTS = (".png", ".webp", ".jpg", ".jpeg", ".bmp")


def main():
    p = argparse.ArgumentParser(description="Resize + convert images to PNG 512x512")
    p.add_argument("folder", help="Folder with source images")
    p.add_argument("--size", type=int, default=512,
                   help="Output size (square). Default 512.")
    args = p.parse_args()

    if not os.path.isdir(args.folder):
        print(f"FATAL: not a folder: {args.folder}")
        sys.exit(1)

    size = (args.size, args.size)
    converted = 0
    for fname in sorted(os.listdir(args.folder)):
        src = os.path.join(args.folder, fname)
        if not os.path.isfile(src):
            continue
        name, ext = os.path.splitext(fname)
        ext_lower = ext.lower()
        if ext_lower not in SUPPORTED_EXTS:
            continue

        dst = os.path.join(args.folder, name + ".png")
        try:
            img = Image.open(src)
        except Exception as e:
            print(f"  SKIP {fname}: {e}")
            continue

        # webp могут быть как RGB так и RGBA — приводим к RGBA для единообразия
        img = img.convert("RGBA")
        if img.size != size:
            img = img.resize(size, Image.LANCZOS)
        img.save(dst, "PNG", optimize=True)

        # Удалить исходник если конвертация была между расширениями
        if ext_lower != ".png" and os.path.exists(dst):
            os.remove(src)
            print(f"  {fname} -> {name}.png  ({size[0]}x{size[1]})  [removed {ext_lower}]")
        else:
            print(f"  {fname}: resized to {size[0]}x{size[1]}")
        converted += 1

    print(f"\nDone. {converted} file(s) processed.")


if __name__ == "__main__":
    main()
