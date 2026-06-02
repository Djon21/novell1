# Карта Ink-истории

Визуальная карта скомпилированной Ink-истории `chapter_01.json`.
Сгенерирована скриптом `tools/ink_graph.py` из JSON после `tools\compile_ink.bat chapter_01`.

## Файлы

| Файл | Узлов | Что внутри |
|---|---|---|
| `chapter_01.html` | **54** | **Открой это** — standalone HTML, Mermaid с CDN, зум-кнопки, dark theme |
| `chapter_01.mmd` | 54 | Тот же граф в формате Mermaid (для встраивания в .md) |
| `chapter_01_all.html` | 322 | Все 322 кнота в HTML (для полной картины) |
| `chapter_01_all.mmd` | 322 | Полный граф в Mermaid |
| `chapter_01_by_file.html` | 322 | Полный граф с группировкой по .ink-файлу |
| `chapter_01_by_file.mmd` | 322 | То же в Mermaid |

**Зачем default = 54 узла?** Из 322 кнотов только ~54 реально участвуют в flow (источники или цели `->`). Остальные 268 — это «листья»: показывают текст и завершаются, навигация между ними идёт через Lua (`ui_manager_v2`). На карте истории это шум, а не сигнал.

## Как посмотреть (с рабочего стола)

### 1. Standalone HTML — рекомендую, один клик
Двойной клик по `chapter_01.html` (или `chapter_01_all.html`) → открывается в браузере. Mermaid подгружается с CDN один раз при первом открытии. Зум-кнопки `−` / `+` / `100%` справа сверху.

Требуется интернет при первом открытии (Mermaid.js с jsdelivr). После этого страница закеширована.

### 2. Mermaid Live Editor
Открой https://mermaid.live → вставь содержимое `.mmd` (без обрамляющих ` ``` `) → рендер. Можно экспортнуть в PNG/SVG.

### 3. VS Code
Расширение **Markdown Preview Mermaid Support** (ext:bierner.markdown-mermaid), открой `README.md` (этот файл) — `Ctrl+Shift+V`.

### 4. CLI в PNG/SVG
```bash
npm i -g @mermaid-js/mermaid-cli
mmdc -i docs/diagrams/chapter_01.mmd -o chapter_01.svg
```

> `mmdc` v11+ не понимает ` ```mermaid ` fence (ожидает raw). Перед `mmdc` убери fence:
> ```bash
> (Get-Content docs\diagrams\chapter_01.mmd) -notmatch '^```' | Set-Content $env:TEMP\chapter_01_raw.mmd
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
python tools/ink_graph.py                          # → chapter_01.{html,mmd} (54 узла, default)
python tools/ink_graph.py --all                    # → все 322 кнота
python tools/ink_graph.py --by-file                # → с группировкой по .ink-файлу
python tools/ink_graph.py --from choose_character  # → только достижимые из choose_character
```

## Что видно из карты

- **26 «хабов» с choices** — это узлы с развилками: `loop_entry`, `choose_character`, `park_*_main_talk`, `cafe_*_main_talk`, `sunday_shop_arrival_with_npc`, `mon_commute_entry`, `mon_office_npc_greeting`, ветки `msg_thread_*`. Тут сюжет реально ветвится.
- **54 узла, 67 рёбер** — реальная структура flow. Подавляющее большинство кнотов — листья, в которые Lua заходит через `goto_knot("...")`.
- Это by design: Ink отвечает за текст, Lua (`ui_manager_v2`) — за навигацию между сценами.
