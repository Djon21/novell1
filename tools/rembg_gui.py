from __future__ import annotations

import os
import queue
import threading
from pathlib import Path
from tkinter import (
    BOTH,
    DISABLED,
    END,
    HORIZONTAL,
    LEFT,
    NORMAL,
    RIGHT,
    VERTICAL,
    BooleanVar,
    StringVar,
    Tk,
    filedialog,
    messagebox,
    ttk,
)

from PIL import Image, ImageTk
from rembg import new_session, remove


IMAGE_TYPES = (
    ("Images", "*.png *.jpg *.jpeg *.webp *.bmp *.tif *.tiff"),
    ("All files", "*.*"),
)

MODELS = (
    ("u2net", "Обычная универсальная модель"),
    ("u2netp", "Быстрее, легче, качество ниже"),
    ("u2net_human_seg", "Лучше для людей"),
    ("isnet-general-use", "Часто точнее, но тяжелее"),
)

BG_COLOR = "#f4f5f7"
PANEL_COLOR = "#ffffff"
TEXT_MUTED = "#667085"
ACCENT = "#2563eb"


class RembgGui:
    def __init__(self, root: Tk) -> None:
        self.root = root
        self.root.title("Rembg Studio")
        self.root.geometry("1080x720")
        self.root.minsize(880, 580)
        self.root.configure(bg=BG_COLOR)

        self.files: list[Path] = []
        self.outputs: dict[Path, Path] = {}
        self.preview_source: Path | None = None
        self.preview_result: Path | None = None
        self.preview_image: ImageTk.PhotoImage | None = None

        self.output_dir = StringVar(value=str(Path.cwd() / "rembg_output"))
        self.model_name = StringVar(value="u2net")
        self.model_hint = StringVar(value=MODELS[0][1])
        self.overwrite = BooleanVar(value=False)
        self.status = StringVar(value="Готово")
        self.counter = StringVar(value="0 файлов")

        self.events: queue.Queue[tuple[str, object]] = queue.Queue()
        self.worker: threading.Thread | None = None

        self._configure_style()
        self._build()
        self._bind_shortcuts()
        self.root.after(100, self._poll_events)

    def _configure_style(self) -> None:
        style = ttk.Style()
        style.theme_use("clam")
        style.configure(".", font=("Segoe UI", 10), background=BG_COLOR, foreground="#101828")
        style.configure("TFrame", background=BG_COLOR)
        style.configure("Panel.TFrame", background=PANEL_COLOR)
        style.configure("Title.TLabel", background=BG_COLOR, foreground="#101828", font=("Segoe UI", 18, "bold"))
        style.configure("Muted.TLabel", background=BG_COLOR, foreground=TEXT_MUTED)
        style.configure("Panel.TLabel", background=PANEL_COLOR, foreground="#101828")
        style.configure("PanelMuted.TLabel", background=PANEL_COLOR, foreground=TEXT_MUTED)
        style.configure("Accent.TButton", background=ACCENT, foreground="#ffffff", padding=(14, 8))
        style.map("Accent.TButton", background=[("active", "#1d4ed8"), ("disabled", "#98a2b3")])
        style.configure("TButton", padding=(12, 7))
        style.configure("Treeview", rowheight=30, background=PANEL_COLOR, fieldbackground=PANEL_COLOR)
        style.configure("Horizontal.TProgressbar", troughcolor="#e4e7ec", background=ACCENT)

    def _build(self) -> None:
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(1, weight=1)

        header = ttk.Frame(self.root, padding=(18, 16, 18, 10))
        header.grid(row=0, column=0, sticky="ew")
        header.columnconfigure(1, weight=1)

        ttk.Label(header, text="Rembg Studio", style="Title.TLabel").grid(row=0, column=0, sticky="w")
        ttk.Label(header, textvariable=self.counter, style="Muted.TLabel").grid(row=1, column=0, sticky="w", pady=(2, 0))

        actions = ttk.Frame(header)
        actions.grid(row=0, column=1, rowspan=2, sticky="e")
        ttk.Button(actions, text="Добавить", command=self.add_files).pack(side=LEFT, padx=(0, 8))
        ttk.Button(actions, text="Папка вывода", command=self.choose_output_dir).pack(side=LEFT, padx=(0, 8))
        ttk.Button(actions, text="Открыть вывод", command=self.open_output_dir).pack(side=LEFT, padx=(0, 8))
        self.start_button = ttk.Button(actions, text="Удалить фон", style="Accent.TButton", command=self.start)
        self.start_button.pack(side=LEFT)

        main = ttk.PanedWindow(self.root, orient=HORIZONTAL)
        main.grid(row=1, column=0, sticky="nsew", padx=18, pady=(0, 18))

        left = ttk.Frame(main, style="Panel.TFrame", padding=12)
        right = ttk.Frame(main, style="Panel.TFrame", padding=12)
        main.add(left, weight=1)
        main.add(right, weight=2)

        self._build_left_panel(left)
        self._build_right_panel(right)

        bottom = ttk.Frame(self.root, padding=(18, 0, 18, 14))
        bottom.grid(row=2, column=0, sticky="ew")
        bottom.columnconfigure(0, weight=1)
        self.progress = ttk.Progressbar(bottom, mode="determinate", style="Horizontal.TProgressbar")
        self.progress.grid(row=0, column=0, sticky="ew", padx=(0, 12))
        ttk.Label(bottom, textvariable=self.status, style="Muted.TLabel").grid(row=0, column=1, sticky="e")

    def _build_left_panel(self, parent: ttk.Frame) -> None:
        parent.columnconfigure(0, weight=1)
        parent.rowconfigure(4, weight=1)

        ttk.Label(parent, text="Настройки", style="Panel.TLabel", font=("Segoe UI", 12, "bold")).grid(
            row=0, column=0, sticky="w"
        )

        settings = ttk.Frame(parent, style="Panel.TFrame")
        settings.grid(row=1, column=0, sticky="ew", pady=(10, 14))
        settings.columnconfigure(1, weight=1)

        ttk.Label(settings, text="Модель", style="PanelMuted.TLabel").grid(row=0, column=0, sticky="w", pady=(0, 6))
        model_box = ttk.Combobox(
            settings,
            textvariable=self.model_name,
            values=[name for name, _ in MODELS],
            state="readonly",
            width=22,
        )
        model_box.grid(row=0, column=1, sticky="ew", padx=(10, 0), pady=(0, 6))
        model_box.bind("<<ComboboxSelected>>", self._update_model_hint)

        ttk.Label(settings, textvariable=self.model_hint, style="PanelMuted.TLabel", wraplength=300).grid(
            row=1, column=0, columnspan=2, sticky="w", pady=(0, 8)
        )
        ttk.Checkbutton(settings, text="Перезаписывать готовые PNG", variable=self.overwrite).grid(
            row=2, column=0, columnspan=2, sticky="w"
        )

        ttk.Label(parent, text="Папка вывода", style="PanelMuted.TLabel").grid(row=2, column=0, sticky="w")
        ttk.Label(parent, textvariable=self.output_dir, style="Panel.TLabel", wraplength=330).grid(
            row=3, column=0, sticky="ew", pady=(4, 16)
        )

        file_header = ttk.Frame(parent, style="Panel.TFrame")
        file_header.grid(row=4, column=0, sticky="new")
        file_header.columnconfigure(0, weight=1)
        ttk.Label(file_header, text="Очередь", style="Panel.TLabel", font=("Segoe UI", 12, "bold")).grid(
            row=0, column=0, sticky="w"
        )
        ttk.Button(file_header, text="Убрать", command=self.remove_selected).grid(row=0, column=1, padx=(8, 0))
        ttk.Button(file_header, text="Очистить", command=self.clear_files).grid(row=0, column=2, padx=(8, 0))

        list_frame = ttk.Frame(parent, style="Panel.TFrame")
        list_frame.grid(row=5, column=0, sticky="nsew", pady=(10, 0))
        list_frame.columnconfigure(0, weight=1)
        list_frame.rowconfigure(0, weight=1)

        self.tree = ttk.Treeview(list_frame, columns=("status",), show="tree headings", selectmode="extended")
        self.tree.heading("#0", text="Файл")
        self.tree.heading("status", text="Статус")
        self.tree.column("#0", minwidth=220, width=260)
        self.tree.column("status", minwidth=90, width=110, anchor="center")
        y_scroll = ttk.Scrollbar(list_frame, orient=VERTICAL, command=self.tree.yview)
        self.tree.configure(yscrollcommand=y_scroll.set)
        self.tree.grid(row=0, column=0, sticky="nsew")
        y_scroll.grid(row=0, column=1, sticky="ns")
        self.tree.bind("<<TreeviewSelect>>", self._on_select)

    def _build_right_panel(self, parent: ttk.Frame) -> None:
        parent.columnconfigure(0, weight=1)
        parent.rowconfigure(1, weight=1)
        parent.rowconfigure(3, weight=0)

        preview_header = ttk.Frame(parent, style="Panel.TFrame")
        preview_header.grid(row=0, column=0, sticky="ew")
        preview_header.columnconfigure(0, weight=1)
        ttk.Label(preview_header, text="Предпросмотр", style="Panel.TLabel", font=("Segoe UI", 12, "bold")).grid(
            row=0, column=0, sticky="w"
        )
        self.preview_mode = StringVar(value="source")
        ttk.Radiobutton(preview_header, text="Исходник", variable=self.preview_mode, value="source", command=self.show_preview).grid(
            row=0, column=1, padx=(8, 0)
        )
        ttk.Radiobutton(preview_header, text="Результат", variable=self.preview_mode, value="result", command=self.show_preview).grid(
            row=0, column=2, padx=(8, 0)
        )

        preview_box = ttk.Frame(parent, style="Panel.TFrame")
        preview_box.grid(row=1, column=0, sticky="nsew", pady=(10, 14))
        preview_box.columnconfigure(0, weight=1)
        preview_box.rowconfigure(0, weight=1)
        self.preview_label = ttk.Label(
            preview_box,
            text="Добавьте изображения или выберите файл в очереди",
            anchor="center",
            style="PanelMuted.TLabel",
        )
        self.preview_label.grid(row=0, column=0, sticky="nsew")
        self.preview_label.bind("<Configure>", lambda _event: self.show_preview())

        ttk.Label(parent, text="Журнал", style="Panel.TLabel", font=("Segoe UI", 12, "bold")).grid(
            row=2, column=0, sticky="w"
        )

        log_frame = ttk.Frame(parent, style="Panel.TFrame")
        log_frame.grid(row=3, column=0, sticky="ew", pady=(10, 0))
        log_frame.columnconfigure(0, weight=1)
        self.log = ttk.Treeview(log_frame, columns=("message",), show="headings", height=6)
        self.log.heading("message", text="Событие")
        self.log.column("message", anchor="w")
        log_scroll = ttk.Scrollbar(log_frame, orient=VERTICAL, command=self.log.yview)
        self.log.configure(yscrollcommand=log_scroll.set)
        self.log.grid(row=0, column=0, sticky="ew")
        log_scroll.grid(row=0, column=1, sticky="ns")

    def _bind_shortcuts(self) -> None:
        self.root.bind("<Control-o>", lambda _event: self.add_files())
        self.root.bind("<Delete>", lambda _event: self.remove_selected())
        self.root.bind("<F5>", lambda _event: self.start())

    def _update_model_hint(self, _event: object | None = None) -> None:
        hints = dict(MODELS)
        self.model_hint.set(hints.get(self.model_name.get(), ""))

    def add_files(self) -> None:
        selected = filedialog.askopenfilenames(title="Выберите изображения", filetypes=IMAGE_TYPES)
        if not selected:
            return

        existing = set(self.files)
        for name in selected:
            path = Path(name)
            if path in existing:
                continue
            self.files.append(path)
            self.tree.insert("", END, iid=str(path), text=path.name, values=("В очереди",))
            existing.add(path)

        self._update_counter()
        self._log(f"Добавлено файлов: {len(selected)}")
        if self.preview_source is None and self.files:
            self.select_file(self.files[0])

    def remove_selected(self) -> None:
        if self._is_busy():
            return

        selected = self.tree.selection()
        for item in selected:
            path = Path(item)
            if path in self.files:
                self.files.remove(path)
            self.outputs.pop(path, None)
            self.tree.delete(item)

        if selected:
            self._log(f"Убрано файлов: {len(selected)}")
            self.preview_source = None
            self.preview_result = None
            self.preview_image = None
            self._update_counter()
            self.show_preview()

    def clear_files(self) -> None:
        if self._is_busy():
            return

        self.files.clear()
        self.outputs.clear()
        for item in self.tree.get_children():
            self.tree.delete(item)
        self.preview_source = None
        self.preview_result = None
        self.preview_image = None
        self.progress["value"] = 0
        self.status.set("Готово")
        self._update_counter()
        self.show_preview()
        self._log("Очередь очищена")

    def choose_output_dir(self) -> None:
        selected = filedialog.askdirectory(title="Выберите папку вывода")
        if selected:
            self.output_dir.set(selected)

    def open_output_dir(self) -> None:
        output_dir = Path(self.output_dir.get())
        output_dir.mkdir(parents=True, exist_ok=True)
        os.startfile(output_dir)

    def select_file(self, path: Path) -> None:
        if str(path) in self.tree.get_children():
            self.tree.selection_set(str(path))
            self.tree.see(str(path))
            self.preview_source = path
            self.preview_result = self.outputs.get(path)
            self.show_preview()

    def start(self) -> None:
        if self._is_busy():
            return
        if not self.files:
            messagebox.showinfo("Rembg Studio", "Сначала добавьте изображения.")
            return

        output_dir = Path(self.output_dir.get())
        output_dir.mkdir(parents=True, exist_ok=True)

        self.progress["maximum"] = len(self.files)
        self.progress["value"] = 0
        self.start_button.configure(state=DISABLED)
        self.status.set("Подготовка модели...")
        self._log(f"Старт: модель {self.model_name.get()}")

        files = list(self.files)
        self.worker = threading.Thread(target=self._process_files, args=(files, output_dir), daemon=True)
        self.worker.start()

    def _process_files(self, files: list[Path], output_dir: Path) -> None:
        try:
            session = new_session(self.model_name.get())
            for index, path in enumerate(files, start=1):
                target = output_dir / f"{path.stem}_nobg.png"
                if target.exists() and not self.overwrite.get():
                    self.events.put(("skip", (path, target, index)))
                    continue

                self.events.put(("active", (path, index)))
                with Image.open(path) as image:
                    result = remove(image, session=session)
                    result.save(target)

                self.events.put(("success", (path, target, index)))

            self.events.put(("done", output_dir))
        except Exception as exc:
            self.events.put(("error", str(exc)))

    def _poll_events(self) -> None:
        while True:
            try:
                kind, payload = self.events.get_nowait()
            except queue.Empty:
                break

            if kind == "active":
                path, index = payload
                self._set_row_status(path, "Обработка")
                self.status.set(f"{index}/{len(self.files)}: {path.name}")
            elif kind == "skip":
                path, target, index = payload
                self.outputs[path] = target
                self._set_row_status(path, "Пропущено")
                self.progress["value"] = min(self.progress["value"] + 1, self.progress["maximum"])
                self.status.set(f"{index}/{len(self.files)}: пропущено")
                self._log(f"Пропущено: {target.name}")
            elif kind == "success":
                path, target, index = payload
                self.outputs[path] = target
                self._set_row_status(path, "Готово")
                self.progress["value"] = min(self.progress["value"] + 1, self.progress["maximum"])
                self.status.set(f"{index}/{len(self.files)}: {target.name}")
                self.preview_source = path
                self.preview_result = target
                self.preview_mode.set("result")
                self.show_preview()
                self._log(f"Готово: {target.name}")
            elif kind == "done":
                self.start_button.configure(state=NORMAL)
                self.status.set(f"Готово: {payload}")
                self._log(f"Завершено: {payload}")
                messagebox.showinfo("Rembg Studio", f"Готово.\n\nПапка: {payload}")
            elif kind == "error":
                self.start_button.configure(state=NORMAL)
                self.status.set("Ошибка")
                self._log(f"Ошибка: {payload}")
                messagebox.showerror("Rembg Studio", str(payload))

        self.root.after(100, self._poll_events)

    def _on_select(self, _event: object | None = None) -> None:
        selected = self.tree.selection()
        if not selected:
            return
        path = Path(selected[0])
        self.preview_source = path
        self.preview_result = self.outputs.get(path)
        self.show_preview()

    def show_preview(self) -> None:
        path = self.preview_source
        if self.preview_mode.get() == "result":
            path = self.preview_result

        if not path or not path.exists():
            text = "Результат появится после обработки" if self.preview_mode.get() == "result" else "Выберите файл"
            self.preview_label.configure(image="", text=text)
            self.preview_image = None
            return

        try:
            with Image.open(path) as image:
                image.thumbnail(self._preview_size(), Image.Resampling.LANCZOS)
                rendered = ImageTk.PhotoImage(image.copy())
        except Exception as exc:
            self.preview_label.configure(image="", text=f"Не удалось открыть превью: {exc}")
            self.preview_image = None
            return

        self.preview_image = rendered
        self.preview_label.configure(image=self.preview_image, text="")

    def _preview_size(self) -> tuple[int, int]:
        width = max(self.preview_label.winfo_width() - 24, 240)
        height = max(self.preview_label.winfo_height() - 24, 240)
        return width, height

    def _set_row_status(self, path: Path, status: str) -> None:
        item = str(path)
        if item in self.tree.get_children():
            self.tree.set(item, "status", status)

    def _log(self, message: str) -> None:
        self.log.insert("", END, values=(message,))
        children = self.log.get_children()
        if children:
            self.log.see(children[-1])

    def _update_counter(self) -> None:
        total = len(self.files)
        self.counter.set(f"{total} файл" if total == 1 else f"{total} файлов")

    def _is_busy(self) -> bool:
        return bool(self.worker and self.worker.is_alive())


def main() -> None:
    root = Tk()
    RembgGui(root)
    root.mainloop()


if __name__ == "__main__":
    main()
