# 🤖 Система совместной работы 4 AI - Сводка

## ✅ Что настроено

### 1. Структура веток
```
master (production)
  ↑
dev (integration) ← все PR идут сюда
  ↑
  ├── ai-local-1 (AI #1 - Сценарист)
  ├── ai-local-2 (AI #2 - Художник) 
  ├── ai-local-3 (AI #3 - Программист)
  └── ai-github (AI #4 - GitHub/Документация)
```

### 2. GitHub Actions CI/CD
Автоматически проверяет при каждом PR:
- ✅ Компиляция Ink скриптов
- ✅ Синтаксис Lua
- ✅ Структура проекта

### 3. Документация
- `AI_WORKFLOW.md` - полная инструкция
- `AI_QUICKSTART.md` - быстрый старт
- `.github/PULL_REQUEST_TEMPLATE.md` - шаблон PR
- `.github/CODEOWNERS` - автоназначение ревьюеров

## 🚀 Как начать работу

### Для локальных AI (1, 2, 3):

```bash
# 1. Переключиться на свою ветку
cd novell1
git checkout ai-local-X  # X = ваш номер (1, 2 или 3)

# 2. Синхронизироваться с dev
git pull origin dev
git merge dev

# 3. Работать над задачей
# ... делаете изменения ...

# 4. Проверить компиляцию
tools\compile_ink.bat  # если трогали .ink файлы
# Ctrl+B в Defold Editor
# F5 для запуска

# 5. Закоммитить
git add .
git commit -m "AI-X: описание изменений"
git push origin ai-local-X

# 6. Создать PR через GitHub
# ai-local-X → dev
```

### Для GitHub AI (#4):

1. Работает только через веб-интерфейс GitHub
2. Создает PR из ветки `ai-github` в `dev`
3. CI автоматически проверит изменения
4. После одобрения - мержится в `dev`

## 🎯 Распределение ответственности

| AI | Ветка | Зона ответственности |
|----|-------|---------------------|
| #1 | ai-local-1 | Сценарии (*.ink), диалоги, квесты |
| #2 | ai-local-2 | Графика (images/), звуки (sounds/), атласы |
| #3 | ai-local-3 | Код (*.lua), GUI (*.gui), логика |
| #4 | ai-github | Документация (*.md), ревью, CI/CD |

## 🔒 Правила безопасности

1. **Никогда не коммитить напрямую в `master` или `dev`**
2. **Всегда работать в своей ветке**
3. **Проверять компиляцию перед push**
4. **Один PR = одна задача**
5. **Синхронизироваться с `dev` перед началом работы**

## 🛠️ Проверка перед коммитом

```bash
# Компиляция Ink
cd novell1
tools\compile_ink.bat

# Проверка в Defold
# 1. Открыть Defold Editor
# 2. Project → Build (Ctrl+B)
# 3. Project → Run (F5)
# 4. Убедиться что игра запускается
```

## 🔄 Workflow пример

```
AI #1 работает над сценарием
  ↓
Коммитит в ai-local-1
  ↓
Создает PR: ai-local-1 → dev
  ↓
GitHub Actions проверяет (CI)
  ↓
AI #4 делает ревью
  ↓
Мерж в dev
  ↓
AI #2 и #3 синхронизируются с dev
  ↓
Продолжают работу
```

## 📊 Мониторинг

- **GitHub Actions**: автоматические проверки при PR
- **Branch protection**: `dev` защищена от прямых коммитов
- **CODEOWNERS**: автоматическое назначение ревьюеров

## 🆘 Частые проблемы

### Конфликт при merge
```bash
git checkout ai-local-X
git merge dev
# Разрешить конфликты в редакторе
git add .
git commit -m "AI-X: resolve conflicts"
git push origin ai-local-X
```

### Ошибка компиляции
```bash
# Откатить последний коммит
git reset --soft HEAD~1

# Исправить ошибки
# ...

# Закоммитить снова
git add .
git commit -m "AI-X: fix compilation"
```

### Нужно начать заново
```bash
git checkout dev
git pull origin dev
git checkout -b ai-local-X-new
```

## 📝 Следующие шаги

1. **Запушить эти изменения в GitHub:**
   ```bash
   cd novell1
   git add .
   git commit -m "Setup: AI team workflow with CI/CD"
   git push origin main
   ```

2. **Настроить branch protection для `dev`:**
   - GitHub → Settings → Branches
   - Add rule для `dev`
   - Require PR reviews
   - Require status checks (CI)

3. **Создать GitHub team или добавить коллабораторов**

4. **Каждая AI переключается на свою ветку и начинает работу**

## 🎉 Готово!

Теперь у вас есть полноценная система для совместной работы 4 нейросетей над одним проектом с автоматической проверкой компиляции.
