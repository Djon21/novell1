# Карта Ink-истории

Визуальная карта скомпилированной Ink-истории `chapter_01.json`.
Сгенерирована скриптом `tools/ink_graph.py` из JSON после `tools\compile_ink.bat chapter_01`.

## Файлы

| Файл | Что внутри |
|---|---|
| `chapter_01.mmd` | Плоский граф: все 322 кнота, 68 рёбер |
| `chapter_01_by_file.mmd` | То же, с группировкой кнотов по .ink-файлу (28 subgraph'ов) |

## Как посмотреть

### 1. GitHub / GitLab (рекомендую, 0 установки)
Закоммить и открой `.mmd` в репо — Mermaid рендерится нативно в Preview. Либо переименуй в `chapter_01.md` (содержимое уже в ``` ```mermaid ```).

### 2. VS Code (если используешь)
Поставь расширение **Markdown Preview Mermaid Support** (ext:bierner.markdown-mermaid), открой `.mmd` как Markdown preview — `Ctrl+Shift+V`.

### 3. Mermaid Live Editor (мгновенно, без установки)
Открой https://mermaid.live → вставь содержимое `.mmd` (без обрамляющих ` ``` `) → рендер. Можно экспортнуть в PNG/SVG.

### 4. CLI в PNG/SVG (для дизайн-доков)
```bash
npm i -g @mermaid-js/mermaid-cli
mmdc -i docs/diagrams/chapter_01.mmd -o docs/diagrams/chapter_01.svg
```

> **Примечание:** `mmdc` v11+ не понимает ` ```mermaid ` fence (ожидает raw). Перед `mmdc` убери fence:
> ```bash
> Get-Content docs\diagrams\chapter_01.mmd | Where-Object { $_ -ne '```mermaid' -and $_ -ne '```' } | Set-Content $env:TEMP\chapter_01_raw.mmd
> mmdc -i $env:TEMP\chapter_01_raw.mmd -o chapter_01.svg
> ```

## Как читать

- 🟦 `▶ START` (синий) — точка входа из `chapter_01.json` → обычно `choose_character`
- ⬜ обычные узлы — кноты
- 🟩 `done` / 🟥 `end` — терминаторы (DONE / END)
- Стрелка без подписи — `->` divert
- Стрелка с подписью `|"…"|` — choice, текст в кавычках

## Регенерация

```bash
# 1. После правок .ink:
tools\compile_ink.bat chapter_01

# 2. Перегенерировать граф:
python tools/ink_graph.py                      # → chapter_01.mmd
python tools/ink_graph.py --by-file            # → chapter_01_by_file.mmd
```

## Что видно из карты

- **67 рёбер на 322 кнота** — основная навигация идёт через Lua (`ui_manager_v2`), а Ink показывает текст и завершается. Это by design.
- **Хабы с choices** (где рёбра > 1): `loop_entry`, `choose_character`, `park_*_main_talk`, `cafe_*_main_talk`, `sunday_shop_arrival_with_npc`, `mon_commute_entry`, `mon_office_npc_greeting`, ветки `msg_thread_*` — там, где сюжет реально ветвится.
- **Листья** (кноты без исходящих рёбер) — это entry-points, в которые Lua заходит через `goto_knot("...")`.
