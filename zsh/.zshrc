export ZSH=$HOME/.oh-my-zsh
ZSH_THEME="edvardm"
plugins=(git zsh-autosuggestions)

# Core ZSH
source $ZSH/oh-my-zsh.sh
source $HOME/.nvm_setup

# Auto load NVM when changing directories
autoload -U add-zsh-hook
load-nvmrc() {
  local node_version="$(nvm version)"
  local nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$node_version" ]; then
      nvm use
    fi
  elif [ "$node_version" != "$(nvm version default)" ]; then
    echo "Reverting to nvm default version"
    nvm use default
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
source $HOME/.zsh_profile

# Work Specific Profile Settings that I don't want on personal machine
[ -f ~/.zsh_work_profile ] && source ~/.zsh_work_profile
