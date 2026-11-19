-- Agents: resume the agent conversations that a Rex server restart ended.
-- Rex restores the panes, but as shells. agent-session.sh, which the session
-- hooks of Claude Code, Codex and omp run, records the resume command of each
-- agent pane in ~/.local/state/rex-agents/<block>.json. Rex keeps block IDs
-- across a restart, so a record finds its pane again. Modelled on
-- https://github.com/oliver-kriska/rex-agents and
-- https://github.com/nexxai/rex-recover.
--
--     rex do restore_agents

local T = "com.superlogical.terminal"
local home = os.getenv("HOME")
local state = (os.getenv("XDG_STATE_HOME") or home .. "/.local/state") .. "/rex-agents"
local shells = { sh = true, bash = true, zsh = true, fish = true }
-- The picker row that restores every pane. A pane's id is its block ID, so
-- the two cannot clash.
local ALL = "all"

local function fail(message)
  error("agents: " .. tostring(message), 0)
end

local function short(path)
  if path:sub(1, #home + 1) == home .. "/" then return "~" .. path:sub(#home + 1) end
  return path
end

-- quote makes value one word for a POSIX shell.
local function quote(value)
  return "'" .. value:gsub("'", "'\\''") .. "'"
end

-- safe reports whether value is a string with no control character. The
-- command is typed into a terminal, where a control character could submit
-- other input.
local function safe(value)
  return type(value) == "string" and value ~= "" and not value:find("%c")
end

local function valid(record)
  if type(record) ~= "table" or not safe(record.session) or not safe(record.block)
    or not safe(record.cwd) or type(record.argv) ~= "table" or #record.argv == 0 then
    return false
  end
  for _, word in ipairs(record.argv) do
    if not safe(word) then return false end
  end
  return true
end

-- idle reports whether the pane shows a shell prompt: the foreground program
-- is a shell, and only login is above it. A shell that runs inside another
-- program, for example in an editor, is not idle.
local function idle(record)
  local r = rex.block.call(T, "process", { session_id = record.session, block_id = record.block })
  if r == nil or r.foreground == nil then return false end
  if not shells[(tostring(r.foreground.name):gsub("^%-", ""))] then return false end
  for _, ancestor in ipairs(r.ancestors or {}) do
    if ancestor.name ~= "login" then return false end
  end
  return true
end

-- waiting returns the records whose pane exists and is idle.
local function waiting()
  local r = rex.exec({ "find", state, "-maxdepth", "1", "-name", "block:*.json" })
  -- find fails when no agent has run yet, because the folder does not exist.
  if r == nil or not r.ok then return {} end
  local records = {}
  for path in r.stdout:gmatch("[^\n]+") do
    local file = io.open(path, "r")
    if file then
      local ok, record = pcall(rex.json.decode, file:read("*a"))
      file:close()
      if ok and valid(record) and idle(record) then records[#records + 1] = record end
    end
  end
  table.sort(records, function(a, b) return a.cwd < b.cwd end)
  return records
end

local function restore(record)
  local words = {}
  for _, word in ipairs(record.argv) do words[#words + 1] = quote(word) end
  local line = "cd -- " .. quote(record.cwd) .. " && " .. table.concat(words, " ") .. "\r"
  local _, err = rex.block.call(T, "write", { session_id = record.session, block_id = record.block, data = line })
  if err then fail(err) end
end

rex.action{
  name = "restore_agents",
  title = "Restore Agents…",
  description = "Resume the agent conversations of panes that a Rex server restart left as shells",
  category = "Agents",
  keywords = "resume revive recover restart claude codex omp",
  run = function(ctx, args)
    local records = waiting()
    if #records == 0 then return "no agent panes to restore" end
    local items = {}
    if #records > 1 then
      items[1] = { id = ALL, title = "Restore all", subtitle = #records .. " panes", icon = "arrow.clockwise" }
    end
    for _, record in ipairs(records) do
      items[#items + 1] = { id = record.block, title = record.agent .. " · " .. short(record.cwd),
        subtitle = table.concat(record.argv, " ") }
    end
    local ok, ui = pcall(function() return rex.ui end)
    if not ok or ui == nil then fail("this Rex server cannot show prompts (it needs control API revision 17)") end
    local answer, why = ui.pick({ title = "Restore Agents", placeholder = "Choose a pane", items = items })
    if answer == nil then
      if why ~= "cancelled" then fail("prompt " .. tostring(why)) end
      return nil
    end
    local restored = {}
    for _, record in ipairs(records) do
      if answer == ALL or answer == record.block then
        restore(record)
        restored[#restored + 1] = record.block
      end
    end
    return restored
  end,
}

rex.bind("alt+cmd+r", "restore_agents")
