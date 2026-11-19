-- Helpers that more than one Rex config file uses.

local M = {}

M.home = os.getenv("HOME")
-- The rex command. The Rex server's PATH does not hold it.
M.REX = M.home .. "/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS/rex"
-- The block type of a terminal, and the flavor of a shell pane.
M.TERMINAL = "com.superlogical.terminal"
M.SHELL = "com.superlogical.terminal.shell"

-- failer returns a function that stops an action with "<name>: <message>".
function M.failer(name)
  return function(message)
    error(name .. ": " .. tostring(message), 0)
  end
end

-- short writes the home folder at the start of path as ~.
function M.short(path)
  if path:sub(1, #M.home + 1) == M.home .. "/" then return "~" .. path:sub(#M.home + 1) end
  return path
end

-- git runs git in dir and returns what it printed, or nil and git's message.
-- Arguments go as a list, never through a shell, so no quoting is needed.
function M.git(dir, ...)
  local r, err = rex.exec({ "git", "-C", dir, ... })
  if r == nil then return nil, err end
  if not r.ok then return nil, r.stderr end
  return r.stdout
end

-- url_path returns the path of a terminal's folder URL, file://<host>/<path>
-- with %XX escapes, or nil.
function M.url_path(url)
  local dir = url and url:match("^file://[^/]*(/.*)$")
  return dir and (dir:gsub("%%(%x%x)", function(hex) return string.char(tonumber(hex, 16)) end))
end

-- pane_dir returns the folder of a pane, or nil and a message. target is
-- { block_id = ..., session_id = ... }; without it, the pane is the focused one.
function M.pane_dir(target)
  local r, err = rex.block.call(M.TERMINAL, "pwd", target)
  if r == nil then return nil, err end
  local dir = M.url_path(r.pwd)
  if dir == nil then return nil, "the focused pane has not reported its folder" end
  return dir
end

-- New worktrees go in <worktrees_dir>/<project>/<branch>.
M.worktrees_dir = M.home .. "/.rex/worktrees"
-- worktree-watch.lua does not ask about a tab whose id is a file in this
-- folder, because the action that closed the tab already asked.
M.closed_dir = M.home .. "/.local/state/rex-worktrees"

-- worktree_of returns the worktree in worktrees_dir that holds dir, or nil.
function M.worktree_of(dir)
  local prefix = M.worktrees_dir .. "/"
  if dir == nil or dir:sub(1, #prefix) ~= prefix then return nil end
  local tree = (dir:sub(#prefix + 1) .. "/"):match("^([^/]+/[^/]+)/")
  return tree and prefix .. tree
end

-- shell returns the layout of a shell pane that starts in cwd. When command
-- is given, the pane runs it instead of an interactive shell.
function M.shell(cwd, command)
  return rex.layout.block{
    flavor = M.SHELL,
    options = { cwd = cwd, command = command },
  }
end

return M
