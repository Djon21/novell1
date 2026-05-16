"""
remove_background.py — убирает фон с портретов / персонажей.

Два режима:
  rembg   — нейросеть `isnet-anime` (rembg) + alpha matting. Работает на любом
            фоне (magenta, сцена, что угодно). Лучшее качество, чистые края.
            Требует: pip install "rembg[cpu]"
  chroma  — старый pipeline: chroma-key (по auto-detect bg-цвету) + despill
            + fringe-fix. Работает только на однородном фоне (magenta).
            Не требует доп. зависимостей.
  auto    — пробует rembg, fallback на chroma если rembg не доступен.

Для каждой PNG в папке:
  1) Применяет выбранный режим
  2) Сохраняет как <basename>_nobg.png рядом с исходником
     Исходник НЕ трогается.

Зависимости:
  - chroma mode: pillow numpy (всегда)
  - rembg mode: pip install "rembg[cpu]"  (модель ~176MB качается при первом запуске)

Usage:
    python tools/remove_background.py <folder> [--mode auto|rembg|chroma]

Examples:
    python tools/remove_background.py tools/port_p/raw_a1
        → auto (rembg если есть, иначе chroma)

    python tools/remove_background.py tools/port_p/scene_chars --mode rembg
        → форсировать rembg

    python tools/remove_background.py tools/port_p/old --mode chroma --tolerance 80
        → старый chroma-key pipeline
"""
import argparse
import os
import sys
import numpy as np
from PIL import Image

# Для chroma-режима используем функции из основного скрипта
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from extract_portrait_overlays import chroma_key, despill_edges


def detect_bg_color(img):
    """Медиана пикселей из 8 точек по краям картинки."""
    arr = np.array(img.convert("RGB"))
    h, w = arr.shape[:2]
    pts = [
        (0, 0), (0, w // 2), (0, w - 1),
        (h // 2, 0), (h // 2, w - 1),
        (h - 1, 0), (h - 1, w // 2), (h - 1, w - 1),
    ]
    samples = np.array([arr[y, x] for y, x in pts])
    return tuple(int(c) for c in np.median(samples, axis=0))


# --- rembg ---
#
# Поддерживаемые модели (выбор через --model):
#   isnet-anime      — 176MB, быстро. Для anime-портретов на простом фоне.
#   birefnet-general — 973MB, медленнее. Лучше для сложных сцен и реалистичных
#                      деталей (волосы на фоне листвы и т.п.).
#   birefnet-portrait — 973MB. Альтернатива general, заточена под людей.
#
# По умолчанию birefnet-general — он надёжно работает и на портретах и на
# сценах. Если нужна скорость / меньше памяти — переключи на isnet-anime.

_rembg_sessions = {}


def _get_rembg_session(model_name):
    """Lazy-init rembg session. Cache per model. Возвращает None если rembg не установлен."""
    if model_name in _rembg_sessions:
        return _rembg_sessions[model_name]
    try:
        from rembg import new_session
        sess = new_session(model_name)
        _rembg_sessions[model_name] = sess
        return sess
    except ImportError:
        return None


def remove_bg_rembg(img, model_name="birefnet-general", alpha_matting=False):
    """
    Через rembg + выбранную модель.
    alpha_matting=True даёт мягкие края (нужно только для isnet-anime;
    birefnet-* сам по себе выдаёт чистые края без матинга).
    """
    from rembg import remove
    session = _get_rembg_session(model_name)
    if alpha_matting:
        return remove(
            img.convert("RGBA"),
            session=session,
            alpha_matting=True,
            alpha_matting_foreground_threshold=240,
            alpha_matting_background_threshold=10,
            alpha_matting_erode_size=10,
        )
    return remove(img.convert("RGBA"), session=session)


# --- chroma-key (legacy fallback) ---

def remove_bg_chroma(img, tolerance, despill):
    """Старый pipeline: chroma key + despill + fringe-fix neutralization."""
    bg_rgb = detect_bg_color(img)
    out = chroma_key(img, bg_rgb, tolerance=tolerance, feather=1.5)
    if despill > 0:
        out = despill_edges(out, bg_rgb, strength=despill)

    # Финальный pass: нейтрализация остаточных bg-tinted пикселей в edge-зоне
    arr = np.array(out)
    rgb = arr[..., :3].astype(np.int16)
    alpha = arr[..., 3]
    bg_arr = np.array(bg_rgb, dtype=np.int16)
    dom = bg_arr > (bg_arr.min() + 30)
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
    return out, bg_rgb, int(fix_mask.sum())


# --- main ---

def main():
    p = argparse.ArgumentParser(description="Remove background from portraits")
    p.add_argument("folder", help="Folder with PNG sources")
    p.add_argument("--mode", choices=("auto", "rembg", "chroma"), default="auto",
                   help="auto (default): rembg если установлен, иначе chroma. "
                        "rembg: только нейросеть (требует pip install rembg). "
                        "chroma: только старый chroma-key pipeline.")
    p.add_argument("--model", default="birefnet-general",
                   choices=("birefnet-general", "birefnet-portrait", "isnet-anime"),
                   help="(rembg mode) модель: birefnet-general (default, 973MB, "
                        "лучшее качество для сложных сцен), "
                        "isnet-anime (176MB, быстрее, для anime-портретов).")
    p.add_argument("--alpha-matting", action="store_true",
                   help="(rembg mode) включить alpha matting для мягких краёв. "
                        "Полезно для isnet-anime; birefnet-* и без него чистые.")
    p.add_argument("--tolerance", type=int, default=60,
                   help="(chroma mode) допуск близости к bg-цвету. Default 60.")
    p.add_argument("--despill", type=float, default=0.7,
                   help="(chroma mode) сила edge-despill. Default 0.7.")
    args = p.parse_args()

    if not os.path.isdir(args.folder):
        print(f"FATAL: not a folder: {args.folder}")
        sys.exit(1)

    # Определить итоговый режим
    mode = args.mode
    if mode == "auto":
        if _get_rembg_session(args.model) is not None:
            mode = "rembg"
        else:
            mode = "chroma"
            print("[auto] rembg не установлен — fallback на chroma. "
                  "Поставь 'pip install rembg[cpu]' для лучшего качества.")
    elif mode == "rembg" and _get_rembg_session(args.model) is None:
        print("FATAL: --mode rembg, но пакет rembg не установлен. "
              "Запусти: pip install \"rembg[cpu]\"")
        sys.exit(1)

    print(f"Mode: {mode}" + (f", model={args.model}" if mode == "rembg" else ""))

    # Suffix'ы файлов которые мы НЕ хотим повторно обрабатывать
    # (это derivative-файлы от нашего же pipeline'а)
    SKIP_SUFFIXES = ("_nobg", "_eye", "_mouth", "_blink", "_overlay", "_crop")

    processed = 0
    for fname in sorted(os.listdir(args.folder)):
        if not fname.lower().endswith(".png"):
            continue
        name, _ = os.path.splitext(fname)
        # Skip any file that already looks like our derivative
        if any(s in name for s in SKIP_SUFFIXES):
            continue
        src = os.path.join(args.folder, fname)
        dst = os.path.join(args.folder, name + "_nobg.png")

        try:
            img = Image.open(src)
        except Exception as e:
            print(f"  SKIP {fname}: {e}")
            continue

        if mode == "rembg":
            out = remove_bg_rembg(img, model_name=args.model, alpha_matting=args.alpha_matting)
            transparent_pct = int((np.array(out)[..., 3] == 0).sum() * 100 / (out.size[0] * out.size[1]))
            out.save(dst, "PNG", optimize=True)
            print(f"  {fname}: rembg/{args.model}, transparent={transparent_pct}% "
                  f"-> {name}_nobg.png ({os.path.getsize(dst)//1024} KB)")
        else:
            out, bg_rgb, fixed = remove_bg_chroma(img, args.tolerance, args.despill)
            transparent_pct = int((np.array(out)[..., 3] == 0).sum() * 100 / (out.size[0] * out.size[1]))
            out.save(dst, "PNG", optimize=True)
            print(f"  {fname}: chroma bg={bg_rgb}, transparent={transparent_pct}%, "
                  f"fringe-fixed={fixed} -> {name}_nobg.png ({os.path.getsize(dst)//1024} KB)")
        processed += 1

    print(f"\nDone. {processed} file(s) processed in '{mode}' mode.")


if __name__ == "__main__":
    main()
