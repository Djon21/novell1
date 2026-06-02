# Карта Ink + Lua истории

Визуальная карта `chapter_01` — **объединяет Ink-кноты и Lua-сцены**.
Ink показывает только текст, навигация между сценами идёт через Lua
(`ui_manager_v2` / `scenes.lua`). Граф ниже показывает обе части.

Сгенерировано `tools/ink_graph.py` из `main/story/chapter_01.json`
+ `main/data/scenes/*.lua` после `tools\compile_ink.bat chapter_01`.

## Файлы

| Файл | Узлов | Что внутри |
|---|---|---|
| `chapter_01.html` | **180** | **Открой это** — standalone HTML, Mermaid с CDN, зум-кнопки, dark theme. Default. |
| `chapter_01.mmd` | 180 | Тот же граф в Mermaid |
| `chapter_01_all.html` | 345 | Все 322 кнота + 23 сцены (для полной картины) |
| `chapter_01_all.mmd` | 345 | То же в Mermaid |
| `chapter_01_by_file.html` | 345 | Все узлы, кноты сгруппированы по .ink-файлу, сцены в отдельной подгруппе |
| `chapter_01_by_file.mmd` | 345 | То же в Mermaid |

**Зачем default = 180 узлов?** Из 322 ink-кнотов только 157 участвуют в flow (источники или цели `->`). Остальные 165 — листья, на которые Lua заходит через `goto_knot`. В граф они не нужны — 180 узлов это сцены (23) + flow-кноты (157).

## Как читать граф

| Элемент | Значение |
|---|---|
| 🟦 `▶ START` | Точка входа `choose_character` (через Ink) |
| 🟪 Скруглённый узел `s_*` | Lua-сцена (point-and-click) |
| ⬜ Прямоугольный узел `n_*` | Ink-кнот |
| `-->` сплошная | Ink divert (knot → knot) |
| `==>` толстая | scene navigation (scene → scene) |
| `-.->` пунктирная | scene → knot (hotspot или on_enter) |
| Подпись на ребре | Choice text / hotspot label |
| 🟩 `DONE` | Терминатор (knot завершается) |

## Как посмотреть (локально)

### 1. Standalone HTML — рекомендую, один клик
Двойной клик по `chapter_01.html` (или `chapter_01_all.html`) → открывается в браузере. Mermaid подгружается с CDN. Зум-кнопки `−` / `+` / `100%` справа сверху.

Требуется интернет при первом открытии (Mermaid.js с jsdelivr).

### 2. Mermaid Live Editor
https://mermaid.live → вставь содержимое `.mmd` (без ` ``` `) → рендер. Можно экспортнуть в PNG/SVG.

### 3. VS Code
Расширение **Markdown Preview Mermaid Support** (bierner.markdown-mermaid) → открой `README.md` (этот) → `Ctrl+Shift+V`.

### 4. CLI в PNG/SVG
```bash
npm i -g @mermaid-js/mermaid-cli
mmdc -i docs/diagrams/chapter_01.mmd -o chapter_01.svg
```

> `mmdc` v11+ не понимает ` ```mermaid ` fence. Перед `mmdc` убери fence:
> ```bash
> (Get-Content docs\diagrams\chapter_01.mmd) -notmatch '^```' | Set-Content $env:TEMP\chapter_01_raw.mmd
> mmdc -i $env:TEMP\chapter_01_raw.mmd -o chapter_01.svg
> ```

## Регенерация

```bash
# 1. После правок .ink или scenes:
tools\compile_ink.bat chapter_01

# 2. Перегенерировать граф:
python tools/ink_graph.py                              # → chapter_01.{html,mmd} (default: 180 узлов)
python tools/ink_graph.py --all                        # → все 322 ink-кнота + сцены
python tools/ink_graph.py --ink-only                   # → только Ink, без сцен
python tools/ink_graph.py --by-file                    # → с группировкой по .ink-файлу
python tools/ink_graph.py --from apartment_hub         # → только достижимые из сцены apartment_hub
python tools/ink_graph.py --top 40                     # → топ-40 узлов по исходящим рёбрам
```

## Что видно из карты

Граф показывает полную структуру сюжета:
- **23 Lua-сцены** (point-and-click): `apartment_hub`, `apartment_bedroom`, `park_hub`, `cafe_corner`, `work_hub` и т.д. Связаны толстыми `==>` стрелками.
- **157 flow-кнотов**: `choose_character`, `loop_entry`, `park_bench_main_talk`, `sunday_shop_arrival_with_npc`, `msg_thread_*` и т.д. Связаны `-->` стрелками.
- **108 hotspot/on_enter связей** (пунктир): сцена вызывает ink-кнот при клике.
- **22 ink → ink diverts + 45 ink choices** (сплошные): внутри story-логики.
- **32 scene → scene навигаций** (толстые): пользователь ходит между сценами.
- **Всего 207 рёбер** в default-графе.
