export ZSH=$HOME/.oh-my-zsh
ZSH_THEME="edvardm"
plugins=(git wd)

# Core ZSH
source $ZSH/oh-my-zsh.sh

# Shell Settings
export DOTFILES_DIRECTORY="$HOME/.dotfiles"

source $DOTFILES_DIRECTORY/shell/paths
source $DOTFILES_DIRECTORY/shell/exports
source $DOTFILES_DIRECTORY/shell/bash_aliases

# BBC Specific
export BBC_DIRECTORY="$HOME/.dotfiles/bbc"

if [ -d "$BBC_DIRECTORY" ]; then
	source $BBC_DIRECTORY/exports
	source $BBC_DIRECTORY/bash_aliases
  source $BBC_DIRECTORY/proxy
	source $BBC_DIRECTORY/javaopts
fi
