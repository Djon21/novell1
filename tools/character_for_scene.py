"""
character_for_scene.py — извлекает персонажа из сцены (через rembg/birefnet),
обрезает до tight bbox, ресайзит под игровое разрешение, сохраняет PNG + JSON
с координатами для размещения в Defold.

Pipeline:
  1) rembg/birefnet-general вырезает силуэт персонажа (любой фон → прозрачный)
  2) Находит bbox непрозрачных пикселей
  3) Crop до bbox
  4) Resize обоих размеров под --game-width (default 1280)
     Прозрачные поля вокруг убраны заранее, так что resize чистый.
  5) Сохраняет:
     - <name>.png — готовый sprite в игровом разрешении
     - <name>.scene.json — позиция и размер в game coords:
         { "x": 675, "y": 183, "w": 146, "h": 516,
           "game_size": [1280, 720],
           "source_size": [1672, 941] }

Usage:
    python tools/character_for_scene.py <input.png> <output_name>
                                         [--game-width 1280]
                                         [--out-dir DIR]
                                         [--model birefnet-general]

Example:
    python tools/character_for_scene.py tools/port_p/mila_park.png mila_park \\
        --out-dir main/images/scene_characters/park

    → main/images/scene_characters/park/mila_park.png
    → main/images/scene_characters/park/mila_park.scene.json

Координаты в JSON: pivot top-left (как в нейронке). Если в Defold у тебя
pivot SW (стандартный для box-нод), Y инвертируешь: defold_y = game_h - (y + h).
"""
import argparse
import json
import os
import sys
import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))


def extract_with_rembg(img, model_name="birefnet-general"):
    from rembg import new_session, remove
    session = new_session(model_name)
    return remove(img.convert("RGBA"), session=session)


def find_bbox(rgba_arr, alpha_threshold=5):
    """Bounding box непрозрачных пикселей."""
    alpha = rgba_arr[..., 3]
    ys, xs = np.where(alpha > alpha_threshold)
    if len(ys) == 0:
        return None
    return (int(xs.min()), int(ys.min()),
            int(xs.max() + 1), int(ys.max() + 1))


def main():
    p = argparse.ArgumentParser(
        description="Extract character from scene, resize to game space, "
                    "output sprite + JSON for Defold placement")
    p.add_argument("input", help="Source PNG (character on any background)")
    p.add_argument("name", help="Output base name (without extension)")
    p.add_argument("--out-dir", default=".", help="Output directory (default: cwd)")
    p.add_argument("--game-width", type=int, default=1280,
                   help="Game logical width (default 1280). Height computed from aspect.")
    p.add_argument("--model", default="birefnet-general",
                   help="rembg model (default birefnet-general)")
    args = p.parse_args()

    if not os.path.exists(args.input):
        print(f"FATAL: file not found: {args.input}")
        sys.exit(1)
    os.makedirs(args.out_dir, exist_ok=True)

    # 1) Load + extract
    print(f"Source: {args.input}")
    img = Image.open(args.input)
    src_w, src_h = img.size
    print(f"  size: {src_w}x{src_h}")

    print(f"Removing background ({args.model})...")
    cutout = extract_with_rembg(img, args.model)

    # 2) Bbox
    arr = np.array(cutout)
    bbox = find_bbox(arr)
    if bbox is None:
        print("FATAL: no character detected (fully transparent result)")
        sys.exit(1)
    x0, y0, x1, y1 = bbox
    bw, bh = x1 - x0, y1 - y0
    print(f"Bbox in source: ({x0},{y0}) size {bw}x{bh}")

    # 3) Crop
    cropped = cutout.crop((x0, y0, x1, y1))

    # 4) Game-space scale
    game_w = args.game_width
    game_h = int(round(src_h * game_w / src_w))  # preserve aspect
    scale = game_w / src_w

    gx = int(round(x0 * scale))
    gy = int(round(y0 * scale))
    gw = int(round(bw * scale))
    gh = int(round(bh * scale))
    print(f"Game-space ({game_w}x{game_h}): pos ({gx},{gy}) size {gw}x{gh}")

    # Resize cropped sprite to game scale
    sprite = cropped.resize((gw, gh), Image.LANCZOS)

    # 5) Save
    png_path = os.path.join(args.out_dir, args.name + ".png")
    json_path = os.path.join(args.out_dir, args.name + ".scene.json")

    sprite.save(png_path, "PNG", optimize=True)
    meta = {
        "x": gx, "y": gy, "w": gw, "h": gh,
        "game_size": [game_w, game_h],
        "source_size": [src_w, src_h],
        "source_bbox": [x0, y0, bw, bh],
        "note": "x/y/w/h в game coords с pivot top-left. Для Defold SW-pivot: y_sw = game_h - (y + h)",
    }
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(meta, f, indent=2, ensure_ascii=False)

    sprite_kb = os.path.getsize(png_path) // 1024
    print(f"\nSaved:")
    print(f"  {png_path}  ({gw}x{gh}, {sprite_kb} KB)")
    print(f"  {json_path}")


if __name__ == "__main__":
    main()
