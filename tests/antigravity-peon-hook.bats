#!/usr/bin/env bats
# Runs antigravity/.gemini/config/peon-hook.sh with a fake peon command, so
# the test plays no sounds and changes no live state.

setup() {
  mkdir -p "$BATS_TEST_TMPDIR/bin"
  cat > "$BATS_TEST_TMPDIR/bin/fake-peon" <<EOF
#!/bin/sh
cat >> "$BATS_TEST_TMPDIR/peon.log"
EOF
  chmod +x "$BATS_TEST_TMPDIR/bin/fake-peon"
}

run_hook() {
  PEON_HOOK_BIN="$BATS_TEST_TMPDIR/bin/fake-peon" run sh -c \
    'printf "%s" "$2" | sh "$1"' _ "$BATS_TEST_DIRNAME/../antigravity/.gemini/config/peon-hook.sh" "$1"
}

@test "translates SessionStart to peon-ping and returns empty JSON" {
  run_hook '{"hookEventName":"SessionStart","conversationId":"abc-123","cwd":"/work/app"}'

  [ "$status" -eq 0 ]
  [ "$output" = '{}' ]
  [ "$(jq -c . "$BATS_TEST_TMPDIR/peon.log")" = '{"hook_event_name":"SessionStart","notification_type":"","cwd":"/work/app","session_id":"antigravity-abc-123","permission_mode":"","source":"antigravity"}' ]
}

@test "falls back to workspacePaths when cwd is missing" {
  run_hook '{"hookEventName":"SessionStart","conversationId":"abc-123","workspacePaths":["/work/fallback"]}'

  [ "$status" -eq 0 ]
  [ "$output" = '{}' ]
  [ "$(jq -r '.cwd' "$BATS_TEST_TMPDIR/peon.log")" = '/work/fallback' ]
}

@test "translates normal Stop to Stop" {
  run_hook '{"hookEventName":"Stop","conversationId":"abc-123","cwd":"/work/app","terminationReason":"NO_TOOL_CALL"}'

  [ "$status" -eq 0 ]
  [ "$output" = '{}' ]
  [ "$(jq -r '.hook_event_name' "$BATS_TEST_TMPDIR/peon.log")" = 'Stop' ]
}

@test "stays silent when the user cancels a turn" {
  run_hook '{"hookEventName":"Stop","conversationId":"abc-123","cwd":"/work/app","terminationReason":"USER_CANCELED"}'

  [ "$status" -eq 0 ]
  [ "$output" = '{}' ]
  [ ! -e "$BATS_TEST_TMPDIR/peon.log" ]
}

@test "translates Stop with ERROR to PostToolUseFailure for Bash" {
  run_hook '{"hookEventName":"Stop","conversationId":"abc-123","cwd":"/work/app","terminationReason":"ERROR","error":"boom"}'

  [ "$status" -eq 0 ]
  [ "$output" = '{}' ]
  [ "$(jq -r '.hook_event_name' "$BATS_TEST_TMPDIR/peon.log")" = 'PostToolUseFailure' ]
  [ "$(jq -r '.tool_name' "$BATS_TEST_TMPDIR/peon.log")" = 'Bash' ]
  [ "$(jq -r '.error' "$BATS_TEST_TMPDIR/peon.log")" = 'boom' ]
}

@test "translates MAX_TOKEN_BUDGET_EXCEEDED Stop to PreCompact" {
  run_hook '{"hookEventName":"Stop","conversationId":"abc-123","cwd":"/work/app","terminationReason":"MAX_TOKEN_BUDGET_EXCEEDED"}'

  [ "$status" -eq 0 ]
  [ "$output" = '{}' ]
  [ "$(jq -r '.hook_event_name' "$BATS_TEST_TMPDIR/peon.log")" = 'PreCompact' ]
}

@test "translates PostToolUse failure to PostToolUseFailure and ignores success" {
  run_hook '{"hookEventName":"PostToolUse","conversationId":"abc-123","cwd":"/work/app","toolCall":{"name":"run_command"}}'
  [ "$status" -eq 0 ]
  [ "$output" = '{}' ]
  [ ! -e "$BATS_TEST_TMPDIR/peon.log" ]

  run_hook '{"hookEventName":"PostToolUse","conversationId":"abc-123","cwd":"/work/app","toolCall":{"name":"run_command"},"error":"exit status 1"}'
  [ "$status" -eq 0 ]
  [ "$output" = '{}' ]
  [ "$(jq -r '.hook_event_name' "$BATS_TEST_TMPDIR/peon.log")" = 'PostToolUseFailure' ]
  [ "$(jq -r '.tool_name' "$BATS_TEST_TMPDIR/peon.log")" = 'Bash' ]
  [ "$(jq -r '.error' "$BATS_TEST_TMPDIR/peon.log")" = 'exit status 1' ]
}

@test "exits 0 with empty JSON when peon-ping is not installed" {
  HOME="$BATS_TEST_TMPDIR/empty-home" CLAUDE_CONFIG_DIR="$BATS_TEST_TMPDIR/empty-home/.claude" \
    CLAUDE_PEON_DIR='' PEON_HOOK_BIN='' PATH="/usr/bin:/bin" \
    run sh -c 'printf "%s" "$2" | sh "$1"' _ \
      "$BATS_TEST_DIRNAME/../antigravity/.gemini/config/peon-hook.sh" \
      '{"hookEventName":"SessionStart","conversationId":"abc-123","cwd":"/work/app"}'

  [ "$status" -eq 0 ]
  [ "$output" = '{}' ]
}
