#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

# Move $HOME/<path> into this run's backup directory. mktemp gives each run a
# new directory, so a later run never overwrites an earlier backup.
backup=""
back_up() {
  if [ -z "$backup" ]; then
    backup="$(mktemp -d "$HOME/.dotfiles-backup.XXXXXX")"
  fi
  mkdir -p "$backup/$(dirname "$1")"
  mv "$HOME/$1" "$backup/$1"
}

# Back up a real file before stow replaces it with a symlink
# (skip if it's already a stow-managed symlink so re-runs stay clean).
for relative in .zshrc .omp/agent/config.yml; do
  if [ -f "$HOME/$relative" ] && [ ! -L "$HOME/$relative" ]; then
    back_up "$relative"
  fi
done

# Create ~/.omp/agent as a real directory so stow links only config.yml.
# Without it, stow would fold ~/.omp into a symlink to this repo, and omp
# would write its databases, sessions, and caches into the repo.
mkdir -p "$HOME/.omp/agent"

# Likewise keep ~/.config/mise/conf.d real so stow links only our fragment and
# mise or machine setup can add their own files beside it.
mkdir -p "$HOME/.config/mise/conf.d"

# Preserve files installed by another skill manager before Stow links ours.
if [ -d "$HOME/.agents" ] && [ ! -L "$HOME/.agents" ]; then
  while IFS= read -r -d '' source; do
    relative="${source#agents/}"
    target="$HOME/$relative"
    if [ -e "$target" ] && [ ! -L "$target" ] &&
       [ "$(realpath "$target")" != "$(realpath "$source")" ]; then
      back_up "$relative"
    fi
  done < <(git ls-files -z -- agents/.agents)
fi

if [ -n "$backup" ]; then
  echo "Backed up existing files to $backup"
fi

# --restow makes this idempotent and picks up newly added files, so the
# agents package keeps ~/.agents (including skills/ and .skill-lock.json)
# in sync on every run.
# --ignore keeps macOS .DS_Store files from causing stow conflicts.
stow --target="$HOME" --restow --ignore='\.DS_Store' zsh agents pnpm claude omp mise
