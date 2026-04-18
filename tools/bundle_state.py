# -*- coding: utf-8 -*-
"""
Консолидирует top-level локалы novel_ui.gui_script в одну таблицу S.

Lua 5.1 имеет лимит 60 upvalues на функцию. init() и on_input() закрывают
>60 module-level локалов. Оборачиваем их в одну таблицу S — тогда функция
замыкает всего один upvalue (S) вместо 40+.

Что переносим:
  • Все node-переменные (bg_node, dialogue_panel, hotspot_boxes, ...)
  • Все mutable-состояния (shake_state, in_menu, hint_timer, ...)
  • Все module-level константы (HOTSPOT_COUNT, PORTRAIT_X, BG_FADE_DUR, ...)
  • Существующие таблицы (hud, inv_modal, item_modal, ui)

Что ОСТАВЛЯЕМ локалами:
  • require'ы: dm, sm, gs, scene_controller, hotspot_editor, items_catalog, yagames
  • local function'ы — это upvalue-функции, их пока не трогаем (~30 штук,
    влезают, если init закрывает только S + модули).

Алгоритм:
1. Читаем файл.
2. Парсим все top-level `local X = ...` и `local X, Y, Z` для целевых имён.
3. Генерируем блок инициализации `local S = { ... }` или набор `S.X = ...`.
4. Word-boundary regex replace <name> → S.<name> по всему файлу.
5. Вставляем инициализатор на место первой убранной декларации.
"""
import io, re

FILE = r"C:\Users\GoldiM\novell1\novell1\main\gui\novel_ui.gui_script"

# Переменные, которые переносим в S.
# Важно: ПОРЯДОК не важен (word-boundary replace независим), но для
# инициализатора удобно сгруппировать по смыслу.
TARGETS = [
    # Story
    "STORY_RESOURCE",
    # Yandex SDK
    "ysdk_ready", "game_lang",
    # Background
    "bg_node", "bg_sprite", "bg_sprite_next", "bg_menu_node", "pulse_overlay",
    "current_bg_image", "BG_FADE_DUR",
    # Shake
    "shake_state",
    # Narrator
    "narrator_panel", "narrator_clock", "narrator_prompt", "narrator_cursor",
    "narrator_visible", "cursor_blink_t",
    # Dialogue / choices
    "dialogue_panel", "name_panel", "name_label",
    "dialogue_text", "continue_hint", "choice_panel", "choice_question_node",
    "choice_btns", "choice_texts", "choice_btn_tops", "choice_btn_lefts",
    # Portraits
    "portraits", "current_portrait",
    "PORTRAIT_X", "PORTRAIT_Y", "PORTRAIT_Z",
    "PORTRAIT_SLIDE_FROM", "PORTRAIT_ANIM_DUR",
    # Text layout
    "TEXT_X_NORMAL", "TEXT_X_PORTRAIT", "TEXT_W_NORMAL", "TEXT_W_PORTRAIT", "TEXT_Y",
    "NAME_X_NORMAL", "NAME_X_PORTRAIT", "NAME_Y",
    # Hotspots
    "hotspot_boxes", "hotspot_labels", "hotspot_icons",
    "hotspot_circles", "hotspot_rings", "hotspot_orbits", "hotspot_dots",
    "HOTSPOT_COUNT", "ORBIT_DOTS",
    # Scene objects
    "scene_obj_nodes", "SCENE_OBJECT_COUNT",
    # HUD & modals (уже таблицы, но сами ссылки — upvalues)
    "hud", "inv_modal", "item_modal", "ui",
    # Menu
    "menu_panel", "menu_btn_play", "menu_btn_continue",
    "menu_btn_play_text", "menu_btn_continue_text",
    "menu_title_glitch_r", "menu_title_glitch_b",
    "menu_btn_play_top_line", "menu_btn_play_left_line",
    "menu_btn_continue_top_line", "menu_btn_continue_left_line",
    # Hint / flags
    "HINT_BLINK_SPEED", "hint_timer",
    "in_menu", "glitch_active", "music_started",
    # SFX
    "SFX_URLS",
]
TARGET_SET = set(TARGETS)

with io.open(FILE, "r", encoding="utf-8") as f:
    src = f.read()

# --- 1. Собираем объявления и их значения -----------------------------
# Паттерны, которые встречаются:
#   local X = value
#   local X, Y, Z                 — no value
#   local X, Y = v1, v2           — mixed (не поддерживаем — ломать не будем)
#   local X; (или end of line)

lines = src.splitlines(keepends=True)

# Словарь имя → строка инициализации (value из `local X = V`).
# Если без value — nil.
initial_values = {}

# Какие строки удалить (топ-level local-декларации чисто target'ов).
lines_to_remove = set()

# Проверяем, что строка — top-level (колонка 1, начинается с "local ")
# А не, скажем, внутри функции.
# Простая эвристика: отступа нет.
def is_toplevel(line):
    return line.startswith("local ")

for i, line in enumerate(lines):
    if not is_toplevel(line):
        continue
    stripped = line.rstrip("\n").rstrip()
    # Убираем комментарий в конце (после " --")
    code = re.sub(r'\s+--.*$', '', stripped)

    # Вариант A: local X = value (включая таблицы-литералы, но не многострочные)
    m = re.match(r'^local\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.+)$', code)
    if m:
        name = m.group(1)
        value = m.group(2)
        if name in TARGET_SET:
            initial_values[name] = value
            lines_to_remove.add(i)
        continue

    # Вариант B: local X1, X2, X3 [без =]
    m = re.match(r'^local\s+([A-Za-z_][A-Za-z0-9_, \t]*)\s*$', code)
    if m:
        names = [n.strip() for n in m.group(1).split(",")]
        if all(n in TARGET_SET for n in names):
            for n in names:
                initial_values[n] = "nil"
            lines_to_remove.add(i)
            continue
        # Если часть имён — target, часть — нет, оставим как есть (не наш кейс,
        # но на всякий случай предупредим).
        if any(n in TARGET_SET for n in names):
            print(f"WARN: смешанная декларация на строке {i+1}: {stripped}")
        continue

# --- 2. Удаляем помеченные строки, запоминаем точку вставки ----------
insert_at = min(lines_to_remove) if lines_to_remove else None
new_lines = [l for i, l in enumerate(lines) if i not in lines_to_remove]

# --- 3. Формируем блок инициализации S --------------------------------
init_block = ["-- Единая таблица состояния. Держит все ноды, флаги и константы,\n",
              "-- которые раньше лежали top-level локалами. Нужно, чтобы init()\n",
              "-- и on_input() не упирались в Lua limit 60 upvalues/function.\n",
              "local S = {}\n"]
for name in TARGETS:
    if name not in initial_values:
        continue   # не встретился в файле
    val = initial_values[name]
    init_block.append(f"S.{name} = {val}\n")

# --- 4. Word-boundary replace имён → S.имя по всему файлу -------------
text = "".join(new_lines)

# Вставляем init_block в позицию первого удалённого local'а.
# После удаления линий позиция нашей первой target-декларации — это
# уменьшенное имя. Проще: вставим ПЕРЕД комментарием-заголовком модулей
# или сразу после require'ов.
# Ищем последний `local X = require(...)` и ставим init_block после него.
last_req = None
req_lines = [i for i, l in enumerate(new_lines) if re.match(r'^local\s+[A-Za-z_]+\s*=\s*require\b', l)]
if req_lines:
    last_req = max(req_lines)
    # Вставляем после last_req
    insert_text = "".join(new_lines[:last_req+1]) + "\n" + "".join(init_block) + "\n" + "".join(new_lines[last_req+1:])
    text = insert_text
else:
    text = "".join(init_block) + "\n" + text

# Теперь replace. Паттерн: \b<name>\b, не трогая:
#   - содержимое строк в "..." и '...'
#   - комментарии после --
# Для простоты и безопасности: работаем построчно, в каждой строке
# отделяем код от комментария и строковых литералов.

def replace_in_code_span(code):
    """В куске кода (без строк и комментариев) заменяем целевые имена."""
    def sub(m):
        name = m.group(0)
        if name in TARGET_SET:
            return "S." + name
        return name
    return re.sub(r'\b[A-Za-z_][A-Za-z0-9_]*\b', sub, code)

def process_line(line):
    # Отделяем строковые литералы и комментарии, чтобы их не трогать.
    # Примитивный лексер: идём по символам, отмечаем "в строке" / "в коде" / "в комментарии".
    out = []
    i = 0
    n = len(line)
    while i < n:
        ch = line[i]
        # Комментарий до конца строки
        if ch == '-' and i+1 < n and line[i+1] == '-':
            out.append(line[i:])
            break
        # Строка двойная
        if ch == '"':
            j = i + 1
            while j < n:
                if line[j] == '\\':
                    j += 2
                    continue
                if line[j] == '"':
                    j += 1
                    break
                j += 1
            out.append(line[i:j])
            i = j
            continue
        # Строка одинарная
        if ch == "'":
            j = i + 1
            while j < n:
                if line[j] == '\\':
                    j += 2
                    continue
                if line[j] == "'":
                    j += 1
                    break
                j += 1
            out.append(line[i:j])
            i = j
            continue
        # Накапливаем код до следующего строко/комментариевого маркера
        j = i
        while j < n and line[j] not in ('"', "'") and not (line[j] == '-' and j+1 < n and line[j+1] == '-'):
            j += 1
        code_span = line[i:j]
        out.append(replace_in_code_span(code_span))
        i = j
    return "".join(out)

new_text_lines = []
for line in text.splitlines(keepends=True):
    new_text_lines.append(process_line(line))

result = "".join(new_text_lines)

# --- 5. Пост-фиксы -----------------------------------------------------
# После replace внутри init_block имена тоже заменились на S.X — это не
# нужно на левой стороне: получили "S.S.name = value". Откатим:
result = re.sub(r'\bS\.S\.', 'S.', result)

# "S.S_value" нам не грозит — word-boundary не склеивает.

with io.open(FILE, "w", encoding="utf-8") as f:
    f.write(result)

print(f"OK: перенесено {len(initial_values)} переменных в S; удалено {len(lines_to_remove)} локалов.")
print("Инициализированы:")
for n in TARGETS:
    if n in initial_values:
        print(f"  S.{n}")
print("Не найдены в top-level local (возможно объявляются иначе):")
for n in TARGETS:
    if n not in initial_values:
        print(f"  !  {n}")
