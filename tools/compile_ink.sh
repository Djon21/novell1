#!/bin/bash
# compile_ink.sh -- compile Ink sources in main/story into JSON.
# Usage:
#   ./tools/compile_ink.sh             -- compile active .ink files
#   ./tools/compile_ink.sh chapter_01  -- compile only chapter_01.ink
#
# Notes:
# - Run from the project root (where game.project lives).
# - Files ending with _old.ink are treated as archive sources and are skipped
#   during bulk compilation. They can still be compiled explicitly.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
STORY_DIR="${PROJECT_ROOT}/main/story"
INKLECATE="${SCRIPT_DIR}/inklecate.exe"

if [ ! -x "${INKLECATE}" ]; then
    echo "[ERROR] inklecate.exe not found in ${SCRIPT_DIR}"
    exit 1
fi

if [ -n "$1" ]; then
    INK_FILE="${STORY_DIR}/$1.ink"
    if [ ! -f "${INK_FILE}" ]; then
        echo "[ERROR] File not found: ${INK_FILE}"
        exit 1
    fi
    FILES=("${INK_FILE}")
else
    mapfile -t FILES < <(find "${STORY_DIR}" -maxdepth 1 -name "*.ink" ! -name "*_old.ink" | sort)
fi

if [ ${#FILES[@]} -eq 0 ]; then
    echo "No active .ink files found in ${STORY_DIR}"
    exit 0
fi

OK=0
FAIL=0

for INK in "${FILES[@]}"; do
    NAME="$(basename "${INK}" .ink)"
    JSON="${STORY_DIR}/${NAME}.json"
    echo "- ${NAME}.ink"
    if "${INKLECATE}" -o "${JSON}" "${INK}" 2>&1; then
        echo "  [OK] ${NAME}.json"
        OK=$((OK + 1))
    else
        echo "  [ERROR] compile failed"
        FAIL=$((FAIL + 1))
    fi
done

echo
echo "Done: ${OK} OK, ${FAIL} errors"
exit ${FAIL}
