"""
ink_graph.py — генератор Mermaid-карты Ink-истории.

Парсит скомпилированный chapter_01.json (вывод tools\\compile_ink.bat)
и строит flowchart в формате Mermaid: кноты как узлы, diverts (->)
и choices как рёбра. Опционально кластеризует по .ink файлу.

Использование:
    python tools/ink_graph.py
    python tools/ink_graph.py --by-file          # группировать по файлу
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


def _walk(content: list, knot: str, edges: list[tuple[str, str, str | None]]) -> None:
    """
    Recursive walk over a knot's content. Appends (knot, target, choice_text)
    to edges for every divert found.
    """
    if not isinstance(content, list):
        return
    choice_map = _collect_choices(content)
    for item in content:
        if not isinstance(item, dict):
            continue
        if "->" in item:
            target = item["->"]
            edges.append((knot, target, None))
            continue
        for k, v in item.items():
            if k.startswith("c-") and isinstance(v, list):
                # recursion: each c-N block is a choice continuation
                text = choice_map.get(k)
                # walk it; only the *first* divert gets the choice text
                _walk_c_block(v, knot, text, edges)


def _walk_c_block(content: list, knot: str, choice_text: str | None,
                  edges: list[tuple[str, str, str | None]]) -> None:
    """Walk a c-N block, attaching choice_text to the first divert edge."""
    if not isinstance(content, list):
        return
    choice_map = _collect_choices(content)
    for item in content:
        if not isinstance(item, dict):
            continue
        if "->" in item:
            target = item["->"]
            edges.append((knot, target, choice_text))
            choice_text = None  # only first divert gets the label
            continue
        for k, v in item.items():
            if k.startswith("c-") and isinstance(v, list):
                sub_text = choice_map.get(k) or choice_text
                _walk_c_block(v, knot, sub_text, edges)


def build_graph(json_path: Path) -> tuple[list[str], list[tuple[str, str, str | None]], str | None]:
    """
    Returns (knot_names, edges, entry_target).
    edge = (from_knot, to_knot, choice_text_or_None)
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
    edges: list[tuple[str, str, str | None]] = []
    for name, payload in knots_dict.items():
        if not isinstance(payload, list) or not payload:
            continue
        content = payload[0]
        _walk(content, name, edges)
    return knot_names, edges, entry


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
# Mermaid rendering
# ---------------------------------------------------------------------------

SAFE_ID_RE = re.compile(r"[^A-Za-z0-9_]")


def safe_id(name: str) -> str:
    return "n_" + SAFE_ID_RE.sub("_", name)


def truncate(text: str, n: int = 40) -> str:
    text = text.replace("\n", " ").replace('"', "'").strip()
    return text if len(text) <= n else text[: n - 1] + "…"


NODE_STYLE = {
    "entry": ('((("', '")))', "#start"),
    "knot":  ('["',  '"]',  ""),
    "done":  ('[["', '"]]]', "#done"),
    "end":   ('[["', '"]]]', "#end"),
}


def render_mermaid(knots: list[str],
                   edges: list[tuple[str, str, str | None]],
                   entry: str | None,
                   knot_to_file: dict[str, str] | None,
                   top: int | None) -> str:
    # group knots by file (or single "All knots" group)
    by_file: dict[str, list[str]] = defaultdict(list)
    if knot_to_file:
        for k in knots:
            by_file[knot_to_file.get(k, "unknown")].append(k)
    else:
        by_file["all"] = list(knots)

    # filter: keep only top-N knots by outgoing-edge count
    keep: set[str] | None = None
    if top is not None and top < len(knots):
        out_count = Counter(src for src, _, _ in edges)
        keep = {k for k, _ in out_count.most_common(top)}
        if entry and entry not in keep:
            keep.add(entry)
    else:
        keep = None  # keep everything

    def keep_k(k: str) -> bool:
        return keep is None or k in keep

    lines: list[str] = ["```mermaid", "flowchart LR"]
    lines.append("    classDef start fill:#7ab8ff,stroke:#2563eb,color:#0b1220;")
    lines.append("    classDef done  fill:#86efac,stroke:#16a34a,color:#052e16;")
    lines.append("    classDef end   fill:#fca5a5,stroke:#dc2626,color:#450a0a;")
    lines.append("")

    def emit_node(node_id: str, label: str, kind: str) -> None:
        open_, close_, _ = NODE_STYLE[kind]
        lines.append(f"    {node_id}{open_}{label}{close_}")

    # entry pseudo-node
    if entry and keep_k(entry):
        emit_node("n___start", "▶ START", "entry")
        lines.append("    n___start:::start")

    # group by file
    for file_label in sorted(by_file.keys()):
        file_knots = [k for k in by_file[file_label] if keep_k(k)]
        if not file_knots:
            continue
        # Mermaid subgraphs need a safe id
        sub_id = "sg_" + SAFE_ID_RE.sub("_", file_label)
        lines.append(f"    subgraph {sub_id}[\"{file_label}\"]")
        for k in sorted(file_knots):
            emit_node(safe_id(k), k, "knot")
        lines.append("    end")
    lines.append("")

    # edges
    seen: set[tuple[str, str, str | None]] = set()
    for src, tgt, text in edges:
        if not (keep_k(src) and keep_k(tgt)):
            continue
        key = (src, tgt, text)
        if key in seen:
            continue
        seen.add(key)
        s, t = safe_id(src), safe_id(tgt)
        if text:
            lines.append(f'    {s} -->|"{truncate(text)}"| {t}')
        else:
            lines.append(f"    {s} --> {t}")

    # entry edge
    if entry and keep_k(entry):
        lines.append(f"    n___start --> {safe_id(entry)}")

    # unknown targets (DONE / END / tunnel calls to missing knots) — render as terminal
    known = set(knots)
    extra_targets: set[str] = set()
    for _, tgt, _ in edges:
        if not keep_k(tgt) and tgt not in known:
            extra_targets.add(tgt)
    for tgt in sorted(extra_targets):
        node_id = safe_id(tgt)
        kind = "done" if tgt in ("done", "DONE") else "end"
        emit_node(node_id, tgt, kind)
        # re-link incoming edges that point at it
        for src, t, text in edges:
            if t == tgt and keep_k(src):
                s = safe_id(src)
                if text:
                    lines.append(f'    {s} -->|"{truncate(text)}"| {node_id}')
                else:
                    lines.append(f"    {s} --> {node_id}")
        lines.append(f"    class {node_id} {kind};")

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
    p.add_argument("--from", dest="src", help="Filter: keep only knots reachable from this one (BFS)")
    p.add_argument("--top", type=int, help="Keep top-N knots by outgoing edge count")
    p.add_argument("--print", action="store_true", help="Print to stdout instead of file")
    args = p.parse_args()

    if not args.json.exists():
        print(f"error: {args.json} not found. Run tools\\compile_ink.bat first.", file=sys.stderr)
        return 1

    knots, edges, entry = build_graph(args.json)
    print(f"Loaded {len(knots)} knots, {len(edges)} edges (entry: {entry})", file=sys.stderr)

    if args.src:
        reachable = bfs_reachable(args.src, edges, set(knots))
        if entry and args.src in (entry, "__start__"):
            reachable.add(args.src)
        knots = [k for k in knots if k in reachable]
        edges = [(s, t, x) for s, t, x in edges if s in reachable and t in reachable]
        print(f"Filtered to {len(knots)} knots reachable from {args.src}", file=sys.stderr)

    knot_to_file = map_knots_to_files(INK_DIR) if args.by_file else None
    mmd = render_mermaid(knots, edges, entry, knot_to_file, args.top)

    if args.print:
        sys.stdout.write(mmd)
        return 0

    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(mmd, encoding="utf-8")
    print(f"Wrote {args.out}", file=sys.stderr)
    return 0


def bfs_reachable(start: str, edges: list[tuple[str, str, str | None]],
                  known: set[str]) -> set[str]:
    adj: dict[str, set[str]] = defaultdict(set)
    for s, t, _ in edges:
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
