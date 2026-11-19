-- Rex configuration, migrated from Herdr and Ghostty.
-- Neither source had a key binding to migrate, so Rex's defaults apply.

require("worktrees")
require("open-in")
require("lazygit-panel")
require("agents")

-- Start worktree-watch.lua, unless an earlier load of this file started it.
-- It stops when the Rex server stops.
local h = require("helpers")
local watch = h.home .. "/.config/rex/worktree-watch.lua"
if not rex.exec({ "pgrep", "-f", "worktree-watch.lua --all" }).ok then
  rex.exec.start({ h.REX, "do", watch, "--all" }, { detach = true })
end
