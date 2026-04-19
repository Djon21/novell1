# АВОСЬ — Визуальная новелла с point-and-click элементами

**АВОСЬ** — это интерактивная история о временных петлях, выборах и последствиях. Игра сочетает классическую визуальную новеллу с элементами point-and-click adventure и RPG-механиками.

## 🎮 Особенности

- **Нелинейный сюжет** на базе [Ink](https://www.inklestudios.com/ink/)
- **Point-and-click исследование** локаций с hotspot'ами
- **Система выборов** влияющая на три оси: TRUST, INSIGHT, SYNC
- **Интерактивный телефон** с SMS, заметками и квестами
- **Гендерный выбор** главного героя с полным согласованием текста
- **Временные петли** как основная механика сюжета

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
- **[HOW_TO_ADD_BACKGROUNDS.md](HOW_TO_ADD_BACKGROUNDS.md)** - добавление фонов
- **[HOW_TO_ADD_SOUNDS.md](HOW_TO_ADD_SOUNDS.md)** - добавление звуков
- **[GRAPHICS_GUIDE.md](GRAPHICS_GUIDE.md)** - требования к графике

### Для программистов:
- **[ROADMAP.md](ROADMAP.md)** - план развития проекта
- **[TODO.md](TODO.md)** - текущие задачи
- **[DOCUMENTATION_AUDIT.md](DOCUMENTATION_AUDIT.md)** - анализ документации

## 🎨 Структура проекта

```
novell1/
├── main/
│   ├── gui/              # UI компоненты (novel_ui.gui)
│   ├── images/           # Графика (фоны, портреты, атласы)
│   ├── scripts/          # Lua-скрипты (game_state, scene_controller)
│   ├── sounds/           # Звуки и музыка
│   └── story/            # Ink-сценарии
├── tools/                # Утилиты (compile_ink, генераторы)
├── ROADMAP.md            # План развития
└── TODO.md               # Текущие задачи
```

## 🛠️ Технологии

- **Движок:** [Defold](https://defold.com/)
- **Сценарии:** [Ink](https://www.inklestudios.com/ink/) + [defold-ink](https://github.com/defold/extension-ink)
- **Язык:** Lua 5.1
- **Платформа:** HTML5 (Яндекс.Игры)

## 📝 Разработка

### Основные модули:
- `dialogue_manager_ink.lua` - движок диалогов на Ink
- `scene_controller.lua` - point-and-click сцены
- `game_state.lua` - состояние игры (флаги, инвентарь, квесты)
- `novel_ui.gui_script` - главный UI-контроллер

### Workflow:
1. Пишем сценарий в `main/story/chapter_01.ink`
2. Компилируем через `tools/compile_ink.bat`
3. Добавляем фоны/звуки по инструкциям
4. Настраиваем сцены в `main/scripts/scenes.lua`
5. Тестируем в Defold

## 🎯 Текущий статус

**Глава 1 (Итерация 001):** ✅ Завершена
- Пробуждение → квартира → метро → офис → крыша
- 5 звуковых эффектов
- 14 фонов
- 3 автотриггера
- Point-and-click навигация

## 🤝 Вклад в проект

Проект находится в активной разработке. Перед коммитом:
1. Проверьте TODO.md на актуальные задачи
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

**Версия:** 0.1.0 (Итерация 001)  
**Дата обновления:** 2026-04-19