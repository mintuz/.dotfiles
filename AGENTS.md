# Repository Guidelines

## Project Structure & Module Organization

This repository stores personal dotfiles as GNU Stow packages. Each top-level package mirrors the path it should create under `$HOME`.

- `zsh/` contains shell startup files such as `.zshrc` and `.zsh_profile`. They add a Homebrew-layout prefix (`/opt/homebrew` or `/home/linuxbrew/.linuxbrew`) when present, `PNPM_HOME`, and `mise activate zsh` when `mise` is on `PATH` or in `~/.local/bin`. They do not need the `brew` executable, and optional commands are skipped when missing.
- `mise/.config/mise/conf.d/dotfiles.toml` makes `.nvmrc` and `.node-version` select Node. When a project needs a Node version that is not installed, mise installs it the first time a Node command runs in that project. This needs an existing mise-managed Node, because that installation provides the `node` shim, and mise's default auto-install settings.
- `pnpm/.config/pnpm/config.yaml` defines global pnpm security and install policy defaults.
- `agents/.agents/` contains agent skill bundles, references, eval fixtures, and `.skill-lock.json`.
- `claude/.claude/CLAUDE.md` contains global Claude Code instructions.
- `omp/.omp/agent/config.yml` contains global omp (oh-my-pi) settings. Only `config.yml` is managed; omp databases, sessions, and caches stay local.
- `install.sh` moves a real `~/.zshrc`, a real `~/.omp/agent/config.yml`, and `~/.agents` files that conflict with this repository into a new `~/.dotfiles-backup.XXXXXX` directory. Each run that backs up files creates its own directory, so a run never overwrites an earlier backup. The installer then creates `~/.omp/agent` and `~/.config/mise/conf.d` and runs `stow --target="$HOME" zsh agents pnpm claude omp mise`.

Tools and `install.sh` can update files in this checkout through Stow links, for example through the folded `~/.agents` link. The owner wants this behaviour. Do not report these writes as defects, and do not add guards against them.

Avoid committing machine-local files such as `.DS_Store`, temporary editor files, or secrets.

## Build, Test, and Development Commands

- `./install.sh` installs the managed packages into `$HOME` using Stow. Run only when you intend to update live dotfile symlinks.
- `stow --simulate --verbose zsh agents pnpm claude omp mise` previews symlink changes without modifying `$HOME`.
- `stow --restow zsh agents pnpm claude omp mise` refreshes existing symlinks after package changes.
- `zsh -n zsh/.zshrc zsh/.zsh_profile` checks shell files for syntax errors.
- `bats tests` runs the installer tests against a temporary home directory. Install bats-core first, for example with `brew install bats-core`.
- `git status --short` confirms the final change set before committing.

## Coding Style & Naming Conventions

Shell files use POSIX-compatible syntax where practical, with zsh-specific features only when needed. Keep indentation at two spaces inside functions and conditionals, preserve existing alias style, and quote variables when paths or user input may contain spaces. Dotfile package paths should match their destination exactly, for example `zsh/.zshrc` maps to `~/.zshrc`.

Agent skills live under `agents/.agents/skills/<skill-name>/`. Use lowercase kebab-case for skill directory names and keep primary instructions in `SKILL.md`.

## Testing Guidelines

`tests/install.bats` tests `install.sh` with bats-core. Run `bats tests` after you change `install.sh`. Validate other changes with syntax checks and Stow dry runs before installing. For agent skill changes, inspect related `evals/evals.json` files when present and keep examples or fixtures close to the skill they exercise.

## Commit & Pull Request Guidelines

Recent history uses short, imperative commit subjects, sometimes with a Conventional Commit prefix such as `feat:`. Keep subjects concise, for example `feat: add zsh alias` or `pnpm security defaults`.

Pull requests should explain the affected package, note any manual verification commands run, and call out changes that affect shell startup, package manager policy, or agent behavior. Include screenshots only when a change affects a visual or rendered artifact.

## Security & Configuration Tips

Do not commit tokens, private hostnames, or work-only configuration. Keep personal or employer-specific overrides in local files sourced conditionally, such as `~/.zsh_work_profile`.
