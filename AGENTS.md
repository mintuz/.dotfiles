# Repository Guidelines

## Project Structure & Module Organization

This repository stores personal dotfiles as GNU Stow packages. Each top-level package mirrors the path it should create under `$HOME`.

- `zsh/` contains shell startup files such as `.zshrc`, `.zsh_profile`, and `.nvm_setup`.
- `pnpm/.config/pnpm/config.yaml` defines global pnpm security and install policy defaults.
- `agents/.agents/` contains agent skill bundles, references, eval fixtures, and `.skill-lock.json`.
- `install.sh` backs up `~/.zshrc` and runs `stow zsh agents pnpm`.

Avoid committing machine-local files such as `.DS_Store`, temporary editor files, or secrets.

## Build, Test, and Development Commands

- `./install.sh` installs the managed packages into `$HOME` using Stow. Run only when you intend to update live dotfile symlinks.
- `stow --simulate --verbose zsh agents pnpm` previews symlink changes without modifying `$HOME`.
- `stow --restow zsh agents pnpm` refreshes existing symlinks after package changes.
- `zsh -n zsh/.zshrc zsh/.zsh_profile zsh/.nvm_setup` checks shell files for syntax errors.
- `git status --short` confirms the final change set before committing.

## Coding Style & Naming Conventions

Shell files use POSIX-compatible syntax where practical, with zsh-specific features only when needed. Keep indentation at two spaces inside functions and conditionals, preserve existing alias style, and quote variables when paths or user input may contain spaces. Dotfile package paths should match their destination exactly, for example `zsh/.zshrc` maps to `~/.zshrc`.

Agent skills live under `agents/.agents/skills/<skill-name>/`. Use lowercase kebab-case for skill directory names and keep primary instructions in `SKILL.md`.

## Testing Guidelines

There is no formal test suite. Validate changes with syntax checks and Stow dry runs before installing. For agent skill changes, inspect related `evals/evals.json` files when present and keep examples or fixtures close to the skill they exercise.

## Commit & Pull Request Guidelines

Recent history uses short, imperative commit subjects, sometimes with a Conventional Commit prefix such as `feat:`. Keep subjects concise, for example `feat: add zsh alias` or `pnpm security defaults`.

Pull requests should explain the affected package, note any manual verification commands run, and call out changes that affect shell startup, package manager policy, or agent behavior. Include screenshots only when a change affects a visual or rendered artifact.

## Security & Configuration Tips

Do not commit tokens, private hostnames, or work-only configuration. Keep personal or employer-specific overrides in local files sourced conditionally, such as `~/.zsh_work_profile`.
