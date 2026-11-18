-- Worktrees: start a Rex session in a project's checkout or worktree, and
-- remove a worktree. Modelled on https://github.com/almonk/rex-projects.
--
-- The pickers need rex.ui (control API revision 17). On an older server, or
-- from a script, give the answers as arguments:
--
--     rex do worktree_session project="$HOME/.dotfiles" branch=my-branch
--     rex do worktree_remove project="$HOME/.dotfiles" branch=my-branch

local home = os.getenv("HOME")

-- Folders whose repositories are listed as projects.
local roots = { home .. "/Workspace" }
-- Projects that are in none of the roots.
local projects = { home .. "/.dotfiles" }
-- New worktrees go in <worktrees_dir>/<project>/<branch>.
local worktrees_dir = home .. "/.rex/worktrees"

-- The id of the picker row that is not a folder. A folder's id is its
-- absolute path, so the two cannot clash.
local NEW = "new"

local function fail(message)
  error("worktrees: " .. tostring(message), 0)
end

local function basename(path)
  return path:match("([^/]+)/*$") or path
end

-- short writes the home folder at the start of path as ~.
local function short(path)
  if path:sub(1, #home + 1) == home .. "/" then return "~" .. path:sub(#home + 1) end
  return path
end

-- git runs git in dir and returns what it printed, or nil and git's message.
-- Arguments go as a list, never through a shell, so no quoting is needed.
local function git(dir, ...)
  local r, err = rex.exec({ "git", "-C", dir, ... })
  if r == nil then return nil, err end
  if not r.ok then return nil, r.stderr end
  return r.stdout
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

rex.action{
  name = "worktree_session",
  title = "New Session in Worktree…",
  description = "Choose a project, then a checkout or a new worktree, and start a session there",
  category = "Worktrees",
  keywords = "project branch repository checkout folder",
  args = { project = "string?", branch = "string?" },
  run = function(ctx, args)
    local project = choose_project(args, "New session")
    if project == nil then return end
    local trees = list_worktrees(project)
    local branch, tree = args.branch, nil
    if branch == nil then
      local items = tree_items(trees)
      items[1].icon = "folder"
      items[#items + 1] = { id = NEW, title = "New worktree…", icon = "plus" }
      local choice = ask("pick", {
        title = basename(project), placeholder = "Choose where to work", items = items,
      })
      if choice == nil then return end
      if choice == NEW then
        branch = ask("input", {
          title = "New worktree in " .. basename(project),
          placeholder = "Branch name",
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

    -- A window in the API is a tab in the app.
    local session, err = rex.call("session.create", {
      label = basename(project) .. " · " .. (tree.branch or basename(tree.path)),
      initial_windows = { {
        window_label = "shell",
        layout = rex.layout.block{
          flavor = "com.superlogical.terminal.shell",
          options = { cwd = tree.path },
        },
      } },
    })
    if session == nil then fail(err) end
    -- Creating a session does not show it. Ask the app to switch to it. With
    -- no app connected, the session still exists.
    pcall(rex.client.queue, "session.select", { session_id = session.session_id })
    return tree.path
  end,
}

rex.action{
  name = "worktree_remove",
  title = "Remove Worktree…",
  description = "Choose a project and one of its worktrees, and remove the worktree. Its branch stays.",
  category = "Worktrees",
  keywords = "project branch repository delete",
  args = { project = "string?", branch = "string?" },
  run = function(ctx, args)
    local project = choose_project(args, "Remove worktree")
    if project == nil then return end
    local trees = list_worktrees(project)
    -- Git cannot remove the main checkout.
    table.remove(trees, 1)
    local tree
    if args.branch then
      tree = find(trees, "branch", args.branch)
      if tree == nil then fail("no worktree for branch " .. args.branch) end
    else
      local choice = ask("pick", {
        title = "Remove worktree of " .. basename(project),
        placeholder = "Choose a worktree to remove (its branch stays)",
        items = tree_items(trees),
      })
      if choice == nil then return end
      tree = find(trees, "path", choice)
    end
    -- Without --force, git refuses a worktree that has changed or untracked
    -- files, so this loses no work.
    local out, err = git(project, "worktree", "remove", tree.path)
    if out == nil then fail(err) end
    return tree.path
  end,
}

rex.bind("alt+cmd+n", "worktree_session")
