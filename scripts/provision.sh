function installRVM() {
	curl -sSL https://get.rvm.io | bash -s stable --ruby
}

function setupDefaults() {
    ./osxdefaults
}

function copyDotfiles() {
  cp -a ../dotfiles/. ~
}

function installNVM() {
	curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.9/install.sh | bash
    nvm install node
}

function installHomebrew() {
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
}

function installBrews() {
  
  brews=( vim git wget mas )

  for item in "${brews[@]}"

  do
    if [[ $item == "vim" ]]; then
      brew install $item --override-system-vim
    else
      brew install $item
    fi
  done
}

installHomebrew && \
installRVM && \
installNVM && \
installBrews && \
setupDefaults && \
copyDotfiles