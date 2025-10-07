#!/usr/bin/env bash
set -euo pipefail

# Set the default accentColor for all userstyles by updating the
# @var select accentColor line to place the * on the chosen color.
#
# Usage:
#   scripts/automation/set-default-accent.sh <color>
#   where <color> is one of:
#     rosewater flamingo pink mauve red maroon peach yellow green teal blue sapphire sky lavender subtext0
#
# Example:
#   scripts/automation/set-default-accent.sh green
#
# Notes:
# - Updates all styles/*/catppuccin.user.less and template/catppuccin.user.less

COLOR=${1:-}
if [[ -z "${COLOR}" ]]; then
  echo "Usage: $0 <color>" >&2
  exit 1
fi

# Allowed colors and labels (keep order consistent across files)
# Format: key:Label
ORDERED_LIST=(
  "rosewater:Rosewater"
  "flamingo:Flamingo"
  "pink:Pink"
  "mauve:Mauve"
  "red:red"
  "maroon:Maroon"
  "peach:Peach"
  "yellow:Yellow"
  "green:Green"
  "teal:Teal"
  "blue:Blue"
  "sapphire:Sapphire"
  "sky:Sky"
  "lavender:Lavender"
  "subtext0:Gray"
)

# Normalize and validate color
LOWER_COLOR=$(printf '%s' "${COLOR}" | tr '[:upper:]' '[:lower:]')
VALID=0
for entry in "${ORDERED_LIST[@]}"; do
  key=${entry%%:*}
  if [[ "${key}" == "${LOWER_COLOR}" ]]; then
    VALID=1
    break
  fi
done
if [[ ${VALID} -ne 1 ]]; then
  echo "Invalid color: ${COLOR}" >&2
  echo "Valid options: ${ORDERED_LIST[@]%%:*}" >&2
  exit 1
fi

# Build the choices string with * on the chosen color
CHOICES="["
FIRST=1
for entry in "${ORDERED_LIST[@]}"; do
  key=${entry%%:*}
  label=${entry#*:}
  # Fix capitalization for 'red' label in list (ensure 'Red')
  if [[ "${key}" == "red" ]]; then
    label="Red"
  fi
  star=""
  if [[ "${key}" == "${LOWER_COLOR}" ]]; then
    star="*"
  fi
  part="\"${key}:${label}${star}\""
  if [[ ${FIRST} -eq 1 ]]; then
    CHOICES+="${part}"
    FIRST=0
  else
    CHOICES+=", ${part}"
  fi
done
CHOICES+="]"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Target files: all styles/*/catppuccin.user.less + template/catppuccin.user.less
mapfile -t FILES < <(find "${REPO_ROOT}/styles" -type f -name "catppuccin.user.less" -print; echo "${REPO_ROOT}/template/catppuccin.user.less" | sed '/^$/d')

UPDATED=0
for file in "${FILES[@]}"; do
  if [[ ! -f "${file}" ]]; then
    continue
  fi
  # Replace the entire @var select accentColor line
  if grep -q "^@var select accentColor \"Accent\" \[" "${file}"; then
    sed -i -E "s|^@var select accentColor \"Accent\" \[.*\]|@var select accentColor \"Accent\" ${CHOICES}|" "${file}"
    echo "Updated default accent in: ${file}"
    UPDATED=$((UPDATED + 1))
  fi
done

echo "Done. Files updated: ${UPDATED}"
