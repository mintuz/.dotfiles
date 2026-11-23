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
    "$checkout/antigravity/.gemini/config" \
    "$checkout/agents/.agents/skills"/{typescript,other} \
    "$checkout/agents/.agents/agents"
  cp "$BATS_TEST_DIRNAME/../install.sh" "$checkout/install.sh"
  printf 'managed\n' > "$checkout/zsh/.zshrc"
  printf 'managed\n' > "$checkout/omp/.omp/agent/config.yml"
  printf 'managed\n' > "$checkout/mise/.config/mise/conf.d/dotfiles.toml"
  printf 'managed\n' > "$checkout/rex/.config/rex/init.lua"
  printf '{}\n' > "$checkout/antigravity/.gemini/config/hooks.json"
  printf '#!/bin/sh\n' > "$checkout/antigravity/.gemini/config/peon-hook.sh"
  printf '{"entries":[{"path":"~/.agents/skills"}]}\n' > "$checkout/antigravity/.gemini/config/skills.json"
  printf 'managed rules\n' > "$checkout/antigravity/.gemini/config/AGENTS.md"
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
  # Fake agy records installed plugin names (from the last path segment).
  cat > "$BATS_TEST_TMPDIR/bin/agy" <<EOF
#!/bin/sh
echo "\$1 \$2 \$(basename "\$3")" >> "$BATS_TEST_TMPDIR/agy.log"
EOF
  chmod +x "$BATS_TEST_TMPDIR/bin/agy"
  # Local git repo mirroring mintuz/skills so tests need no network.
  skills_repo="$BATS_TEST_TMPDIR/mintuz-skills"
  mkdir -p "$skills_repo/.claude-plugin" "$skills_repo/src/core" "$skills_repo/src/app"
  printf '{"name":"mintuz-skills","plugins":[{"name":"core","source":"./src/core"},{"name":"app","source":"./src/app"}]}\n' \
    > "$skills_repo/.claude-plugin/marketplace.json"
  printf '{"name":"core"}\n' > "$skills_repo/src/core/plugin.json"
  printf '{"name":"app"}\n' > "$skills_repo/src/app/plugin.json"
  git -C "$skills_repo" init -q
  git -C "$skills_repo" config user.email test@example.com
  git -C "$skills_repo" config user.name Test
  git -C "$skills_repo" add .
  git -C "$skills_repo" commit -q -m init
  git -C "$checkout" init -q
  git -C "$checkout" add agents claude workclaude omp
}

run_install() {
  HOME="$home" PATH="$BATS_TEST_TMPDIR/bin:$PATH" \
    MINTUZ_SKILLS_REPO="${MINTUZ_SKILLS_REPO:-$skills_repo}" \
    TALAT_MCP_BIN="${TALAT_MCP_BIN:-$BATS_TEST_TMPDIR/no-talat}" \
    TWODO_MCP_BIN="${TWODO_MCP_BIN:-$BATS_TEST_TMPDIR/no-twodo}" \
    "$checkout/install.sh"
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

@test "sets up RTK in the personal and work Claude Code profiles and Antigravity" {
  run_install

  [ "$(cat "$BATS_TEST_TMPDIR/rtk.log")" = "$home/.claude init --global --auto-patch
$home/.workclaude init --global --auto-patch
 init --global --agent antigravity --auto-patch" ]
}

@test "keeps ~/.gemini/config real, backs up real Antigravity files, and links managed ones" {
  mkdir -p "$home/.gemini/config"
  printf '{"local": true}\n' > "$home/.gemini/config/hooks.json"
  printf '{"entries": []}\n' > "$home/.gemini/config/skills.json"
  printf 'old rules\n' > "$home/.gemini/config/AGENTS.md"
  printf '{"mcpServers": {"work": {"url": "https://work.example/mcp"}}}\n' > "$home/.gemini/config/mcp_config.json"

  run_install

  [ ! -L "$home/.gemini" ]
  [ ! -L "$home/.gemini/config" ]
  [ -L "$home/.gemini/config/hooks.json" ]
  [ -L "$home/.gemini/config/peon-hook.sh" ]
  [ -L "$home/.gemini/config/skills.json" ]
  [ -L "$home/.gemini/config/AGENTS.md" ]
  [ ! -L "$home/.gemini/config/mcp_config.json" ]
  [ "$(cat "$(backups)/.gemini/config/hooks.json")" = '{"local": true}' ]
  [ "$(cat "$(backups)/.gemini/config/skills.json")" = '{"entries": []}' ]
  [ "$(cat "$(backups)/.gemini/config/AGENTS.md")" = 'old rules' ]
  [ ! -e "$checkout/antigravity/.gemini/config/mcp_config.json" ]
}

@test "merges Antigravity MCP servers conditionally and keeps local ones" {
  mkdir -p "$home/.gemini/config"
  printf '{"mcpServers": {"work": {"url": "https://work.example/mcp"}}}\n' > "$home/.gemini/config/mcp_config.json"

  run_install

  mcp="$home/.gemini/config/mcp_config.json"
  [ "$(jq -r '.mcpServers.work.url' "$mcp")" = 'https://work.example/mcp' ]
  [ "$(jq -r '.mcpServers.notion.url' "$mcp")" = 'https://mcp.notion.com/mcp' ]
  [ "$(jq -r '.mcpServers.mobbin.url' "$mcp")" = 'https://api.mobbin.com/mcp' ]
  [ "$(jq -r '.mcpServers.revenuecat.url' "$mcp")" = 'https://mcp.revenuecat.ai/mcp' ]
  [ "$(jq -r '.mcpServers.tally.url' "$mcp")" = 'https://api.tally.so/mcp' ]
  [ "$(jq -e '.mcpServers | has("talat") | not' "$mcp")" = true ]
  [ "$(jq -e '.mcpServers | has("2do") | not' "$mcp")" = true ]

  # When talat and 2do binaries exist, both are registered with their resolved paths.
  talat="$BATS_TEST_TMPDIR/talat_mcp"
  twodo="$home/Library/Application Support/Claude/Claude Extensions/local.mcpb.beehive-innovations.2do/dist/TwoDoMCPBridge"
  mkdir -p "$(dirname "$twodo")"
  printf '#!/bin/sh\n' > "$talat"
  printf '#!/bin/sh\n' > "$twodo"
  chmod +x "$talat" "$twodo"

  TALAT_MCP_BIN="$talat" TWODO_MCP_BIN="$twodo" run_install

  [ "$(jq -r '.mcpServers.talat.command' "$mcp")" = '/usr/bin/python3' ]
  [[ "$(jq -r '.mcpServers.talat.args[1]' "$mcp")" == *"$talat"* ]]
  [ "$(jq -r '.mcpServers["2do"].command' "$mcp")" = "$twodo" ]
  [ "$(jq -r '.mcpServers.work.url' "$mcp")" = 'https://work.example/mcp' ]
}

@test "syncs Antigravity plugins from mintuz/skills and falls back cleanly when offline" {
  run_install

  [ "$(cat "$BATS_TEST_TMPDIR/agy.log")" = "plugin install core
plugin install app" ]

  # Offline with local Claude marketplace cache falls back to the cache.
  rm -f "$BATS_TEST_TMPDIR/agy.log"
  mkdir -p "$home/.claude/plugins/marketplaces"
  cp -R "$skills_repo" "$home/.claude/plugins/marketplaces/mintuz-skills"
  MINTUZ_SKILLS_REPO="$BATS_TEST_TMPDIR/missing-repo" run_install

  [ "$(cat "$BATS_TEST_TMPDIR/agy.log")" = "plugin install core
plugin install app" ]

  # Offline with no local cache prints a message and continues cleanly.
  rm -rf "$BATS_TEST_TMPDIR/agy.log" "$home/.claude/plugins/marketplaces/mintuz-skills"
  MINTUZ_SKILLS_REPO="$BATS_TEST_TMPDIR/missing-repo" run run_install

  [ "$status" -eq 0 ]
  [[ "$output" == *"Antigravity plugin sync from mintuz/skills failed"* ]]
  [ ! -e "$BATS_TEST_TMPDIR/agy.log" ]
}

@test "sets up peon-ping with the J.A.R.V.I.S. pack and no pop-ups in both Claude Code profiles" {
  run_install

  [ "$(cat "$BATS_TEST_TMPDIR/peon.log")" = "$home/.claude peon-ping-setup --packs=jarvis-mk2
$home/.claude peon packs use jarvis-mk2
$home/.claude peon notifications off
$home/.workclaude peon-ping-setup --packs=jarvis-mk2
$home/.workclaude peon packs use jarvis-mk2
$home/.workclaude peon notifications off" ]
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
