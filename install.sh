#!/usr/bin/env bash
# ckg-agent-kit installer
# Installs CKG agent skills and OpenSpec ckg-aware schema.
#
# Usage:
#   ./install.sh --global    Install to ~/.config/opencode/skills/ + ~/.local/share/openspec/schemas/
#   ./install.sh --project   Install to .opencode/skills/ + openspec/schemas/ in current directory

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODE="${1:-}"

# ── Targets ──────────────────────────────────────────────────────────────────
GLOBAL_SKILLS="$HOME/.config/opencode/skills"
GLOBAL_SCHEMA="$HOME/.local/share/openspec/schemas"
PROJECT_SKILLS=".opencode/skills"
PROJECT_SCHEMA="openspec/schemas"

# ── Mode selection ────────────────────────────────────────────────────────────
if [[ "$MODE" == "--global" ]]; then
  SKILLS_DIR="$GLOBAL_SKILLS"
  SCHEMA_DIR="$GLOBAL_SCHEMA"
elif [[ "$MODE" == "--project" ]]; then
  SKILLS_DIR="$PROJECT_SKILLS"
  SCHEMA_DIR="$PROJECT_SCHEMA"
else
  echo "ckg-agent-kit installer"
  echo ""
  echo "Usage: ./install.sh [--global|--project]"
  echo ""
  echo "  --global   Install skills to ~/.config/opencode/skills/"
  echo "             Install schema  to ~/.local/share/openspec/schemas/"
  echo "             Skills available in every project (OpenCode auto-discovers)."
  echo ""
  echo "  --project  Install skills to .opencode/skills/ (current directory)"
  echo "             Install schema  to openspec/schemas/ (current directory)"
  echo "             Skills scoped to this project only."
  echo ""
  exit 1
fi

# ── Install skills ────────────────────────────────────────────────────────────
echo "Installing skills → $SKILLS_DIR"
mkdir -p "$SKILLS_DIR"
for skill_src in "$SCRIPT_DIR"/skills/*/; do
  skill_name="$(basename "$skill_src")"
  skill_dst="${SKILLS_DIR}/${skill_name}"
  rm -rf "$skill_dst"
  cp -r "$skill_src" "$skill_dst"
  echo "  ✓ $skill_name"
done

# ── Install schema ────────────────────────────────────────────────────────────
echo "Installing schema  → ${SCHEMA_DIR}/ckg-aware"
mkdir -p "$SCHEMA_DIR"
rm -rf "${SCHEMA_DIR}/ckg-aware"
cp -r "$SCRIPT_DIR/schema/ckg-aware" "${SCHEMA_DIR}/ckg-aware"
echo "  ✓ ckg-aware"

# ── Next steps ────────────────────────────────────────────────────────────────
echo ""
echo "Done."
echo ""
echo "Next steps:"
echo "  1. Install the CKG MCP server:"
echo "       pip install ckg-mcp"
echo "     (or clone https://github.com/your-org/joern-KG-builder and pip install -e ckg/mcp)"
echo ""
echo "  2. In your project, set the OpenSpec schema:"
echo "       echo 'schema: ckg-aware' > openspec/config.yaml"
echo "     Or copy the example: cp $SCRIPT_DIR/config/openspec-config.example.yaml openspec/config.yaml"
echo ""
echo "  3. Configure your MCP client to connect to ckg-mcp."
echo "     See docs/CLIENTS.md for OpenCode, Claude Desktop, VS Code, and LibreChat configs."
echo ""
echo "  4. Read the workflow guide: docs/WORKFLOW.md"
