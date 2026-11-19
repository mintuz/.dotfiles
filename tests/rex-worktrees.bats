#!/usr/bin/env bats
# Runs the worktree actions of rex/.config/rex/worktrees.lua with `rex do`,
# against a temporary home directory. The prompts and the server calls are
# replaced, so the test changes nothing in the running Rex server.

setup() {
  command -v rex >/dev/null 2>&1 || skip "rex is not installed"
  export HOME="$BATS_TEST_TMPDIR/home"
  project="$HOME/Workspace/demo"
  mkdir -p "$project"
  git -C "$project" init -q -b main
  git -C "$project" -c user.name=t -c user.email=t@example.com commit -q --allow-empty -m first
}

# run_action ACTION ANSWERS runs ACTION with no arguments. ANSWERS is a Lua
# list of the answers that the prompts give, in order.
run_action() {
  REX_SESSION='' REX_BLOCK='' run rex do --json - <<EOF
local actions, answers, calls = {}, $2, {}
rex.action = function(action) actions[action.name] = action.run end
rex.bind = function() end
local function answer(opts)
  local reply = table.remove(answers, 1)
  -- "@n" answers with the id of row n.
  local row = type(reply) == "string" and reply:match("^@(%d+)\$")
  return row and opts.items[tonumber(row)].id or reply
end
rex.ui = { pick = answer, input = answer }
-- Records the arguments of session.create and session.new_window.
rex.call = function(_, args)
  calls[#calls + 1] = args
  return { session_id = "s" }
end
rex.client = { queue = function() end }
package.path = "$BATS_TEST_DIRNAME/../rex/.config/rex/?.lua;" .. package.path
dofile("$BATS_TEST_DIRNAME/../rex/.config/rex/worktrees.lua")
return { result = actions.$1({ session_id = "current" }, {}), calls = calls }
EOF
}

@test "makes a worktree for a new branch, opens it again, then removes it" {
  worktree="$HOME/.rex/worktrees/demo/feat-x"

  # Row 1 of the project picker is ~/.dotfiles, and row 2 is demo. "new" is the New worktree row.
  run_action worktree_session '{ "@2", "new", " feat/x " }'
  [ "$status" -eq 0 ]
  [ "$(git -C "$worktree" branch --show-current)" = feat/x ]
  [[ "$output" == *'"cwd": "'"$worktree"'"'* ]]
  [[ "$output" == *'"label": "demo · feat/x"'* ]]

  # Row 2 of the checkout picker is now the worktree.
  run_action worktree_session '{ "@2", "@2" }'
  [ "$status" -eq 0 ]
  [[ "$output" == *'"label": "demo · feat/x"'* ]]

  # A tab opens in the session that the action ran in.
  run_action worktree_tab '{ "@2", "@2" }'
  [ "$status" -eq 0 ]
  [[ "$output" == *'"session_id": "current"'* ]]
  [[ "$output" == *'"window_label": "demo · feat/x"'* ]]
  [[ "$output" == *'"cwd": "'"$worktree"'"'* ]]

  # A worktree with an untracked file stays.
  touch "$worktree/untracked"
  run_action worktree_remove '{ "@2", "@1" }'
  [ "$status" -ne 0 ]
  [ -d "$worktree" ]

  rm "$worktree/untracked"
  run_action worktree_remove '{ "@2", "@1" }'
  [ "$status" -eq 0 ]
  [ ! -e "$worktree" ]
  git -C "$project" rev-parse --verify --quiet refs/heads/feat/x
}
