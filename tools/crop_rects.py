"""
crop_rects.py — режет фигуры из картинки по координатам из .rects.json
(созданного через mark_eyes.py) и сохраняет каждую как отдельный PNG.

Если фигура rect — сохраняется как есть (вся область внутри прямоугольника
непрозрачна). Если ellipse или circle — на crop накладывается соответствующая
альфа-маска, углы становятся прозрачными.

Опционально feather (gaussian blur маски) для мягких краёв.

Usage:
    python tools/crop_rects.py <image_path> [--prefix LABEL] [--rects PATH]
                                            [--feather N]

Examples:
    python tools/crop_rects.py tools/port_p/rawl/1.png --prefix mouth
    python tools/crop_rects.py tools/port_p/rawl/2.png --prefix mouth \\
        --rects tools/port_p/rawl/1.rects.json --feather 2
"""
import argparse
import json
import os
import sys
from PIL import Image, ImageDraw, ImageFilter
import numpy as np


def make_shape_mask(w, h, shape, feather=0.0):
    """Бинарная маска w x h по форме (rect/ellipse/circle), с опциональным feather."""
    mask = Image.new("L", (w, h), 0)
    draw = ImageDraw.Draw(mask)
    if shape in ("ellipse", "circle"):
        draw.ellipse([0, 0, w - 1, h - 1], fill=255)
    else:  # rect default
        draw.rectangle([0, 0, w - 1, h - 1], fill=255)
    if feather > 0:
        mask = mask.filter(ImageFilter.GaussianBlur(feather))
    return mask


def main():
    p = argparse.ArgumentParser(description="Crop rects/ellipses from image by .rects.json")
    p.add_argument("image", help="Path to source image")
    p.add_argument("--prefix", default="crop",
                   help="Output filename prefix (default: crop)")
    p.add_argument("--rects", default=None,
                   help="Path to .rects.json. По умолчанию ищет рядом с image. "
                        "Используй чтобы применить одну разметку к нескольким "
                        "картинкам с тем же ракурсом.")
    p.add_argument("--feather", type=float, default=0.0,
                   help="Gaussian blur маски в пикселях (default 0 = жёсткие "
                        "края). Для ellipse/circle обычно 1.5-3 даёт мягкий "
                        "край. На rect тоже работает.")
    args = p.parse_args()

    image_path = args.image
    base, _ = os.path.splitext(image_path)
    json_path = args.rects or (base + ".rects.json")

    if not os.path.exists(image_path):
        print(f"FATAL: image not found: {image_path}")
        sys.exit(1)
    if not os.path.exists(json_path):
        print(f"FATAL: rects file not found: {json_path}")
        print(f"       сначала запусти mark_eyes.py чтобы наметить фигуры")
        sys.exit(1)

    with open(json_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    img = Image.open(image_path).convert("RGBA")
    rects = data.get("rects", [])
    if not rects:
        print(f"WARN: в {json_path} нет фигур")
        sys.exit(0)

    print(f"Source:  {image_path}  ({img.size[0]}x{img.size[1]})")
    print(f"Rects:   {len(rects)} from {os.path.basename(json_path)}")
    print(f"Feather: {args.feather}")

    for i, r in enumerate(rects, 1):
        x, y, w, h = r["x"], r["y"], r["w"], r["h"]
        shape = r.get("shape", "rect")
        crop = img.crop((x, y, x + w, y + h))

        if shape != "rect" or args.feather > 0:
            mask = make_shape_mask(w, h, shape, feather=args.feather)
            arr = np.array(crop)
            arr[..., 3] = np.minimum(arr[..., 3], np.array(mask)).astype(np.uint8)
            crop = Image.fromarray(arr, "RGBA")

        dst = f"{base}_{args.prefix}_{i}.png"
        crop.save(dst, "PNG", optimize=True)
        print(f"  shape {i}: {shape} ({x},{y},{w},{h}) -> "
              f"{os.path.basename(dst)} ({crop.size[0]}x{crop.size[1]}, "
              f"{os.path.getsize(dst)//1024} KB)")


if __name__ == "__main__":
    main()
