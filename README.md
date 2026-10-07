dotfiles
========

Keeping my config consistent across multiple devices.

My settings work on macOS and Linux with zsh and oh-my-zsh. Node comes from
[mise](https://mise.jdx.dev); Homebrew-layout packages are used when present.
My setup works for me but if it doesn't work for you, no hard feelings go ahead and change it :)

Keeping my work device and personal device development environment consistent.

If you think the changes you make would benefit me, send a pull request.

## Install independently

Install Git, GNU Stow, zsh, Oh My Zsh and its `zsh-autosuggestions` plugin first.
Install [mise](https://mise.jdx.dev/getting-started.html) and make it available
on `PATH` or at `~/.local/bin/mise`. This repository does not require the
machine-provisioning repository.

Before replacing an existing nvm-based shell, install and select a working
Node runtime:

```sh
mise use --global node@lts
mise exec -- node --version
```

Then clone this repository and run its installer:

```sh
git clone https://github.com/mintuz/.dotfiles.git "$HOME/.dotfiles"
cd "$HOME/.dotfiles"
./install.sh
```

The installer always links into `$HOME`, even when the checkout is elsewhere.
It keeps `~/.config/mise/conf.d` as a real directory. Its `dotfiles.toml`
fragment can therefore coexist with machine-specific fragments and your
existing mise configuration.

The shell no longer starts nvm or requires the `brew` command. It adds an
existing Apple Silicon or Linux Homebrew package prefix to `PATH`, then
activates mise. It resolves Python from the active `PATH`, not a Mac-only
path. `PNPM_HOME` remains configurable and otherwise uses the platform default.

Project `.nvmrc` and `.node-version` files select Node. The directory hook
installs a missing project version before use; it does not install a missing
global default when starting a shell outside a project. Leaving the project
restores the global selection. Review and trust project mise configuration
before allowing it to run.

For the coordinated machine-setup migration, run its Node installation step
before applying these dotfiles. Existing nvm installations are not deleted,
but these shell files no longer activate them.


## Test the installer

Install [bats-core](https://github.com/bats-core/bats-core), for example with
`brew install bats-core`. Then run the installer tests from the repository root:

```sh
bats tests
```

The tests run `install.sh` against a temporary home directory.

## License
```
The MIT License (MIT)

Copyright (c) 2015 Adam Bulmer

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
```
