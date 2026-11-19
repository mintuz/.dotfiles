#!/usr/bin/env bats
# Runs the action of rex/.config/rex/open-in.lua with `rex do`. The pane and
# the open command are replaced, so the test opens no editor.

setup() {
  command -v rex >/dev/null 2>&1 || skip "rex is not installed"
  project="$BATS_TEST_TMPDIR/my project"
  mkdir -p "$project/sub dir"
  git -C "$project" init -q
}

# run_action PANE_URL runs open_in_cursor with the focused pane at PANE_URL.
run_action() {
  REX_SESSION='' REX_BLOCK='' run rex do --json - <<EOF2
local action
rex.action = function(a) action = a.run end
rex.bind = function() end
rex.block = { call = function() return { pwd = "$1" } end }
-- Records the arguments of open, and runs every other command.
local exec, opened = rex.exec, nil
rex.exec = function(argv, opts)
  if argv[1] ~= "open" then return exec(argv, opts) end
  opened = argv
  return { ok = true }
end
package.path = "$BATS_TEST_DIRNAME/../rex/.config/rex/?.lua;" .. package.path
dofile("$BATS_TEST_DIRNAME/../rex/.config/rex/open-in.lua")
return { result = action({}, {}), opened = opened }
EOF2
}

@test "opens the repository of the focused pane in Cursor" {
  run_action "file://host${project// /%20}/sub%20dir"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"result": "'"$project"'"'* ]]
  [[ "$output" == *'"Cursor"'* ]]
}

@test "opens the folder of a pane outside a repository" {
  run_action "file://host$BATS_TEST_TMPDIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"result": "'"$BATS_TEST_TMPDIR"'"'* ]]
}

@test "fails when the pane has not reported its folder" {
  run_action ""
  [ "$status" -ne 0 ]
  [[ "$output" == *"has not reported its folder"* ]]
}
