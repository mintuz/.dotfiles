# Repository Guidelines

## Project Structure & Module Organization

This repository stores personal dotfiles as GNU Stow packages. Each top-level package mirrors the path it should create under `$HOME`.

- `zsh/` contains shell startup files such as `.zshrc` and `.zsh_profile`. They add a Homebrew-layout prefix (`/opt/homebrew` or `/home/linuxbrew/.linuxbrew`) when present, `PNPM_HOME`, and `mise activate zsh` when `mise` is on `PATH` or in `~/.local/bin`. They do not need the `brew` executable, and optional commands are skipped when missing.
- `mise/.config/mise/conf.d/dotfiles.toml` makes `.nvmrc` and `.node-version` select Node. When a project needs a Node version that is not installed, mise installs it the first time a Node command runs in that project. This needs an existing mise-managed Node, because that installation provides the `node` shim, and mise's default auto-install settings.
- `pnpm/.config/pnpm/config.yaml` defines global pnpm security and install policy defaults.
- `agents/.agents/` contains agent skill bundles, references, eval fixtures, `.skill-lock.json`, and `agents/`, the single copy of each subagent definition that more than one harness uses.
- `claude/.claude/CLAUDE.md` contains global Claude Code instructions. `claude/.claude/agents/` holds the Claude Code subagents: relative symlinks to the shared copies in `agents/.agents/agents/`. `~/.claude` is the personal Claude Code profile, which `claude` uses.
- `workclaude/.workclaude/` is the work Claude Code profile. The `workclaude` alias in `zsh/.zshrc` runs `claude` with `CLAUDE_CONFIG_DIR=~/.workclaude`. The package contains only relative symlinks to the shared `CLAUDE.md` and subagents. Each profile keeps its own login, `settings.json`, plugins, MCP servers and history in its local directory. Do not add these files to this repository.
- `omp/.omp/agent/config.yml` contains global omp (oh-my-pi) settings. `omp/.omp/agent/agents/` holds the omp subagents: omp-only files such as `astra.md` and `fable.md`, and relative symlinks to the shared copies. omp databases, sessions, caches and the runtime `config.yml.lock` stay local.
- `.githooks/pre-push` runs `gitleaks` on the commits that a push sends, and stops the push when it finds a possible secret. When `gitleaks` is not installed, the hook stops every push. `install.sh` sets `core.hooksPath` to `.githooks` for this repository only.
- `install.sh` moves a real `~/.zshrc`, a real `~/.omp/agent/config.yml`, real agent files that this repository manages, and `~/.agents` files that conflict with this repository into a new `~/.dotfiles-backup.XXXXXX` directory. Each run that backs up files creates its own directory, so a run never overwrites an earlier backup. The installer then creates `~/.omp/agent`, `~/.omp/agent/agents`, `~/.claude/agents`, `~/.workclaude/agents` and `~/.config/mise/conf.d` as real directories and runs `stow --target="$HOME" zsh agents pnpm claude workclaude omp mise`. When `rtk` is on `PATH`, the installer then runs `rtk init --global --auto-patch` once for `~/.claude` and once for `~/.workclaude`. RTK writes `RTK.md` and its hook into each local profile directory. The shared `CLAUDE.md` imports `@RTK.md`.

Tools and `install.sh` can update files in this checkout through Stow links, for example through the folded `~/.agents` link. The owner wants this behaviour. Do not report these writes as defects, and do not add guards against them.

Avoid committing machine-local files such as `.DS_Store`, temporary editor files, or secrets.

## Build, Test, and Development Commands

- `./install.sh` installs the managed packages into `$HOME` using Stow. Run only when you intend to update live dotfile symlinks.
- `stow --simulate --verbose zsh agents pnpm claude workclaude omp mise` previews symlink changes without modifying `$HOME`.
- `stow --restow zsh agents pnpm claude workclaude omp mise` refreshes existing symlinks after package changes.
- `zsh -n zsh/.zshrc zsh/.zsh_profile` checks shell files for syntax errors.
- `bats tests` runs the installer tests against a temporary home directory, and the pre-push hook tests against a temporary remote. Install bats-core first, for example with `brew install bats-core`.
- `gitleaks git --no-banner --redact .` scans the full history. Install gitleaks first, for example with `brew install gitleaks`. Old history contains false positives, such as placeholder keys in skill references and files from a removed `atom/` folder.
- `git status --short` confirms the final change set before committing.

## Coding Style & Naming Conventions

Shell files use POSIX-compatible syntax where practical, with zsh-specific features only when needed. Keep indentation at two spaces inside functions and conditionals, preserve existing alias style, and quote variables when paths or user input may contain spaces. Dotfile package paths should match their destination exactly, for example `zsh/.zshrc` maps to `~/.zshrc`.

Agent skills live under `agents/.agents/skills/<skill-name>/`. Use lowercase kebab-case for skill directory names and keep primary instructions in `SKILL.md`.

To share a subagent between Claude Code and omp, put the file in `agents/.agents/agents/<name>.md`, then add a relative symlink to it in `claude/.claude/agents/`, `workclaude/.workclaude/agents/` and `omp/.omp/agent/agents/`. A subagent with harness-specific frontmatter, such as an omp model selector, goes only in that harness's package. Codex has no subagent folder; skills that need a delegate use its general-purpose agent.

## Testing Guidelines

`tests/install.bats` tests `install.sh` with bats-core. Run `bats tests` after you change `install.sh`. Validate other changes with syntax checks and Stow dry runs before installing. For agent skill changes, inspect related `evals/evals.json` files when present and keep examples or fixtures close to the skill they exercise.

## Commit & Pull Request Guidelines

Recent history uses short, imperative commit subjects, sometimes with a Conventional Commit prefix such as `feat:`. Keep subjects concise, for example `feat: add zsh alias` or `pnpm security defaults`.

Pull requests should explain the affected package, note any manual verification commands run, and call out changes that affect shell startup, package manager policy, or agent behavior. Include screenshots only when a change affects a visual or rendered artifact.

## Security & Configuration Tips

Do not commit tokens, private hostnames, or work-only configuration. Keep personal or employer-specific overrides in local files sourced conditionally, such as `~/.zsh_work_profile`.
