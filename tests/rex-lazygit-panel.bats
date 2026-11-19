#!/usr/bin/env bats
# Runs the action of rex/.config/rex/lazygit-panel.lua with `rex do`. The pane
# and session.new_layer are replaced, so the test opens no pane.

setup() {
  command -v rex >/dev/null 2>&1 || skip "rex is not installed"
  dir="$BATS_TEST_TMPDIR/my dir"
}

# run_action PANE_URL runs lazygit_float with the focused pane at PANE_URL.
run_action() {
  REX_SESSION='' REX_BLOCK='' run rex do --json - <<EOF2
local action
rex.action = function(a) action = a.run end
rex.bind = function() end
rex.block = { call = function() return { pwd = "$1" } end }
-- Records the layer that the action asks for.
local layer
rex.session = { new_layer = function(spec) layer = spec return {} end }
package.path = "$BATS_TEST_DIRNAME/../rex/.config/rex/?.lua;" .. package.path
dofile("$BATS_TEST_DIRNAME/../rex/.config/rex/lazygit-panel.lua")
action({}, {})
return layer
EOF2
}

@test "opens lazygit in the folder of the focused pane in a floating pane" {
  run_action "file://host${dir// /%20}"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"lazygit"'* ]]
  [[ "$output" == *'"cwd": "'"$dir"'"'* ]]
  [[ "$output" == *'"focus": true'* ]]
}

@test "fails when the pane has not reported its folder" {
  run_action ""
  [ "$status" -ne 0 ]
  [[ "$output" == *"lazygit-panel: the focused pane has not reported its folder"* ]]
}
