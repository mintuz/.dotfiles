-- Lazygit panel: open lazygit for the folder of the focused pane in a
-- floating pane.
--
--     rex do lazygit_float

local h = require("helpers")
local fail = h.failer("lazygit-panel")

rex.action{
  name = "lazygit_float",
  title = "Open Lazygit in Floating Pane",
  description = "Open lazygit for the folder of the focused pane in a floating pane",
  category = "Git",
  keywords = "git",
  run = function(ctx, args)
    local dir, err = h.pane_dir()
    if dir == nil then fail(err) end
    local _, err = rex.session.new_layer{
      bounds = { 0.05, 0.05, 0.9, 0.9 },
      focus = true,
      layout = h.shell(dir, { "lazygit" }),
    }
    if err ~= nil then fail(err) end
  end,
}

rex.bind("alt+cmd+g", "lazygit_float")
