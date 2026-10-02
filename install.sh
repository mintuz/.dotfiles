#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

# Back up a real file before stow replaces it with a symlink
# (skip if it's already a stow-managed symlink so re-runs stay clean).
backup_if_real_file() {
  if [ -f "$1" ] && [ ! -L "$1" ]; then
    mv "$1" "$1.old"
  fi
}

backup_if_real_file "$HOME/.zshrc"
backup_if_real_file "$HOME/.omp/agent/config.yml"

# Create ~/.omp/agent as a real directory so stow links only config.yml.
# Without it, stow would fold ~/.omp into a symlink to this repo, and omp
# would write its databases, sessions, and caches into the repo.
mkdir -p "$HOME/.omp/agent"

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
stow --restow --ignore='\.DS_Store' zsh agents pnpm claude omp
