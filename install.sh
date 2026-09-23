#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

# Back up a real ~/.zshrc before stow replaces it with a symlink
# (skip if it's already a stow-managed symlink so re-runs stay clean).
if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
  mv "$HOME/.zshrc" "$HOME/.zshrc.old"
fi

# Preserve files installed by another skill manager before Stow links ours.
if [ -d "$HOME/.agents" ] && [ ! -L "$HOME/.agents" ]; then
  backup=""
  while IFS= read -r -d '' source; do
    relative="${source#agents/}"
    target="$HOME/$relative"
    if [ -e "$target" ] && [ ! -L "$target" ] &&
       [ "$(realpath "$target")" != "$(realpath "$source")" ]; then
      if [ -z "$backup" ]; then
        backup="$(mktemp -d "$HOME/.agents-stow-backup.XXXXXX")"
      fi
      mkdir -p "$backup/$(dirname "$relative")"
      mv "$target" "$backup/$relative"
    fi
  done < <(git ls-files -z -- agents/.agents)
  if [ -n "$backup" ]; then
    echo "Backed up existing agent files to $backup"
  fi
fi

# --restow makes this idempotent and picks up newly added files, so the
# agents package keeps ~/.agents (including skills/ and .skill-lock.json)
# in sync on every run.
# --ignore keeps macOS .DS_Store files from causing stow conflicts.
stow --restow --ignore='\.DS_Store' zsh agents pnpm claude
