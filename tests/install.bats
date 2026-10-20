#!/usr/bin/env bats
# Runs install.sh from a temporary checkout against a temporary home directory.

setup() {
  home="$BATS_TEST_TMPDIR/home"
  checkout="$BATS_TEST_TMPDIR/checkout"
  mkdir -p "$home" "$checkout"/{zsh,pnpm} \
    "$checkout/claude/.claude/agents" \
    "$checkout/omp/.omp/agent/agents" \
    "$checkout/mise/.config/mise/conf.d" \
    "$checkout/agents/.agents/skills"/{typescript,other} \
    "$checkout/agents/.agents/agents"
  cp "$BATS_TEST_DIRNAME/../install.sh" "$checkout/install.sh"
  printf 'managed\n' > "$checkout/zsh/.zshrc"
  printf 'managed\n' > "$checkout/omp/.omp/agent/config.yml"
  printf 'managed\n' > "$checkout/mise/.config/mise/conf.d/dotfiles.toml"
  printf 'managed\n' > "$checkout/agents/.agents/skills/typescript/SKILL.md"
  printf 'managed\n' > "$checkout/agents/.agents/skills/other/SKILL.md"
  printf 'shared agent\n' > "$checkout/agents/.agents/agents/shared.md"
  ln -s ../../../agents/.agents/agents/shared.md "$checkout/claude/.claude/agents/shared.md"
  ln -s ../../../../agents/.agents/agents/shared.md "$checkout/omp/.omp/agent/agents/shared.md"
  printf 'omp agent\n' > "$checkout/omp/.omp/agent/agents/omp-only.md"
  git -C "$checkout" init -q
  git -C "$checkout" add agents claude omp
}

run_install() {
  HOME="$home" "$checkout/install.sh"
}

backups() {
  find "$home" -maxdepth 1 -name '.dotfiles-backup.*' | sort
}

@test "links into HOME, not the checkout's parent directory" {
  run_install

  [ -L "$home/.zshrc" ]
  [ -L "$home/.omp/agent/config.yml" ]
  [ ! -L "$home/.omp/agent" ]
  [ -L "$home/.config/mise/conf.d/dotfiles.toml" ]
  [ ! -L "$home/.config/mise/conf.d" ]
  [ ! -e "$BATS_TEST_TMPDIR/.zshrc" ]
  [ ! -e "$BATS_TEST_TMPDIR/.config" ]
}

@test "backs up conflicting agent files and keeps unmanaged ones" {
  mkdir -p "$home/.agents/skills"/{typescript,custom}
  printf 'original\n' > "$home/.agents/skills/typescript/SKILL.md"
  printf 'untouched\n' > "$home/.agents/skills/custom/SKILL.md"

  run_install

  [ "$(backups | wc -l)" -eq 1 ]
  [ "$(cat "$(backups)/.agents/skills/typescript/SKILL.md")" = original ]
  [ "$(cat "$home/.agents/skills/custom/SKILL.md")" = untouched ]
  [ -L "$home/.agents/skills/typescript/SKILL.md" ]
}

@test "a later backup never overwrites an earlier one" {
  printf 'first\n' > "$home/.zshrc"
  run_install
  rm "$home/.zshrc"
  printf 'second\n' > "$home/.zshrc"
  run_install

  [ "$(backups | wc -l)" -eq 2 ]
  [ "$(backups | while read -r dir; do cat "$dir/.zshrc"; done | sort)" = $'first\nsecond' ]
  [ -L "$home/.zshrc" ]
}

@test "rerun keeps machine-specific mise config and makes no new backup" {
  run_install
  printf '[tools]\nnode = "24"\n' > "$home/.config/mise/conf.d/dev-machine.toml"

  run_install

  [ -z "$(backups)" ]
  [ "$(cat "$home/.config/mise/conf.d/dev-machine.toml")" = $'[tools]\nnode = "24"' ]
  [ ! -e "$checkout/mise/.config/mise/conf.d/dev-machine.toml" ]
}

@test "links one shared agent into Claude Code and omp" {
  run_install

  [ "$(cat "$home/.claude/agents/shared.md")" = 'shared agent' ]
  [ "$(cat "$home/.omp/agent/agents/shared.md")" = 'shared agent' ]
  [ "$(cat "$home/.omp/agent/agents/omp-only.md")" = 'omp agent' ]
  [ ! -e "$home/.claude/agents/omp-only.md" ]
  [ "$(realpath "$home/.claude/agents/shared.md")" = "$(realpath "$checkout/agents/.agents/agents/shared.md")" ]
}

@test "keeps harness agent folders real so local agents stay out of the checkout" {
  run_install
  printf 'local\n' > "$home/.claude/agents/local.md"
  printf 'local\n' > "$home/.omp/agent/agents/local.md"

  [ ! -L "$home/.claude/agents" ]
  [ ! -L "$home/.omp/agent/agents" ]
  [ ! -e "$checkout/claude/.claude/agents/local.md" ]
  [ ! -e "$checkout/omp/.omp/agent/agents/local.md" ]
}

@test "backs up real agent files that the checkout manages and keeps unmanaged ones" {
  mkdir -p "$home/.claude/agents" "$home/.omp/agent/agents"
  printf 'old copy\n' > "$home/.claude/agents/shared.md"
  printf 'original\n' > "$home/.omp/agent/agents/omp-only.md"
  printf 'untouched\n' > "$home/.omp/agent/agents/custom.md"

  run_install

  [ "$(backups | wc -l)" -eq 1 ]
  [ "$(cat "$(backups)/.claude/agents/shared.md")" = 'old copy' ]
  [ "$(cat "$(backups)/.omp/agent/agents/omp-only.md")" = original ]
  [ "$(cat "$home/.omp/agent/agents/custom.md")" = untouched ]
  [ "$(cat "$home/.claude/agents/shared.md")" = 'shared agent' ]
  [ "$(cat "$home/.omp/agent/agents/omp-only.md")" = 'omp agent' ]
}

@test "never stows omp's runtime config lock file" {
  printf '' > "$checkout/omp/.omp/agent/config.yml.lock"
  mkdir -p "$home/.omp/agent"
  printf '' > "$home/.omp/agent/config.yml.lock"

  run_install

  [ -f "$home/.omp/agent/config.yml.lock" ]
  [ ! -L "$home/.omp/agent/config.yml.lock" ]
  [ -L "$home/.omp/agent/config.yml" ]
}
