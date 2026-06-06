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


def get_included_ink_files() -> set[Path]:
    """Return set of .ink files that are INCLUDEd by chapter_01.ink (recursive)."""
    included: set[Path] = set()
    chapter = INK_DIR / "chapter_01.ink"
    if not chapter.exists():
        return included
    text = chapter.read_text(encoding="utf-8", errors="replace")
    for m in re.finditer(r'^\s*INCLUDE\s+(.+)$', text, re.MULTILINE):
        rel = m.group(1).strip().replace("/", "\\")
        fpath = (chapter.parent / rel).resolve()
        if fpath.exists() and "archive" not in fpath.parts and "_old" not in fpath.name:
            included.add(fpath)
    return included

def scan_all() -> int:
    all_ink = sorted(INK_DIR.rglob("*.ink"))
    active: list[Path] = []
    for f in all_ink:
        if "_old" in f.name:
            continue
        if "archive" in f.parts or f.name.startswith("archive_"):
            continue
        active.append(f)
    included_files = get_included_ink_files()

    # Pass 1: collect knot definitions
    all_knots: set[str] = set(BUILTIN_KNOTS)
    for f in active:
        text = f.read_text(encoding="utf-8", errors="replace")
        for m in re.finditer(r"^===\s*([a-zA-Z_][\w]*)\s*===", text, re.MULTILINE):
            all_knots.add(m.group(1))

    # Pass 1a: collect all knot references (for dead knot detection)
    refd_knots: set[str] = set(BUILTIN_KNOTS)
    for f in active:
        text = f.read_text(encoding="utf-8", errors="replace")
        for m in re.finditer(r"->\s*([a-zA-Z_][\w]*)", text):
            refd_knots.add(m.group(1))
    # Also scan scene Lua files for knot references
    scene_dir = ROOT / "main" / "data" / "scenes"
    if scene_dir.exists():
        for sf in sorted(scene_dir.rglob("*.lua")):
            sft = sf.read_text(encoding="utf-8", errors="replace")
            for m in re.finditer(r'''knot\s*=\s*["']([a-zA-Z_][\w]*)["']''', sft):
                refd_knots.add(m.group(1))

    # Pass 1.5: collect all VAR declarations (dead flag detection)
    ink_vars: dict[str, int] = {}
    bootstrap_path = INK_DIR / "00_bootstrap.ink"
    if bootstrap_path.exists():
        bt = bootstrap_path.read_text(encoding="utf-8", errors="replace")
        for m in re.finditer(r'^VAR\s+([a-zA-Z_][\w]*)\s*=', bt, re.MULTILINE):
            ink_vars[m.group(1)] = 0
    # Search for each VAR in all active files
    for fname in active:
        ft = fname.read_text(encoding="utf-8", errors="replace")
        for varname in list(ink_vars.keys()):
            if varname in ft:
                ink_vars[varname] += 1

    # Pass 1.5b: collect all # set_flag:name=true for sync check
    all_set_flags: set[str] = set()
    for f in active:
        text = f.read_text(encoding="utf-8", errors="replace")
        for m in re.finditer(r'#\s*set_flag:\s*([a-zA-Z_][\w]*)\s*=\s*true', text):
            all_set_flags.add(m.group(1))

    # Collect quest tags + phone_map locations
    quest_starts: dict[str, list[tuple[Path, int]]] = {}
    quest_dones: dict[str, list[tuple[Path, int]]] = {}
    quest_invalid: list[tuple[Path, int, str]] = []
    phone_map_lines: list[tuple[Path, int, list[str]]] = []
    set_flag_no_var: list[tuple[Path, int, str]] = []

    for f in active:
        raw_text = f.read_text(encoding="utf-8", errors="replace")
        file_lines = raw_text.split("\n")
        for i, ln in enumerate(file_lines, 1):
            # quest:complete — invalid tag
            if re.search(r'#\s*quest\s*:\s*complete', ln):
                quest_invalid.append((f, i, "quest:complete is invalid — use quest:done"))
                continue
            # quest:start:ID
            sm = re.match(r"^.*#\s*quest\s*:\s*start\s*:\s*([a-zA-Z_][\w]*)\s*", ln)
            if sm:
                qid = sm.group(1)
                quest_starts.setdefault(qid, []).append((f, i))
                continue
            # quest:done:ID
            dm = re.match(r"^.*#\s*quest\s*:\s*done\s*:\s*([a-zA-Z_][\w]*)\s*", ln)
            if dm:
                qid = dm.group(1)
                quest_dones.setdefault(qid, []).append((f, i))
            # # set_flag:name  без VAR в bootstrap
            fm = re.search(r'#\s*set_flag:\s*([a-zA-Z_][\w]*)\s*=', ln)
            if fm:
                flag_name = fm.group(1)
                if flag_name not in ink_vars:
                    set_flag_no_var.append((f, i, flag_name))
            # # phone:map — для проверки map:allow/map:lock_all
            if "# phone:map" in ln:
                # Собираем контекст — 15 строк назад
                ctx_start = max(0, i - 16)
                ctx = file_lines[ctx_start:i]
                phone_map_lines.append((f, i, ctx))

    # Читаем quests.lua для проверки существования квестов
    quest_catalog: set[str] = set()
    quests_lua_path = ROOT / "main" / "scripts" / "quests.lua"
    if quests_lua_path.exists():
        qlua = quests_lua_path.read_text(encoding="utf-8", errors="replace")
        for km in re.finditer(r"^\s*(\w+)\s*=\s*\{", qlua, re.MULTILINE):
            name = km.group(1)
            if name not in ("M", "ORDER_INDEX"):
                quest_catalog.add(name)

    # Pass 2: lint
    _current_speaker = None
    _knot_has_gender_check = False
    _speaker_tag_line = None  # для проверки пустых реплик

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
                _speaker_tag_line = i
                continue

            # Empty speaker dialogue: после # speaker:mc/npc/none идёт -> или # comment без текста
            if _speaker_tag_line is not None and stripped:
                if stripped.startswith("//") or (stripped.startswith("#") and "speaker" not in stripped):
                    continue  # теги и комментарии между speaker и текстом — норма
                if re.match(r"^(->|\* |\})", stripped):
                    warn(f, _speaker_tag_line, f"empty speaker dialogue — no text after '# speaker:' tag (line {i}: '{stripped[:40]}')")
                _speaker_tag_line = None

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

            # Проверка: ~ flag = true без # set_flag:flag=true нигде в коде
            SKIP_SYNC_VARS = {
                "INSIGHT", "TRUST", "SYNC",
                "phone_active", "phone_taken", "can_leave_apt",
                "anomaly_noticed", "npc_opened_up", "phone_history_seeded",
                "date_route_chosen", "used_fallback", "requested_clarification",
                "understood_uncertainty", "decision_deferred",
                "office_strategy", "day_strategy", "anomaly_interpreted",
            }
            vm = re.match(r"^\s*~\s*([a-zA-Z_][\w]*)\s*=\s*true\s*$", stripped)
            if vm:
                varname = vm.group(1)
                if varname not in SKIP_SYNC_VARS and varname not in all_set_flags and varname[:1].islower():
                        warn(f, i, f"'~ {varname} = true' never '# set_flag:{varname}=true' anywhere — flag won't sync to game_state")

            # Pronoun-gender mismatch: "я" с {mc_gender} в speaker:npc или "ты" с {mc_gender} в speaker:mc
            if _current_speaker in ("mc", "npc") and not raw.strip().startswith("*"):
                # Ищем использование {mc_gender} или {npc_gender} на строке
                for gtype, expected_speaker, is_ya in (
                    ("mc_gender", "mc", True),   # "я" + {mc_gender} → должен быть speaker:mc
                    ("mc_gender", "npc", False),  # "ты" + {mc_gender} → должен быть speaker:npc
                    ("npc_gender", "npc", True),   # "я" + {npc_gender} → должен быть speaker:npc
                    ("npc_gender", "mc", False),   # "ты" + {npc_gender} → должен быть speaker:mc
                ):
                    if gtype in raw:
                        pron = "я " if is_ya else "ты "
                        # Проверяем, что перед alternation есть нужный pronoun в пределах строки
                        idx = raw.find("{" + gtype)
                        if idx >= 0:
                            context = raw[max(0, idx - 25):idx]
                            if pron in context and _current_speaker != expected_speaker:
                                tag_name = "{mc_gender}" if gtype == "mc_gender" else "{npc_gender}"
                                expected = "speaker:mc" if expected_speaker == "mc" else "speaker:npc"
                                warn(f, i, f"'{pron}...{tag_name}' in {_current_speaker} — should be in {expected} (the pronoun refers to {'speaker' if is_ya else 'listener'})")

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

    # Dead VAR check: declared in 00_bootstrap.ink but never referenced
    if ink_vars:
        # Служебные/числовые переменные — не варним
        skip_dead = {
            "iteration_number", "iteration_label", "loop_awareness",
            "completed_iterations", "false_endings_count",
            "mc_gender", "npc_gender",
            "mc_name", "mc_name_gen", "mc_name_dat", "mc_name_acc", "mc_name_ins", "mc_name_prep",
            "npc_name", "npc_name_gen", "npc_name_dat", "npc_name_acc", "npc_name_ins", "npc_name_prep",
            "TRUST", "SYNC", "INSIGHT",
            "current_iteration_end",
        }
        for varname, count in sorted(ink_vars.items()):
            if varname in skip_dead:
                continue
            if count <= 1:  # only found in bootstrap itself (declaration)
                warn(bootstrap_path, 0, f"dead VAR '{varname}' — declared but never referenced in any active .ink file")

    # Quest tag checks
    # 1. invalid quest:complete tag
    for f, ln, msg in quest_invalid:
        error(f, ln, msg)
    # 2. quest:start without quest:done
    for qid in sorted(quest_starts):
        if qid not in quest_dones:
            # Skip if quest isn't in catalog (might be removed)
            if qid in quest_catalog:
                for f, ln in quest_starts[qid][:1]:
                    warn(f, ln, f"quest '{qid}' has # quest:start: but NO # quest:done: found")
    # 3. quest:done without quest:start (might be from previous iteration or external)
    for qid in sorted(quest_dones):
        if qid not in quest_starts and qid in quest_catalog:
            for f, ln in quest_dones[qid][:1]:
                warn(f, ln, f"quest '{qid}' has # quest:done: but NO # quest:start: found")

    # 4. # return_to_scene not last tag before -> DONE
    # The `_last_tag_was_return_to_scene` check is done inline during Pass 2

    # 5. Files in New/ directory
    new_dir = INK_DIR / "New"
    if new_dir.exists():
        for nf in sorted(new_dir.rglob("*.ink")):
            warn(nf, 0, f"file in chapters/New/ — not compiled into chapter_01.json (inactive)")

    # Dead knot check: defined but never referenced by -> or Lua scene
    # Dead knot detection: only consider knots from INCLUDEd files
    included_knots: set[str] = set(BUILTIN_KNOTS)
    for f in included_files:
        text = f.read_text(encoding="utf-8", errors="replace")
        for m in re.finditer(r"^===\s*([a-zA-Z_][\w]*)\s*===", text, re.MULTILINE):
            included_knots.add(m.group(1))
    skip_knot_prefixes = ("inv_", "phone_", "msg_", "sms_", "tue_", "mon_", "cafe_", "park_", "shop_", "bar_", "view_")
    # Knots that are legitimately called from Lua (not from Ink ->)
    lua_entry_knots = {"apartment_start", "seed_phone_history"}
    for knot_name in sorted(included_knots - refd_knots - {"DONE", "END", "START"}):
        if knot_name.startswith(skip_knot_prefixes):
            continue
        if knot_name in lua_entry_knots:
            continue
        warn(INK_DIR, 0, f"dead knot '{knot_name}' — defined but never referenced by any -> or Lua scene")

    # 6. Quest ID in ink tags not found in quests.lua catalog
    for qid in sorted(set(list(quest_starts.keys()) + list(quest_dones.keys()))):
        if qid not in quest_catalog and qid not in ("find_phone",):
            for f, ln in (quest_starts.get(qid) or quest_dones.get(qid) or []):
                warn(f, ln, f"quest tag references '{qid}' which is not defined in quests.lua")

    # 7. # set_flag:name without VAR in bootstrap
    skip_novar_suffixes = ("_seen", "_arrived", "_done", "_finished", "_pending", "_started", "_taken")
    for f, ln, flag_name in set_flag_no_var:
        # Флаги, которые не нужно объявлять в Ink (только Lua-side)
        if flag_name in ink_vars:
            continue
        # Флаги-атомы (room_seen, arrived, done) — не требуют VAR
        if any(flag_name.endswith(s) for s in skip_novar_suffixes):
            continue
        # Флаги без VAR, которые всё равно нужны в Lua (explicit skip list)
        if flag_name in ("bedroom_morning_seen", "kitchen_morning_seen", "mon_home_bedroom_seen",
                         "mon_home_hall_seen", "mon_home_kitchen_seen", "tue_home_bedroom_seen",
                         "tue_home_hall_seen", "tue_home_kitchen_seen",
                         "monday_dressed", "monday_washed_up", "work_card_taken",
                         "monday_ready_for_work", "monday_left_home", "monday_finished",
                         "tuesday_pending", "tuesday_morning_started", "tuesday_left_home",
                         "tuesday_consequence_seen", "tuesday_investigation_done",
                         "tuesday_rooftop_reached",
                         "reached_office", "reached_work_district", "left_apartment",
                         "mon_office_error_seen", "mon_office_arrived", "monday_office_finished",
                         "mon_office_started", "monday_mail_read", "monday_folder_taken",
                         "monday_report_page_taken", "monday_case_file_assembled",
                         "monday_case_file_submitted", "monday_checked_in_office",
                         "iteration_001_finished", "cafe_arrived", "cafe_order_done",
                         "cafe_talk_done", "cafe_window_detail_seen", "cafe_shelf_detail_seen",
                         "cafe_backroom_mirror_seen", "cafe_backroom_board_seen",
                         "cafe_backroom_books_seen",
                         "park_npc_at_bench", "park_npc_at_path", "park_npc_bench_shown",
                         "park_npc_path_shown", "sunday_viewpoint_seen",
                         "loop2_invite_after_office_sent",
                         "msg_mila_replied", "msg_artem_replied",
                         "tuesday_log_reviewed", "tuesday_npc_talked", "tuesday_appeal_read",
                         "messenger_work_team_ack", "messenger_prod_bot_questioned",
                         "bar_counter_seen_after_reveal",
                         "cafe_order_coffee", "cafe_order_sweet", "cafe_order_tea"):
            continue
        warn(f, ln, f"'# set_flag:{flag_name}=...' but no 'VAR {flag_name}' in 00_bootstrap.ink")

    # 8. # phone:map without # map:allow or # map:lock_all in context
    for f, ln, ctx in phone_map_lines:
        has_map_setup = False
        for ctx_line in ctx:
            cl = ctx_line.strip()
            if cl.startswith("# map:allow") or cl.startswith("# map:lock_all") or cl.startswith("# map:lock_to"):
                has_map_setup = True
                break
        if not has_map_setup:
            warn(f, ln, f"'# phone:map' without preceding '# map:allow' or '# map:lock_all' — map may show wrong POIs")

    eprint(f"\n{len(active)} files scanned, {_error_count} errors, {_warning_count} warnings")
    if "--ci" in sys.argv:
        return 1 if _error_count > 0 else 0
    return 0


if __name__ == "__main__":
    sys.exit(scan_all())
