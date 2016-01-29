Hello, this is my personal 2016 OSX setup. Probably more things I can automate but it's not like i'm doing this everyday. I've had to update this because of a future rebuild of my works laptop, and I don't want much downtime. Time is code. I've decided to consolidate both my provisioning script and my actual .dotfiles directories.

*** Things this script will do for you ***
* Setup atom with common packages for JS Web Developers
* Setup a sane gitconfig
* Setup a folder structure for projects within your home directory.
* Install tools and apps where they can be automated
* Remind me what else to install if it can't be automated.

# Setup

Git clone this project into your home directory then follow out the steps below

## Move this directory to be hidden
```
mv ~/dotfiles ~/.dotfiles
```

## Setup OSX Defaults mainly UI tweaks.

```
~/.dotfiles/scripts/osxdefaults
```

## Swap to ZSH and bring over some default config files

```
~/.dotfiles/scripts/setup.sh
```

## Provision OSX with tools and apps I use

```
~/.dotfiles/scripts/provision.sh
```

## Some other steps to take

### App Store Apps to download
* XScope
* Sketch
* Omnigraffle 6
* Patterns
* OnePassword

### Games to download
* Starcraft 2
* Heroes of the storm
* Guild Wars 2
* League of Legends

### Stuff to not store in repo
* Pull in BBC Related dotfiles from private repo.
* Restore backup certificates
* Setup Email clients again
* Install Chrome extension (Authy)
* Setup auth to personal webserver.

## Atom Packages it will install

[atom-beautify](git+https://github.com/Glavin001/atom-beautify.git)
Beautify HTML, CSS, JavaScript, PHP, Python, Ruby, Java, C, C++, C#, Objective-C, CoffeeScript, TypeScript, and SQL in Atom

[atom-ternjs](git+https://github.com/tststs/atom-ternjs.git)
JavaScript code intelligence for atom with Tern. Adds support for ES5, ES6 (JavaScript 2015), Node.js, jQuery & Angular. Extendable via plugins. Uses suggestion provider by autocomplete-plus.

[autoclose-html](git+https://github.com/mattberkowitz/autoclose-html.git)
Automates closing of HTML Tags

[autocomplete-plus](git+https://github.com/atom/autocomplete-plus.git)
Display possible completions in the editor while typing

[emmet](git+https://github.com/emmetio/emmet-atom.git)
Emmet – the essential tool for web developers

[file-icons](git+https://github.com/DanBrooker/file-icons.git)
Assign file extension icons and colours for improved visual grepping

[git-diff](git+https://github.com/atom/git-diff.git)
Marks lines in the editor gutter that have been added, edited, or deleted since the last commit.

[git-plus](git+https://github.com/akonwi/git-plus.git)
Do git things without the terminal

[highlight-line](git+https://github.com/richrace/highlight-line.git)
Highlights the current line in the editor

[highlight-selected](git+https://github.com/richrace/highlight-selected.git)
Highlights the current word selected when double clicking

[indent-guide-improved](git+https://github.com/harai/indent-guide-improved.git)
This draws indent guide more correctly and understandably.

[javascript-snippets](git+https://github.com/zenorocha/atom-javascript-snippets.git)
JavaScript & NodeJS Snippets for Atom

[linter](git+https://github.com/atom-community/linter.git)
A Base Linter with Cow Powers

[linter-jshint](git+https://github.com/AtomLinter/linter-jshint.git)
Linter plugin for JavaScript, using jshint

[merge-conflicts](git+https://github.com/smashwilson/merge-conflicts.git)
Resolve git conflicts within Atom

[minimap](git+https://github.com/atom-minimap/minimap.git)
A preview of the full source code.

[node-debugger](git+https://github.com/kiddkai/atom-node-debugger.git)
Debugger For Nodejs

[nuclide](git+https://github.com/facebook/nuclide.git)
A unified developer experience for web and mobile development, built as a suite of features on top of Atom to provide hackability and the support of an active community.

[open-recent](git+https://github.com/Zren/atom-open-recent.git)
Open recent files in the current window, and recent folders (optionally) in a new window.

[pigments](git+https://github.com/abe33/atom-pigments.git)
A package to display colors in project and files.

[react](git+https://github.com/orktes/atom-react.git)
React.js (JSX) language support, indentation, snippets, auto completion, reformatting

[save-session](git+https://github.com/mpeterson2/save-session.git)
An Atom package to restore your session.

[synced-sidebar](git+https://github.com/peterdotjs/atom-synced-sidebar.git)
Based on Sublime Text SyncedSideBar plugin. Active tab & sidebar are synced - sidebar entry automatically scrolls into view.

[todo-show](git+https://github.com/mrodalgaard/atom-todo-show.git)
Finds all the TODOs, FIXMEs, CHANGEDs, etc. in your project.

[tool-bar](git+https://github.com/suda/tool-bar.git)
Package providing customisable tool bar
