#!/usr/bin/env bats
# Runs rex/.config/rex/agent-session.sh against a temporary state folder, so
# the test changes no record of a real pane.

setup() {
  export XDG_STATE_HOME="$BATS_TEST_TMPDIR/state"
  record="$XDG_STATE_HOME/rex-agents/block:b1.json"
}

# run_hook AGENT JSON runs the hook in pane block:b1 with JSON as its input.
run_hook() {
  REX_SESSION=session:s1 REX_BLOCK=block:b1 run sh -c \
    'printf "%s" "$2" | sh "$1" "$3"' _ "$BATS_TEST_DIRNAME/../rex/.config/rex/agent-session.sh" "$2" "$1"
}

start='{"hook_event_name":"SessionStart","session_id":"id1","cwd":"/work/my app"}'

@test "records the resume command of a Claude Code pane" {
  unset CLAUDE_CONFIG_DIR
  run_hook claude "$start"

  [ "$status" -eq 0 ]
  [ "$(jq -c . "$record")" = '{"agent":"claude","session":"session:s1","block":"block:b1","cwd":"/work/my app","argv":["claude","--resume","id1"]}' ]
}

@test "keeps the Claude Code profile of the pane" {
  CLAUDE_CONFIG_DIR=/home/me/.workclaude run_hook claude "$start"

  [ "$(jq -c .argv "$record")" = '["env","CLAUDE_CONFIG_DIR=/home/me/.workclaude","claude","--resume","id1"]' ]
}

@test "records the resume commands of Codex and omp" {
  unset CODEX_HOME
  run_hook codex "$start"
  [ "$(jq -c .argv "$record")" = '["codex","resume","id1"]' ]

  run_hook omp "$start"
  [ "$(jq -c .argv "$record")" = '["omp","--resume=id1"]' ]
}

@test "removes the record only when the person ends the session" {
  run_hook claude "$start"
  run_hook claude '{"hook_event_name":"SessionEnd","reason":"other"}'
  [ -f "$record" ]

  run_hook claude '{"hook_event_name":"SessionEnd","reason":"prompt_input_exit"}'
  [ ! -e "$record" ]
}

@test "writes nothing without a session ID" {
  run_hook claude '{"hook_event_name":"SessionStart","cwd":"/work"}'

  [ "$status" -eq 0 ]
  [ ! -e "$record" ]
  [ -z "$(ls -A "$XDG_STATE_HOME/rex-agents")" ]
}

@test "does nothing outside Rex or for a block ID with a slash" {
  REX_SESSION='' REX_BLOCK='' run sh "$BATS_TEST_DIRNAME/../rex/.config/rex/agent-session.sh" claude <<< "$start"
  [ "$status" -eq 0 ]
  REX_SESSION=s REX_BLOCK=block:../x run sh "$BATS_TEST_DIRNAME/../rex/.config/rex/agent-session.sh" claude <<< "$start"
  [ "$status" -eq 0 ]
  [ ! -e "$XDG_STATE_HOME" ]
}
