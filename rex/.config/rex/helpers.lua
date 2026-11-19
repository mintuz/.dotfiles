-- Helpers that more than one Rex config file uses.

local M = {}

M.home = os.getenv("HOME")
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

-- pane_dir returns the folder of the focused pane, or nil and a message. The
-- terminal reports it as a URL, file://<host>/<path>, with %XX escapes.
function M.pane_dir()
  local r, err = rex.block.call(M.TERMINAL, "pwd")
  if r == nil then return nil, err end
  local dir = r.pwd and r.pwd:match("^file://[^/]*(/.*)$")
  if dir == nil then return nil, "the focused pane has not reported its folder" end
  return (dir:gsub("%%(%x%x)", function(hex) return string.char(tonumber(hex, 16)) end))
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
