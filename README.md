# АВОСЬ — Point-and-Click Adventure с элементами визуальной новеллы

**АВОСЬ** — это интерактивная история о временных петлях, выборах и последствиях. Игра эволюционировала из визуальной новеллы в полноценный point-and-click adventure с RPG-элементами, свободной навигацией и интерактивными локациями.

## 🎮 Особенности

- **Свободная навигация** по локациям с интерактивными hotspot'ами
- **Нелинейный сюжет** на базе [Ink](https://www.inklestudios.com/ink/)
- **Система квестов** с отслеживанием прогресса в телефоне
- **Интерактивный телефон** с SMS, заметками, квестами и приложениями
- **Инвентарь** с предметами и verb-механикой
- **Система выборов** влияющая на три оси: TRUST, INSIGHT, SYNC
- **Гендерный выбор** главного героя с полным согласованием текста
- **Временные петли** как основная механика сюжета
- **Модульная архитектура V2** с раздельными GUI компонентами

## 🚀 Быстрый старт

### Требования
- [Defold Editor](https://defold.com/download/) 1.4.0+
- Git

### Запуск проекта
1. Клонируйте репозиторий
2. Откройте проект в Defold Editor
3. Нажмите `Project → Build` (Ctrl+B)
4. Запустите игру (F5)

### Компиляция Ink-сценариев
После изменения `.ink` файлов:
```bash
# Windows:
tools\compile_ink.bat

# Linux/macOS:
./tools/compile_ink.sh
```

## 📚 Документация

### Для сценаристов и дизайнеров:
- **[INK_STYLE.md](main/story/INK_STYLE.md)** - полная спецификация написания сценариев
- **[HOW_TO_ADD_BACKGROUNDS.md](docs/guides/HOW_TO_ADD_BACKGROUNDS.md)** - добавление фонов
- **[HOW_TO_ADD_SOUNDS.md](docs/guides/HOW_TO_ADD_SOUNDS.md)** - добавление звуков
- **[HOW_TO_ADD_SCENES.md](docs/guides/HOW_TO_ADD_SCENES.md)** - создание point-and-click сцен
- **[HOW_TO_ADD_PORTRAITS.md](docs/guides/HOW_TO_ADD_PORTRAITS.md)** - добавление портретов персонажей
- **[GRAPHICS_GUIDE.md](docs/guides/GRAPHICS_GUIDE.md)** - требования к графике

### Для программистов:
- **[ROADMAP.md](docs/planning/ROADMAP.md)** - план развития проекта (Спринты 1-6)
- **[TODO.md](docs/planning/TODO.md)** - текущие задачи и приоритеты
- **[YANDEX_GAMES_REQUIREMENTS.md](docs/planning/YANDEX_GAMES_REQUIREMENTS.md)** - чеклист требований Яндекс.Игр
- **[V2_ARCHITECTURE.md](docs/internal/V2_ARCHITECTURE.md)** - архитектура V2 системы
- **[F1_HOTSPOT_EDITOR.md](docs/guides/F1_HOTSPOT_EDITOR.md)** - редактор hotspot'ов (F1)
- **[Документация проекта](docs/README.md)** - полный каталог документов

## 🎨 Структура проекта

```
AVOS_S/
├── main/
│   ├── gui/
│   │   ├── components/       # Legacy UI (не используется)
│   │   ├── components_v2/    # Модульные V2 компоненты
│   │   │   ├── atoms/        # Базовые элементы (HUD, углы)
│   │   │   ├── dialogue_v2.gui
│   │   │   ├── choice_v2.gui
│   │   │   ├── inventory_v2.gui
│   │   │   ├── phone_v2.gui
│   │   │   ├── map_v2.gui
│   │   │   ├── nav_buttons_v2.gui
│   │   │   └── main_menu_v2.gui
│   │   └── modules/          # v2_theme.lua (палитра, шрифты)
│   ├── images/               # Графика (фоны, портреты, атласы)
│   ├── scripts/              # Lua-скрипты
│   │   ├── game_state.lua    # Состояние игры
│   │   ├── scene_controller.lua  # Point-and-click движок
│   │   ├── scenes.lua        # Каталог сцен
│   │   ├── quests.lua        # Каталог квестов
│   │   ├── items_catalog.lua # Каталог предметов
│   │   └── dialogue_manager_ink.lua
│   ├── sounds/               # Звуки и музыка
│   ├── story/                # Ink-сценарии
│   │   └── chapter_01.ink
│   ├── main.collection       # Legacy коллекция
│   └── main_v2.collection    # V2 коллекция (активная)
├── tools/                    # Утилиты и скрипты
│   ├── compile_ink.bat
│   ├── update_gui_resolution.py
│   ├── scale_hotspots.py
│   └── update_center_positions.py
├── docs/                     # Вся документация проекта
│   ├── guides/               # Практические инструкции
│   ├── planning/             # Планирование и требования
│   ├── history/              # Исторические отчеты миграций
│   └── internal/             # Внутренние техдоки
├── .opencode/                # Служебные материалы/скиллы
└── game.project              # Разрешение: 1280×720
```

## 🛠️ Технологии

- **Движок:** [Defold](https://defold.com/) 1.4.0+
- **Сценарии:** [Ink](https://www.inklestudios.com/ink/) + [defold-ink](https://github.com/defold/extension-ink)
- **SDK:** [Яндекс.Игры](https://yandex.ru/dev/games/) (defold-yagames)
- **Язык:** Lua 5.1
- **Разрешение:** 1280×720 (16:9)
- **Платформа:** HTML5 (Яндекс.Игры, десктоп + мобильные)

## 📝 Разработка

### Основные модули (V2 архитектура):
- `ui_manager_v2.script` - координатор всех UI компонентов
- `dialogue_manager_ink.lua` - движок диалогов на Ink
- `scene_controller.lua` - point-and-click движок с hotspot'ами
- `game_state.lua` - состояние игры (флаги, инвентарь, квесты, SMS)
- `scenes.lua` - каталог сцен с hotspot'ами и объектами
- `quests.lua` - каталог квестов с шагами и условиями
- `items_catalog.lua` - каталог предметов инвентаря

### Workflow:
1. Пишем сценарий в `main/story/chapter_01.ink`
2. Компилируем через `tools/compile_ink.bat`
3. Добавляем фоны/звуки по инструкциям
4. Настраиваем сцены в `main/scripts/scenes.lua`
5. Добавляем квесты в `main/scripts/quests.lua`
6. Тестируем в Defold (F5)
7. Редактируем hotspot'ы через F1-редактор

## 🎯 Текущий статус

**Версия:** 0.2.0 (Итерация 001 + V2 архитектура)

### Завершено:
- ✅ **Глава 1** - полный сюжет от пробуждения до крыши
- ✅ **V2 архитектура** - модульные GUI компоненты
- ✅ **Разрешение 1280×720** - миграция завершена (2026-04-20)
- ✅ **Point-and-click** - свободная навигация по квартире
- ✅ **Система квестов** - интеграция с телефоном
- ✅ **Инвентарь** - 4×3 сетка с verb-механикой
- ✅ **Телефон** - SMS, квесты, заметки, звонки
- ✅ **Стек сцен** - корректная работа вложенных переходов

### Контент:
- 14 фоновых сцен
- 5 звуковых эффектов
- 2 портрета персонажей
- 5 сцен с hotspot'ами (квартира, кухня, ванная, спальня, телефон)
- 4 квеста (make_coffee, find_phone, reply_anya, go_to_office)
- ~900 строк Ink-сценария

### В разработке:
- ⚠️ Интеграция SDK Яндекс.Игр (LoadingAPI, реклама)
- ⚠️ Промоматериалы (иконка, обложка, скриншоты)
- ⚠️ Полное тестирование на всех платформах

### Соответствие Яндекс.Играм:
- **Текущее:** ~60% требований выполнено
- **До публикации:** 6 критических задач (см. YANDEX_GAMES_REQUIREMENTS.md)

## 🤝 Вклад в проект

Проект находится в активной разработке. Перед коммитом:
1. Проверьте docs/planning/TODO.md на актуальные задачи
2. Следуйте INK_STYLE.md для сценариев
3. Компилируйте Ink после изменений
4. Тестируйте игру перед коммитом

## 📄 Лицензия

[Укажите лицензию проекта]

## 🔗 Ссылки

- [Defold Documentation](https://defold.com/learn)
- [Ink Documentation](https://github.com/inkle/ink/blob/master/Documentation/WritingWithInk.md)
- [Яндекс.Игры SDK](https://yandex.ru/dev/games/)

---

**Версия:** 0.2.0 (V2 архитектура + разрешение 1280×720)  
**Дата обновления:** 2026-04-21
