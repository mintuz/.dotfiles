-- worktree-watch.lua: after the last tab with a pane in a worktree closes, ask
-- whether to remove the worktree. init.lua starts this script with
--
--     rex do ~/.config/rex/worktree-watch.lua --all
--
-- A handler cannot show a prompt, so the script runs the worktree_closed
-- action of worktrees.lua, which asks.
--
-- ponytail: closing a whole session sends no window_closed event, so it does
-- not ask. Handle session_destroyed if that is needed.

package.path = os.getenv("HOME") .. "/.config/rex/?.lua;" .. package.path
local h = require("helpers")

-- The last folder each terminal reported, and the tab that holds each block.
local dir_of, window_of = {}, {}

local function scan(session_id)
  local view = rex.call("session.view", { session_id = session_id })
  if view == nil then return end
  for _, window in ipairs(view.windows) do
    for _, layer in ipairs(window.layers) do
      for _, block in ipairs(layer.blocks) do
        window_of[block.block_id] = window.window_id
        if dir_of[block.block_id] == nil and block.creator_name == h.TERMINAL then
          dir_of[block.block_id] = h.pane_dir({ block_id = block.block_id, session_id = session_id })
        end
      end
    end
  end
end

-- The script hears sessions only after its top level finishes.
rex.after(0, function()
  local list = rex.call("session.list")
  for _, session in ipairs(list and list.sessions or {}) do scan(session.session_id) end
end)

rex.on("session_view_changed", function(ctx) scan(ctx.session_id) end)

rex.on("terminal.pwd_changed", function(ctx, ev)
  dir_of[ctx.block_id] = h.url_path(ev.pwd)
end)

-- A tab's window_closed event comes before the block_closed events of its blocks.
rex.on("block_closed", function(ctx, ev)
  dir_of[ev.block_id], window_of[ev.block_id] = nil, nil
end)

rex.on("window_closed", function(ctx, ev)
  local trees = {}
  for block, window in pairs(window_of) do
    if window == ev.window_id then
      local tree = h.worktree_of(dir_of[block])
      if tree then trees[tree] = true end
      dir_of[block], window_of[block] = nil, nil
    end
  end
  -- worktree_close_tab asked already.
  if os.remove(h.closed_dir .. "/" .. ev.window_id) then return end
  -- Do not ask about a worktree that a pane in another tab is still in.
  for block in pairs(window_of) do
    local tree = h.worktree_of(dir_of[block])
    if tree then trees[tree] = nil end
  end
  for tree in pairs(trees) do
    rex.exec.start({ h.REX, "do", "worktree_closed", "path=" .. tree }, { detach = true })
  end
end)
