"""
generate_scenario_inventory.py — сканирует проект и генерирует
`docs/scenario_context/PROJECT_INVENTORY.md` со всеми существующими ID
которые AI должен знать чтобы не галлюцинировать.

Что собирается:
  - Scenes из main/data/scenes/*.lua (id, label, bg, on_enter knot)
  - Hotspots для каждой сцены (id, label, action)
  - Ink knots из main/story/chapters/*.ink (имя + краткая аннотация)
  - Characters из main/gui/components_v2/dialogue_v2.gui_script CHARS
  - Items из ink-тегов `# add_item:`
  - Flags из ink `# set_flag:` и lua `get_flag(...)` / `set_flag(...)`
  - Backgrounds из main/images/backgrounds/*.atlas
  - Scene characters из main/scripts/scene_characters.lua SCENES
  - Phone POIs из main/gui/components_v2/phone_map.gui_script POI_SCENES

Usage:
    python tools/generate_scenario_inventory.py
        → перезапишет docs/scenario_context/PROJECT_INVENTORY.md

Запускать перед каждой сессией с AI-сценаристом, чтобы документ всегда
отражал актуальное состояние проекта.
"""
from __future__ import annotations
import os
import re
import sys
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "docs" / "scenario_context" / "PROJECT_INVENTORY.md"

# ---------------------------- Scenes & Hotspots ----------------------------

def extract_brace_body(text: str, open_brace_index: int) -> tuple[str, int]:
    """Return body inside {...} and index just after the matching closing brace."""
    assert text[open_brace_index] == "{"
    depth = 1
    i = open_brace_index + 1
    while i < len(text) and depth > 0:
        ch = text[i]
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
        i += 1
    return text[open_brace_index + 1:i - 1], i


def iter_top_level_table_entries(body: str):
    """
    Iterate `name = {...}` / `name = other_name` entries in a Lua table body.
    This deliberately only reads depth-0 entries so nested `hotspots = {}` and
    `on_enter = {}` blocks are not mistaken for scene ids.
    """
    i = 0
    depth = 0
    while i < len(body):
        if depth == 0:
            m = re.match(r"\s*,?\s*([a-zA-Z_][\w]*)\s*=\s*", body[i:])
            if m:
                key = m.group(1)
                i += m.end()
                while i < len(body) and body[i].isspace():
                    i += 1
                if i < len(body) and body[i] == "{":
                    entry_body, end = extract_brace_body(body, i)
                    yield key, "block", entry_body
                    i = end
                    continue
                expr_start = i
                while i < len(body) and body[i] not in ",\n\r":
                    i += 1
                yield key, "expr", body[expr_start:i].strip()
                continue

        ch = body[i]
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
        i += 1


def scan_scene_files() -> dict:
    """
    Парсит main/data/scenes/*.lua (кроме _shared.lua) и собирает scenes:
      { scene_id: { source, bg, label, on_enter_knot, hotspots:[...] } }
    """
    scenes = {}
    scenes_dir = ROOT / "main" / "data" / "scenes"
    for lua in sorted(scenes_dir.glob("*.lua")):
        if lua.name == "_shared.lua":
            continue
        text = lua.read_text(encoding="utf-8")

        # Newer location files may define scenes as locals and return aliases:
        #   local shop_street = { ... }
        #   return { shop_hub = shop_street }
        local_defs = {}
        for m in re.finditer(r"^local\s+([a-z_][\w]*)\s*=\s*\{", text, re.MULTILINE):
            name = m.group(1)
            body, _ = extract_brace_body(text, m.end() - 1)
            local_defs[name] = body

        # Source of exported scene ids is the module's return table.
        rm = re.search(r"\breturn\s*\{", text)
        if not rm:
            continue
        return_body, _ = extract_brace_body(text, rm.end() - 1)
        for scene_id, kind, value in iter_top_level_table_entries(return_body):
            if kind == "block":
                scenes[scene_id] = parse_scene_block(scene_id, value, lua.name)
            else:
                ref = value.rstrip(",")
                if ref in local_defs:
                    info = parse_scene_block(scene_id, local_defs[ref], lua.name)
                    if ref != scene_id:
                        info["alias_of"] = ref
                    scenes[scene_id] = info
    return scenes


def parse_scene_block(scene_id: str, block: str, source: str) -> dict:
    info = {
        "source": source,
        "label": None,
        "bg": None,
        "on_enter_knot": None,
        "alias_of": None,
        "hotspots": [],
    }
    m = re.search(r"\blabel\s*=\s*['\"]([^'\"]+)['\"]", block)
    if m:
        info["label"] = m.group(1)
    m = re.search(r"\bbg\s*=\s*([^,\n]+)", block)
    if m:
        info["bg"] = m.group(1).strip()
    m = re.search(r"\bon_enter\s*=\s*\{[^}]*?knot\s*=\s*['\"]([^'\"]+)['\"]",
                  block, re.DOTALL)
    if m:
        info["on_enter_knot"] = m.group(1)
    # Hotspots — массив таблиц в hotspots = { { ... }, { ... } }
    info["hotspots"] = parse_hotspots(block)
    return info


def parse_hotspots(block: str) -> list:
    """Достаёт hotspot-блоки в формате { id=..., label=..., action=... }."""
    out = []
    # Найти hotspots = { ... },
    m = re.search(r"\bhotspots\s*=\s*\{", block)
    if not m:
        return out
    body, _ = extract_brace_body(block, m.end() - 1)
    # Внутри hotspots — массив таблиц или scene recipes: s.inspect{...}.
    j = 0
    while j < len(body):
        recipe = None
        rm = re.match(r"\s*,?\s*s\.([a-z_][\w]*)\s*\{", body[j:])
        if rm:
            recipe = rm.group(1)
            brace_index = j + rm.end() - 1
            hb, k = extract_brace_body(body, brace_index)
            j = k
        elif body[j] == "{":
            hb, k = extract_brace_body(body, j)
            j = k
        else:
            j += 1
            continue

        if hb:
            h = {}
            mm = re.search(r"\bid\s*=\s*['\"]([^'\"]+)['\"]", hb)
            if mm: h["id"] = mm.group(1)
            mm = re.search(r"\blabel\s*=\s*['\"]([^'\"]+)['\"]", hb)
            if mm: h["label"] = mm.group(1)
            mm = re.search(r"\baction\s*=\s*\{[^}]*?type\s*=\s*['\"]([^'\"]+)['\"]", hb, re.DOTALL)
            if mm:
                h["action_type"] = mm.group(1)
                mm2 = re.search(r"\bknot\s*=\s*['\"]([^'\"]+)['\"]", hb)
                if mm2: h["action_knot"] = mm2.group(1)
                mm3 = re.search(r"\bscene\s*=\s*['\"]([^'\"]+)['\"]", hb)
                if mm3: h["action_scene"] = mm3.group(1)
                mm4 = re.search(r"\bitem\s*=\s*['\"]([^'\"]+)['\"]", hb)
                if mm4: h["action_item"] = mm4.group(1)
            elif recipe:
                if recipe == "nav_scene":
                    h["action_type"] = "goto_scene"
                    mm = re.search(r"\bscene\s*=\s*['\"]([^'\"]+)['\"]", hb)
                    if mm: h["action_scene"] = mm.group(1)
                elif recipe in ("nav_ink", "inspect", "pickup", "use", "story", "item_target", "leave"):
                    h["action_type"] = "ink_knot"
                    mm = re.search(r"\bknot\s*=\s*['\"]([^'\"]+)['\"]", hb)
                    if mm: h["action_knot"] = mm.group(1)
                h["recipe"] = recipe
            # Маркер наличия условий видимости / доступности. Сами Lua-функции
            # в inventory не вытаскиваем (могут быть многострочные + ссылаться
            # на хелперы вроде not_chosen_or_met) — только флаг что условие есть.
            # Если задача про "когда виден этот хотспот" — AI должен открыть
            # source-файл сцены, не полагаться на inventory.
            if re.search(r"\bvisible_when\s*=", hb):
                h["has_visible_when"] = True
            if re.search(r"\bcondition\s*=", hb):
                h["has_condition"] = True
            if h.get("id"):
                out.append(h)
    return out


# ---------------------------- Ink knots ----------------------------

def scan_ink_knots() -> dict:
    """
    Парсит main/story/chapters/*.ink (без _old/_old3 версий) и возвращает:
      { knot_name: { source, summary } }
    summary = первая non-tag, non-empty строка после знака `===`.
    """
    knots = {}
    ink_dir = ROOT / "main" / "story" / "chapters"
    for ink in sorted(ink_dir.rglob("*.ink")):
        if "_old" in ink.name:
            continue
        if "archive" in ink.parts:
            continue
        text = ink.read_text(encoding="utf-8", errors="replace")
        # === knot_name ===
        for m in re.finditer(r"^===\s*([a-zA-Z_][\w]*)\s*===", text, re.MULTILINE):
            name = m.group(1)
            tail = text[m.end():]
            summary = first_meaningful_line(tail)
            knots[name] = {"source": ink.name, "summary": summary}
    return knots


def first_meaningful_line(tail: str) -> str:
    """Берёт первую содержательную строку из knot body, до 80 символов."""
    for raw in tail.splitlines()[:25]:
        line = raw.strip()
        if not line:
            continue
        if line.startswith("//") or line.startswith("==="):
            continue
        if line.startswith("#"):  # пропускаем теги
            # Возможна одна строка с несколькими тегами + текст после
            stripped = re.sub(r"#\s*\S+(?:\s*:\s*\S+)*", "", line).strip()
            if stripped:
                return stripped[:100]
            continue
        if line.startswith("~") or line.startswith("{") or line.startswith("->"):
            continue
        if line.startswith("*") or line.startswith("+"):
            # Choice option — но контента нет, пропустим
            continue
        return line[:120]
    return ""


# ---------------------------- Characters ----------------------------

def scan_characters() -> list:
    """
    CHARS из dialogue_v2.gui_script. Группирует ключи по `atlas` полю —
    разные алиасы одного персонажа (mila/мила, artem/артём) сливаются
    в одну запись.
    Возвращает список dict'ов: { atlas, keys: [список ключей], portrait_*, ... }
    """
    script = ROOT / "main" / "gui" / "components_v2" / "dialogue_v2.gui_script"
    text = script.read_text(encoding="utf-8")
    m = re.search(r"local\s+CHARS\s*=\s*\{", text)
    if not m:
        return []
    start = m.end()
    depth = 1
    i = start
    while i < len(text) and depth > 0:
        ch = text[i]
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
        i += 1
    block = text[start:i - 1]

    # Парсим каждый entry: ключ + содержимое его {}
    entries = []
    pos = 0
    while True:
        mm = re.search(r"(?:\[\s*['\"]([^'\"]+)['\"]\s*\]|([a-zA-Z_][\w]*))\s*=\s*\{",
                       block[pos:])
        if not mm:
            break
        key = mm.group(1) or mm.group(2)
        body_start = pos + mm.end()
        d2 = 1
        j = body_start
        while j < len(block) and d2 > 0:
            if block[j] == "{": d2 += 1
            elif block[j] == "}": d2 -= 1
            j += 1
        body = block[body_start:j - 1]
        if key != "_default":
            atlas = None
            am = re.search(r"\batlas\s*=\s*['\"]([^'\"]+)['\"]", body)
            if am: atlas = am.group(1)
            anim = {}
            for fn in ("portrait", "portrait_idle", "portrait_blink", "portrait_talk"):
                fm = re.search(rf"\b{fn}\s*=\s*['\"]([^'\"]+)['\"]", body)
                if fm: anim[fn] = fm.group(1)
            entries.append({"key": key, "atlas": atlas, "anim": anim})
        pos = j

    # Группировка по atlas (или по key если нет atlas)
    grouped = {}
    for e in entries:
        gid = e["atlas"] or e["key"]
        if gid not in grouped:
            grouped[gid] = {"atlas": e["atlas"], "keys": [], "anim": e["anim"]}
        grouped[gid]["keys"].append(e["key"])
        # Берём anim информацию из первой записи с заполненным портретом
        if not grouped[gid]["anim"] and e["anim"]:
            grouped[gid]["anim"] = e["anim"]
    return list(grouped.values())


# ---------------------------- Items & Flags ----------------------------

def scan_items_and_flags() -> tuple:
    """
    Items: все ID из `# add_item:ID`, `# remove_item:ID`, `# item:add:ID` etc.
    Flags: все имена из `# set_flag:NAME=...`, `get_flag("NAME"...)`,
           `set_flag("NAME"...)`, `~ NAME = ...` (ink VARs).
    """
    items = set()
    flags = set()

    # Ink files
    for ink in (ROOT / "main" / "story" / "chapters").rglob("*.ink"):
        if "_old" in ink.name:
            continue
        if "archive" in ink.parts:
            continue
        text = ink.read_text(encoding="utf-8", errors="replace")
        for m in re.finditer(r"#\s*(?:add_item|remove_item|item:(?:add|remove))\s*:\s*([a-zA-Z_][\w]*)", text):
            items.add(m.group(1))
        for m in re.finditer(r"#\s*(?:set_flag|flag)\s*:\s*([a-zA-Z_][\w]*)\s*=", text):
            flags.add(m.group(1))

    # Lua files (scenes + scripts) — ловим get_flag/set_flag
    for ext_dir in [ROOT / "main" / "data" / "scenes",
                    ROOT / "main" / "scripts",
                    ROOT / "main" / "gui"]:
        for lua in ext_dir.rglob("*.lua"):
            try:
                text = lua.read_text(encoding="utf-8", errors="replace")
            except Exception:
                continue
            for m in re.finditer(r"\b(?:get_flag|set_flag)\s*\(\s*['\"]([a-zA-Z_][\w]*)['\"]", text):
                flags.add(m.group(1))

    return sorted(items), sorted(flags)


# ---------------------------- Backgrounds ----------------------------

def scan_backgrounds() -> list:
    bg_dir = ROOT / "main" / "images" / "backgrounds"
    bgs = []
    for atlas in sorted(bg_dir.glob("*.atlas")):
        bgs.append(atlas.stem)
    return bgs


# ---------------------------- Scene characters ----------------------------

def scan_scene_characters() -> dict:
    """SCENES таблица из scene_characters.lua + SCENE_GROUPS."""
    f = ROOT / "main" / "scripts" / "scene_characters.lua"
    text = f.read_text(encoding="utf-8")
    out = {"groups": {}, "scenes": {}}

    # SCENE_GROUPS: scene_id = "group"
    m = re.search(r"local\s+SCENE_GROUPS\s*=\s*\{", text)
    if m:
        start = m.end()
        depth = 1
        i = start
        while i < len(text) and depth > 0:
            if text[i] == "{": depth += 1
            elif text[i] == "}": depth -= 1
            i += 1
        block = text[start:i - 1]
        for mm in re.finditer(r"([a-z_][\w]*)\s*=\s*['\"]([^'\"]+)['\"]", block):
            out["groups"][mm.group(1)] = mm.group(2)

    # SCENES: group = { key = {...}, ... }
    m = re.search(r"local\s+SCENES\s*=\s*\{", text)
    if m:
        start = m.end()
        depth = 1
        i = start
        while i < len(text) and depth > 0:
            if text[i] == "{": depth += 1
            elif text[i] == "}": depth -= 1
            i += 1
        block = text[start:i - 1]
        # Группы 1-го уровня
        for mm in re.finditer(r"^    ([a-z_][\w]*)\s*=\s*\{", block, re.MULTILINE):
            group = mm.group(1)
            gstart = mm.end()
            d2 = 1; j = gstart
            while j < len(block) and d2 > 0:
                if block[j] == "{": d2 += 1
                elif block[j] == "}": d2 -= 1
                j += 1
            gblock = block[gstart:j - 1]
            entries = {}
            for em in re.finditer(r"([a-zA-Z_][\w]*)\s*=\s*\{([^{}]*(?:\{[^{}]*\}[^{}]*)*)\}",
                                   gblock):
                key = em.group(1)
                ebody = em.group(2)
                e = {}
                for fn, pattern in [("atlas", r"atlas\s*=\s*['\"]([^'\"]+)['\"]"),
                                     ("sprite", r"sprite\s*=\s*['\"]([^'\"]+)['\"]"),
                                     ("knot", r"knot\s*=\s*['\"]([^'\"]+)['\"]")]:
                    fm = re.search(pattern, ebody)
                    if fm: e[fn] = fm.group(1)
                entries[key] = e
            if entries:
                out["scenes"][group] = entries
    return out


# ---------------------------- Phone POIs ----------------------------

def scan_phone_pois() -> dict:
    f = ROOT / "main" / "gui" / "components_v2" / "phone_map.gui_script"
    text = f.read_text(encoding="utf-8")
    out = {}
    m = re.search(r"local\s+POI_SCENES\s*=\s*\{", text)
    if not m:
        return out
    start = m.end()
    depth = 1; i = start
    while i < len(text) and depth > 0:
        if text[i] == "{": depth += 1
        elif text[i] == "}": depth -= 1
        i += 1
    block = text[start:i - 1]
    for mm in re.finditer(r"(poi_[a-z_]+)\s*=\s*\{\s*scene\s*=\s*['\"]([^'\"]+)['\"][^}]*?label\s*=\s*['\"]([^'\"]+)['\"]",
                           block, re.DOTALL):
        out[mm.group(1)] = {"scene": mm.group(2), "label": mm.group(3)}
    return out


# ---------------------------- Render ----------------------------

def render(data) -> str:
    lines = []
    add = lines.append
    add("# Project Inventory")
    add("")
    add("**Auto-generated** скриптом `tools/generate_scenario_inventory.py`.")
    add("Запускать перед каждой сессией AI-сценариста чтобы документ отражал")
    add("текущее состояние проекта.")
    add("")
    add(f"_Сгенерировано: {datetime.now().strftime('%Y-%m-%d %H:%M')}_")
    add("")
    add("Это **источник правды для AI** о том что реально существует в проекте:")
    add("scene_id, knot имена, hotspot id, флаги, предметы. Не ссылайся на")
    add("вещи которых нет в этом списке — спроси у пользователя сначала.")
    add("")
    add("---")
    add("")

    # Scenes
    add("## Scenes")
    add("")
    add("Exploration-сцены и их хотспоты. Source: `main/data/scenes/*.lua`.")
    add("")
    add("**Gated column:**")
    add("- 👁 — у хотспота есть `visible_when` (может быть скрыт по условию)")
    add("- 🔒 — у хотспота есть `condition` (виден, но locked/неактивен по условию)")
    add("- `—` — без условий, виден всегда")
    add("")
    add("> ⚠️ **Inventory НЕ показывает сами Lua-условия** видимости/доступности.")
    add("> Если задача зависит от «когда виден этот хотспот», «при каких флагах»,")
    add("> «почему он не появляется» — открой соответствующий `main/data/scenes/<file>.lua`")
    add("> и читай `visible_when` / `condition` функции там. Они часто многострочные")
    add("> и могут ссылаться на shared-хелперы (`not_chosen_or_met`, `can_offer_place`).")
    add("")
    for sid, info in sorted(data["scenes"].items()):
        label = info.get("label") or "—"
        bg = info.get("bg") or "—"
        oek = info.get("on_enter_knot")
        head = f"### `{sid}` ({label})"
        add(head)
        meta = [f"source: `{info['source']}`", f"bg: `{bg}`"]
        if info.get("alias_of"):
            meta.append(f"alias_of: `{info['alias_of']}`")
        if oek:
            meta.append(f"on_enter: `{oek}`")
        add(" — " + ", ".join(meta))
        if info["hotspots"]:
            add("")
            add("| Hotspot id | Label | Action | Gated |")
            add("|---|---|---|---|")
            for h in info["hotspots"]:
                if h.get("action_type") == "ink_knot":
                    act = f"knot: `{h.get('action_knot', '?')}`"
                elif h.get("action_type") == "goto_scene":
                    act = f"scene: `{h.get('action_scene', '?')}`"
                elif h.get("action_type") == "add_item":
                    act = f"item: `{h.get('action_item', '?')}`"
                else:
                    act = h.get("action_type", "—")
                # Gated-маркер: хотспот имеет visible_when и/или condition.
                # Сами Lua-условия сюда не выводятся — слишком сложные, читай source.
                gated_marks = []
                if h.get("has_visible_when"): gated_marks.append("👁")
                if h.get("has_condition"):    gated_marks.append("🔒")
                gated = " ".join(gated_marks) or "—"
                add(f"| `{h['id']}` | {h.get('label', '—')} | {act} | {gated} |")
        add("")

    # Ink knots
    add("## Ink Knots")
    add("")
    add("Все объявленные `=== knot_name ===` в `main/story/chapters/*.ink`")
    add("(без `_old*` версий). Используй ТОЛЬКО эти имена для `action_knot`")
    add("в hotspot'ах и для `# scene_char:show:...:...` если требуется.")
    add("")
    by_file = {}
    for kname, kinfo in data["knots"].items():
        by_file.setdefault(kinfo["source"], []).append((kname, kinfo["summary"]))
    for src in sorted(by_file.keys()):
        add(f"### `{src}`")
        add("")
        add("| Knot | Аннотация |")
        add("|---|---|")
        for kname, summary in sorted(by_file[src]):
            add(f"| `{kname}` | {summary or '—'} |")
        add("")

    # Characters
    add("## Characters (CHARS)")
    add("")
    add("Speaker keys из `dialogue_v2.gui_script` CHARS table. Используются")
    add("в `# speaker:KEY`. Каждый персонаж может иметь несколько алиасов")
    add("(латинский ID и кириллическая форма) — обе формы работают одинаково.")
    add("")
    add("| Atlas | Aliases (для `# speaker:`) | Анимации портрета |")
    add("|---|---|---|")
    for c in data["chars"]:
        keys = ", ".join(f"`{k}`" for k in c["keys"])
        atlas = c["atlas"] or "—"
        anim = c.get("anim") or {}
        anim_bits = []
        if anim.get("portrait_idle"):  anim_bits.append("idle")
        if anim.get("portrait_blink"): anim_bits.append("blink")
        if anim.get("portrait_talk"):  anim_bits.append("talk")
        if not anim_bits and anim.get("portrait"):
            anim_bits.append("static")
        anims = ", ".join(anim_bits) or "—"
        add(f"| `{atlas}` | {keys} | {anims} |")
    add("")

    # Scene characters
    sc = data["scene_chars"]
    add("## Scene Characters")
    add("")
    add("Персонажи в полный рост на фоне сцены (`# scene_char:show:GROUP:KEY`).")
    add("Source: `main/scripts/scene_characters.lua`.")
    add("")
    if sc["groups"]:
        add("### Scene groups")
        add("")
        add("| scene_id | group |")
        add("|---|---|")
        for sid, grp in sorted(sc["groups"].items()):
            add(f"| `{sid}` | `{grp}` |")
        add("")
    if sc["scenes"]:
        add("### Available characters per group")
        add("")
        for group, entries in sorted(sc["scenes"].items()):
            add(f"**`{group}`**:")
            for key, e in sorted(entries.items()):
                bits = [f"sprite=`{e.get('sprite','?')}`",
                        f"atlas=`{e.get('atlas','?')}`"]
                if e.get("knot"):
                    bits.append(f"click→knot=`{e['knot']}`")
                add(f"  - `{key}` — " + ", ".join(bits))
            add("")

    # Items
    add("## Items")
    add("")
    add("Все ID из ink-тегов `# add_item:` / `# remove_item:`.")
    add("")
    add(" ".join(f"`{i}`" for i in data["items"]) or "(пусто)")
    add("")

    # Flags
    add("## Flags")
    add("")
    add(f"Все имена флагов встречающиеся в `# set_flag:`, `get_flag(...)`,")
    add(f"`set_flag(...)`. Всего: **{len(data['flags'])}**.")
    add("")
    # Группируем по префиксу до первого `_`
    grouped = {}
    for f in data["flags"]:
        prefix = f.split("_")[0]
        grouped.setdefault(prefix, []).append(f)
    for prefix in sorted(grouped.keys()):
        add(f"**`{prefix}_*`**: " + " ".join(f"`{x}`" for x in sorted(grouped[prefix])))
        add("")

    # Backgrounds
    add("## Backgrounds")
    add("")
    add("Доступные bg-атласы (используются в `# bg:NAME` и `scene.bg`).")
    add("Source: `main/images/backgrounds/*.atlas`.")
    add("")
    for bg in data["bgs"]:
        add(f"- `{bg}`")
    add("")

    # Phone POIs
    pois = data["phone_pois"]
    if pois:
        add("## Phone Map POIs")
        add("")
        add("POI на карте телефона. `# map:allow:POI`, `# map:lock_to:POI`.")
        add("")
        add("| POI | Scene при тапе | Label |")
        add("|---|---|---|")
        for poi, info in sorted(pois.items()):
            add(f"| `{poi}` | `{info['scene']}` | {info['label']} |")
        add("")

    return "\n".join(lines)


def main():
    data = {
        "scenes": scan_scene_files(),
        "knots": scan_ink_knots(),
        "chars": scan_characters(),
        "scene_chars": scan_scene_characters(),
        "bgs": scan_backgrounds(),
        "phone_pois": scan_phone_pois(),
    }
    data["items"], data["flags"] = scan_items_and_flags()

    out_text = render(data)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(out_text, encoding="utf-8")

    print(f"Generated: {OUT.relative_to(ROOT)}")
    print(f"  Scenes:           {len(data['scenes'])}")
    print(f"  Ink knots:        {len(data['knots'])}")
    total_aliases = sum(len(c["keys"]) for c in data["chars"])
    print(f"  Characters:       {len(data['chars'])} ({total_aliases} aliases)")
    print(f"  Scene chars:      "
          f"{sum(len(e) for e in data['scene_chars']['scenes'].values())} "
          f"in {len(data['scene_chars']['scenes'])} group(s)")
    print(f"  Items:            {len(data['items'])}")
    print(f"  Flags:            {len(data['flags'])}")
    print(f"  Backgrounds:      {len(data['bgs'])}")
    print(f"  Phone POIs:       {len(data['phone_pois'])}")
    print(f"  Output size:      {len(out_text) // 1024} KB, {out_text.count(chr(10))} lines")


if __name__ == "__main__":
    main()
