"""
compose_overlay.py — клеит crop'ы (от crop_rects.py) обратно на прозрачный
холст в исходных координатах из .rects.json. На выходе — overlay PNG того же
размера что и исходник, готовый для атласа Defold.

Pairs хорошо с crop_rects.py:
    1) mark_eyes.py 1.png            -> 1.rects.json
    2) crop_rects.py 1.png --prefix mouth
                                     -> 1_mouth_1.png, 1_mouth_2.png ...
    3) compose_overlay.py 1.png --prefix mouth
                                     -> 1_mouth_overlay.png

Usage:
    python tools/compose_overlay.py <image_path> --prefix LABEL
                                    [--rects PATH] [--out PATH]

Args:
    image_path  — путь к исходной картинке. Нужен только чтобы найти .rects.json
                  и crop-файлы рядом. Сама картинка не используется как контент.
    --prefix    — тот же prefix что был у crop_rects.py (e.g. mouth, eye).
    --rects     — путь к .rects.json. По умолчанию <image_path>.rects.json.
    --out       — путь к выходному PNG. По умолчанию <basename>_<prefix>_overlay.png.

Example:
    python tools/compose_overlay.py tools/port_p/rawl/1.png --prefix mouth
        -> tools/port_p/rawl/1_mouth_overlay.png
"""
import argparse
import json
import os
import sys
from PIL import Image


def main():
    p = argparse.ArgumentParser(description="Compose crops back onto transparent canvas")
    p.add_argument("image", help="Path to source image (used to find rects.json and crops nearby)")
    p.add_argument("--prefix", required=True,
                   help="Префикс crop-файлов (тот же что использовал в crop_rects.py)")
    p.add_argument("--rects", default=None, help="Path to .rects.json (default: <image>.rects.json)")
    p.add_argument("--out", default=None, help="Output PNG path")
    p.add_argument("--tight", action="store_true",
                   help="Crop output to union bbox всех rect'ов и сохранить "
                        "<output>.offset.json с координатами. Резко уменьшает "
                        "размер PNG (только feature-зона, без прозрачных полей). "
                        "Нужно для упаковки в маленький Defold-атлас.")
    args = p.parse_args()

    image_path = args.image
    base, _ = os.path.splitext(image_path)
    json_path = args.rects or (base + ".rects.json")
    out_path = args.out or f"{base}_{args.prefix}_overlay.png"

    if not os.path.exists(json_path):
        print(f"FATAL: rects file not found: {json_path}")
        sys.exit(1)

    with open(json_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    W, H = data["size"]
    rects = data.get("rects", [])
    if not rects:
        print(f"WARN: в {json_path} нет фигур")
        sys.exit(0)

    canvas = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    print(f"Canvas: {W}x{H}")
    print(f"Rects:  {len(rects)} from {os.path.basename(json_path)}")

    found = 0
    for i, r in enumerate(rects, 1):
        crop_path = f"{base}_{args.prefix}_{i}.png"
        if not os.path.exists(crop_path):
            print(f"  SKIP rect {i}: crop not found ({os.path.basename(crop_path)})")
            continue
        crop = Image.open(crop_path).convert("RGBA")
        canvas.paste(crop, (r["x"], r["y"]), crop)
        print(f"  rect {i}: pasted {os.path.basename(crop_path)} at ({r['x']},{r['y']})")
        found += 1

    if found == 0:
        print("FATAL: ни один crop не найден. Запусти crop_rects.py сначала.")
        sys.exit(1)

    if args.tight:
        # Union bbox всех rect'ов
        bx0 = min(r["x"] for r in rects)
        by0 = min(r["y"] for r in rects)
        bx1 = max(r["x"] + r["w"] for r in rects)
        by1 = max(r["y"] + r["h"] for r in rects)
        bw, bh = bx1 - bx0, by1 - by0
        canvas = canvas.crop((bx0, by0, bx1, by1))
        offset_path = out_path + ".offset.json"
        with open(offset_path, "w", encoding="utf-8") as f:
            json.dump({
                "x": bx0, "y": by0, "w": bw, "h": bh,
                "source_size": [W, H],
            }, f, indent=2)
        print(f"Tight: bbox ({bx0},{by0},{bw},{bh}) of source {W}x{H}")
        print(f"Offset saved: {offset_path}")

    canvas.save(out_path, "PNG", optimize=True)
    print(f"Saved: {out_path}  ({canvas.size[0]}x{canvas.size[1]}, "
          f"{os.path.getsize(out_path)//1024} KB)")


if __name__ == "__main__":
    main()
