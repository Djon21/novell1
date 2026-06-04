"""
ink_lint.py — валидатор .ink файлов.

Проверяет:
  - Теги (# key:value) — ключ из списка известных, формат значения
  - Knot references (-> name) — что knot существует
  - INCLUDE пути — что файл существует

Использование:
    python tools/ink_lint.py
    python tools/ink_lint.py --ci   # exit(1) при любой ошибке
"""
from __future__ import annotations
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
INK_DIR = ROOT / "main" / "story" / "chapters"

# ---------------------------------------------------------------------------
# Tag registry: key -> validation
#   None        = any value accepted
#   str regex   = value must match
# ---------------------------------------------------------------------------

TAG_SPEC: dict[str, str | None] = {
    "bg":               r"^[a-zA-Z_][\w]*(|none)$",
    "color":            None,
    "speaker":          None,
    "sfx":              None,
    "shake":            None,
    "pulse":            None,
    "flag":             None,
    "set_flag":         None,
    "add_item":         r"^[a-zA-Z_][\w]*$",
    "remove_item":      r"^[a-zA-Z_][\w]*$",
    "item":             r"^(add|remove)\s*:\s*([a-zA-Z_][\w]*)$",
    "quest":            None,
    "bank":             None,
    "note":             None,
    "mail":             None,
    "call":             None,
    "clue":             None,
    "term":             None,
    "meta":             None,
    "loop":             None,
    "adv":              None,
    "ad":               None,
    "hud":              None,
    "day_transition":   None,
    "transit":          None,
    "goto_scene":       None,
    "explore":          None,
    "return_to_scene":  None,
    "splash":           None,
    "scene_char":       None,
    "map":              None,
    "phone":            None,
    "sms":              None,
    "msg":              None,
}

BUILTIN_KNOTS: set[str] = {"DONE", "END", "START"}  # Ink built-in divert targets

CUSTOM_PREFIXES = ["flag_"]

# Глаголы прошедшего времени мужского рода, требующие гендерной альтернации.
# Если слово из этого списка встречается в реплике без {mc_gender}/{npc_gender} — warning.
GENDERED_VERBS = [
    "сказал", "пошёл", "вышел", "пришёл", "вошёл", "нашёл", "прошёл",
    "сделал", "увидел", "понял", "взял", "начал", "узнал", "подумал",
    "оказал", "написал", "услышал", "решил", "ответил", "спросил",
    "встал", "надел", "сел", "открыл", "закрыл", "посмотрел", "обратил",
    "успел", "выпил", "попил",
]

# ---------------------------------------------------------------------------

_error_count = 0
_warning_count = 0


def eprint(*args, **kwargs):
    """Print with error-replacement to handle windows cp1251."""
    text = " ".join(str(a) for a in args)
    try:
        print(text, **kwargs, file=sys.stderr)
    except UnicodeEncodeError:
        print(text.encode("utf-8", errors="replace").decode("utf-8", errors="replace"), **kwargs, file=sys.stderr)


def error(file: Path, line: int, msg: str) -> None:
    global _error_count
    _error_count += 1
    rel = file.relative_to(ROOT)
    eprint(f"ERROR:{rel}:{line}: {msg}")


def warn(file: Path, line: int, msg: str) -> None:
    global _warning_count
    _warning_count += 1
    rel = file.relative_to(ROOT)
    eprint(f"WARN:{rel}:{line}: {msg}")


def looks_custom(key: str) -> bool:
    for p in CUSTOM_PREFIXES:
        if key.startswith(p):
            return True
    return False


def validate_tag(file: Path, line_n: int, line_text: str) -> None:
    """Validate one or more tags on a single line."""
    # Разбиваем строку на отдельные # теги:
    #   # bg:foo # speaker:none  →  ["bg:foo", "speaker:none"]
    parts = re.split(r"(?<!#)\s+#\s+(?=[a-zA-Z_])", line_text.lstrip("#").strip())
    for part in parts:
        part = part.strip()
        if not part:
            continue
        m = re.match(r"^([a-zA-Z_][\w]*)\s*:\s*(.*)$", part)
        if not m:
            m2 = re.match(r"^([a-zA-Z_][\w]*)$", part)
            if m2:
                key = m2.group(1)
                raw_val = ""
            else:
                error(file, line_n, f"cannot parse tag segment: {part!r}")
                continue
        else:
            key = m.group(1)
            raw_val = m.group(2).strip()

        if key in ("TODO", "FIXME", "HACK", "XXX"):
            return

        if key not in TAG_SPEC:
            if looks_custom(key):
                return
            if not raw_val:
                warn(file, line_n, f"unknown tag '{key}'")
            else:
                warn(file, line_n, f"unknown tag '{key}' (value: {raw_val})")
            return

        spec = TAG_SPEC[key]
        if spec is None:
            return  # any value accepted

        if raw_val and not re.match(spec, raw_val):
            warn(file, line_n, f"tag '{key}': value {raw_val!r} — unexpected format (expected {spec})")


def scan_all() -> int:
    all_ink = sorted(INK_DIR.rglob("*.ink"))
    active: list[Path] = []
    for f in all_ink:
        if "_old" in f.name:
            continue
        if "archive" in f.parts:
            continue
        active.append(f)

    # Pass 1: collect knot definitions
    all_knots: set[str] = set(BUILTIN_KNOTS)
    for f in active:
        text = f.read_text(encoding="utf-8", errors="replace")
        for m in re.finditer(r"^===\s*([a-zA-Z_][\w]*)\s*===", text, re.MULTILINE):
            all_knots.add(m.group(1))

    # Pass 2: lint
    _current_speaker = None
    _knot_has_gender_check = False

    for f in active:
        text = f.read_text(encoding="utf-8", errors="replace")
        lines = text.split("\n")
        for i, raw in enumerate(lines, 1):
            stripped = raw.strip()

            # Knot definition — сброс
            if re.match(r"^===\s*[a-zA-Z_][\w]*\s*===", stripped):
                _current_speaker = None
                _knot_has_gender_check = False
                continue

            # Если в knot уже есть {mc_gender}/{npc_gender} — не варним
            if "{mc_gender" in stripped or "{npc_gender" in stripped:
                _knot_has_gender_check = True

            # Track speaker
            if re.match(r"^\s*#\s*speaker\s*:", stripped, re.IGNORECASE):
                m = re.search(r"speaker\s*:\s*(\w+)", stripped, re.IGNORECASE)
                _current_speaker = m.group(1).lower() if m else None

            # INCLUDE
            im = re.match(r"^INCLUDE\s+(.+)$", stripped)
            if im:
                inc_path = im.group(1).strip()
                resolved = (f.parent / inc_path).resolve()
                if not resolved.exists():
                    error(f, i, f"INCLUDE '{inc_path}' not found")
                continue

            # Comment
            if stripped.startswith("//") or stripped.startswith("/*"):
                continue

            # Tag(s)
            if stripped.startswith("#"):
                validate_tag(f, i, stripped)
                continue

            # Knot reference: -> name or -> name.thread
            for rm in re.finditer(r"->\s*([a-zA-Z_][\w.]*)", stripped):
                ref = rm.group(1)
                knot_part = ref.split(".")[0]
                if knot_part not in all_knots:
                    error(f, i, f"reference to unknown knot '{knot_part}'")
                # -> DONE без тега завершения сцены перед ним
                if knot_part == "DONE" and (not raw or raw[0] not in (" ", "\t")):
                    # Разрешённые теги: return_to_scene, explore:, adv:, goto_scene:, phone:map, phone:sms, phone:messenger
                    has_ret = False
                    for lookback in range(max(0, i - 11), i - 1):
                        ln = lines[lookback].strip()
                        if ln.startswith("# return_to_scene") or ln.startswith("# explore:") or ln.startswith("# adv:") or ln.startswith("# goto_scene:") or ln.startswith("# phone:"):
                            has_ret = True
                            break
                    if not has_ret:
                        warn(f, i, f"'-> DONE' without '# return_to_scene' or '# explore:' — story may end instead of returning to scene")

            # Block-form conditional choice: {condition:\n* [choice]
            if stripped.startswith("{") and ":" in stripped and not stripped.startswith("{-"):
                next_line = lines[i] if i < len(lines) else ""
                if next_line.strip().startswith("* ["):
                    warn(f, i, f"block-form conditional '{{...:}}' followed by '* [choice]' — use inline '* {{condition}} [choice]' instead")

            # Gendered verb check: реплики с глаголами прошедшего времени без {mc_gender}/{npc_gender}
            if _current_speaker in ("mc", "npc", "none") and not raw.strip().startswith("*") and not _knot_has_gender_check:
                has_gender = "{mc_gender" in raw or "{npc_gender" in raw
                if not has_gender:
                    for verb in GENDERED_VERBS:
                        match = re.search(r"(?<!\w)" + re.escape(verb) + r"(?!\w)", raw)
                        if match:
                            # Проверяем: есть ли "я" или "ты" в пределах 20 символов ДО глагола?
                            verb_pos = match.start()
                            before = raw[max(0, verb_pos - 25):verb_pos]
                            # Если перед глаголом "он", "она", "они" — третье лицо, пропускаем
                            third_person = bool(re.search(r'(?<!\w)(Он|Она|Оно|Они)\s*$', before))
                            near_pronoun = bool(re.search(r'(?<!\w)(я |ты |мне |тебе )', before)) and not third_person
                            # Если глагол в начале строки — почти всегда опущенное "я"
                            verb_at_start = verb_pos < 10 and not third_person
                            if near_pronoun or verb_at_start:
                                warn(f, i, f"gendered verb '{verb}' found without {{{{mc_gender}}}}/{{{{npc_gender}}}} alternation")
                            break

    eprint(f"\n{len(active)} files scanned, {_error_count} errors, {_warning_count} warnings")
    if "--ci" in sys.argv:
        return 1 if _error_count > 0 else 0
    return 0


if __name__ == "__main__":
    sys.exit(scan_all())
