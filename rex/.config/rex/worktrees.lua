-- Worktrees: start a Rex session or open a tab in a project's checkout or
-- worktree, and remove a worktree. Modelled on https://github.com/almonk/rex-projects.
--
-- The pickers need rex.ui (control API revision 17). On an older server, or
-- from a script, give the answers as arguments:
--
--     rex do worktree_session project="$HOME/.dotfiles" branch=my-branch
--     rex do worktree_tab project="$HOME/.dotfiles" branch=my-branch
--     rex do worktree_remove project="$HOME/.dotfiles" branch=my-branch
--     rex do worktree_prune project="$HOME/.dotfiles" all=true

local h = require("helpers")
local home, short, git = h.home, h.short, h.git

-- Folders whose repositories are listed as projects.
local roots = { home .. "/Workspace" }
-- Projects that are in none of the roots.
local projects = { home .. "/.dotfiles" }
local worktrees_dir = h.worktrees_dir

-- The ids of the picker rows that are not folders. A folder's id is its
-- absolute path, so they cannot clash.
local NEW, ALL = "new", "all"

local fail = h.failer("worktrees")

local function basename(path)
  return path:match("([^/]+)/*$") or path
end

-- Lua 5.1 does not seed math.random itself.
math.randomseed(os.time())

-- random_branch returns "<project>-<6 random letters or digits>", such as
-- dotfiles-k3x9qa. A leading dot of the project's folder is left out.
local function random_branch(project)
  local chars, out = "abcdefghijklmnopqrstuvwxyz0123456789", {}
  for i = 1, 6 do
    local n = math.random(#chars)
    out[i] = chars:sub(n, n)
  end
  return basename(project):gsub("^%.", "") .. "-" .. table.concat(out)
end

-- ask shows a rex.ui prompt ("pick" or "input"). It returns the answer, or nil
-- when the person cancels.
local function ask(kind, opts)
  local ok, ui = pcall(function() return rex.ui end)
  if not ok or ui == nil then
    fail("this Rex server cannot show prompts (it needs control API revision 17); pass project= and branch=")
  end
  local answer, why = ui[kind](opts)
  if answer == nil and why ~= "cancelled" then fail("prompt " .. tostring(why)) end
  return answer
end

-- choose_project returns the project's folder, or nil when the person cancels.
local function choose_project(args, title)
  if args.project then return args.project end
  local paths = {}
  for _, path in ipairs(projects) do paths[#paths + 1] = path end
  for _, root in ipairs(roots) do
    -- A main checkout has a .git folder. A worktree has a .git file, and is
    -- listed under its project instead. -print0 ends each path with NUL, the
    -- one byte a path cannot hold.
    local r = rex.exec({ "find", root, "-mindepth", "2", "-maxdepth", "2",
      "-name", ".git", "-type", "d", "-print0" })
    if r ~= nil then
      for hit in r.stdout:gmatch("[^%z]+") do paths[#paths + 1] = hit:sub(1, -6) end
    end
  end
  table.sort(paths, function(a, b) return basename(a):lower() < basename(b):lower() end)
  local items = {}
  for _, path in ipairs(paths) do
    items[#items + 1] = { id = path, title = basename(path), subtitle = short(path), icon = "folder" }
  end
  return ask("pick", { title = title, placeholder = "Choose a project", items = items })
end

-- list_worktrees returns a project's checkouts, main one first, as
-- { path = ..., branch = ... or nil }.
local function list_worktrees(project)
  local out, err = git(project, "worktree", "list", "--porcelain")
  if out == nil then fail(err) end
  local trees = {}
  -- Each checkout is a paragraph of lines. A prunable one has lost its folder.
  for entry in (out .. "\n"):gmatch("(.-)\n\n") do
    local path = entry:match("^worktree ([^\n]+)")
    if path and not entry:find("\nprunable", 1, true) then
      trees[#trees + 1] = { path = path, branch = entry:match("\nbranch refs/heads/([^\n]+)") }
    end
  end
  return trees
end

local function find(trees, field, value)
  for _, tree in ipairs(trees) do
    if tree[field] == value then return tree end
  end
end

local function tree_items(trees)
  local items = {}
  for _, tree in ipairs(trees) do
    items[#items + 1] = {
      id = tree.path,
      title = tree.branch or basename(tree.path),
      subtitle = short(tree.path),
      icon = "branch",
    }
  end
  return items
end

-- add_worktree makes a worktree of project for branch and returns it.
local function add_worktree(project, branch)
  -- A branch name may hold slashes; a folder name may not.
  local folder = branch:gsub("/", "-")
  local dir = worktrees_dir .. "/" .. basename(project) .. "/" .. folder
  local out, err
  if git(project, "rev-parse", "--verify", "--quiet", "refs/heads/" .. branch) then
    out, err = git(project, "worktree", "add", dir, branch)
  else
    -- ponytail: a new branch starts from the remote's default branch as last
    -- fetched, or from HEAD when there is no remote. Add a fetch or a base
    -- picker if stale or other bases are needed.
    local base = git(project, "symbolic-ref", "--short", "-q", "refs/remotes/origin/HEAD")
    base = base and base:match("%S+") or "HEAD"
    -- --no-track: the new branch must not push to the default branch.
    out, err = git(project, "worktree", "add", "--no-track", "-b", branch, dir, base)
  end
  if out == nil then fail(err) end
  return { path = dir, branch = branch }
end

-- choose_tree returns the project's folder and the checkout to work in. It
-- makes the worktree when the branch has none. It returns nil when the person
-- cancels.
local function choose_tree(args, title)
  local project = choose_project(args, title)
  if project == nil then return end
  local trees = list_worktrees(project)
  local branch, tree = args.branch, nil
  if branch == nil then
    local items = tree_items(trees)
    items[1].icon = "folder"
    -- First, so that Return chooses it.
    table.insert(items, 1, { id = NEW, title = "New worktree…", icon = "plus" })
    local choice = ask("pick", {
      title = basename(project), placeholder = "Choose where to work", items = items,
    })
    if choice == nil then return end
    if choice == NEW then
      -- Return keeps the random name. Edit the text to use another one.
      branch = ask("input", {
        title = "New worktree in " .. basename(project),
        placeholder = "Branch name",
        value = random_branch(project),
        confirm = "Create worktree",
      })
      if branch == nil then return end
    else
      tree = find(trees, "path", choice)
    end
  end
  if tree == nil then
    branch = branch:match("^%s*(.-)%s*$")
    if branch == "" then return end
    -- A branch that already has a worktree opens that worktree.
    tree = find(trees, "branch", branch) or add_worktree(project, branch)
  end
  return project, tree
end

local function label(project, tree)
  return basename(project) .. " · " .. (tree.branch or basename(tree.path))
end

-- remove_choice asks what to do with tree. It returns "remove", "keep", or
-- nil when the person cancels.
local function remove_choice(tree, title, remove_title, keep_title)
  return ask("pick", {
    title = title,
    placeholder = "Remove the worktree? Its branch stays unless it is merged.",
    items = {
      { id = "remove", title = remove_title, subtitle = short(tree), icon = "trash" },
      { id = "keep", title = keep_title, icon = "xmark" },
    },
  })
end

-- try_remove removes the worktree at tree, and then its branch when the
-- branch is merged. It returns nil and git's message when git refuses.
local function try_remove(tree)
  local branch = git(tree, "symbolic-ref", "--short", "-q", "HEAD")
  local common = git(tree, "rev-parse", "--path-format=absolute", "--git-common-dir")
  -- Without --force, git refuses a worktree that has changed or untracked
  -- files, so this loses no work.
  local out, err = git(tree, "worktree", "remove", tree)
  if out == nil then return nil, err end
  -- -d refuses a branch that is not merged into HEAD of the main checkout,
  -- so this loses no commits. A random name made by New worktree… is
  -- otherwise left behind.
  if branch and common then
    git(common:match("[^\n]+"), "branch", "-d", branch:match("%S+"))
  end
  return true
end

-- remove_many removes each worktree in paths that git allows, and returns
-- the removed ones. It then fails with git's message for each of the others.
local function remove_many(paths)
  local removed, refused = {}, {}
  for _, path in ipairs(paths) do
    local ok, err = try_remove(path)
    if ok then
      removed[#removed + 1] = path
    else
      refused[#refused + 1] = short(path) .. ": " .. tostring(err):match("[^\n]*")
    end
  end
  if #refused > 0 then
    fail("removed " .. #removed .. ", kept " .. #refused .. "\n" .. table.concat(refused, "\n"))
  end
  return removed
end

local function remove_tree(tree)
  local ok, err = try_remove(tree)
  if not ok then fail(err) end
end

local action_args = { project = "string?", branch = "string?" }

-- A window in the API is a tab in the app.

rex.action{
  name = "worktree_session",
  title = "New Session in Worktree…",
  description = "Choose a project, then a checkout or a new worktree, and start a session there",
  category = "Worktrees",
  keywords = "project branch repository checkout folder",
  args = action_args,
  run = function(ctx, args)
    local project, tree = choose_tree(args, "New session")
    if tree == nil then return end
    local session, err = rex.call("session.create", {
      label = label(project, tree),
      initial_windows = { { window_label = "shell", layout = h.shell(tree.path) } },
    })
    if session == nil then fail(err) end
    -- Creating a session does not show it. Ask the app to switch to it. With
    -- no app connected, the session still exists.
    pcall(rex.client.queue, "session.select", { session_id = session.session_id })
    return tree.path
  end,
}

rex.action{
  name = "worktree_tab",
  title = "New Tab in Worktree…",
  description = "Choose a project, then a checkout or a new worktree, and open a tab there in the current session",
  category = "Worktrees",
  keywords = "project branch repository checkout folder window",
  args = action_args,
  run = function(ctx, args)
    if ctx.session_id == nil then fail("no current session to open a tab in") end
    local project, tree = choose_tree(args, "New tab")
    if tree == nil then return end
    -- The new tab becomes the active tab of the session.
    local window, err = rex.call("session.new_window", {
      session_id = ctx.session_id,
      window_label = label(project, tree),
      layout = h.shell(tree.path),
    })
    if window == nil then fail(err) end
    return tree.path
  end,
}

rex.action{
  name = "worktree_remove",
  title = "Remove Worktree…",
  description = "Choose a project and one of its worktrees, and remove the worktree. Its branch stays.",
  category = "Worktrees",
  keywords = "project branch repository delete",
  args = action_args,
  run = function(ctx, args)
    local project = choose_project(args, "Remove worktree")
    if project == nil then return end
    local trees = list_worktrees(project)
    -- Git cannot remove the main checkout.
    table.remove(trees, 1)
    if args.branch then
      local tree = find(trees, "branch", args.branch)
      if tree == nil then fail("no worktree for branch " .. args.branch) end
      remove_tree(tree.path)
      return tree.path
    end
    if #trees == 0 then fail(basename(project) .. " has no worktrees") end
    local items = tree_items(trees)
    for _, item in ipairs(items) do
      -- git refuses to remove these, so show them before the person ticks them.
      local status = git(item.id, "status", "--porcelain")
      if status == nil or status ~= "" then item.detail = "changed" end
    end
    table.insert(items, 1, { id = ALL, title = "All worktrees", icon = "star" })
    local chosen = ask("pick", {
      title = "Remove worktrees of " .. basename(project),
      placeholder = "Tick worktrees to remove (merged branches go too)",
      items = items,
      multiple = true,
      confirm = "Remove",
    })
    if chosen == nil then return end
    if chosen[1] == ALL then
      chosen = {}
      for _, tree in ipairs(trees) do chosen[#chosen + 1] = tree.path end
    end
    return remove_many(chosen)
  end,
}

rex.action{
  name = "worktree_prune",
  title = "Remove Merged Worktrees…",
  description = "Choose a project, and remove its worktrees whose branches are merged and that have no changed files",
  category = "Worktrees",
  keywords = "project branch repository delete prune clean merged",
  args = { project = "string?", all = "boolean?" },
  run = function(ctx, args)
    local project = choose_project(args, "Remove merged worktrees")
    if project == nil then return end
    -- Branches merged into HEAD of the main checkout: the ones that
    -- `git branch -d` deletes.
    local out, err = git(project, "branch", "--merged", "HEAD", "--format=%(refname:short)")
    if out == nil then fail(err) end
    local merged = {}
    for branch in out:gmatch("[^\n]+") do merged[branch] = true end
    local trees = list_worktrees(project)
    table.remove(trees, 1)
    local candidates = {}
    for _, tree in ipairs(trees) do
      if tree.branch and merged[tree.branch] and git(tree.path, "status", "--porcelain") == "" then
        candidates[#candidates + 1] = tree
      end
    end
    if #candidates == 0 then fail(basename(project) .. " has no merged worktrees without changes") end
    local chosen = {}
    if args.all then
      for _, tree in ipairs(candidates) do chosen[#chosen + 1] = tree.path end
    else
      local items = tree_items(candidates)
      -- All start ticked. Untick the ones to keep.
      for _, item in ipairs(items) do item.selected = true end
      chosen = ask("pick", {
        title = "Remove merged worktrees of " .. basename(project),
        placeholder = "Untick worktrees to keep",
        items = items,
        multiple = true,
        confirm = "Remove",
      })
      if chosen == nil then return end
    end
    return remove_many(chosen)
  end,
}

rex.action{
  name = "worktree_close_tab",
  title = "Close Tab…",
  description = "Close the current tab. When the focused pane is in a worktree, first ask whether to remove the worktree",
  category = "Worktrees",
  keywords = "close tab window remove delete worktree",
  run = function(ctx, args)
    if ctx.session_id == nil then fail("no current session to close a tab in") end
    local view, err = rex.call("session.view", { session_id = ctx.session_id })
    if view == nil then fail(err) end
    local window_id = view.active_window_id
    for _, window in ipairs(view.windows) do
      for _, layer in ipairs(window.layers) do
        for _, block in ipairs(layer.blocks) do
          if block.block_id == ctx.block_id then window_id = window.window_id end
        end
      end
    end
    local tree = h.worktree_of(h.pane_dir())
    if tree then
      local choice = remove_choice(tree, "Close tab", "Close tab and remove worktree", "Close tab, keep worktree")
      if choice == nil then return end
      -- The tab stays open when git refuses to remove the worktree.
      if choice == "remove" then remove_tree(tree) end
      -- Tell worktree-watch.lua that it need not ask about this tab.
      rex.exec({ "mkdir", "-p", h.closed_dir })
      local file = io.open(h.closed_dir .. "/" .. window_id, "w")
      if file then file:close() end
    end
    local _, close_err = rex.call("session.close_window", { session_id = ctx.session_id, window_id = window_id })
    if close_err then fail(close_err) end
    return tree
  end,
}

-- worktree-watch.lua runs this action after the last tab with a pane in a
-- worktree closes.
rex.action{
  name = "worktree_closed",
  title = "Remove Worktree of Closed Tab…",
  description = "Ask whether to remove a worktree that no open tab is in",
  category = "Worktrees",
  keywords = "close tab remove delete worktree",
  args = { path = "string" },
  run = function(ctx, args)
    -- Nothing to ask when the worktree is gone already.
    if git(args.path, "rev-parse", "--git-dir") == nil then return end
    if remove_choice(args.path, "Tab closed", "Remove worktree", "Keep worktree") ~= "remove" then return end
    remove_tree(args.path)
    return args.path
  end,
}

rex.bind("alt+cmd+n", "worktree_session")
rex.bind("alt+cmd+t", "worktree_tab")
-- Replaces Rex's Close Tab shortcut.
rex.bind("alt+cmd+w", "worktree_close_tab")
