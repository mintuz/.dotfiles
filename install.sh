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
for relative in .zshrc .omp/agent/config.yml .config/rex/init.lua \
  .gemini/config/hooks.json .gemini/config/peon-hook.sh \
  .gemini/config/skills.json .gemini/config/AGENTS.md; do
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

# Keep ~/.gemini/config real so stow links only our managed Antigravity hook
# files, and Antigravity's settings, MCP config and installed plugins stay out
# of this repo.
mkdir -p "$HOME/.gemini/config"

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
stow --target="$HOME" --restow --ignore='\.DS_Store' --ignore='config\.yml\.lock' zsh agents pnpm claude workclaude omp mise rex antigravity

# Set up RTK in each Claude Code profile and in Antigravity. rtk writes RTK.md
# and its hook into each local Claude profile directory, and its Antigravity
# plugin into ~/.gemini/config/plugins/rtk, so none of it reaches this repo.
# The shared CLAUDE.md already imports @RTK.md.
if command -v rtk >/dev/null 2>&1; then
  for profile in .claude .workclaude; do
    CLAUDE_CONFIG_DIR="$HOME/$profile" rtk init --global --auto-patch
  done
  rtk init --global --agent antigravity --auto-patch
fi

# Set up peon-ping in each Claude Code profile, select the J.A.R.V.I.S.
# pack and turn off its desktop pop-ups. The sounds still play. The Homebrew
# setup writes its hooks, skills and config.json into the profile's local
# directory and its packs into ~/.openpeon, so none of them reaches this repo. A failure, such as no network, does not stop the install.
if command -v peon-ping-setup >/dev/null 2>&1; then
  for profile in .claude .workclaude; do
    (export CLAUDE_CONFIG_DIR="$HOME/$profile"
      peon-ping-setup --packs=jarvis-mk2 && peon packs use jarvis-mk2 &&
      peon notifications off) ||
      echo "peon-ping setup failed for ~/$profile"
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

  # Merge managed Antigravity MCP servers into ~/.gemini/config/mcp_config.json
  # while keeping any extra local or work servers intact. Always register the
  # portable remote HTTP servers; register talat and 2do only when their local
  # binaries exist on this machine.
  mcp_file="$HOME/.gemini/config/mcp_config.json"
  [ -f "$mcp_file" ] || printf '{}\n' > "$mcp_file"
  talat_bin="${TALAT_MCP_BIN:-/Applications/talat.app/Contents/MacOS/talat_mcp}"
  twodo_bin="${TWODO_MCP_BIN:-$HOME/Library/Application Support/Claude/Claude Extensions/local.mcpb.beehive-innovations.2do/dist/TwoDoMCPBridge}"
  has_talat=false
  [ -x "$talat_bin" ] && has_talat=true
  has_twodo=false
  [ -x "$twodo_bin" ] && has_twodo=true
  talat_py="import json, signal, subprocess, sys
proc = None
def cleanup(sig, _):
    if proc and proc.poll() is None:
        proc.terminate()
    sys.exit(0)
signal.signal(signal.SIGTERM, cleanup)
signal.signal(signal.SIGINT, cleanup)
while True:
    line = sys.stdin.buffer.readline()
    if not line:
        break
    if proc is None:
        try:
            msg = json.loads(line)
        except Exception:
            msg = {}
        if isinstance(msg, dict) and msg.get('method') == 'server/discover':
            resp = {'jsonrpc': '2.0', 'id': msg.get('id'), 'error': {'code': -32601, 'message': 'Method not found'}}
            sys.stdout.buffer.write((json.dumps(resp) + chr(10)).encode())
            sys.stdout.buffer.flush()
            continue
        proc = subprocess.Popen(['$talat_bin'], stdin=subprocess.PIPE)
    try:
        proc.stdin.write(line)
        proc.stdin.flush()
    except BrokenPipeError:
        break
if proc:
    proc.stdin.close()
    sys.exit(proc.wait())"
  updated_mcp="$(jq \
    --argjson has_talat "$has_talat" \
    --arg talat_py "$talat_py" \
    --argjson has_twodo "$has_twodo" \
    --arg twodo_bin "$twodo_bin" \
    '
      .mcpServers = (
        (.mcpServers // {}) + {
          notion: {url: "https://mcp.notion.com/mcp"},
          mobbin: {url: "https://api.mobbin.com/mcp"},
          revenuecat: {url: "https://mcp.revenuecat.ai/mcp"},
          tally: {url: "https://api.tally.so/mcp"}
        }
        + (if $has_talat then {talat: {command: "/usr/bin/python3", args: ["-c", $talat_py]}} else {} end)
        + (if $has_twodo then {"2do": {command: $twodo_bin}} else {} end)
      )
    ' "$mcp_file")"
  printf '%s\n' "$updated_mcp" > "$mcp_file"
else
  echo "jq is not installed, so the Rex hooks and Antigravity MCP config were not updated"
fi

# Sync Antigravity plugins from mintuz/skills when agy is on PATH. Prefer a
# fresh shallow clone and fall back to Claude Code's local marketplace cache
# when offline. A failure, such as no network on a new machine, does not stop
# the install.
if command -v agy >/dev/null 2>&1; then
  sync_antigravity_plugins() {
    local repo="${MINTUZ_SKILLS_REPO:-https://github.com/mintuz/skills.git}"
    local cache="$HOME/.claude/plugins/marketplaces/mintuz-skills"
    local tmp_dir=""
    local src_dir=""

    tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/mintuz-skills.XXXXXX")" || return 1
    if git clone --quiet --depth 1 "$repo" "$tmp_dir" 2>/dev/null; then
      src_dir="$tmp_dir"
    elif [ -d "$cache" ]; then
      src_dir="$cache"
    else
      rm -rf "$tmp_dir"
      return 1
    fi

    local status=0
    local sources=""
    if command -v jq >/dev/null 2>&1 && [ -f "$src_dir/.claude-plugin/marketplace.json" ]; then
      sources="$(jq -r '.plugins[].source // empty' "$src_dir/.claude-plugin/marketplace.json")"
    fi
    if [ -n "$sources" ]; then
      while IFS= read -r rel; do
        [ -n "$rel" ] || continue
        agy plugin install "$src_dir/$rel" || status=1
      done <<EOF
$sources
EOF
    else
      for plugin_dir in "$src_dir"/src/*; do
        [ -d "$plugin_dir" ] || continue
        agy plugin install "$plugin_dir" || status=1
      done
    fi
    rm -rf "$tmp_dir"
    return "$status"
  }
  sync_antigravity_plugins || echo "Antigravity plugin sync from mintuz/skills failed"
fi
