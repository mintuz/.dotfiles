#!/usr/bin/env bats
# Runs install.sh from a temporary checkout against a temporary home directory.

setup() {
  home="$BATS_TEST_TMPDIR/home"
  checkout="$BATS_TEST_TMPDIR/checkout"
  mkdir -p "$home" "$checkout"/{zsh,pnpm,claude} \
    "$checkout/omp/.omp/agent" \
    "$checkout/mise/.config/mise/conf.d" \
    "$checkout/agents/.agents/skills"/{typescript,other}
  cp "$BATS_TEST_DIRNAME/../install.sh" "$checkout/install.sh"
  printf 'managed\n' > "$checkout/zsh/.zshrc"
  printf 'managed\n' > "$checkout/omp/.omp/agent/config.yml"
  printf 'managed\n' > "$checkout/mise/.config/mise/conf.d/dotfiles.toml"
  printf 'managed\n' > "$checkout/agents/.agents/skills/typescript/SKILL.md"
  printf 'managed\n' > "$checkout/agents/.agents/skills/other/SKILL.md"
  git -C "$checkout" init -q
  git -C "$checkout" add agents
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
