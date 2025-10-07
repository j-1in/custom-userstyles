#!/usr/bin/env bash
set -euo pipefail

# Replace all @import lines that reference lib.less (or lib/lib.less)
# with the provided URL across all styles/*/catppuccin.user.less files.
#
# Usage:
#   scripts/automation/replace-import-url.sh "https://cdn.jsdelivr.net/gh/you/your-repo@main/lib/lib.less"
#
# Optional second arg: target directory (default: styles)
#   scripts/automation/replace-import-url.sh "<NEW_URL>" path/to/styles

NEW_URL=${1:-}
TARGET_DIR=${2:-styles}

if [[ -z "${NEW_URL}" ]]; then
  echo "Usage: $0 NEW_URL [TARGET_DIR]" >&2
  exit 1
fi

# Warn if URL does not end with lib.less
if [[ ! "${NEW_URL}" =~ lib(\/lib)?\.less$ ]]; then
  echo "Warning: NEW_URL does not appear to end with lib.less: ${NEW_URL}" >&2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
TARGET_PATH="${REPO_ROOT}/${TARGET_DIR}"

if [[ ! -d "${TARGET_PATH}" ]]; then
  echo "Target directory not found: ${TARGET_PATH}" >&2
  exit 1
fi

# Find all userstyle files
mapfile -t FILES < <(find "${TARGET_PATH}" -type f -name "catppuccin.user.less" | sort)

if [[ ${#FILES[@]} -eq 0 ]]; then
  echo "No userstyle files found under ${TARGET_PATH}" >&2
  exit 0
fi

# Replace import lines that reference lib.less
UPDATED=0
SKIPPED=0
for file in "${FILES[@]}"; do
  if grep -E -q '^[[:space:]]*@import[[:space:]]+"[^"]*lib(/lib)?\.less";' "${file}"; then
    sed -i -E "s|^[[:space:]]*@import[[:space:]]+\"[^\"]*lib(/lib)?\\.less\";|@import \"${NEW_URL}\";|" "${file}"
    echo "Updated: ${file}"
    UPDATED=$((UPDATED + 1))
  else
    echo "Skipped (no lib.less import): ${file}"
    SKIPPED=$((SKIPPED + 1))
  fi
done

echo "Done. Updated: ${UPDATED}, Skipped: ${SKIPPED}"