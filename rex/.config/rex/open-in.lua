-- Open in: open the repository of the focused pane in an editor. In a
-- worktree, that is the worktree. Outside a repository, it is the pane's folder.
--
--     rex do open_in_cursor

local function fail(message)
  error("open-in: " .. tostring(message), 0)
end

-- pane_dir returns the folder of the focused pane. The terminal reports it as
-- a URL, file://<host>/<path>, with %XX escapes.
local function pane_dir()
  local r, err = rex.block.call("com.superlogical.terminal", "pwd")
  if r == nil then fail(err) end
  local dir = r.pwd and r.pwd:match("^file://[^/]*(/.*)$")
  if dir == nil then fail("the focused pane has not reported its folder") end
  return (dir:gsub("%%(%x%x)", function(hex) return string.char(tonumber(hex, 16)) end))
end

-- project_dir returns the top folder of the repository that holds dir, or dir.
local function project_dir(dir)
  local r = rex.exec({ "git", "-C", dir, "rev-parse", "--show-toplevel" })
  if r ~= nil and r.ok then return (r.stdout:gsub("%s+$", "")) end
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
