#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

# Use the tracked hooks in .githooks for this repo only. The pre-push hook
# runs gitleaks, so a push with a secret in it stops before it leaves here.
git config core.hooksPath .githooks

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

# Keep the harness agent folders real so stow links each managed agent file,
# and agents that a harness or another tool adds stay out of this repo.
# ~/.workclaude must be real too: Claude Code writes the work profile's
# login, history and settings there, and none of it may land in this repo.
mkdir -p "$HOME/.claude/agents" "$HOME/.workclaude/agents" "$HOME/.omp/agent/agents"

# Back up a real agent file before stow replaces it with our link.
while IFS= read -r -d '' source; do
  relative="${source#*/}"
  if [ -f "$HOME/$relative" ] && [ ! -L "$HOME/$relative" ]; then
    back_up "$relative"
  fi
done < <(git ls-files -z -- claude/.claude/agents workclaude/.workclaude/agents omp/.omp/agent/agents)

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
# --ignore keeps macOS .DS_Store files and omp's runtime config.yml.lock from
# causing stow conflicts. omp writes the lock beside the real config.yml,
# which is in this repo.
stow --target="$HOME" --restow --ignore='\.DS_Store' --ignore='config\.yml\.lock' zsh agents pnpm claude workclaude omp mise

# Set up RTK in each Claude Code profile. rtk writes RTK.md and its hook into
# the profile's local directory, so neither reaches this repo. The shared
# CLAUDE.md already imports @RTK.md.
if command -v rtk >/dev/null 2>&1; then
  for profile in .claude .workclaude; do
    CLAUDE_CONFIG_DIR="$HOME/$profile" rtk init --global --auto-patch
  done
fi
