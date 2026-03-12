#!/usr/bin/env bash
# phlux-doc-tools init script
# Copies slash commands into the host repo's .claude/commands/ directory.
# Safe to re-run — overwrites existing commands with latest versions.
#
# Usage: bash tools/doc-tools/init.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMANDS_SRC="$SCRIPT_DIR/commands"

# --- Find the host repo root (walk up looking for .git/) ---
find_repo_root() {
    local dir="$SCRIPT_DIR"
    while [[ "$dir" != "/" && "$dir" != "" ]]; do
        # Check parent — init.sh lives inside the submodule, so the host
        # repo root is above the submodule directory.
        dir="$(dirname "$dir")"
        if [[ -d "$dir/.git" || -f "$dir/.git" ]]; then
            # If .git is a file, we're in a submodule worktree — keep going
            if [[ -f "$dir/.git" ]]; then
                dir="$(dirname "$dir")"
                continue
            fi
            echo "$dir"
            return 0
        fi
    done
    return 1
}

REPO_ROOT=$(find_repo_root) || {
    echo "ERROR: Could not find a git repository root above $SCRIPT_DIR"
    echo "Make sure phlux-doc-tools is inside a git repository (e.g., as a submodule)."
    exit 1
}

COMMANDS_DST="$REPO_ROOT/.claude/commands"

echo "phlux-doc-tools init"
echo "  Source:      $COMMANDS_SRC"
echo "  Destination: $COMMANDS_DST"
echo ""

# --- Create destination directory ---
mkdir -p "$COMMANDS_DST"

# --- Copy commands ---
count=0
for src_file in "$COMMANDS_SRC"/*.md; do
    [[ -f "$src_file" ]] || continue
    name="$(basename "$src_file")"
    cp "$src_file" "$COMMANDS_DST/$name"
    echo "  Installed: $name"
    count=$((count + 1))
done

echo ""
echo "Done: $count commands installed to .claude/commands/"
echo ""
echo "NOTE: These are copies, not symlinks. After updating the phlux-doc-tools"
echo "submodule, re-run this script to pick up command changes:"
echo "  bash tools/doc-tools/init.sh"
