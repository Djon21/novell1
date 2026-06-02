# Карта Ink-истории

Визуальная карта скомпилированной Ink-истории `chapter_01.json`.
Сгенерирована скриптом `tools/ink_graph.py` из JSON после `tools\compile_ink.bat chapter_01`.

## Файлы

| Файл | Узлов | Что внутри |
|---|---|---|
| `chapter_01.mmd` | **54** | **Default** — только узлы, участвующие в потоке (хабы + их цели). GitHub-friendly. |
| `chapter_01_all.mmd` | 322 | Все кноты включая листья. Слишком большой для GitHub — открывать через mermaid.live / mmdc. |
| `chapter_01_by_file.mmd` | 322 | То же что `chapter_01_all.mmd`, с группировкой по .ink-файлу (28 subgraph'ов). |

**Зачем default = 54 узла?** Из 322 кнотов только ~54 реально участвуют в flow (источники или цели `->`). Остальные 268 — это «листья»: показывают текст и завершаются, навигация между ними идёт через Lua (`ui_manager_v2`). На карте истории это шум, а не сигнал.

## Как посмотреть

### 1. GitHub / GitLab (рекомендую, 0 установки)
Закоммить и открой `.md` файл с блоком ``` ```mermaid ``` в репо — рендерится нативно в Preview.

### 2. VS Code (если используешь)
Поставь расширение **Markdown Preview Mermaid Support** (ext:bierner.markdown-mermaid), открой этот `README.md` — `Ctrl+Shift+V`.

### 3. Mermaid Live Editor (мгновенно, без установки)
Открой https://mermaid.live → вставь содержимое `.mmd` (без обрамляющих ` ``` `) → рендер. Можно экспортнуть в PNG/SVG.

### 4. CLI в PNG/SVG (для дизайн-доков)
```bash
npm i -g @mermaid-js/mermaid-cli
mmdc -i docs/diagrams/chapter_01.mmd -o chapter_01.svg
```

> **Примечание:** `mmdc` v11+ не понимает ` ```mermaid ` fence (ожидает raw). Перед `mmdc` убери fence:
> ```bash
> (Get-Content docs\diagrams\chapter_01.mmd) -notmatch '^\`\`\`' | Set-Content $env:TEMP\chapter_01_raw.mmd
> mmdc -i $env:TEMP\chapter_01_raw.mmd -o chapter_01.svg
> ```

## Как читать

- 🟦 `▶ START` (синий) — точка входа из `chapter_01.json` → обычно `choose_character`
- ⬜ обычные узлы — кноты, между которыми есть divert или choice
- 🟩 `done` / 🟥 `end` — терминаторы (DONE / END)
- Стрелка без подписи — `->` divert
- Стрелка с подписью `|"…"|` — choice, текст в кавычках

## Регенерация

```bash
# 1. После правок .ink:
tools\compile_ink.bat chapter_01

# 2. Перегенерировать граф:
python tools/ink_graph.py                          # → chapter_01.mmd (54 узла, default)
python tools/ink_graph.py --all                    # → chapter_01.mmd (все 322)
python tools/ink_graph.py --by-file                # → chapter_01_by_file.mmd (с группировкой)
python tools/ink_graph.py --from choose_character  # → только достижимые из choose_character
```

## Что видно из карты

- **26 «хабов» с choices** — это узлы с развилками: `loop_entry`, `choose_character`, `park_*_main_talk`, `cafe_*_main_talk`, `sunday_shop_arrival_with_npc`, `mon_commute_entry`, `mon_office_npc_greeting`, ветки `msg_thread_*`. Тут сюжет реально ветвится.
- **54 узла, 67 рёбер** — реальная структура flow. Подавляющее большинство кнотов — листья, в которые Lua заходит через `goto_knot("...")`.
- Это by design: Ink отвечает за текст, Lua (`ui_manager_v2`) — за навигацию между сценами.
