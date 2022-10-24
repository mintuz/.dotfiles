export ZSH=$HOME/.oh-my-zsh
ZSH_THEME="edvardm"
plugins=(git zsh-autosuggestions)

# Core ZSH
source $ZSH/oh-my-zsh.sh
source $HOME/.nvm_setup

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
source $HOME/.zsh_profile
