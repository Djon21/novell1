"""Remove terminal line nodes v_term_l2 through v_term_l18 from phone_term.gui."""

PATH = r"C:\Users\GoldiM\novell1\AVOS\AVOS_G\main\gui\components_v2\phone_term.gui"

with open(PATH, "r", encoding="utf-8") as f:
    text = f.read()


def remove_node_block(text, node_id):
    """Remove a nodes { ... } block containing id: 'node_id'."""
    pattern = f'id: "{node_id}"'
    idx = text.find(pattern)
    if idx == -1:
        return text, False

    # Walk backward to find the start of this block
    start = text.rfind("nodes {", 0, idx)
    if start == -1:
        return text, False

    # Walk forward counting braces to find block end
    depth = 0
    end = start
    for i in range(start, len(text)):
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
            if depth == 0:
                end = i + 1
                break

    return text[:start] + text[end:], True


original_len = len(text)

for i in range(2, 19):
    text, ok = remove_node_block(text, f"v_term_l{i}")
    print(f"  v_term_l{i}: {'OK' if ok else 'FAILED'}")

# Clean up blank lines
import re
text = re.sub(r"\n{3,}", "\n\n", text)

with open(PATH, "w", encoding="utf-8") as f:
    f.write(text)

print(f"\n{original_len} -> {len(text)} bytes ({len(text) - original_len:+d})")
