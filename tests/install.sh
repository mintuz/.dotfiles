#!/bin/bash
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
fixture="$(mktemp -d)"
trap 'rm -rf "$fixture"' EXIT

mkdir -p "$fixture/.dotfiles"/{zsh,pnpm,claude} \
  "$fixture/.dotfiles/agents/.agents/skills"/{typescript,other} \
  "$fixture/.agents/skills"/{typescript,custom}
cp "$repo/install.sh" "$fixture/.dotfiles/install.sh"
printf managed > "$fixture/.dotfiles/agents/.agents/skills/typescript/SKILL.md"
printf managed > "$fixture/.dotfiles/agents/.agents/skills/other/SKILL.md"
printf original > "$fixture/.agents/skills/typescript/SKILL.md"
printf untouched > "$fixture/.agents/skills/custom/SKILL.md"
git -C "$fixture/.dotfiles" init -q
git -C "$fixture/.dotfiles" add agents

HOME="$fixture" "$fixture/.dotfiles/install.sh"
backup=("$fixture"/.agents-stow-backup.*)
test "${#backup[@]}" -eq 1
test "$(cat "${backup[0]}/.agents/skills/typescript/SKILL.md")" = original
test "$(cat "$fixture/.agents/skills/custom/SKILL.md")" = untouched
test -L "$fixture/.agents/skills/typescript/SKILL.md"
HOME="$fixture" "$fixture/.dotfiles/install.sh"
test "$(find "$fixture" -maxdepth 1 -name '.agents-stow-backup.*' | wc -l | tr -d ' ')" = 1
printf 'install.sh conflict backup and rerun: PASS\n'
