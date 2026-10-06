#!/bin/bash
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
fixture="$(mktemp -d)"
trap 'rm -rf "$fixture"' EXIT
home="$fixture/home"
checkout="$fixture/checkout"

mkdir -p "$checkout"/{zsh,pnpm,claude,omp} \
  "$checkout/mise/.config/mise/conf.d" \
  "$checkout/agents/.agents/skills"/{typescript,other} \
  "$home/.agents/skills"/{typescript,custom}
cp "$repo/install.sh" "$checkout/install.sh"
printf managed > "$checkout/agents/.agents/skills/typescript/SKILL.md"
printf managed > "$checkout/agents/.agents/skills/other/SKILL.md"
printf '[settings]\nidiomatic_version_file_enable_tools = ["node"]\n' > "$checkout/mise/.config/mise/conf.d/dotfiles.toml"
printf original > "$home/.agents/skills/typescript/SKILL.md"
printf untouched > "$home/.agents/skills/custom/SKILL.md"
git -C "$checkout" init -q
git -C "$checkout" add agents

HOME="$home" "$checkout/install.sh"
backup=("$home"/.agents-stow-backup.*)
test "${#backup[@]}" -eq 1
test "$(cat "${backup[0]}/.agents/skills/typescript/SKILL.md")" = original
test "$(cat "$home/.agents/skills/custom/SKILL.md")" = untouched
test -L "$home/.agents/skills/typescript/SKILL.md"
test -L "$home/.config/mise/conf.d/dotfiles.toml"
test ! -L "$home/.config/mise/conf.d"
test ! -e "$fixture/.config"
printf '[tools]\nnode = "24"\n' > "$home/.config/mise/conf.d/dev-machine.toml"
HOME="$home" "$checkout/install.sh"
test "$(find "$home" -maxdepth 1 -name '.agents-stow-backup.*' | wc -l | tr -d ' ')" = 1
test "$(cat "$home/.config/mise/conf.d/dev-machine.toml")" = $'[tools]\nnode = "24"'
test ! -e "$checkout/mise/.config/mise/conf.d/dev-machine.toml"
printf 'install.sh HOME target, conflict backup, independent mise config, and rerun: PASS\n'
