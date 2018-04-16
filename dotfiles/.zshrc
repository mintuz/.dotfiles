export ZSH=$HOME/.oh-my-zsh
ZSH_THEME="pygmalion"
plugins=(git wd)

# Core ZSH
source $ZSH/oh-my-zsh.sh

# Shell Settings
export DOTFILES_DIRECTORY="$HOME/.dotfiles"

# Add tab completion for SSH hostnames based on ~/.ssh/config, ignoring wildcards
[ -e "$HOME/.ssh/config" ] && complete -o "default" -o "nospace" -W "$(grep "^Host" ~/.ssh/config | grep -v "[?*]" | cut -d " " -f2- | tr ' ' '\n')" scp sftp ssh;

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm

source $DOTFILES_DIRECTORY/paths
source $DOTFILES_DIRECTORY/exports
source $DOTFILES_DIRECTORY/commands

# BBC Specific
export BBC_DIRECTORY="$HOME/.dotfiles/bbc"

if [ -d "$BBC_DIRECTORY" ]; then
	source $BBC_DIRECTORY/exports
	source $BBC_DIRECTORY/bash_aliases
  	source $BBC_DIRECTORY/proxy
	source $BBC_DIRECTORY/javaopts
fi
