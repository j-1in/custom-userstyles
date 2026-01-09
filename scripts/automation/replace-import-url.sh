#!/usr/bin/env bash
set -euo pipefail

# Replace all @import lines that reference lib.less (or lib/lib.less)
# with the provided URL across all styles/*/catppuccin.user.less files.
# Additionally, update the @updateURL metadata in the userstyle header
# to point at the raw file path corresponding to each file.
#
# Usage:
#   scripts/automation/replace-import-url.sh "https://cdn.jsdelivr.net/gh/you/your-repo@main/lib/lib.less"
#
# Optional second arg: target directory (default: styles)
#   scripts/automation/replace-import-url.sh "<NEW_URL>" path/to/styles
#
# Examples of NEW_URL that will work:
# - https://raw.githubusercontent.com/user/repo/main/lib/lib.less
# - https://cdn.jsdelivr.net/gh/user/repo@main/lib/lib.less

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

# Counters
UPDATED=0
SKIPPED=0

for file in "${FILES[@]}"; do
  changed=false

  # 1) Replace import lines that reference lib.less
  if grep -E -q '^[[:space:]]*@import[[:space:]]+"[^"]*lib(/lib)?\.less";' "${file}"; then
    sed -i -E "s|^[[:space:]]*@import[[:space:]]+\"[^\"]*lib(/lib)?\\.less\";|@import \"${NEW_URL}\";|" "${file}"
    echo "Updated import: ${file}"
    changed=true
  fi

  # 2) Update @updateURL metadata line (if present)
  if grep -E -q '^[[:space:]]*@updateURL[[:space:]]+' "${file}"; then
    # Path of file relative to repo root (e.g. styles/anilist/catppuccin.user.less)
    REL_PATH="${file#${REPO_ROOT}/}"

    # Construct an appropriate update URL by replacing the lib.less portion of NEW_URL
    # with the relative file path. Handle common patterns like lib/lib.less and lib.less.
    if [[ "${NEW_URL}" =~ lib(/lib)?\.less$ ]]; then
      prefix="${NEW_URL%lib/lib.less}"
      if [[ "${prefix}" == "${NEW_URL}" ]]; then
        prefix="${NEW_URL%lib.less}"
      fi
      UPDATE_URL="${prefix}${REL_PATH}"
    else
      # If NEW_URL doesn't end with lib.less, fall back to replacing the filename
      # with the relative path (use the directory portion of NEW_URL).
      base_dir="${NEW_URL%/*}/"
      UPDATE_URL="${base_dir}${REL_PATH}"
    fi

    # Normalize accidental multiple slashes except the protocol separator '://'
    proto="$(echo "${UPDATE_URL}" | sed -nE 's#^(https?://).*#\1#p' || true)"
    if [[ -n "${proto}" ]]; then
      rest="${UPDATE_URL#${proto}}"
    else
      rest="${UPDATE_URL}"
    fi
    rest="$(echo "${rest}" | sed -E 's#//+#/#g')"
    UPDATE_URL="${proto}${rest}"

    # Replace the @updateURL line
    sed -i -E "s|(^[[:space:]]*@updateURL[[:space:]]+).*$|\1${UPDATE_URL}|" "${file}"
    echo "Updated updateURL: ${file} -> ${UPDATE_URL}"
    changed=true
  fi

  if [[ "${changed}" = true ]]; then
    UPDATED=$((UPDATED + 1))
  else
    echo "Skipped (no changes): ${file}"
    SKIPPED=$((SKIPPED + 1))
  fi
done

echo "Done. Files touched: ${UPDATED}, Skipped: ${SKIPPED}"
