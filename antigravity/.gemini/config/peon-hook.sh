#!/bin/sh
# Translates Antigravity lifecycle hook payloads on stdin into peon-ping's
# CESP JSON format and invokes peon.sh, then prints "{}" on stdout as required
# by Antigravity's hooks.json contract. Always exits 0 so a failure never
# blocks Antigravity.

finish() {
  printf '{}\n'
  exit 0
}

command -v jq >/dev/null 2>&1 || finish

# Resolve peon.sh. Prefer an explicit override (used in tests), then the
# installed Claude Code hook copy (which shares config.json and packs), then
# the Homebrew peon CLI on PATH.
peon_cmd=""
if [ -n "${PEON_HOOK_BIN:-}" ] && [ -x "$PEON_HOOK_BIN" ]; then
  peon_cmd="$PEON_HOOK_BIN"
elif [ -n "${CLAUDE_PEON_DIR:-}" ] && [ -f "$CLAUDE_PEON_DIR/peon.sh" ]; then
  peon_cmd="$CLAUDE_PEON_DIR/peon.sh"
elif [ -f "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/hooks/peon-ping/peon.sh" ]; then
  peon_cmd="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/hooks/peon-ping/peon.sh"
elif command -v peon >/dev/null 2>&1; then
  peon_cmd="$(command -v peon)"
else
  finish
fi

input="$(cat)"
[ -n "$input" ] || finish

payload="$(printf '%s' "$input" | jq -c '
  (.hookEventName // "") as $raw |
  (.conversationId // "") as $id |
  (.cwd // .workspacePaths[0] // "") as $cwd |
  (.error // "") as $err |
  (.terminationReason // "") as $reason |
  (if $raw == "SessionStart" then
     {event: "SessionStart"}
   elif $raw == "PostToolUse" and $err != "" then
     {event: "PostToolUseFailure", tool_name: "Bash", error: $err}
   elif $raw == "Stop" then
     if $reason == "USER_CANCELED" then empty
     elif $reason == "ERROR" then
       {event: "PostToolUseFailure", tool_name: "Bash", error: (if $err != "" then $err else "Execution error" end)}
     elif $reason == "MAX_TOKEN_BUDGET_EXCEEDED" then
       {event: "PreCompact"}
     else
       {event: "Stop"}
     end
   else
     empty
   end) |
  {
    hook_event_name: .event,
    notification_type: "",
    cwd: $cwd,
    session_id: (if $id != "" then "antigravity-" + $id else "antigravity" end),
    permission_mode: "",
    source: "antigravity"
  } + (if .tool_name then {tool_name: .tool_name, error: .error} else {} end)
' 2>/dev/null)" || finish

[ -n "$payload" ] || finish

# Redirect stdout and stderr to /dev/null so backgrounded audio playback
# inside peon.sh never inherits Antigravity's stdout pipe or corrupts JSON.
if [ -x "$peon_cmd" ]; then
  printf '%s\n' "$payload" | "$peon_cmd" >/dev/null 2>&1 || true
else
  printf '%s\n' "$payload" | bash "$peon_cmd" >/dev/null 2>&1 || true
fi

finish
