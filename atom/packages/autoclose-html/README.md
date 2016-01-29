# Auto Close HTML package for Atom Text Editor

Will automatically add closing tags when you complete the opening tag.

# Installation

Install using

`apm install autoclose-html`

# Usage

Under normal circumstances ending tags will be inserted on the same line for inline elements and with `\n\t\n` in between for block elements. This is determined by attaching an element of the given type to the window and checking it's calculated `display` value.
You can use Force Inline and Force Block preferences to override this.

By Default works for HTML, HTML (Go), HTML (Rails), HTML (Angular), HTML (Mustache), HTML (Handlebars), HTML (Ruby - ERB), HTML (Jinja Templates), Ember HTMLBars, JavaScript with JSX, PHP.  If you feel like another grammar should be supported by default please submit a PR, you can always add

# Bug Reports and Contributing

If you find a bug, please feel free to file an issue. Please understand however that I have very little time to work on this anymore, so most feature requests will not be implemented.

Better than an issue, however, would be to try and fix it yourself and submit a PR.

If you are interested in helping maintain this library, please contact me. As I mentioned, I have very little time to devote to this anymore, so if someone has interest in helping to keep it maintained, I'm open to considering it.


# Options

## Additional Grammar

Comma delimited list of grammar names, other than defaults (see above), to apply this plugin to. Use "*" to run for all grammars.

## Force Inline

Elements in this comma delimited list will render their closing tags on the same line, even if they are block by default. You can set this to "*" to force all closing tags to render inline.

## Force Block

Elements in this comma delimited list will render their closing tags after a tabbed line, even if they are inline by default. A value of "*" for Force Inline overrides all values in Force Block.

## Never Close

Elements in this comma delimited list should *not* render a closing tag

## Make Never Close Elements Self Closing

Will convert elements in Never Close list from `<br>` to `<br />`


# Changelog

#### 0.20.0
- HTML (Jinja Templates), Ember HTMLBars, JavaScript with JSX added to default grammars, per user requests
- Dispose events on deactivate (should prevent double closing after an upgrade in the future, although I don't think it will help for this release)
- Added ability to use "*" for Force Inline Options
- Some Readme cleanup
