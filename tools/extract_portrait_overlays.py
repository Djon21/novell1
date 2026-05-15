"""
extract_portrait_overlays.py

Извлекает прозрачные оверлеи из пар нейросетевых портретов для layered-анимации
(см. docs/guides/HOW_TO_ANIMATE_PORTRAITS.md).

Решает три типичные проблемы AI-генерации:
  1. Однородный фон вместо прозрачного → chroma key
  2. Сдвиг изображения между генерациями → phase correlation alignment
  3. Мусор в diff'е от мелких отличий (волосы, антиалиас) → morphological cleanup

Pipeline (single-pair mode):
  1) Открыть base и variant, привести к RGBA
  2) Chroma-key: убрать заданный фоновый цвет (default magenta FF00FF) → alpha
  3) Phase correlate: найти оптимальный сдвиг variant'а относительно base
  4) Сдвинуть variant
  5) Пиксельный diff в RGB, threshold, удалить мелкие изолированные blob'ы,
     dilate + feather на краях
  6) Применить маску как alpha к variant'у → прозрачный оверлей
  7) Сохранить base (transparent BG) и overlay

Зависимости: pillow numpy
    pip install pillow numpy

Базовый вызов:
    python extract_portrait_overlays.py \\
        --base    tools/port_p/raw/mila_open_magenta.png \\
        --variant tools/port_p/raw/mila_closed_magenta.png \\
        --out-base    main/images/portraits/mila/mila_base.png \\
        --out-overlay main/images/portraits/mila/mila_blink_2.png

Опции для подкрутки если результат не нравится:
    --bg-color FF00FF       — цвет фона для chroma key
    --bg-tolerance 50       — допуск близости к фон. цвету (0-255)
    --no-align              — пропустить phase correlation
    --diff-threshold 22     — порог отличия пикселей (0-255)
    --min-blob-px 80        — минимальный размер связного blob'а в diff-маске
    --dilate 2              — расширение маски в пикселях (спасает антиалиас)
    --feather 2.0           — сглаживание краёв маски (gaussian blur, px)
    --debug-dir tmp/        — сохранить промежуточные PNG для отладки

Если оверлей получается дырявый → уменьши diff-threshold или min-blob-px.
Если ловит лишнее (волосы, фон) → увеличь diff-threshold или min-blob-px,
                                   или увеличь bg-tolerance.
"""
import argparse
import os
import sys
import numpy as np
from PIL import Image, ImageFilter


def parse_hex_color(s):
    s = s.lstrip("#")
    if len(s) != 6:
        raise ValueError(f"--bg-color должен быть RRGGBB hex, получено: {s}")
    return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4))


def despill_edges(img, bg_rgb, strength=0.7, edge_width=4):
    """
    Убирает «кайму» фонового цвета ТОЛЬКО на антиалиасных краях после chroma
    key. Для magenta (#FF00FF) подавляет R и B каналы пропорционально их
    превышению над G в edge-зоне.

    Edge-зона определяется как: пиксели с alpha < 245 ИЛИ соседи (в радиусе
    edge_width) полупрозрачных пикселей. Solid pixels (внутренняя часть кожи
    /волос) не трогаются — их цвет считаем правильным.

    strength: 0.0 — disable, 1.0 — полное подавление превышения над min-каналом.
    edge_width: радиус «edge-зоны» от полупрозрачных пикселей внутрь.
    """
    arr = np.array(img.convert("RGBA")).astype(np.float32)
    rgb = arr[..., :3]
    alpha = arr[..., 3]
    bg = np.array(bg_rgb, dtype=np.float32)

    # Edge mask: alpha < 245 (semi-transparent) ИЛИ рядом с такими пикселями
    edge_seed = (alpha > 5) & (alpha < 245)
    edge_seed_img = Image.fromarray((edge_seed.astype(np.uint8) * 255), "L")
    if edge_width > 0:
        edge_seed_img = edge_seed_img.filter(
            ImageFilter.MaxFilter(edge_width * 2 + 1))
    edge_mask = np.array(edge_seed_img) > 127

    # Soft edge factor: внутри solid-зоны 0, на полупрозрачной границе ~1,
    # линейно по alpha. Бережёт цвет solid-пикселей (волосы и т.п.).
    edge_factor = np.where(
        edge_mask,
        np.clip((245.0 - alpha) / 245.0 + 0.3, 0.0, 1.0),
        0.0,
    )

    bg_min = bg.min()
    is_dominant = bg > (bg_min + 30)

    for c in range(3):
        if not is_dominant[c]:
            continue
        other_min = np.minimum.reduce(
            [rgb[..., k] for k in range(3) if k != c])
        excess = np.maximum(0, rgb[..., c] - other_min)
        rgb[..., c] = rgb[..., c] - excess * strength * edge_factor

    arr[..., :3] = np.clip(rgb, 0, 255)
    return Image.fromarray(arr.astype(np.uint8), "RGBA")


def chroma_key(img, bg_rgb, tolerance=50, feather=1.5):
    """
    Делает фон прозрачным. Пиксели близкие к bg_rgb → alpha=0,
    далёкие → alpha=255, плавный переход на границе.
    """
    img = img.convert("RGBA")
    arr = np.array(img)
    # float32 чтобы не было overflow и NaN при возведении в квадрат
    rgb = arr[..., :3].astype(np.float32)
    bg = np.array(bg_rgb, dtype=np.float32)
    dist = np.sqrt(((rgb - bg) ** 2).sum(axis=-1))
    # Soft cutoff: full transparency ниже tolerance, full opacity выше 2*tolerance
    lo = float(tolerance)
    hi = float(tolerance) * 2.0
    alpha = np.clip((dist - lo) / max(hi - lo, 1.0) * 255.0, 0, 255).astype(np.uint8)
    arr[..., 3] = alpha
    out = Image.fromarray(arr, "RGBA")
    if feather > 0:
        a = Image.fromarray(arr[..., 3], "L").filter(ImageFilter.GaussianBlur(feather))
        arr2 = np.array(out)
        arr2[..., 3] = np.array(a)
        out = Image.fromarray(arr2, "RGBA")
    return out


def luminance_masked(img):
    """Y-канал, занулённый по alpha (transparent → 0)."""
    arr = np.array(img.convert("RGBA")).astype(np.float32)
    y = 0.299 * arr[..., 0] + 0.587 * arr[..., 1] + 0.114 * arr[..., 2]
    a = arr[..., 3] / 255.0
    return y * a


def phase_correlate(a, b):
    """
    Найти смещение (dx, dy) которое максимизирует совпадение b → a.
    Использует Фурье phase correlation, классическое решение для translation.
    Возвращает целочисленные пиксельные смещения.
    """
    a = a - a.mean()
    b = b - b.mean()
    # Hann window — уменьшает edge effects при FFT
    h, w = a.shape
    win_y = 0.5 - 0.5 * np.cos(2 * np.pi * np.arange(h) / max(h - 1, 1))
    win_x = 0.5 - 0.5 * np.cos(2 * np.pi * np.arange(w) / max(w - 1, 1))
    win = np.outer(win_y, win_x)
    A = np.fft.fft2(a * win)
    B = np.fft.fft2(b * win)
    R = A * np.conj(B)
    mag = np.abs(R)
    R = R / (mag + 1e-9)
    r = np.fft.ifft2(R).real
    py, px = np.unravel_index(np.argmax(r), r.shape)
    dy = py if py < h // 2 else py - h
    dx = px if px < w // 2 else px - w
    return int(dx), int(dy)


def shift_image(img, dx, dy):
    """Сдвинуть изображение на (dx, dy). Новые области → прозрачные."""
    canvas = Image.new("RGBA", img.size, (0, 0, 0, 0))
    canvas.paste(img, (int(round(dx)), int(round(dy))), img)
    return canvas


def shift_image_subpixel(img, dx, dy):
    """
    Сдвиг с sub-pixel точностью через PIL affine transform с bilinear filtering.
    Используется когда phase correlation дала дробное смещение.
    """
    if abs(dx - round(dx)) < 0.01 and abs(dy - round(dy)) < 0.01:
        return shift_image(img, dx, dy)
    # Affine: identity + translation
    out = img.transform(
        img.size,
        Image.AFFINE,
        (1, 0, -dx, 0, 1, -dy),
        resample=Image.BILINEAR,
        fillcolor=(0, 0, 0, 0),
    )
    return out


def refine_subpixel(base_lum, var_lum, dx0, dy0, search_radius=1.0, step=0.25,
                    align_mask=None):
    """
    После целочисленного phase correlation: локальный поиск лучшего sub-pixel
    смещения. Метрика — sum of squared differences (SSD) в окне ±radius
    с шагом step. Возвращает (dx, dy) с дробной частью.

    align_mask: если задан, SSD считается только по пикселям где маска True.
    Полезно чтобы исключить область фактических отличий (глаза) из метрики.
    """
    h, w = base_lum.shape
    best_dx, best_dy = float(dx0), float(dy0)
    best_ssd = None

    candidates = []
    n_steps = int(round(search_radius / step))
    for iy in range(-n_steps, n_steps + 1):
        for ix in range(-n_steps, n_steps + 1):
            candidates.append((dx0 + ix * step, dy0 + iy * step))

    for dx, dy in candidates:
        # Сдвигаем variant и считаем SSD
        v_shifted = subpixel_shift_array(var_lum, dx, dy)
        diff = (base_lum - v_shifted) ** 2
        if align_mask is not None:
            ssd = float(diff[align_mask].sum())
        else:
            # Игнорируем нулевые края (там transparent после сдвига)
            valid = v_shifted > 0
            ssd = float(diff[valid].sum() / max(valid.sum(), 1))
        if best_ssd is None or ssd < best_ssd:
            best_ssd = ssd
            best_dx, best_dy = dx, dy

    return best_dx, best_dy


def subpixel_shift_array(arr, dx, dy):
    """Bilinear sub-pixel shift для 2D numpy float array."""
    if abs(dx - round(dx)) < 0.01 and abs(dy - round(dy)) < 0.01:
        return np.roll(np.roll(arr, int(round(dy)), axis=0),
                       int(round(dx)), axis=1)
    h, w = arr.shape
    # Координаты исходных пикселей для каждого выходного пикселя
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    src_x = xx - dx
    src_y = yy - dy
    # Bilinear sampling
    x0 = np.floor(src_x).astype(np.int32)
    y0 = np.floor(src_y).astype(np.int32)
    x1 = x0 + 1
    y1 = y0 + 1
    fx = src_x - x0
    fy = src_y - y0
    x0c = np.clip(x0, 0, w - 1); x1c = np.clip(x1, 0, w - 1)
    y0c = np.clip(y0, 0, h - 1); y1c = np.clip(y1, 0, h - 1)
    out = (
        arr[y0c, x0c] * (1 - fx) * (1 - fy) +
        arr[y0c, x1c] * fx * (1 - fy) +
        arr[y1c, x0c] * (1 - fx) * fy +
        arr[y1c, x1c] * fx * fy
    )
    # Обнулить пиксели, чьи source-координаты вышли за пределы
    valid = (src_x >= 0) & (src_x <= w - 1) & (src_y >= 0) & (src_y <= h - 1)
    out = np.where(valid, out, 0.0)
    return out


def parse_roi(s):
    """Парсит 'x,y,w,h' в (x, y, w, h) или None."""
    if not s:
        return None
    parts = [int(p.strip()) for p in s.split(",")]
    if len(parts) != 4:
        raise ValueError(f"--roi должно быть x,y,w,h, получено: {s}")
    return tuple(parts)


def auto_detect_roi(base, var_aligned, threshold=22, padding=15,
                    top_n=2, min_blob_px=500, erode_radius=4):
    """
    Найти ROI автоматически по диффу после alignment'а.
    Алгоритм: |delta| > threshold → маска → эрозия (убивает тонкие fringes
    от chroma key) → connected components → взять top_n крупнейших → bbox.

    top_n=2 для пары глаз, top_n=1 для рта.
    erode_radius=4 убивает blob'ы тоньше 8px (волосы, антиалиас) но оставляет
    компактные feature changes (глаза, рот).

    Возвращает (x, y, w, h) или None.
    """
    ba = np.array(base.convert("RGBA"))
    va = np.array(var_aligned.convert("RGBA"))
    delta = np.abs(ba[..., :3].astype(np.int16) - va[..., :3].astype(np.int16)).max(axis=-1)
    valid = (ba[..., 3] > 20) & (va[..., 3] > 20)
    diff = (delta > threshold) & valid

    # Эрозия: тонкие fringes от chroma key умирают, плотные blob'ы (eyes, mouth)
    # остаются. Делаем через MinFilter (erosion) на бинарной маске.
    if erode_radius > 0:
        diff_img = Image.fromarray((diff.astype(np.uint8) * 255), "L")
        diff_img = diff_img.filter(ImageFilter.MinFilter(erode_radius * 2 + 1))
        diff = np.array(diff_img) > 127

    blobs = find_blobs(diff)
    big = [(s, p) for s, p in blobs[:top_n] if s >= min_blob_px]
    if not big:
        return None

    ys_all, xs_all = [], []
    for _, pixels in big:
        for y, x in pixels:
            ys_all.append(y)
            xs_all.append(x)

    h, w = diff.shape
    y_min = max(0, min(ys_all) - padding)
    x_min = max(0, min(xs_all) - padding)
    y_max = min(h - 1, max(ys_all) + padding)
    x_max = min(w - 1, max(xs_all) + padding)

    # Sanity check: bounding box не должен быть пол-картинки
    bb_area = (y_max - y_min) * (x_max - x_min)
    img_area = h * w
    if bb_area > img_area * 0.4:
        print(f"  [auto-roi] bounding box подозрительно большой "
              f"({bb_area*100//img_area}% площади). Скорее всего alignment "
              f"плохой или top-n слишком велик. Возвращаю None.")
        return None

    return (int(x_min), int(y_min), int(x_max - x_min), int(y_max - y_min))


def match_colors_at_roi_edge(base, var_aligned, roi, ring_thickness=12):
    """
    Сэмплируем кольцо вокруг ROI в base и variant, считаем mean RGB delta,
    сдвигаем все пиксели variant'а так чтобы скинтон совпал с base.
    """
    ba = np.array(base.convert("RGBA")).astype(np.float32)
    va = np.array(var_aligned.convert("RGBA")).astype(np.float32)

    x, y, w, h = roi
    H, W = ba.shape[:2]
    ring = np.zeros((H, W), dtype=bool)
    y0 = max(0, y - ring_thickness)
    x0 = max(0, x - ring_thickness)
    y1 = min(H, y + h + ring_thickness)
    x1 = min(W, x + w + ring_thickness)
    ring[y0:y1, x0:x1] = True
    # Вычитаем внутренний прямоугольник = остаётся только кольцо
    ring[max(0, y):min(H, y + h), max(0, x):min(W, x + w)] = False

    valid = ring & (ba[..., 3] > 100) & (va[..., 3] > 100)
    n = int(valid.sum())
    if n < 50:
        print(f"  [match-color] кольцо слишком пустое ({n} пикс), пропуск")
        return var_aligned

    base_mean = ba[..., :3][valid].mean(axis=0)
    var_mean = va[..., :3][valid].mean(axis=0)
    delta = base_mean - var_mean
    print(f"  [match-color] sampled {n}px, delta RGB = "
          f"({delta[0]:+.1f}, {delta[1]:+.1f}, {delta[2]:+.1f})")

    out = va.copy()
    out[..., :3] = np.clip(out[..., :3] + delta, 0, 255)
    return Image.fromarray(out.astype(np.uint8), "RGBA")


def sample_skin_color(img, roi, ring_thickness=12):
    """
    Mean RGB цвет в кольце вокруг ROI (предположительно скин-зона).
    Возвращает np.array([R,G,B]) или None если мало sample'ов.
    """
    arr = np.array(img.convert("RGBA")).astype(np.float32)
    H, W = arr.shape[:2]
    x, y, w, h = roi
    ring = np.zeros((H, W), dtype=bool)
    y0 = max(0, y - ring_thickness); x0 = max(0, x - ring_thickness)
    y1 = min(H, y + h + ring_thickness); x1 = min(W, x + w + ring_thickness)
    ring[y0:y1, x0:x1] = True
    ring[max(0, y):min(H, y + h), max(0, x):min(W, x + w)] = False
    valid = ring & (arr[..., 3] > 100)
    if valid.sum() < 50:
        return None
    return arr[..., :3][valid].mean(axis=0)


def make_facial_mask(img, roi, skin_color, tolerance=55, dark_thresh=70):
    """
    Маска пикселей, похожих на «лицо»: либо близкие к скин-цвету, либо очень
    тёмные (ресницы, зрачки). Волосы (коричневые, средне-тёмные) НЕ проходят.

    Возвращает Image L (0/255) того же размера что img.
    """
    arr = np.array(img.convert("RGBA")).astype(np.float32)
    rgb = arr[..., :3]
    alpha = arr[..., 3]
    skin_dist = np.sqrt(((rgb - skin_color) ** 2).sum(axis=-1))
    luminance = 0.299 * rgb[..., 0] + 0.587 * rgb[..., 1] + 0.114 * rgb[..., 2]
    is_skin = skin_dist < tolerance
    is_dark = luminance < dark_thresh
    is_opaque = alpha > 100
    facial = (is_skin | is_dark) & is_opaque
    return Image.fromarray((facial.astype(np.uint8) * 255), "L")


def make_paste_mask(size, roi, shape="rect", feather=8.0):
    """
    Маска для roi-paste режима: 255 внутри ROI, 0 снаружи, feather на границе.
    shape='rect' — прямоугольник, shape='ellipse' — эллипс вписанный в roi.
    """
    from PIL import ImageDraw
    w_img, h_img = size
    mask = Image.new("L", (w_img, h_img), 0)
    draw = ImageDraw.Draw(mask)
    x, y, w, h = roi
    if shape == "ellipse":
        draw.ellipse([x, y, x + w, y + h], fill=255)
    else:
        draw.rectangle([x, y, x + w, y + h], fill=255)
    if feather > 0:
        mask = mask.filter(ImageFilter.GaussianBlur(feather))
    return mask


def find_blobs(mask_arr):
    """
    Найти все связные области (4-connected) в булевой маске.
    Возвращает list of (size, pixels), отсортированный по убыванию размера.
    """
    h, w = mask_arr.shape
    visited = np.zeros_like(mask_arr, dtype=bool)
    blobs = []

    for sy in range(h):
        for sx in range(w):
            if mask_arr[sy, sx] and not visited[sy, sx]:
                stack = [(sy, sx)]
                pixels = []
                while stack:
                    y, x = stack.pop()
                    if y < 0 or y >= h or x < 0 or x >= w:
                        continue
                    if visited[y, x] or not mask_arr[y, x]:
                        continue
                    visited[y, x] = True
                    pixels.append((y, x))
                    stack.extend([(y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)])
                blobs.append((len(pixels), pixels))

    blobs.sort(key=lambda b: -b[0])
    return blobs


def keep_top_blobs(mask_arr, n):
    """Оставить N самых больших связных областей."""
    blobs = find_blobs(mask_arr)
    out = np.zeros_like(mask_arr, dtype=bool)
    for size, pixels in blobs[:n]:
        ys, xs = zip(*pixels)
        out[list(ys), list(xs)] = True
    return out


def make_overlay(base, var, threshold=22, dilate=2, feather=2.0, min_blob_px=80,
                 roi=None, keep_top_blobs_n=0):
    """
    Создать прозрачный оверлей: alpha=255 только где var отличается от base.
    Пайплайн: pixel diff → threshold → mask по ROI → cleanup blob'ов → dilate → feather.

    roi: (x, y, w, h) — если задан, diff ограничивается этим прямоугольником.
    largest_blob_only: если True, оставляется только самая большая связная область.
    """
    ba = np.array(base.convert("RGBA"))
    va = np.array(var.convert("RGBA"))
    bb = ba[..., :3].astype(np.int16)
    vv = va[..., :3].astype(np.int16)

    # Per-pixel максимум отличий по каналам
    delta = np.abs(bb - vv).max(axis=-1)

    # Игнорируем прозрачные пиксели
    valid = (ba[..., 3] > 20) & (va[..., 3] > 20)
    mask = (delta > threshold) & valid

    # ROI: обнуляем всё снаружи прямоугольника
    if roi is not None:
        x, y, w, h = roi
        roi_mask = np.zeros_like(mask, dtype=bool)
        y2 = min(y + h, mask.shape[0])
        x2 = min(x + w, mask.shape[1])
        roi_mask[max(0, y):y2, max(0, x):x2] = True
        mask = mask & roi_mask

    # Уборка мелких изолированных пятен через morphological opening
    erode_radius = max(1, int(np.sqrt(max(min_blob_px, 1)) / 2))
    mask_img = Image.fromarray((mask.astype(np.uint8) * 255), "L")
    if min_blob_px > 0:
        mask_img = mask_img.filter(ImageFilter.MinFilter(erode_radius * 2 + 1))
        mask_img = mask_img.filter(ImageFilter.MaxFilter(erode_radius * 2 + 1))

    # Keep top-N blobs ДО dilate: считаем связные области на чистой маске
    # (без раздутия dilate). N=2 идеально для пары глаз, N=1 — для рта.
    if keep_top_blobs_n > 0:
        m_bool = np.array(mask_img) > 127
        m_bool = keep_top_blobs(m_bool, keep_top_blobs_n)
        mask_img = Image.fromarray((m_bool.astype(np.uint8) * 255), "L")

    # Dilate — расширяет маску, спасает antialias
    if dilate > 0:
        mask_img = mask_img.filter(ImageFilter.MaxFilter(dilate * 2 + 1))

    # Сглаживание границы
    if feather > 0:
        mask_img = mask_img.filter(ImageFilter.GaussianBlur(feather))

    # Финальный alpha = min(mask, original_variant_alpha)
    final_alpha = np.minimum(
        np.array(mask_img),
        np.array(var.convert("RGBA"))[..., 3]
    ).astype(np.uint8)
    out_arr = np.array(var.copy())
    out_arr[..., 3] = final_alpha
    return Image.fromarray(out_arr, "RGBA")


def save_debug(img, path):
    if path:
        img.save(path, "PNG")
        print(f"  [debug] {path}")


def main():
    p = argparse.ArgumentParser(
        description="Извлекает прозрачный оверлей из пары AI-портретов")
    p.add_argument("--base", required=True, help="Path to base portrait")
    p.add_argument("--variant", required=True, help="Path to variant portrait")
    p.add_argument("--out-base", required=True,
                   help="Output base (transparent BG)")
    p.add_argument("--out-overlay", required=True,
                   help="Output overlay (transparent except diff region)")
    p.add_argument("--bg-color", default="FF00FF",
                   help="Background color to chroma-key (default magenta)")
    p.add_argument("--bg-tolerance", type=int, default=50,
                   help="Tolerance for chroma key, 0-255 (default 50)")
    p.add_argument("--no-align", action="store_true",
                   help="Skip phase correlation alignment")
    p.add_argument("--diff-threshold", type=int, default=22,
                   help="Pixel diff threshold 0-255 (default 22)")
    p.add_argument("--min-blob-px", type=int, default=80,
                   help="Remove diff blobs smaller than this (default 80)")
    p.add_argument("--dilate", type=int, default=2,
                   help="Dilate mask by N px (default 2)")
    p.add_argument("--feather", type=float, default=2.0,
                   help="Gaussian blur mask edges (default 2.0)")
    p.add_argument("--roi", default=None,
                   help="x,y,w,h: ограничить diff этим прямоугольником "
                        "(rectangle вокруг глаз или рта). Без него — diff "
                        "на всю площадь портрета, ловит много мусора.")
    p.add_argument("--keep-top-blobs", type=int, default=0,
                   help="Оставить N самых больших связных областей после "
                        "threshold. 2 для пары глаз, 1 для рта, 0=не фильтровать.")
    p.add_argument("--subpixel", action="store_true",
                   help="Уточнить alignment с sub-pixel точностью "
                        "(локальный SSD-поиск ±1px с шагом 0.25). Заметно "
                        "чище края оверлея.")
    p.add_argument("--mode", choices=("diff", "roi-paste"), default="diff",
                   help="diff (default): маска по пиксельной разнице. "
                        "roi-paste: брать variant внутри ROI с feathered "
                        "краями, без diff'а. roi-paste чище визуально если "
                        "alignment хороший, но overlay тяжелее (всё ROI).")
    p.add_argument("--auto-roi", action="store_true",
                   help="Найти ROI автоматически по диффу после alignment'а. "
                        "Не нужно открывать редактор и измерять координаты "
                        "вручную. Перебивает --roi если задан.")
    p.add_argument("--auto-roi-top-n", type=int, default=2,
                   help="Сколько крупнейших blob'ов учитывать для auto-roi "
                        "(2 для пары глаз, 1 для рта). По умолчанию 2.")
    p.add_argument("--auto-roi-min-blob-px", type=int, default=500,
                   help="Минимальный размер blob'а для auto-roi (default 500). "
                        "Поднять если ловит лишнее, опустить если не находит.")
    p.add_argument("--roi-shape", choices=("rect", "ellipse"), default="rect",
                   help="Форма маски в roi-paste mode. ellipse лучше "
                        "повторяет форму глаз/рта чем прямоугольник.")
    p.add_argument("--match-color", action="store_true",
                   help="Выровнять скинтон variant'а под base. Сэмплирует "
                        "кольцо вокруг ROI, считает RGB-delta, сдвигает "
                        "variant. Лечит 'патч' от разного освещения генераций.")
    p.add_argument("--despill", type=float, default=0.7,
                   help="Edge despill: уменьшает кайму фонового цвета на "
                        "антиалиасных краях. 0.0 = выкл, 1.0 = полное "
                        "подавление, 0.7 = баланс (default).")
    p.add_argument("--exclude-hair", action="store_true",
                   help="В roi-paste mode: фильтровать non-facial пиксели "
                        "variant'а (волосы) по цвету. Лечит ситуацию когда "
                        "вариант имеет прядь волос над глазом в другом "
                        "положении чем base.")
    p.add_argument("--facial-tolerance", type=int, default=55,
                   help="Допуск skin-color distance в facial mask (default 55). "
                        "Поднять если ресницы/детали глаза теряются.")
    p.add_argument("--output-size", type=int, default=None,
                   help="Уменьшить выходные PNG до квадрата NxN (default: as-is)")
    p.add_argument("--debug-dir", default=None,
                   help="Save intermediate PNGs here for debugging")
    args = p.parse_args()

    bg_rgb = parse_hex_color(args.bg_color)
    os.makedirs(os.path.dirname(args.out_base) or ".", exist_ok=True)
    os.makedirs(os.path.dirname(args.out_overlay) or ".", exist_ok=True)
    if args.debug_dir:
        os.makedirs(args.debug_dir, exist_ok=True)

    print(f"Base:    {args.base}")
    print(f"Variant: {args.variant}")
    print(f"Chroma key bg: #{args.bg_color} ±{args.bg_tolerance}")

    # 1) Загрузка + chroma key
    base_raw = Image.open(args.base)
    var_raw = Image.open(args.variant)
    if base_raw.size != var_raw.size:
        print(f"WARN: размеры различаются {base_raw.size} vs {var_raw.size}. "
              "Подгоняю variant под base.")
        var_raw = var_raw.resize(base_raw.size, Image.LANCZOS)

    base = chroma_key(base_raw, bg_rgb, tolerance=args.bg_tolerance)
    var = chroma_key(var_raw, bg_rgb, tolerance=args.bg_tolerance)

    # Edge despill: подавляем кайму фонового цвета на антиалиасных границах.
    if args.despill > 0:
        base = despill_edges(base, bg_rgb, strength=args.despill)
        var = despill_edges(var, bg_rgb, strength=args.despill)
        print(f"Despill: strength {args.despill}")

    if args.debug_dir:
        save_debug(base, os.path.join(args.debug_dir, "01_base_keyed.png"))
        save_debug(var, os.path.join(args.debug_dir, "02_variant_keyed.png"))

    # 2) Alignment через phase correlation (целочисленное)
    if args.no_align:
        print("Alignment: пропущен (--no-align)")
        var_aligned = var
        align_dx, align_dy = 0.0, 0.0
    else:
        lum_a = luminance_masked(base)
        lum_b = luminance_masked(var)
        dx, dy = phase_correlate(lum_a, lum_b)
        print(f"Alignment: coarse shift dx={dx}, dy={dy}")
        # 2a) Sub-pixel refinement: SSD-поиск в окне ±1px с шагом 0.25.
        # Маска для SSD: исключаем ROI (там фактические отличия будут портить
        # метрику) и исключаем фон (там transparent после chroma key).
        if args.subpixel:
            roi_box = parse_roi(args.roi)
            valid_mask = (lum_a > 0) & (lum_b > 0)
            if roi_box is not None:
                x, y, w, h = roi_box
                valid_mask[max(0, y):min(y + h, valid_mask.shape[0]),
                           max(0, x):min(x + w, valid_mask.shape[1])] = False
            fdx, fdy = refine_subpixel(lum_a, lum_b, dx, dy,
                                       search_radius=1.0, step=0.25,
                                       align_mask=valid_mask)
            print(f"Alignment: refined dx={fdx:.2f}, dy={fdy:.2f}")
            var_aligned = shift_image_subpixel(var, fdx, fdy)
            align_dx, align_dy = fdx, fdy
        else:
            var_aligned = shift_image(var, dx, dy)
            align_dx, align_dy = float(dx), float(dy)
        if args.debug_dir:
            save_debug(var_aligned,
                       os.path.join(args.debug_dir, "03_variant_aligned.png"))

    # 3) ROI: ручная или автоматическая
    roi = parse_roi(args.roi)
    if args.auto_roi:
        auto_roi = auto_detect_roi(base, var_aligned,
                                   threshold=args.diff_threshold,
                                   padding=15,
                                   top_n=args.auto_roi_top_n,
                                   min_blob_px=args.auto_roi_min_blob_px)
        if auto_roi:
            roi = auto_roi
            print(f"Auto-ROI: x={roi[0]} y={roi[1]} w={roi[2]} h={roi[3]}")
        else:
            print("WARN: --auto-roi не нашёл значимых отличий. Использую --roi "
                  "если задан, иначе full image.")
    if roi and not args.auto_roi:
        print(f"ROI: x={roi[0]} y={roi[1]} w={roi[2]} h={roi[3]}")
    print(f"Mode: {args.mode}")

    # 4) Match color (опционально): сдвигаем скинтон variant под base
    if args.match_color:
        if roi is None:
            print("WARN: --match-color требует ROI, пропуск")
        else:
            var_aligned = match_colors_at_roi_edge(base, var_aligned, roi)

    # 5) Overlay
    if args.mode == "roi-paste":
        if roi is None:
            print("FATAL: --mode roi-paste требует --roi или --auto-roi")
            sys.exit(1)
        mask_img = make_paste_mask(var_aligned.size, roi,
                                   shape=args.roi_shape,
                                   feather=args.feather)
        mask_arr = np.array(mask_img).astype(np.float32)

        # --exclude-hair: умножаем paste-alpha на facial-маску ВАРИАНТА.
        # Hair-пиксели в variant'е (волосы средне-тёмные коричневые, не близкие
        # к скину и не очень тёмные) получают 0 → variant'ова прядь не пастится
        # → base проступает в этом месте.
        #
        # ВАЖНО: НЕ умножаем на base_facial — в base в области глаз есть
        # склера/радужка/зрачок которые тоже non-facial, AND с базой фильтровал
        # бы как раз ту область которую мы хотим заблинкать.
        if args.exclude_hair:
            skin = sample_skin_color(base, roi)
            if skin is None:
                print("  [exclude-hair] не удалось сэмплировать skin-color, "
                      "пропуск")
            else:
                print(f"  [exclude-hair] skin RGB ~ "
                      f"({skin[0]:.0f}, {skin[1]:.0f}, {skin[2]:.0f})")
                var_facial = make_facial_mask(var_aligned, roi, skin,
                                              tolerance=args.facial_tolerance)
                # Smooth boundaries to avoid hard cuts at hair edges
                var_facial = var_facial.filter(ImageFilter.GaussianBlur(2.0))
                mask_arr = mask_arr * np.array(var_facial).astype(np.float32) / 255.0
                if args.debug_dir:
                    save_debug(var_facial,
                               os.path.join(args.debug_dir, "05_var_facial.png"))

        final_mask = np.clip(mask_arr, 0, 255).astype(np.uint8)
        out_arr = np.array(var_aligned)
        out_arr[..., 3] = np.minimum(
            final_mask,
            np.array(var_aligned)[..., 3]
        ).astype(np.uint8)
        overlay = Image.fromarray(out_arr, "RGBA")
    else:
        overlay = make_overlay(
            base, var_aligned,
            threshold=args.diff_threshold,
            dilate=args.dilate,
            feather=args.feather,
            min_blob_px=args.min_blob_px,
            roi=roi,
            keep_top_blobs_n=args.keep_top_blobs,
        )

    # 4) Downscale если запрошен output-size
    if args.output_size:
        size = (args.output_size, args.output_size)
        base = base.resize(size, Image.LANCZOS)
        overlay = overlay.resize(size, Image.LANCZOS)
        print(f"Resized to {size}")

    # 5) Save
    base.save(args.out_base, "PNG", optimize=True)
    overlay.save(args.out_overlay, "PNG", optimize=True)

    base_kb = os.path.getsize(args.out_base) // 1024
    overlay_kb = os.path.getsize(args.out_overlay) // 1024
    print(f"\nSaved:")
    print(f"  {args.out_base}     ({base_kb} KB)")
    print(f"  {args.out_overlay}  ({overlay_kb} KB)")

    # Stats: сколько непрозрачных пикселей в overlay (sanity check)
    a = np.array(overlay)[..., 3]
    visible = int((a > 10).sum())
    total = a.size
    print(f"  Overlay visible pixels: {visible}/{total} ({visible*100//total}%)")
    if visible < 100:
        print("  [WARN] оверлей почти пустой. Попробуй уменьшить --diff-threshold "
              "или --min-blob-px.")
    elif visible > total * 0.3:
        print("  [WARN] оверлей покрывает >30% картинки. Видимо alignment не "
              "сработал. Попробуй --bg-tolerance побольше или сгенерируй пару "
              "с более стабильным base.")


if __name__ == "__main__":
    main()
