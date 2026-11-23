#!/bin/sh
# Records the conversation of an agent's pane, so the Rex action Restore
# Agents… can resume it after a Rex server restart. Rex keeps block IDs across
# a restart, so the record, ~/.local/state/rex-agents/<block>.json, finds its
# pane again.
#
#     agent-session.sh claude|codex|omp|agy < hook-input.json
#
# The session hooks of Claude Code, Codex and Antigravity run the script, and
# omp/.omp/agent/extensions/rex-tab-title.ts runs it for omp. The input is the
# hook's JSON: session_id (or conversationId), cwd (or workspacePaths[0]),
# hook_event_name (or hookEventName) and, for SessionEnd, reason.
# Outside Rex, the script does nothing. It always exits 0, so a failure never
# stops the agent.

[ -n "${REX_SESSION:-}" ] && [ -n "${REX_BLOCK:-}" ] || exit 0
# The block ID becomes a file name, so it must not hold a "/".
case "$REX_BLOCK" in block:*) ;; *) exit 0 ;; esac
case "$REX_BLOCK" in *[!a-zA-Z0-9:-]*) exit 0 ;; esac

dir="${XDG_STATE_HOME:-$HOME/.local/state}/rex-agents"
record="$dir/$REX_BLOCK.json"
input=$(cat)

if [ "$(printf '%s' "$input" | jq -r '.hook_event_name // .hookEventName // empty')" = SessionEnd ]; then
  # A Rex server restart also ends the agent, with reason "other". Keep the
  # record then, and remove it only when the person ends the session.
  case "$(printf '%s' "$input" | jq -r '.reason // empty')" in
    prompt_input_exit | logout) rm -f "$record" ;;
  esac
  exit 0
fi

# The resume command of each agent. profile_var names the variable that selects the
# agent's profile, for example CLAUDE_CONFIG_DIR=~/.workclaude.
case "$1" in
  claude) resume='["claude", "--resume", $id]' profile_var=CLAUDE_CONFIG_DIR ;;
  codex) resume='["codex", "resume", $id]' profile_var=CODEX_HOME ;;
  omp) resume='["omp", "--resume=" + $id]' profile_var= ;;
  agy) resume='["agy", "--conversation", $id]' profile_var= ;;
  *) exit 0 ;;
esac
profile=
if [ -n "$profile_var" ] && [ -n "$(printenv "$profile_var")" ]; then
  profile="$profile_var=$(printenv "$profile_var")"
fi

umask 077
mkdir -p "$dir" || exit 0
temporary=$(mktemp "$dir/.record.XXXXXX") || exit 0
# Write a temporary file, then rename it, so a reader never sees half a record.
if printf '%s' "$input" | jq -e \
  --arg agent "$1" --arg session "$REX_SESSION" --arg block "$REX_BLOCK" --arg profile "$profile" \
  "(.session_id // .conversationId // empty) as \$id | (.cwd // .workspacePaths[0] // \"\") as \$cwd | select(\$id != \"\" and \$cwd != \"\") |
   {agent: \$agent, session: \$session, block: \$block, cwd: \$cwd,
    argv: ((if \$profile == \"\" then [] else [\"env\", \$profile] end) + $resume)}" \
  > "$temporary" 2>/dev/null; then
  mv -f "$temporary" "$record"
else
  rm -f "$temporary"
fi
exit 0
