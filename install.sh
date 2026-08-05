#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

# Back up a real ~/.zshrc before stow replaces it with a symlink
# (skip if it's already a stow-managed symlink so re-runs stay clean).
if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
  mv "$HOME/.zshrc" "$HOME/.zshrc.old"
fi

# --restow makes this idempotent and picks up newly added files, so the
# agents package keeps ~/.agents (including skills/ and .skill-lock.json)
# in sync on every run.
# --ignore keeps macOS .DS_Store files from causing stow conflicts.
stow --restow --ignore='\.DS_Store' zsh agents pnpm claude
