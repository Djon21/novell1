# АВОСЬ

АВОСЬ — narrative point-and-click / visual novel на Defold. Текущий runtime уже работает через `v2`-стек: Ink отвечает за диалоги, `scene_controller.lua` — за exploration-сцены, `game_state.lua` — за состояние игры, а `ui_manager_v2.script` и `main/gui/components_v2/` — за интерфейс.

## Текущее состояние

- Активный bootstrap: `game.project` -> `/main/main_v2.collectionc`
- Активная рабочая ветка: `AVOS_S`
- Legacy GUI отключён и архивируется в `archive/legacy_runtime/`; он больше не считается fallback или рабочей альтернативой для v2

## Быстрый старт

1. Откройте проект в Defold Editor.
2. Запустите `Project -> Build` или `F5`.
3. Если меняли `.ink`, перекомпилируйте сценарий:

```bash
# Windows
tools\compile_ink.bat

# Linux/macOS
./tools/compile_ink.sh
```

## Карта документации

Подробная навигация теперь собрана в `docs/README.md`.

### С чего начинать

- `docs/reference/CODEX_CONTEXT.md` — короткий handoff для новых Codex-сессий
- `docs/reference/ARCHITECTURE.md` — актуальная карта runtime-архитектуры
- `docs/reference/CONTINUE_HERE.md` — что читать первым и куда обычно продолжают работу

### Контент и пайплайны

- `main/story/README.md` — Ink-пайплайн, поддерживаемые теги, ограничения текущего story-loader
- `main/story/INK_STYLE.md` — стиль и правила написания Ink
- `docs/guides/HOW_TO_ADD_SCENES.md` — добавление exploration-сцен, hotspot'ов, объектов и `exits`
- `docs/guides/HOW_TO_ADD_BACKGROUNDS.md` — добавление фонов и привязка к Ink / `scenes.lua`
- `docs/guides/HOW_TO_ADD_PORTRAITS.md` — добавление v2-портретов в `dialogue_v2`
- `docs/guides/HOW_TO_ADD_SOUNDS.md` — текущий звуковой пайплайн и caveats
- `docs/guides/GRAPHICS_GUIDE.md` — требования к графике и атласам
- `docs/guides/F1_HOTSPOT_EDITOR.md` — встроенный редактор hotspot'ов и scene objects
- `docs/guides/DESIGN_PORT_RULES.md` — правила портирования HTML/CSS-макетов в Defold GUI

### Планирование и живые хвосты

- `docs/reference/ROADMAP.md` — стратегические направления после завершённой v2-миграции
- `docs/reference/TODO.md` — оперативный список текущих незакрытых задач
- `docs/reference/DOCUMENTATION_AUDIT.md` — текущее состояние docs и оставшиеся пробелы

### Архив / история миграции

Эти файлы полезны как хронология и reference по legacy UI, но не должны использоваться как основной source of truth для текущей разработки:

- `docs/archive/legacy-ui/AVOS_V2_PROGRESS.md`
- `docs/archive/legacy-ui/GUI_MIGRATION_PLAN.md`
- `docs/archive/legacy-ui/GUI_AUDIT.md`
- `docs/archive/legacy-ui/GUI_CREATION_GUIDE.md`
- `docs/archive/legacy-ui/GUI_VALIDATION_REPORT.md`
- `docs/archive/legacy-ui/INTEGRATION_REPORT.md`
- `docs/archive/legacy-ui/MIGRATION_STATUS.md`
- `docs/archive/legacy-ui/MIGRATION_COMPLETE.md`
- `docs/archive/legacy-ui/NODE_MAP.md`

## Структура проекта

```text
main/
├── main_v2.collection          # текущая главная коллекция
├── gui/
│   ├── ui_manager_v2.script    # оркестратор v2 UI
│   ├── components_v2/          # активные GUI-компоненты
│   └── components/             # legacy GUI-компоненты (reference)
├── images/
│   ├── backgrounds/             # dedicated atlas на каждый fullscreen фон (v2)
│   ├── backgrounds.atlas        # legacy atlas (только для v1 GUI)
│   ├── hotspots.atlas           # иконки hotspot'ов (v2)
│   ├── scene_objects.atlas      # overlay-спрайты сцен (mobile и т.д.)
│   ├── v2.atlas                 # v2-портреты и часть v2-ассетов
│   └── characters.atlas         # legacy portrait atlas
├── scripts/
│   ├── dialogue_manager_ink.lua
│   ├── scene_controller.lua
│   ├── scenes.lua
│   ├── game_state.lua
│   ├── items_catalog.lua
│   └── quests.lua
├── sounds/
│   ├── *.ogg / *.sound
│   └── CREDITS.md
└── story/
    ├── chapter_01.ink
    ├── chapter_01.json
    └── README.md

docs/
├── README.md
├── reference/
├── guides/
└── archive/legacy-ui/
```

Legacy runtime-файлы старого GUI теперь живут отдельно в `archive/legacy_runtime/`.

## Важные caveats

- `dialogue_manager_ink.lua` уже парсит теги `# sfx`, `# shake`, `# pulse`, но текущий `v2`-UI пока не забирает `dm.get_effects()`. Фоновая музыка работает, а одноразовые эффекты требуют отдельного bridge в `ui_manager_v2.script`.
- `nav_buttons_v2` готов к работе с `exits`, но `scenes.lua` пока в основном опирается на hotspot-переходы. Направленная навигация частично подготовлена, но не развёрнута везде.
- Папка `skills/` в этом репозитории является отдельной областью и в эту ревизию документации намеренно не включалась.
