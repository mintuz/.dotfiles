export ZSH=$HOME/.oh-my-zsh
ZSH_THEME="edvardm"
plugins=(git zsh-autosuggestions)

# Core ZSH
source $ZSH/oh-my-zsh.sh
source $HOME/.nvm_setup

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
source $HOME/.zsh_profile

# Work Specific Profile Settings that I don't want on personal machine
[ -f ~/.zsh_work_profile ] && source ~/.zsh_work_profile
