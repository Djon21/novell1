"""
remove_background.py — убирает однородный фон с портретов через chroma key.

Для каждой картинки в папке:
  1) Сэмплирует цвет фона из углов и краёв (медиана — устойчиво к
     случайным «выбросам», например если персонаж касается угла кадра)
  2) Применяет chroma_key (alpha=0 в зонах близких к фону)
  3) Применяет despill_edges (убирает кайму фон-цвета на антиалиасных границах)
  4) Сохраняет как <basename>_nobg.png рядом с исходником.
     Исходник НЕ трогается.

Зависимости: pillow numpy

Usage:
    python tools/remove_background.py <folder> [--tolerance 60]

Example:
    python tools/remove_background.py tools/port_p/raw_a1
        → 1_nobg.png, 2_nobg.png, ...

Auto-detect означает, что нам не важно какой именно magenta нейронка
нарисовала в этот раз — алгоритм найдёт реальный bg-цвет сам.
"""
import argparse
import os
import sys
import numpy as np
from PIL import Image

# Используем уже готовые функции из основного скрипта
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from extract_portrait_overlays import chroma_key, despill_edges


def detect_bg_color(img):
    """Медиана пикселей из 8 точек по краям картинки — устойчивая оценка фон-цвета."""
    arr = np.array(img.convert("RGB"))
    h, w = arr.shape[:2]
    # 8 точек: 4 угла + 4 середины краёв
    pts = [
        (0, 0), (0, w // 2), (0, w - 1),
        (h // 2, 0), (h // 2, w - 1),
        (h - 1, 0), (h - 1, w // 2), (h - 1, w - 1),
    ]
    samples = np.array([arr[y, x] for y, x in pts])
    return tuple(int(c) for c in np.median(samples, axis=0))


def main():
    p = argparse.ArgumentParser(description="Remove solid background from portraits")
    p.add_argument("folder", help="Folder with PNG sources")
    p.add_argument("--tolerance", type=int, default=60,
                   help="Допуск близости к bg-цвету (0–255, default 60). "
                        "Увеличить если по краям волос остаётся кайма.")
    p.add_argument("--despill", type=float, default=0.7,
                   help="Сила edge-despill (0=выкл, 1=полное подавление, "
                        "default 0.7).")
    args = p.parse_args()

    if not os.path.isdir(args.folder):
        print(f"FATAL: not a folder: {args.folder}")
        sys.exit(1)

    processed = 0
    for fname in sorted(os.listdir(args.folder)):
        if not fname.lower().endswith(".png"):
            continue
        # Пропускаем уже обработанные
        if fname.endswith("_nobg.png"):
            continue
        name, _ = os.path.splitext(fname)
        src = os.path.join(args.folder, fname)
        dst = os.path.join(args.folder, name + "_nobg.png")

        try:
            img = Image.open(src)
        except Exception as e:
            print(f"  SKIP {fname}: {e}")
            continue

        bg_rgb = detect_bg_color(img)
        out = chroma_key(img, bg_rgb, tolerance=args.tolerance, feather=1.5)
        if args.despill > 0:
            out = despill_edges(out, bg_rgb, strength=args.despill)

        # Финальный pass: для пикселей всё ещё magenta-tinted на полупрозрачной
        # границе — заменить на серый той же яркости. Гарантирует отсутствие
        # видимой цветной каймы. Не трогает solid-пиксели (alpha > 240) внутри
        # силуэта — там натуральные цвета должны остаться.
        arr = np.array(out)
        rgb = arr[..., :3].astype(np.int16)
        alpha = arr[..., 3]
        # bg-доминирующие каналы (для magenta = R и B)
        bg_arr = np.array(bg_rgb, dtype=np.int16)
        bg_min_ch = bg_arr.min()
        dom = bg_arr > (bg_min_ch + 30)
        # score = насколько пиксель «утянут» в bg
        score = np.zeros(rgb.shape[:2], dtype=np.int16)
        non_dom_idx = [i for i in range(3) if not dom[i]]
        if non_dom_idx:
            other_max = np.maximum.reduce([rgb[..., i] for i in non_dom_idx])
            dom_idx = [i for i in range(3) if dom[i]]
            if dom_idx:
                dom_min = np.minimum.reduce([rgb[..., i] for i in dom_idx])
                score = np.maximum(0, dom_min - other_max)
        fix_mask = (score > 20) & (alpha > 0) & (alpha < 245)
        if fix_mask.any():
            lum = (0.3 * rgb[..., 0] + 0.59 * rgb[..., 1] + 0.11 * rgb[..., 2]).astype(np.int16)
            for c in range(3):
                rgb[..., c] = np.where(fix_mask, lum, rgb[..., c])
            arr[..., :3] = np.clip(rgb, 0, 255).astype(np.uint8)
            out = Image.fromarray(arr, "RGBA")
            print(f"    [fringe-fix] {int(fix_mask.sum())} pixels neutralized")

        out.save(dst, "PNG", optimize=True)

        # Sanity: сколько прозрачных пикселей получилось
        a = np.array(out)[..., 3]
        transparent_pct = (a == 0).sum() * 100 // a.size
        print(f"  {fname}: bg={bg_rgb}, transparent={transparent_pct}% "
              f"-> {name}_nobg.png ({os.path.getsize(dst)//1024} KB)")
        processed += 1

    print(f"\nDone. {processed} file(s) processed.")


if __name__ == "__main__":
    main()
