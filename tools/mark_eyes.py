"""
mark_eyes.py — интерактивная разметка областей (глаза, рот, что угодно) для
overlay-pipeline'а. Поддерживает три формы: rect / ellipse / circle.

Открывает картинку, ты мышкой обводишь фигуры, программа сохраняет координаты
и форму в JSON рядом с картинкой. Дальше crop_rects.py режет по этой разметке.

Управление:
    ЛКМ-drag        — нарисовать (форма выбирается клавишами r/e/c)
    r               — режим прямоугольника (rect)
    e               — режим эллипса / овала (ellipse)
    c               — режим круга (circle, при drag'е форма квадрат)
    ПКМ по фигуре   — удалить эту фигуру
    Backspace / Del — удалить последнюю
    s               — сохранить в <image>.rects.json
    q / Esc         — выход без сохранения

Запуск:
    python tools/mark_eyes.py <path_to_image>

Формат JSON (поле "shape" опционально, default — "rect"):
    {
      "image": "2_nobg.png",
      "size": [width, height],
      "rects": [
        {"x": 203, "y": 175, "w": 50, "h": 35, "shape": "rect"},
        {"x": 283, "y": 175, "w": 35, "h": 32, "shape": "ellipse"}
      ]
    }
"""
import json
import os
import sys
import tkinter as tk
from PIL import Image, ImageTk


RECT_OUTLINE = "#00ff44"
DRAG_OUTLINE = "#ffff00"
OUTLINE_WIDTH = 2

SHAPES = ("rect", "ellipse", "circle")


class EyeMarker:
    def __init__(self, root, image_path):
        self.root = root
        self.image_path = image_path
        self.image = Image.open(image_path).convert("RGBA")
        self.img_w, self.img_h = self.image.size

        min_display = 800
        long_side = max(self.img_w, self.img_h)
        self.scale = max(1, min_display // long_side) if long_side < min_display else 1
        self.disp_w = self.img_w * self.scale
        self.disp_h = self.img_h * self.scale

        disp_img = self.image.resize((self.disp_w, self.disp_h), Image.NEAREST)
        bg = Image.new("RGBA", (self.disp_w, self.disp_h), (200, 200, 200, 255))
        bg.alpha_composite(disp_img)
        self.tk_image = ImageTk.PhotoImage(bg)

        self.canvas = tk.Canvas(root, width=self.disp_w, height=self.disp_h,
                                bg="#333")
        self.canvas.pack()
        self.canvas.create_image(0, 0, anchor="nw", image=self.tk_image)

        self.shapes = []         # list of dicts {x,y,w,h,shape}
        self.shape_ids = []      # list of canvas item ids
        self.current_shape = "rect"
        self.drag_start = None
        self.drag_item_id = None

        self.canvas.bind("<ButtonPress-1>", self.on_drag_start)
        self.canvas.bind("<B1-Motion>", self.on_drag_motion)
        self.canvas.bind("<ButtonRelease-1>", self.on_drag_end)
        self.canvas.bind("<Button-3>", self.on_right_click)
        root.bind("<KeyPress-r>", lambda e: self.set_shape("rect"))
        root.bind("<KeyPress-e>", lambda e: self.set_shape("ellipse"))
        root.bind("<KeyPress-c>", lambda e: self.set_shape("circle"))
        root.bind("<KeyPress-s>", self.on_save)
        root.bind("<KeyPress-q>", self.on_quit)
        root.bind("<Escape>", self.on_quit)
        root.bind("<BackSpace>", self.on_undo)
        root.bind("<Delete>", self.on_undo)

        self.status = tk.Label(root, text="", font=("Consolas", 10),
                               anchor="w", padx=8, pady=4)
        self.status.pack(fill="x")
        self.update_status()

        # Auto-load existing JSON
        self.json_path = os.path.splitext(image_path)[0] + ".rects.json"
        if os.path.exists(self.json_path):
            try:
                with open(self.json_path, "r", encoding="utf-8") as f:
                    data = json.load(f)
                for r in data.get("rects", []):
                    self.add_shape(r["x"], r["y"], r["w"], r["h"],
                                   r.get("shape", "rect"))
                self.update_status(f"Loaded {len(self.shapes)} shape(s) "
                                   f"from {os.path.basename(self.json_path)}")
            except Exception as e:
                print(f"Could not load existing rects: {e}")

    # --- coordinates ---

    def canvas_to_image(self, cx, cy):
        return cx // self.scale, cy // self.scale

    def image_to_canvas(self, ix, iy):
        return ix * self.scale, iy * self.scale

    # --- shape mode ---

    def set_shape(self, shape):
        if shape in SHAPES:
            self.current_shape = shape
            self.update_status(f"shape -> {shape}")

    # --- drawing ---

    def make_canvas_shape(self, cx0, cy0, cx1, cy1, shape, color):
        if shape == "rect":
            return self.canvas.create_rectangle(
                cx0, cy0, cx1, cy1, outline=color, width=OUTLINE_WIDTH)
        else:  # ellipse, circle (на canvas рисуется как oval)
            return self.canvas.create_oval(
                cx0, cy0, cx1, cy1, outline=color, width=OUTLINE_WIDTH)

    def on_drag_start(self, e):
        self.drag_start = (e.x, e.y)
        self.drag_item_id = self.make_canvas_shape(
            e.x, e.y, e.x, e.y, self.current_shape, DRAG_OUTLINE)

    def on_drag_motion(self, e):
        if not self.drag_start or not self.drag_item_id:
            return
        x0, y0 = self.drag_start
        x1, y1 = e.x, e.y
        if self.current_shape == "circle":
            # Зажимаем aspect: w = h = max(dx, dy), в направлении drag'а
            dx = abs(x1 - x0)
            dy = abs(y1 - y0)
            side = max(dx, dy)
            sx = 1 if x1 >= x0 else -1
            sy = 1 if y1 >= y0 else -1
            x1 = x0 + sx * side
            y1 = y0 + sy * side
        self.canvas.coords(self.drag_item_id, x0, y0, x1, y1)

    def on_drag_end(self, e):
        if not self.drag_start:
            return
        x0, y0 = self.drag_start
        x1, y1 = e.x, e.y
        if self.current_shape == "circle":
            dx = abs(x1 - x0); dy = abs(y1 - y0)
            side = max(dx, dy)
            sx = 1 if x1 >= x0 else -1
            sy = 1 if y1 >= y0 else -1
            x1 = x0 + sx * side
            y1 = y0 + sy * side

        self.canvas.delete(self.drag_item_id)
        self.drag_item_id = None
        shape = self.current_shape
        self.drag_start = None

        cx0, cy0 = min(x0, x1), min(y0, y1)
        cx1, cy1 = max(x0, x1), max(y0, y1)
        if (cx1 - cx0) < 4 or (cy1 - cy0) < 4:
            return

        ix0, iy0 = self.canvas_to_image(cx0, cy0)
        ix1, iy1 = self.canvas_to_image(cx1, cy1)
        self.add_shape(ix0, iy0, ix1 - ix0, iy1 - iy0, shape)
        self.update_status(f"Added {shape} #{len(self.shapes)}")

    def add_shape(self, x, y, w, h, shape):
        self.shapes.append({"x": x, "y": y, "w": w, "h": h, "shape": shape})
        cx0, cy0 = self.image_to_canvas(x, y)
        cx1, cy1 = self.image_to_canvas(x + w, y + h)
        sid = self.make_canvas_shape(cx0, cy0, cx1, cy1, shape, RECT_OUTLINE)
        self.shape_ids.append(sid)

    def remove_shape_index(self, idx):
        self.canvas.delete(self.shape_ids[idx])
        del self.shapes[idx]
        del self.shape_ids[idx]

    def on_right_click(self, e):
        # Удаляем верхнюю фигуру под курсором. Для ellipse/circle — простой
        # bbox-check (как у rect): для нашей задачи этого хватает.
        for i in range(len(self.shapes) - 1, -1, -1):
            s = self.shapes[i]
            cx0, cy0 = self.image_to_canvas(s["x"], s["y"])
            cx1, cy1 = self.image_to_canvas(s["x"] + s["w"], s["y"] + s["h"])
            if cx0 <= e.x <= cx1 and cy0 <= e.y <= cy1:
                self.remove_shape_index(i)
                self.update_status(f"Removed shape {i+1}")
                return

    def on_undo(self, e=None):
        if self.shapes:
            self.remove_shape_index(len(self.shapes) - 1)
            self.update_status(f"Undo. {len(self.shapes)} left")

    # --- save / quit ---

    def on_save(self, e=None):
        data = {
            "image": os.path.basename(self.image_path),
            "size": [self.img_w, self.img_h],
            "rects": self.shapes,
        }
        with open(self.json_path, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        self.update_status(f"Saved {len(self.shapes)} shape(s) -> "
                           f"{os.path.basename(self.json_path)}")
        print(f"Saved to {self.json_path}")

    def on_quit(self, e=None):
        self.root.quit()

    # --- status ---

    def update_status(self, msg=""):
        base = (f"{os.path.basename(self.image_path)}  "
                f"{self.img_w}x{self.img_h} (x{self.scale})  |  "
                f"shape: [{self.current_shape}] (r/e/c switch)  |  "
                f"items: {len(self.shapes)}  |  "
                f"LMB-drag draw  RMB del  Backspace undo  s save  q quit")
        self.status.config(text=base + ("  | " + msg if msg else ""))


def main():
    if len(sys.argv) != 2:
        print("Usage: python mark_eyes.py <image_path>")
        sys.exit(1)
    image_path = sys.argv[1]
    if not os.path.exists(image_path):
        print(f"File not found: {image_path}")
        sys.exit(1)

    root = tk.Tk()
    root.title(f"mark_eyes — {os.path.basename(image_path)}")
    EyeMarker(root, image_path)
    root.mainloop()


if __name__ == "__main__":
    main()
