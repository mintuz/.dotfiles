# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh
ZSH_THEME="edvardm"
plugins=(git wd)

source $ZSH/oh-my-zsh.sh

# User configuration
export PATH="/bin:/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin"
export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting

# Setup path to include current directory bin directory, for Rails binstubs
export PATH="./bin:$PATH"

# House Keeping
alias show_hidden="defaults write com.apple.finder AppleShowAllFiles YES"
alias hide_hidden="defaults write com.apple.finder AppleShowAllFiles NO"

# Dev Helpers
alias killnode="killall node"