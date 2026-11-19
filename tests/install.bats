#!/usr/bin/env bats
# Runs install.sh from a temporary checkout against a temporary home directory.

setup() {
  home="$BATS_TEST_TMPDIR/home"
  checkout="$BATS_TEST_TMPDIR/checkout"
  mkdir -p "$home" "$checkout"/{zsh,pnpm} \
    "$checkout/claude/.claude/agents" \
    "$checkout/workclaude/.workclaude/agents" \
    "$checkout/omp/.omp/agent/agents" \
    "$checkout/mise/.config/mise/conf.d" \
    "$checkout/rex/.config/rex" \
    "$checkout/agents/.agents/skills"/{typescript,other} \
    "$checkout/agents/.agents/agents"
  cp "$BATS_TEST_DIRNAME/../install.sh" "$checkout/install.sh"
  printf 'managed\n' > "$checkout/zsh/.zshrc"
  printf 'managed\n' > "$checkout/omp/.omp/agent/config.yml"
  printf 'managed\n' > "$checkout/mise/.config/mise/conf.d/dotfiles.toml"
  printf 'managed\n' > "$checkout/rex/.config/rex/init.lua"
  printf 'managed\n' > "$checkout/agents/.agents/skills/typescript/SKILL.md"
  printf 'managed\n' > "$checkout/agents/.agents/skills/other/SKILL.md"
  printf 'shared agent\n' > "$checkout/agents/.agents/agents/shared.md"
  ln -s ../../../agents/.agents/agents/shared.md "$checkout/claude/.claude/agents/shared.md"
  ln -s ../../../agents/.agents/agents/shared.md "$checkout/workclaude/.workclaude/agents/shared.md"
  ln -s ../../../../agents/.agents/agents/shared.md "$checkout/omp/.omp/agent/agents/shared.md"
  printf 'omp agent\n' > "$checkout/omp/.omp/agent/agents/omp-only.md"
  # Fake rtk records which profile each run targets.
  mkdir -p "$BATS_TEST_TMPDIR/bin"
  printf '#!/bin/sh\necho "$CLAUDE_CONFIG_DIR $*" >> "%s"\n' "$BATS_TEST_TMPDIR/rtk.log" > "$BATS_TEST_TMPDIR/bin/rtk"
  chmod +x "$BATS_TEST_TMPDIR/bin/rtk"
  # Fake peon-ping commands record the same way.
  for cmd in peon-ping-setup peon; do
    printf '#!/bin/sh\necho "$CLAUDE_CONFIG_DIR %s $*" >> "%s"\n' "$cmd" "$BATS_TEST_TMPDIR/peon.log" > "$BATS_TEST_TMPDIR/bin/$cmd"
    chmod +x "$BATS_TEST_TMPDIR/bin/$cmd"
  done
  git -C "$checkout" init -q
  git -C "$checkout" add agents claude workclaude omp
}

run_install() {
  HOME="$home" PATH="$BATS_TEST_TMPDIR/bin:$PATH" "$checkout/install.sh"
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
  [ "$(git -C "$checkout" config core.hooksPath)" = .githooks ]
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

@test "backs up a real Rex config and links the managed one" {
  mkdir -p "$home/.config/rex"
  printf 'original\n' > "$home/.config/rex/init.lua"

  run_install

  [ "$(cat "$(backups)/.config/rex/init.lua")" = original ]
  [ "$(cat "$home/.config/rex/init.lua")" = managed ]
}

@test "rerun keeps machine-specific mise config and makes no new backup" {
  run_install
  printf '[tools]\nnode = "24"\n' > "$home/.config/mise/conf.d/dev-machine.toml"

  run_install

  [ -z "$(backups)" ]
  [ "$(cat "$home/.config/mise/conf.d/dev-machine.toml")" = $'[tools]\nnode = "24"' ]
  [ ! -e "$checkout/mise/.config/mise/conf.d/dev-machine.toml" ]
}

@test "links one shared agent into both Claude Code profiles and omp" {
  run_install

  [ "$(cat "$home/.claude/agents/shared.md")" = 'shared agent' ]
  [ "$(cat "$home/.workclaude/agents/shared.md")" = 'shared agent' ]
  [ "$(cat "$home/.omp/agent/agents/shared.md")" = 'shared agent' ]
  [ "$(cat "$home/.omp/agent/agents/omp-only.md")" = 'omp agent' ]
  [ ! -e "$home/.claude/agents/omp-only.md" ]
  [ "$(realpath "$home/.claude/agents/shared.md")" = "$(realpath "$checkout/agents/.agents/agents/shared.md")" ]
}

@test "keeps harness agent folders real so local agents stay out of the checkout" {
  run_install
  printf 'local\n' > "$home/.claude/agents/local.md"
  printf 'local\n' > "$home/.omp/agent/agents/local.md"
  printf 'secret\n' > "$home/.workclaude/.credentials.json"

  [ ! -L "$home/.claude/agents" ]
  [ ! -L "$home/.workclaude" ]
  [ ! -L "$home/.workclaude/agents" ]
  [ ! -e "$checkout/workclaude/.workclaude/.credentials.json" ]
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

@test "sets up RTK in the personal and work Claude Code profiles" {
  run_install

  [ "$(cat "$BATS_TEST_TMPDIR/rtk.log")" = "$home/.claude init --global --auto-patch
$home/.workclaude init --global --auto-patch" ]
}

@test "sets up peon-ping with the J.A.R.V.I.S. pack in both Claude Code profiles" {
  run_install

  [ "$(cat "$BATS_TEST_TMPDIR/peon.log")" = "$home/.claude peon-ping-setup --packs=jarvis-mk2
$home/.claude peon packs use jarvis-mk2
$home/.workclaude peon-ping-setup --packs=jarvis-mk2
$home/.workclaude peon packs use jarvis-mk2" ]
}

@test "continues the install when peon-ping setup fails" {
  printf '#!/bin/sh\nexit 1\n' > "$BATS_TEST_TMPDIR/bin/peon-ping-setup"

  run run_install

  [ "$status" -eq 0 ]
  [[ "$output" == *"peon-ping setup failed for ~/.claude"* ]]
  [ ! -e "$BATS_TEST_TMPDIR/peon.log" ]
}

@test "adds the Rex tab title hook once and keeps other settings" {
  mkdir -p "$home/.claude" "$home/.codex"
  printf '{"model": "opus", "hooks": {"Stop": [{"hooks": [{"type": "command", "command": "other"}]}]}}\n' > "$home/.claude/settings.json"
  hook="$home/.config/rex/agent-tab-title.sh"

  run_install
  run_install

  for file in .claude/settings.json .workclaude/settings.json .codex/hooks.json; do
    [ "$(jq --arg cmd "$hook" '[.hooks.Stop[].hooks[] | select(.command == $cmd)] | length' "$home/$file")" -eq 1 ]
  done
  [ "$(jq -r '.model' "$home/.claude/settings.json")" = opus ]
  [ "$(jq -r '.hooks.Stop[0].hooks[0].command' "$home/.claude/settings.json")" = other ]
}

@test "adds the Rex session hooks once" {
  mkdir -p "$home/.codex"
  session="$home/.config/rex/agent-session.sh"

  run_install
  run_install

  count() { jq --arg event "$2" --arg cmd "$3" '[.hooks[$event][]?.hooks[] | select(.command == $cmd)] | length' "$home/$1"; }
  for file in .claude/settings.json .workclaude/settings.json; do
    [ "$(count "$file" SessionStart "$session claude")" -eq 1 ]
    [ "$(count "$file" SessionEnd "$session claude")" -eq 1 ]
  done
  [ "$(count .codex/hooks.json SessionStart "$session codex")" -eq 1 ]
  [ "$(count .codex/hooks.json SessionEnd "$session codex")" -eq 0 ]
}

@test "adds no Codex hook file when Codex is not set up" {
  run_install

  [ ! -e "$home/.codex" ]
}
