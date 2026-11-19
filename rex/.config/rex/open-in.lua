-- Open in: open the repository of the focused pane in an editor. In a
-- worktree, that is the worktree. Outside a repository, it is the pane's folder.
--
--     rex do open_in_cursor

local h = require("helpers")
local fail = h.failer("open-in")

-- pane_dir returns the folder of the focused pane.
local function pane_dir()
  local dir, err = h.pane_dir()
  if dir == nil then fail(err) end
  return dir
end

-- project_dir returns the top folder of the repository that holds dir, or dir.
local function project_dir(dir)
  local top = h.git(dir, "rev-parse", "--show-toplevel")
  if top ~= nil then return (top:gsub("%s+$", "")) end
  return dir
end

rex.action{
  name = "open_in_cursor",
  title = "Open in Cursor",
  description = "Open the repository of the focused pane in Cursor",
  category = "Editor",
  keywords = "editor ide project folder worktree",
  run = function(ctx, args)
    local path = project_dir(pane_dir())
    -- open -a needs no cursor command on the server's PATH.
    local r, err = rex.exec({ "open", "-a", "Cursor", path })
    if r == nil then fail(err) end
    if not r.ok then fail(r.stderr) end
    return path
  end,
}

rex.bind("alt+cmd+o", "open_in_cursor")
