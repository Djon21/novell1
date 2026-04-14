#!/bin/bash
# Автокоммит после завершения работы Claude

# Переходим в корень репозитория
ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$ROOT"

# Ничего нет — выходим
git add -A
git diff --cached --quiet && exit 0

# Определяем тип коммита по изменённым файлам
CHANGED_EXTS=$(git diff --cached --name-only | grep -oE '\.[a-z]+$' | sort -u | tr '\n' ' ')
CHANGED_FILES=$(git diff --cached --name-only | xargs -I{} basename {} 2>/dev/null | head -3 | paste -sd ', ')

if echo "$CHANGED_EXTS" | grep -qE '\.script|\.lua'; then
  PREFIX="feat"
elif echo "$CHANGED_EXTS" | grep -qE '\.collection|\.scene|\.go'; then
  PREFIX="feat"
elif echo "$CHANGED_EXTS" | grep -qE '\.project|\.json|\.md'; then
  PREFIX="chore"
else
  PREFIX="chore"
fi

git commit -m "$PREFIX: $CHANGED_FILES"
