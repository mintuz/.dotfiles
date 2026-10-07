# Keep PATH and fpath free of duplicates when this file is sourced again.
# PATH needs the flag too: assignments to the string do not use path's flag.
typeset -U path PATH fpath

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="edvardm"
plugins=(git zsh-autosuggestions)

# Homebrew-layout packages, installed by Homebrew or mise, on Apple Silicon
# macOS or Linux. Completions must be on fpath before oh-my-zsh runs compinit.
for brew_prefix in /opt/homebrew /home/linuxbrew/.linuxbrew; do
  if [ -d "$brew_prefix/bin" ]; then
    export HOMEBREW_PREFIX="$brew_prefix"
    export PATH="$brew_prefix/bin:$brew_prefix/sbin:$PATH"
    fpath=("$brew_prefix/share/zsh/site-functions" $fpath)
    break
  fi
done
unset brew_prefix

# Core ZSH
source "$ZSH/oh-my-zsh.sh"

# Global pnpm packages
if [ -z "${PNPM_HOME:-}" ]; then
  case "$OSTYPE" in
    darwin*) export PNPM_HOME="$HOME/Library/pnpm" ;;
    *) export PNPM_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/pnpm" ;;
  esac
fi
export PATH="$PNPM_HOME/bin:$PNPM_HOME:$PATH"

# Runtimes from mise. ~/.config/mise/conf.d/dotfiles.toml makes project .nvmrc
# and .node-version files select Node; elsewhere the global version applies.
export PATH="$HOME/.local/bin:$PATH"
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

[ -f "$HOME/.fzf.zsh" ] && source "$HOME/.fzf.zsh"
source "$HOME/.zsh_profile"

# Work Specific Profile Settings that I don't want on personal machine
[ -f "$HOME/.zsh_work_profile" ] && source "$HOME/.zsh_work_profile"

# Start Bonsai with live server output; press Ctrl+C to stop.
alias bonsai-start='env BONSAI_FAMILY=bonsai2 BONSAI_MODEL=27B BONSAI_CTX=65536 BONSAI_IMAGE_MAX_TOKENS=0 BONSAI_HOST=127.0.0.1 PORT=8080 /bin/sh "$HOME/Applications/Bonsai-demo/scripts/start_llama_server.sh" -np 1 --alias bonsai2 --reasoning-budget 2048 --sleep-idle-seconds 300'
