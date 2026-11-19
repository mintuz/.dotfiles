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
for relative in .zshrc .omp/agent/config.yml .config/rex/init.lua; do
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

# Keep ~/.config/rex real too. If stow folded it into a link to this repo, the
# backup step of the next run would see the repo's own init.lua as a real file
# and move it out of the repo.
mkdir -p "$HOME/.config/rex"

# Keep the harness agent folders real so stow links each managed agent file,
# and agents that a harness or another tool adds stay out of this repo.
# ~/.workclaude must be real too: Claude Code writes the work profile's
# login, history and settings there, and none of it may land in this repo.
# ~/.omp/agent/extensions stays real for the same reason as the agent folders.
mkdir -p "$HOME/.claude/agents" "$HOME/.workclaude/agents" "$HOME/.omp/agent/agents" \
  "$HOME/.omp/agent/extensions"

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
stow --target="$HOME" --restow --ignore='\.DS_Store' --ignore='config\.yml\.lock' zsh agents pnpm claude workclaude omp mise rex

# Set up RTK in each Claude Code profile. rtk writes RTK.md and its hook into
# the profile's local directory, so neither reaches this repo. The shared
# CLAUDE.md already imports @RTK.md.
if command -v rtk >/dev/null 2>&1; then
  for profile in .claude .workclaude; do
    CLAUDE_CONFIG_DIR="$HOME/$profile" rtk init --global --auto-patch
  done
fi

# Add the Rex hooks to each local profile file, so none of them reaches this
# repo. The Stop hook copies the agent's terminal title to its Rex tab. The
# session hooks record each agent pane for the Rex action Restore Agents….
# Codex has no SessionEnd hook. omp runs the same scripts from
# omp/.omp/agent/extensions/rex-tab-title.ts.
# A file that already has a hook keeps it unchanged.
rex_dir="$HOME/.config/rex"
# add_hook FILE EVENT COMMAND
add_hook() {
  [ -f "$1" ] || printf '{}\n' > "$1"
  if ! jq -e --arg event "$2" --arg cmd "$3" 'any(.hooks[$event][]?.hooks[]?; .command == $cmd)' "$1" >/dev/null; then
    updated="$(jq --arg event "$2" --arg cmd "$3" \
      '.hooks[$event] += [{hooks: [{type: "command", command: $cmd, timeout: 5}]}]' "$1")"
    # Write in place to keep the file's permissions.
    printf '%s\n' "$updated" > "$1"
  fi
}
if command -v jq >/dev/null 2>&1; then
  for settings in "$HOME/.claude/settings.json" "$HOME/.workclaude/settings.json"; do
    add_hook "$settings" Stop "$rex_dir/agent-tab-title.sh"
    add_hook "$settings" SessionStart "$rex_dir/agent-session.sh claude"
    add_hook "$settings" SessionEnd "$rex_dir/agent-session.sh claude"
  done
  if [ -d "$HOME/.codex" ]; then
    add_hook "$HOME/.codex/hooks.json" Stop "$rex_dir/agent-tab-title.sh"
    add_hook "$HOME/.codex/hooks.json" SessionStart "$rex_dir/agent-session.sh codex"
  fi
else
  echo "jq is not installed, so the Rex hooks were not added"
fi
