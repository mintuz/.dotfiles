function installRVM() {
	curl -sSL https://get.rvm.io | bash -s stable --ruby
}

function installNVM() {
  curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.30.2/install.sh | bash
}

function makeDirectories() {
	mkdir ~/Workspace/
	mkdir ~/Workspace/Websites/
	mkdir ~/Workspace/Applications/
}

function installHomebrew() {
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
}

function installBrews() {

  brew tap caskroom/homebrew-cask
  brews=( vim git phantomjs fontforge ttfautohint rename tree wget cmake brew-cask siege )

  for item in "${brews[@]}"

  do
    if [[ $item == "vim" ]]; then
      brew install $item --override-system-vim
    else
      brew install $item
    fi
  done

}

function installSoftware() {

  casks=( dropbox alfred vlc \
  				google-chrome firefox sublime-text atom limechat \
  				sequel-pro little-snitch google-drive vagrant vagrant-manager \
  				caffeine skype nmap
        )

  for item in "${casks[@]}"
  do
    brew cask install $item
  done

}

function setupSymlinks() {
  ln -s ~/.dotfiles/atom ~/.atom
}

makeDirectories && \
installRVM && \
installNVM && \
installHomebrew && \
installBrews && \
installSoftware && \
setupSymlinks
