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
export PATH="$HOME/.scripts:$PATH"

# Go Language
export PATH=$PATH:/usr/local/go/bin
export GOPATH="$HOME/Golang/"

# Use Brew PHP
export PATH="$(brew --prefix homebrew/php/php54)/bin:$PATH"

# Java / SBT Opts
# Works for MacBook Air early 2014 model
export SBT_OPTS="-XX:+CMSClassUnloadingEnabled -XX:PermSize=512M -XX:MaxPermSize=1024M"

# House Keeping
alias show_hidden="defaults write com.apple.finder AppleShowAllFiles YES"
alias hide_hidden="defaults write com.apple.finder AppleShowAllFiles NO"

# Dev Helpers
alias killnode="killall node"
alias show_hidden="defaults write com.apple.Finder AppleShowAllFiles YES"
alias hide_hidden="defaults write com.apple.Finder AppleShowAllFiles NO"

# Add tab completion for SSH hostnames based on ~/.ssh/config, ignoring wildcards
[ -e "$HOME/.ssh/config" ] && complete -o "default" -o "nospace" -W "$(grep "^Host" ~/.ssh/config | grep -v "[?*]" | cut -d " " -f2- | tr ' ' '\n')" scp sftp ssh;
