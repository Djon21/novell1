# Краткая инструкция для AI команды

## Быстрый старт

### AI #1 (Сценарист) - ветка `ai-local-1`
```bash
cd novell1
git checkout ai-local-1
git pull origin dev
git merge dev
# Работаете с файлами в main/story/*.ink
git add .
git commit -m "AI-1: добавил сцену X"
git push origin ai-local-1
# Создать PR: ai-local-1 → dev
```

### AI #2 (Художник) - ветка `ai-local-2`
```bash
cd novell1
git checkout ai-local-2
git pull origin dev
git merge dev
# Работаете с main/images/*, main/sounds/*
git add .
git commit -m "AI-2: добавил фон Y"
git push origin ai-local-2
# Создать PR: ai-local-2 → dev
```

### AI #3 (Программист) - ветка `ai-local-3`
```bash
cd novell1
git checkout ai-local-3
git pull origin dev
git merge dev
# Работаете с main/scripts/*.lua, main/gui/*
git add .
git commit -m "AI-3: исправил баг Z"
git push origin ai-local-3
# Создать PR: ai-local-3 → dev
```

### AI #4 (GitHub) - ветка `ai-github`
- Работает только через GitHub веб-интерфейс
- Создает PR из `ai-github` → `dev`
- Занимается документацией и ревью

## Проверка перед коммитом

```bash
# Компиляция Ink
cd novell1
tools\compile_ink.bat

# Проверка в Defold
# Ctrl+B (Build)
# F5 (Run)
```

## Правила

1. Всегда синхронизируйтесь с `dev` перед работой
2. Один PR = одна задача
3. Проверяйте компиляцию перед push
4. GitHub Actions автоматически проверит ваш PR

## Структура веток

```
master (production) ← только финальные релизы
  ↑
dev (integration) ← сюда идут все PR
  ↑
  ├── ai-local-1 (сценарии)
  ├── ai-local-2 (графика/звук)
  ├── ai-local-3 (код)
  └── ai-github (документация)
```

## Что делать при конфликте

```bash
git checkout ai-local-X
git merge dev
# Разрешить конфликты в редакторе
git add .
git commit -m "AI-X: resolve conflicts"
git push origin ai-local-X
```

Полная документация: `AI_WORKFLOW.md`
