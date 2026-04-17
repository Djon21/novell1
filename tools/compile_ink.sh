#!/bin/bash
# compile_ink.sh — компилирует все .ink файлы в main/story/ в .json
# Использование:
#   ./tools/compile_ink.sh          — компилировать все .ink
#   ./tools/compile_ink.sh hello    — компилировать только hello.ink
#
# Запускать из корня проекта (папка с game.project).

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
STORY_DIR="${PROJECT_ROOT}/main/story"
INKLECATE="${SCRIPT_DIR}/inklecate.exe"

if [ ! -x "${INKLECATE}" ]; then
    echo "❌ inklecate.exe не найден в ${SCRIPT_DIR}"
    exit 1
fi

if [ -n "$1" ]; then
    # Компилируем один файл
    INK_FILE="${STORY_DIR}/$1.ink"
    if [ ! -f "${INK_FILE}" ]; then
        echo "❌ Файл не найден: ${INK_FILE}"
        exit 1
    fi
    FILES=("${INK_FILE}")
else
    # Компилируем все .ink
    mapfile -t FILES < <(find "${STORY_DIR}" -maxdepth 1 -name "*.ink")
fi

if [ ${#FILES[@]} -eq 0 ]; then
    echo "⚠️  В ${STORY_DIR} нет .ink файлов"
    exit 0
fi

OK=0
FAIL=0

for INK in "${FILES[@]}"; do
    NAME="$(basename "${INK}" .ink)"
    JSON="${STORY_DIR}/${NAME}.json"
    echo "→ ${NAME}.ink"
    if "${INKLECATE}" -o "${JSON}" "${INK}" 2>&1; then
        echo "  ✅ → ${NAME}.json"
        OK=$((OK + 1))
    else
        echo "  ❌ ошибка компиляции"
        FAIL=$((FAIL + 1))
    fi
done

echo ""
echo "Готово: ${OK} OK, ${FAIL} ошибок"
exit ${FAIL}
