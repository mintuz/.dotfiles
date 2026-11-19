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
-- "@n" answers with the id of row n, and "=" with the prefilled value.
local function id(opts, reply)
  if reply == "=" then return opts.value end
  local row = type(reply) == "string" and reply:match("^@(%d+)\$")
  return row and opts.items[tonumber(row)].id or reply
end
local function answer(opts)
  local reply = table.remove(answers, 1)
  -- A table answers a multiple pick with a list of ids.
  if type(reply) ~= "table" then return id(opts, reply) end
  local ids = {}
  for i, r in ipairs(reply) do ids[i] = id(opts, r) end
  return ids
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

  # Row 1 of the project picker is ~/.dotfiles, and row 2 is demo. Row 1 of
  # the checkout picker is New worktree….
  run_action worktree_session '{ "@2", "@1", " feat/x " }'
  [ "$status" -eq 0 ]
  [ "$(git -C "$worktree" branch --show-current)" = feat/x ]
  [[ "$output" == *'"cwd": "'"$worktree"'"'* ]]
  [[ "$output" == *'"label": "demo · feat/x"'* ]]

  # Row 3 of the checkout picker, after New worktree… and main, is now the worktree.
  run_action worktree_session '{ "@2", "@3" }'
  [ "$status" -eq 0 ]
  [[ "$output" == *'"label": "demo · feat/x"'* ]]

  # A tab opens in the session that the action ran in.
  run_action worktree_tab '{ "@2", "@3" }'
  [ "$status" -eq 0 ]
  [[ "$output" == *'"session_id": "current"'* ]]
  [[ "$output" == *'"window_label": "demo · feat/x"'* ]]
  [[ "$output" == *'"cwd": "'"$worktree"'"'* ]]

  # A worktree with an untracked file stays. Row 1 of the remove picker is All worktrees.
  touch "$worktree/untracked"
  run_action worktree_remove '{ "@2", { "@2" } }'
  [ "$status" -ne 0 ]
  [ -d "$worktree" ]

  # The branch has no commits of its own, so it goes with the worktree.
  rm "$worktree/untracked"
  run_action worktree_remove '{ "@2", { "@2" } }'
  [ "$status" -eq 0 ]
  [ ! -e "$worktree" ]
  ! git -C "$project" rev-parse --verify --quiet refs/heads/feat/x
}

@test "names a new worktree after the project, and removes all worktrees but keeps unmerged branches" {
  run_action worktree_tab '{ "@2", "@1", "=" }'
  [ "$status" -eq 0 ]
  [[ "$output" =~ \"window_label\":\ \"demo\ ·\ (demo-[a-z0-9]{6})\" ]]
  random="${BASH_REMATCH[1]}"
  [ -d "$HOME/.rex/worktrees/demo/$random" ]

  run_action worktree_tab '{ "@2", "@1", "kept" }'
  [ "$status" -eq 0 ]
  git -C "$HOME/.rex/worktrees/demo/kept" -c user.name=t -c user.email=t@example.com commit -q --allow-empty -m work

  run_action worktree_remove '{ "@2", { "@1" } }'
  [ "$status" -eq 0 ]
  [ ! -e "$HOME/.rex/worktrees/demo/$random" ]
  [ ! -e "$HOME/.rex/worktrees/demo/kept" ]
  ! git -C "$project" rev-parse --verify --quiet "refs/heads/$random"
  git -C "$project" rev-parse --verify --quiet refs/heads/kept
}

@test "removes merged worktrees without changes, and keeps the others" {
  for name in done dirty work; do
    run_action worktree_tab "{ \"@2\", \"@1\", \"$name\" }"
    [ "$status" -eq 0 ]
  done
  touch "$HOME/.rex/worktrees/demo/dirty/untracked"
  git -C "$HOME/.rex/worktrees/demo/work" -c user.name=t -c user.email=t@example.com commit -q --allow-empty -m work

  # Only done is listed, ticked. The answer confirms the ticked rows.
  run_action worktree_prune '{ "@2", { "@1" } }'
  [ "$status" -eq 0 ]
  [ ! -e "$HOME/.rex/worktrees/demo/done" ]
  ! git -C "$project" rev-parse --verify --quiet refs/heads/done
  [ -d "$HOME/.rex/worktrees/demo/dirty" ]
  [ -d "$HOME/.rex/worktrees/demo/work" ]

  run_action worktree_prune '{ "@2" }'
  [ "$status" -ne 0 ]
  [[ "$output" == *"no merged worktrees"* ]]
}
