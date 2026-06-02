"""
ink_graph.py — генератор Mermaid-карты Ink-истории.

Парсит скомпилированный chapter_01.json (вывод tools\\compile_ink.bat)
и строит flowchart в формате Mermaid: кноты как узлы, diverts (->)
и choices как рёбра. Опционально кластеризует по .ink файлу.

По умолчанию выводит только узлы, реально участвующие в потоке
(источники или цели diverts). Это ~54 узла вместо 322 и нормально
рендерится на GitHub. Листья (которые просто показывают текст и
завершаются) — это entry-точки из Lua, на flow-карте они шум.

Использование:
    python tools/ink_graph.py                    # flow-узлы (default, GitHub-friendly)
    python tools/ink_graph.py --all              # ВСЕ 322 кнота (для mermaid.live)
    python tools/ink_graph.py --by-file          # группировать по .ink файлу
    python tools/ink_graph.py --from choose_character
    python tools/ink_graph.py --top 60           # только топ-60 по рёбрам
    python tools/ink_graph.py --out docs/diagrams/chapter_01.mmd
"""
from __future__ import annotations
import argparse
import json
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

# Force UTF-8 stdout on Windows (cp1251 default breaks on Cyrillic)
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")
if hasattr(sys.stderr, "reconfigure"):
    sys.stderr.reconfigure(encoding="utf-8")

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_JSON = ROOT / "main" / "story" / "chapter_01.json"
DEFAULT_OUT = ROOT / "docs" / "diagrams" / "chapter_01.mmd"
INK_DIR = ROOT / "main" / "story" / "chapters"

# ---------------------------------------------------------------------------
# JSON walking
# ---------------------------------------------------------------------------

def _collect_choices(content: list) -> dict[str, str]:
    """
    Find all choice declarations in a content list.

    Layout in compiled JSON:
        "ev","str","^choice text","/str","/ev",{"*": ".^.c-0","flg": N}, ...
    Returns: {"c-0": "choice text", ...}
    """
    out: dict[str, str] = {}
    n = len(content)
    i = 0
    while i < n:
        if (i + 5 < n
                and content[i] == "ev"
                and content[i + 1] == "str"
                and isinstance(content[i + 2], str)
                and content[i + 2].startswith("^")
                and content[i + 3] == "/str"
                and content[i + 4] == "/ev"
                and isinstance(content[i + 5], dict)
                and "*" in content[i + 5]):
            text = content[i + 2].lstrip("^").strip()
            star = content[i + 5]["*"]
            m = re.match(r"\.+\^?\.?(c-\d+)$", star)
            if m:
                out[m.group(1)] = text
            i += 6
        else:
            i += 1
    return out


Edge = tuple[str, str, str, str, str, str | None]
"""
Unified edge: (src, src_kind, tgt, tgt_kind, kind, label)
  src, tgt  — raw node names (knot name or scene id)
  src_kind, tgt_kind in {"knot", "scene"}
  kind in {"ink", "ink_choice", "nav", "hotspot", "on_enter"}
  label — choice text, hotspot label, or None
"""

KNOT = "knot"
SCENE = "scene"
INK = "ink"
INK_CHOICE = "ink_choice"
NAV = "nav"
HOTSPOT = "hotspot"
ON_ENTER = "on_enter"
SCENE_JUMP = "scene_jump"  # # goto_scene:X or # explore:X in ink → runtime switches scene


def _extract_knot_content(payload) -> list | None:
    """
    A knot's payload in the compiled JSON is one of:

      1. [content_list, params]            — content lives in payload[0]
         e.g. loop_entry, choose_character
      2. [item, item, ..., 'end'|'done', None]   — payload IS the content list
         e.g. day_start, sunday_start_splash

    Return the list to walk, or None if the payload is malformed.
    """
    if not isinstance(payload, list) or not payload:
        return None
    if isinstance(payload[0], list):
        return payload[0]
    # payload is the content list itself; drop trailing terminators
    items = [x for x in payload if x is not None and x not in ("end", "done", "END", "DONE")]
    return items or None


def _walk(content: list, knot: str, edges: list[Edge]) -> None:
    """
    Recursive walk over a knot's content. Appends (knot, "knot", target, "knot", "ink", None)
    edges for every divert found.
    """
    if not isinstance(content, list):
        return
    choice_map = _collect_choices(content)
    for item in content:
        if not isinstance(item, dict):
            continue
        if "->" in item:
            target = item["->"]
            edges.append((knot, KNOT, target, KNOT, INK, None))
            continue
        for k, v in item.items():
            if k.startswith("c-") and isinstance(v, list):
                # recursion: each c-N block is a choice continuation
                text = choice_map.get(k)
                # walk it; only the *first* divert gets the choice text
                _walk_c_block(v, knot, text, edges)


def _walk_c_block(content: list, knot: str, choice_text: str | None,
                  edges: list[Edge]) -> None:
    """Walk a c-N block, attaching choice_text to the first divert edge."""
    if not isinstance(content, list):
        return
    choice_map = _collect_choices(content)
    for item in content:
        if not isinstance(item, dict):
            continue
        if "->" in item:
            target = item["->"]
            edges.append((knot, KNOT, target, KNOT, INK_CHOICE, choice_text))
            choice_text = None  # only first divert gets the label
            continue
        for k, v in item.items():
            if k.startswith("c-") and isinstance(v, list):
                sub_text = choice_map.get(k) or choice_text
                _walk_c_block(v, knot, sub_text, edges)


def build_graph(json_path: Path, scenes_dir: Path | None = None
                ) -> tuple[list[str], list[str], list[Edge], str | None]:
    """
    Returns (knot_names, scene_ids, edges, entry_target).
    Edge = (src, src_kind, tgt, tgt_kind, kind, label).
    """
    with json_path.open("r", encoding="utf-8") as f:
        data = json.load(f)

    root = data["root"]
    main_content = root[0]
    knots_dict = root[2]

    # entry: first divert in mainContent
    entry: str | None = None
    if isinstance(main_content, list):
        for item in main_content:
            if isinstance(item, dict) and "->" in item:
                entry = item["->"]
                break

    knot_names = list(knots_dict.keys())
    edges: list[Edge] = []
    for name, payload in knots_dict.items():
        content = _extract_knot_content(payload)
        if content is None:
            continue
        _walk(content, name, edges)

    # scan .ink source for # goto_scene:X and # explore:X scene-jump tags.
    # These are deferred commands interpreted by the Lua runtime
    # (dialogue_manager_ink.lua) after the knot's paragraphs finish — so the
    # node-level ink diverts alone don't show the next scene transition.
    if scenes_dir is not None:
        for sj in _parse_scene_jumps_from_ink(INK_DIR):
            edges.append(sj)

    scene_ids: list[str] = []
    if scenes_dir is not None:
        scene_ids, scene_edges = parse_scenes(scenes_dir)
        for src, kind, tgt, label in scene_edges:
            if kind == NAV:
                edges.append((src, SCENE, tgt, SCENE, NAV, label))
            elif kind == HOTSPOT:
                edges.append((src, SCENE, tgt, KNOT, HOTSPOT, label))
            elif kind == ON_ENTER:
                edges.append((src, SCENE, tgt, KNOT, ON_ENTER, label))

    return knot_names, scene_ids, edges, entry


# ---------------------------------------------------------------------------
# Source-file mapping (best-effort, scans .ink files for === knot === defs)
# ---------------------------------------------------------------------------

KNOT_DEF_RE = re.compile(r"^===\s*([a-zA-Z_][\w]*)\s*===", re.MULTILINE)


def map_knots_to_files(ink_dir: Path) -> dict[str, str]:
    """
    Returns {knot_name: relative_path_to_ink_file}.
    Later .ink files in INCLUDE order override (unlikely, but safe).
    """
    out: dict[str, str] = {}
    if not ink_dir.exists():
        return out
    for f in sorted(ink_dir.rglob("*.ink")):
        try:
            text = f.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        for m in KNOT_DEF_RE.finditer(text):
            out.setdefault(m.group(1), str(f.relative_to(ink_dir)).replace("\\", "/"))
    return out


# ---------------------------------------------------------------------------
# Lua scene parsing
# ---------------------------------------------------------------------------

SCENES_DIR = ROOT / "main" / "data" / "scenes"

# Factory functions in _shared.lua that produce hotspot actions.
# nav_scene has .scene (goto_scene action); the rest have .knot (ink_knot action).
NAV_SCENE_FACTORY = "nav_scene"
INK_KNOT_FACTORIES = {"nav_ink", "inspect", "pickup", "use", "story", "item_target", "leave"}


def _find_balanced_block(text: str, start_idx: int) -> tuple[int, int] | None:
    """Given text and the index of an opening '{', return (start, end) indices
    of the whole `{ ... }` block (end is index of matching closing brace)."""
    depth = 0
    i = start_idx
    in_string = False
    string_quote = ""
    while i < len(text):
        c = text[i]
        # crude string handling
        if in_string:
            if c == "\\":
                i += 2
                continue
            if c == string_quote:
                in_string = False
        else:
            if c in ('"', "'"):
                in_string = True
                string_quote = c
            elif c == "{":
                depth += 1
            elif c == "}":
                depth -= 1
                if depth == 0:
                    return (start_idx, i)
        i += 1
    return None


def _extract_string_field(block: str, field: str) -> str | None:
    """Find `field = "value"` inside a `{ ... }` block, return value or None."""
    m = re.search(rf'\b{re.escape(field)}\s*=\s*"([^"]*)"', block)
    return m.group(1) if m else None


def _parse_scene_file(path: Path) -> tuple[list[str], list[tuple[str, str, str, str | None]]]:
    """
    Parse one scene .lua file. Returns:
        scene_ids: top-level scene_id keys
        edges: list of (scene_id, edge_kind, target, label) where
            edge_kind in {"nav", "hotspot", "on_enter"}
            target is scene_id (for nav) or knot name (for hotspot/on_enter)
            label is the hotspot label, or None for on_enter
    """
    text = path.read_text(encoding="utf-8", errors="replace")
    scene_ids: list[str] = []
    edges: list[tuple[str, str, str, str | None]] = []

    # A scene table is identified by the presence of scene-shape fields:
    # typically `bg = ...` AND (`label = ...` OR `hotspots = ...`).
    # The candidate key pattern is 4-space-indent `<word> = {` (matches both
    # direct `return { foo = {...} }` style and `local foo = { ... } return { foo }`).
    for m in re.finditer(r"^    ([a-z][a-z0-9_]*)\s*=\s*\{", text, re.MULTILINE):
        scene_id = m.group(1)
        block_start = m.end() - 1  # index of `{`
        block_range = _find_balanced_block(text, block_start)
        if not block_range:
            continue
        _, block_end = block_range
        body = text[block_start:block_end + 1]

        # Validate: must have `bg =` (or similar scene-shape markers) to be
        # a real scene, not `on_enter = {` / `hotspots = {` / `rect = {` etc.
        if not re.search(r"\bbg\s*=", body):
            continue
        if not re.search(r"\b(label|hotspots)\s*=", body):
            continue

        scene_ids.append(scene_id)

        # on_enter.knot
        on_enter_match = re.search(r"on_enter\s*=\s*\{", body)
        if on_enter_match:
            oe_start = on_enter_match.end() - 1
            oe_range = _find_balanced_block(body, oe_start)
            if oe_range:
                _, oe_end = oe_range
                oe_body = body[oe_start:oe_end + 1]
                knot = _extract_string_field(oe_body, "knot")
                if knot:
                    edges.append((scene_id, "on_enter", knot, None))

        # Hotspot blocks: s.nav_scene{...}, s.inspect{...}, etc.
        # Find each s.<factory>{ and extract fields.
        for hs in re.finditer(r"\bs\.(nav_scene|nav_ink|inspect|pickup|use|story|item_target|leave)\s*\{", body):
            factory = hs.group(1)
            hs_start = hs.end() - 1
            hs_range = _find_balanced_block(body, hs_start)
            if not hs_range:
                continue
            _, hs_end = hs_range
            hs_body = body[hs_start:hs_end + 1]

            label = _extract_string_field(hs_body, "label")

            if factory == NAV_SCENE_FACTORY:
                target_scene = _extract_string_field(hs_body, "scene")
                if target_scene:
                    edges.append((scene_id, "nav", target_scene, label))
            elif factory in INK_KNOT_FACTORIES:
                target_knot = _extract_string_field(hs_body, "knot")
                if target_knot:
                    edges.append((scene_id, "hotspot", target_knot, label))

    return scene_ids, edges


def parse_scenes(scenes_dir: Path) -> tuple[list[str], list[tuple[str, str, str, str | None]]]:
    """
    Walk scenes_dir, parse each .lua file, merge results.
    Returns (scene_ids, edges) across all files.

    Aliases (e.g. apartment_bedroom_morning = apartment_bedroom) are kept as
    separate scene_ids pointing to themselves — they're real aliases Lua
    resolves at runtime, and the graph should show the user-facing id.
    """
    all_ids: list[str] = []
    all_edges: list[tuple[str, str, str, str | None]] = []
    if not scenes_dir.exists():
        return all_ids, all_edges
    for f in sorted(scenes_dir.glob("*.lua")):
        if f.name.startswith("_"):
            continue  # skip _shared.lua
        try:
            ids, edges = _parse_scene_file(f)
        except (OSError, UnicodeDecodeError):
            continue
        all_ids.extend(ids)
        all_edges.extend(edges)
    return all_ids, all_edges


# ---------------------------------------------------------------------------
# .ink source scanning for scene-jump tags
# ---------------------------------------------------------------------------

SCENE_JUMP_TAG_RE = re.compile(
    r"^\s*#\s*(?:goto_scene|explore)\s*:\s*([a-zA-Z_][\w]*)",
    re.MULTILINE,
)
KNOT_HEAD_RE = re.compile(r"^===\s*([a-zA-Z_][\w]*)\s*===", re.MULTILINE)


def _is_active_ink(path: Path) -> bool:
    """Same exclusion rules as tools/ink_lint.py: skip _old files and archive/."""
    if "_old" in path.name:
        return False
    if "archive" in path.parts:
        return False
    return True


def _parse_scene_jumps_from_ink(ink_dir: Path) -> list[Edge]:
    """
    Scan active .ink files for `# goto_scene:SCENE` and `# explore:SCENE` tags.

    These are deferred commands consumed by the Lua runtime
    (dialogue_manager_ink.lua -> "enter_scene" scene_bucket) after the knot
    finishes its paragraphs. Each tag inside a knot produces an edge
    (knot, "knot", scene_id, "scene", "scene_jump", None).

    If a knot has multiple jumps (different code branches), we add one edge
    per (knot, scene) pair. Knot is duplicated on the source side, which
    is fine — Mermaid allows multiple outgoing edges from one node.
    """
    edges: list[Edge] = []
    if not ink_dir.exists():
        return edges
    for f in sorted(ink_dir.rglob("*.ink")):
        if not _is_active_ink(f):
            continue
        try:
            text = f.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        # Find all knot headers and the start offset of each block
        # so we can map each tag to its enclosing knot.
        knot_starts = [(m.group(1), m.start()) for m in KNOT_HEAD_RE.finditer(text)]
        # Also note the end of each block (start of next knot, or EOF)
        for i, (knot_name, start) in enumerate(knot_starts):
            end = knot_starts[i + 1][1] if i + 1 < len(knot_starts) else len(text)
            body = text[start:end]
            for tm in SCENE_JUMP_TAG_RE.finditer(body):
                scene_id = tm.group(1)
                edges.append((knot_name, KNOT, scene_id, SCENE, SCENE_JUMP, None))
    return edges


# ---------------------------------------------------------------------------
# Mermaid rendering
# ---------------------------------------------------------------------------

SAFE_ID_RE = re.compile(r"[^A-Za-z0-9_]")


def safe_id(name: str) -> str:
    return "n_" + SAFE_ID_RE.sub("_", name)


def truncate(text: str, n: int = 40) -> str:
    # Mermaid treats some chars as syntax inside labels:
    #   " quotes open/close label, < > render as HTML, | ends the edge label,
    #   # starts a comment, [ ] { } ( ) open node shapes. Strip them all.
    text = (text.replace("\n", " ")
                .replace('"', "'")
                .replace("|", "/")
                .replace("<", "")
                .replace(">", ""))
    # collapse runs of whitespace
    text = " ".join(text.split()).strip()
    return text if len(text) <= n else text[: n - 1] + "…"


NODE_STYLE = {
    "entry": ('((("', '")))', "kstart"),
    "knot":  ('["',  '"]',  "kknot"),
    "scene": ('("',  '")',  "kscene"),
    "done":  ('[["', '"]]]', "kdone"),
    "end":   ('[["', '"]]]', "kend"),
}


def wrap_html(mmd: str, title: str = "Ink graph") -> str:
    """Wrap a ```mermaid ...``` block in a standalone HTML file.

    Uses mermaid.js from a CDN; the user just double-clicks the .html to view.
    No build step, no npm, no server.
    """
    # Strip outer fence; we'll re-embed inside a <pre class="mermaid"> which
    # the Mermaid library will pick up and render in place.
    body = mmd
    if body.startswith("```mermaid"):
        body = body[len("```mermaid"):]
    if body.rstrip().endswith("```"):
        body = body.rstrip()[:-3]
    body = body.strip()

    return f"""<!doctype html>
<html lang="ru">
<head>
<meta charset="utf-8">
<title>{title}</title>
<style>
  body {{ margin: 0; padding: 24px; background: #0f172a; color: #e2e8f0;
          font: 14px/1.4 -apple-system, "Segoe UI", system-ui, sans-serif; }}
  h1 {{ font-size: 18px; margin: 0 0 12px; }}
  .legend {{ color: #94a3b8; margin-bottom: 16px; }}
  .mermaid {{ background: #1e293b; border-radius: 8px; padding: 16px;
              overflow: auto; max-height: 90vh; }}
  .controls {{ position: fixed; top: 12px; right: 12px; display: flex; gap: 8px; }}
  .controls button {{ background: #1e293b; color: #e2e8f0; border: 1px solid #334155;
                       border-radius: 4px; padding: 4px 10px; cursor: pointer; }}
  .controls button:hover {{ background: #334155; }}
</style>
</head>
<body>
  <h1>{title}</h1>
  <div class="legend">
    <strong>Upstream:</strong> <code>tools/ink_graph.py</code>
    &middot; <strong>Source:</strong> <code>main/story/chapter_01.json</code>
  </div>
  <div class="controls">
    <button onclick="document.querySelector('.mermaid').style.zoom =
      (parseFloat(document.querySelector('.mermaid').style.zoom || 1) * 0.9).toString()">−</button>
    <button onclick="document.querySelector('.mermaid').style.zoom =
      (parseFloat(document.querySelector('.mermaid').style.zoom || 1) * 1.1).toString()">+</button>
    <button onclick="document.querySelector('.mermaid').style.zoom = '1'">100%</button>
  </div>
  <pre class="mermaid">
{body}
  </pre>
  <script type="module">
    import mermaid from "https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs";
    mermaid.initialize({{
      startOnLoad: true,
      theme: "dark",
      flowchart: {{ htmlLabels: true, curve: "basis" }},
      securityLevel: "loose",
    }});
  </script>
</body>
</html>
"""


def render_mermaid(knots: list[str],
                   scenes: list[str],
                   edges: list[Edge],
                   entry: str | None,
                   knot_to_file: dict[str, str] | None,
                   top: int | None) -> str:
    # --top filter: keep only top-N nodes by outgoing edge count
    keep: set[str] | None = None
    if top is not None:
        out_count: Counter[str] = Counter(src for src, _, _, _, _, _ in edges)
        # count from both knots and scenes
        all_nodes = set(knots) | set(scenes)
        keep = {n for n, _ in out_count.most_common(top)}
        if entry:
            keep.add(entry)
        # If we filtered too aggressively, leave as is (will be a sparse graph)

    def keep_n(name: str) -> bool:
        return keep is None or name in keep

    # classify unknown targets (DONE / END)
    known_knots = set(knots)
    known_scenes = set(scenes)
    extra_knots: set[str] = set()
    extra_scenes: set[str] = set()
    for src, sk, tgt, tk, kind, _ in edges:
        if sk == KNOT and not keep_n(src):
            continue
        if tk == KNOT and not keep_n(tgt) and tgt not in known_knots and tgt not in ("done", "DONE", "end", "END"):
            extra_knots.add(tgt)
        if tk == SCENE and not keep_n(tgt) and tgt not in known_scenes:
            extra_scenes.add(tgt)
    # also terminals
    for src, sk, tgt, tk, kind, _ in edges:
        if sk == KNOT and not keep_n(src):
            continue
        if tgt in ("done", "DONE") and (keep_n(src) or not keep):
            extra_knots.add(tgt)
        if tgt in ("end", "END") and (keep_n(src) or not keep):
            extra_knots.add(tgt)

    lines: list[str] = ["```mermaid", "flowchart LR"]
    # Class defs (kstart/kdone/kend are Mermaid-safe, 'start'/'done'/'end' are reserved)
    lines.append("    classDef kstart fill:#7ab8ff,stroke:#2563eb,color:#0b1220,stroke-width:2px;")
    lines.append("    classDef kdone  fill:#86efac,stroke:#16a34a,color:#052e16,stroke-width:2px;")
    lines.append("    classDef kend   fill:#fca5a5,stroke:#dc2626,color:#450a0a,stroke-width:2px;")
    lines.append("    classDef kknot  fill:#1e293b,stroke:#64748b,color:#e2e8f0;")
    lines.append("    classDef kscene fill:#312e81,stroke:#a78bfa,color:#ede9fe,stroke-width:2px;")
    lines.append("")

    def emit_node(node_id: str, label: str, kind: str, class_name: str | None = None) -> None:
        open_, close_, default_cls = NODE_STYLE[kind]
        lines.append(f"    {node_id}{open_}{label}{close_}")
        cls = class_name or default_cls
        if cls:
            lines.append(f"    class {node_id} {cls};")

    def id_for(name: str, kind: str) -> str:
        if kind == SCENE:
            return "s_" + SAFE_ID_RE.sub("_", name)
        return "n_" + SAFE_ID_RE.sub("_", name)

    # ---------- entry pseudo-node ----------
    if entry:
        emit_node("n___start", "▶ START", "entry")

    # ---------- scene nodes (always first / outer) ----------
    scenes_to_show = [s for s in scenes if keep_n(s)]
    if scenes_to_show:
        lines.append("    subgraph sg_scenes[\"Lua scenes (point-and-click)\"]")
        for s in sorted(scenes_to_show):
            emit_node(id_for(s, SCENE), s, "scene")
        lines.append("    end")
        lines.append("")

    # ---------- knot nodes (optionally grouped by .ink file) ----------
    knots_to_show = [k for k in knots if keep_n(k)]
    if knot_to_file and knots_to_show:
        by_file: dict[str, list[str]] = defaultdict(list)
        for k in knots_to_show:
            by_file[knot_to_file.get(k, "unknown")].append(k)
        for file_label in sorted(by_file.keys()):
            file_knots = sorted(by_file[file_label])
            if not file_knots:
                continue
            sub_id = "sg_" + SAFE_ID_RE.sub("_", file_label)
            lines.append(f"    subgraph {sub_id}[\"{file_label}\"]")
            for k in file_knots:
                emit_node(id_for(k, KNOT), k, "knot")
            lines.append("    end")
        lines.append("")
    elif knots_to_show:
        # flat: emit all knots
        for k in sorted(knots_to_show):
            emit_node(id_for(k, KNOT), k, "knot")
        lines.append("")

    # ---------- terminal pseudo-nodes (DONE / END / unknown) ----------
    for tgt in sorted(extra_knots):
        if tgt in ("done", "DONE"):
            emit_node(id_for(tgt, KNOT), "DONE", "done")
        elif tgt in ("end", "END"):
            emit_node(id_for(tgt, KNOT), "END", "end")
        else:
            # unknown knot referenced from kept source — emit as plain knot
            emit_node(id_for(tgt, KNOT), tgt, "knot")
    for tgt in sorted(extra_scenes):
        emit_node(id_for(tgt, SCENE), tgt + " (?)", "scene")
    lines.append("")

    # ---------- edges ----------
    seen: set[tuple] = set()
    edge_idx = 0
    for src, sk, tgt, tk, kind, text in edges:
        if sk == KNOT and not keep_n(src):
            continue
        if tk == KNOT and not keep_n(tgt):
            continue
        if sk == SCENE and not keep_n(src):
            continue
        if tk == SCENE and not keep_n(tgt):
            continue
        key = (src, tgt, kind, text)
        if key in seen:
            continue
        seen.add(key)
        s = id_for(src, sk)
        t = id_for(tgt, tk)

        # edge syntax (different arrow types visually distinguish the four flows)
        if kind in (HOTSPOT, ON_ENTER):
            arrow = "-.->"   # scene → knot: dashed
        elif kind == NAV:
            arrow = "==>"    # scene → scene: thick
        elif kind == SCENE_JUMP:
            arrow = "-.->"   # knot → scene (ink # goto_scene / # explore): dashed
        else:
            arrow = "-->"    # knot → knot (ink flow)

        if text:
            lbl = truncate(text)
            lines.append(f"    {s} {arrow}|\"{lbl}\"| {t}")
        else:
            lines.append(f"    {s} {arrow} {t}")
        edge_idx += 1

    # ---------- entry edge ----------
    if entry and (keep_n(entry) or keep is None):
        lines.append(f"    n___start --> {id_for(entry, KNOT)}")

    lines.append("```")
    lines.append("")
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main() -> int:
    p = argparse.ArgumentParser(description="Generate a Mermaid flowchart of the Ink story.")
    p.add_argument("--json", type=Path, default=DEFAULT_JSON, help="Compiled ink JSON path")
    p.add_argument("--out",  type=Path, default=DEFAULT_OUT,  help="Output .mmd file path")
    p.add_argument("--by-file", action="store_true", help="Cluster knots by source .ink file")
    p.add_argument("--from", dest="src", help="Filter: keep only nodes reachable from this one (BFS)")
    p.add_argument("--top", type=int, help="Keep top-N nodes by outgoing edge count")
    p.add_argument("--all", action="store_true",
                   help="Include ALL knots (default: only those involved in flow). "
                        "Full graph with all 322 knots is large.")
    p.add_argument("--ink-only", action="store_true",
                   help="Ink-only graph: skip scene parsing, just diverts/choices.")
    p.add_argument("--print", action="store_true", help="Print to stdout instead of file")
    p.add_argument("--html", action="store_true",
                   help="Wrap the diagram in a standalone HTML file (Mermaid from CDN, "
                        "no npm, no internet beyond loading the library).")
    args = p.parse_args()

    if not args.json.exists():
        print(f"error: {args.json} not found. Run tools\\compile_ink.bat first.", file=sys.stderr)
        return 1

    scenes_dir = None if args.ink_only else SCENES_DIR
    knots, scenes, edges, entry = build_graph(args.json, scenes_dir=scenes_dir)
    print(f"Loaded {len(knots)} knots, {len(scenes)} scenes, {len(edges)} edges "
          f"(entry: {entry})", file=sys.stderr)

    # Default: only knots involved in actual flow (source or target of a divert).
    # Other ~268 are leaf "show text and end" knots driven by Lua entry points.
    if not args.all and not args.top:
        involved: set[str] = set()
        for s, _sk, t, _tk, _k, _l in edges:
            involved.add(s)
            involved.add(t)
        if entry:
            involved.add(entry)
        if involved:
            knots = [k for k in knots if k in involved]
            scenes = [s for s in scenes if s in involved]
            edges = [e for e in edges if e[0] in involved and e[2] in involved]
            print(f"Filtered to {len(knots)} flow knots, {len(scenes)} scenes "
                  f"(use --all for all 322 knots)", file=sys.stderr)

    if args.src:
        reachable = bfs_reachable(args.src, edges, set(knots) | set(scenes))
        if entry and args.src in (entry, "__start__"):
            reachable.add(args.src)
        knots = [k for k in knots if k in reachable]
        scenes = [s for s in scenes if s in reachable]
        edges = [e for e in edges if e[0] in reachable and e[2] in reachable]
        print(f"Filtered to {len(knots)} knots, {len(scenes)} scenes "
              f"reachable from {args.src}", file=sys.stderr)

    knot_to_file = map_knots_to_files(INK_DIR) if args.by_file else None
    mmd = render_mermaid(knots, scenes, edges, entry, knot_to_file, args.top)

    if args.print:
        sys.stdout.write(mmd)
        return 0

    if args.html:
        html = wrap_html(mmd, title=args.out.stem)
        args.out = args.out.with_suffix(".html")
    else:
        html = mmd

    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(html, encoding="utf-8")
    print(f"Wrote {args.out}", file=sys.stderr)
    return 0


def bfs_reachable(start: str, edges: list[Edge], known: set[str]) -> set[str]:
    adj: dict[str, set[str]] = defaultdict(set)
    for s, _sk, t, _tk, _k, _l in edges:
        if s in known and t in known:
            adj[s].add(t)
    seen: set[str] = {start}
    frontier = [start]
    while frontier:
        nxt = []
        for n in frontier:
            for m in adj[n]:
                if m not in seen:
                    seen.add(m)
                    nxt.append(m)
        frontier = nxt
    return seen


if __name__ == "__main__":
    sys.exit(main())
