#!/usr/bin/env bash
# ckg-agent-kit uninstaller
#
# Usage:
#   ./uninstall.sh --global    Remove from ~/.config/opencode/skills/ + ~/.local/share/openspec/schemas/
#   ./uninstall.sh --project   Remove from .opencode/skills/ + openspec/schemas/ in current directory

set -euo pipefail

MODE="${1:-}"

GLOBAL_SKILLS="$HOME/.config/opencode/skills"
GLOBAL_SCHEMA="$HOME/.local/share/openspec/schemas"
PROJECT_SKILLS=".opencode/skills"
PROJECT_SCHEMA="openspec/schemas"

SKILLS=(blast-radius get-code-flow openspec-ckg-recon openspec-ckg-verify)

if [[ "$MODE" == "--global" ]]; then
  SKILLS_DIR="$GLOBAL_SKILLS"
  SCHEMA_DIR="$GLOBAL_SCHEMA"
elif [[ "$MODE" == "--project" ]]; then
  SKILLS_DIR="$PROJECT_SKILLS"
  SCHEMA_DIR="$PROJECT_SCHEMA"
else
  echo "Usage: ./uninstall.sh [--global|--project]"
  exit 1
fi

echo "Removing skills from $SKILLS_DIR"
for skill in "${SKILLS[@]}"; do
  target="${SKILLS_DIR}/${skill}"
  if [[ -d "$target" ]]; then
    rm -rf "$target"
    echo "  ✓ removed $skill"
  else
    echo "  - $skill (not found, skipping)"
  fi
done

echo "Removing schema from ${SCHEMA_DIR}/ckg-aware"
if [[ -d "${SCHEMA_DIR}/ckg-aware" ]]; then
  rm -rf "${SCHEMA_DIR}/ckg-aware"
  echo "  ✓ removed ckg-aware"
else
  echo "  - ckg-aware (not found, skipping)"
fi

echo ""
echo "Done. Your openspec/config.yaml still references schema: ckg-aware."
echo "Update it to 'schema: spec-driven' if you no longer want CKG-enhanced templates."
