sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
mv ~/.dotfiles/templates/zshrc ~/.zshrc
mv ~/.dotfiles/templates/gitconfig ~/.gitconfig
mv ~/.dotfiles/templates/npmrc ~/.npmrc

echo "Restart your terminal now to turn into ZSH"
echo "Then run '~/.dotfiles/provision.sh'"
