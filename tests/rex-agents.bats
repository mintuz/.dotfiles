#!/usr/bin/env bats
# Runs the action of rex/.config/rex/agents.lua with `rex do`, against a
# temporary state folder. The panes and the prompt are replaced, so the test
# types into no real pane.

setup() {
  command -v rex >/dev/null 2>&1 || skip "rex is not installed"
  export XDG_STATE_HOME="$BATS_TEST_TMPDIR/state"
  mkdir -p "$XDG_STATE_HOME/rex-agents"
  # Pane b1 is a shell prompt, b2 runs vim, and b3 holds a bad record.
  printf '{"agent":"claude","session":"s","block":"block:b1","cwd":"/work/it'"'"'s","argv":["claude","--resume","id1"]}' \
    > "$XDG_STATE_HOME/rex-agents/block:b1.json"
  printf '{"agent":"codex","session":"s","block":"block:b2","cwd":"/work","argv":["codex","resume","id2"]}' \
    > "$XDG_STATE_HOME/rex-agents/block:b2.json"
  printf '{"agent":"omp","session":"s","block":"block:b3","cwd":"/work","argv":["omp","x\\ry"]}' \
    > "$XDG_STATE_HOME/rex-agents/block:b3.json"
}

# run_action ANSWER runs restore_agents. ANSWER is the id that the picker
# returns, as Lua, or nil to cancel.
run_action() {
  REX_SESSION='' REX_BLOCK='' run rex do --json - <<EOF2
local action, rows, written = nil, nil, {}
rex.action = function(a) action = a.run end
rex.bind = function() end
local foreground = { ["block:b1"] = "-zsh", ["block:b2"] = "vim", ["block:b3"] = "zsh" }
rex.block = { call = function(_, method, args)
  if method == "write" then written[#written + 1] = args.data return {} end
  return { foreground = { name = foreground[args.block_id] }, ancestors = { { name = "login" } } }
end }
rex.ui = { pick = function(opts)
  rows = {}
  for _, item in ipairs(opts.items) do rows[#rows + 1] = item.id end
  return $1, "cancelled"
end }
dofile("$BATS_TEST_DIRNAME/../rex/.config/rex/agents.lua")
return { result = action({}, {}), rows = rows, written = written }
EOF2
}

@test "lists only idle panes with a valid record and types the quoted command" {
  run_action '"block:b1"'

  [ "$status" -eq 0 ]
  [[ "$output" == *'"rows": ['*'"block:b1"'*']'* ]]
  [[ "$output" != *'"block:b2"'* ]]
  [[ "$output" != *'"block:b3"'* ]]
  [[ "$output" != *'"all"'* ]]
  [ "$(jq -r '.written[0]' <<< "$output")" = "cd -- '/work/it'\\''s' && 'claude' '--resume' 'id1'"$'\r' ]
}

@test "types nothing when the person cancels" {
  run_action nil

  [ "$status" -eq 0 ]
  [ "$(jq '.written | length' <<< "$output")" -eq 0 ]
}
