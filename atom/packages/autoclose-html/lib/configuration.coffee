module.exports =
    config:
        additionalGrammars:
            title: 'Additional Grammars'
            description: 'Comma delimited list of grammar names, other than HTML and PHP, to apply this plugin to. Use "*" to run for all grammars.'
            type: 'array'
            default: []

        forceInline:
            title: 'Force Inline'
            description: 'Elements in this comma delimited list will render their closing tags on the same line, even if they are block by default. Use * to force all closing tags to render inline'
            type: 'array'
            default: ['title', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6']
        forceBlock:
            title: 'Force Block'
            description: 'Elements in this comma delimited list will render their closing tags after a tabbed line, even if they are inline by default. Values are ignored if Force Inline is *'
            type: 'array'
            default: ['head']
        neverClose:
            title: 'Never Close Elements'
            description: 'Comma delimited list of elements to never close'
            type: 'array'
            default: ['br', 'hr', 'img', 'input', 'link', 'meta', 'area', 'base', 'col', 'command', 'embed', 'keygen', 'param', 'source', 'track', 'wbr']
        makeNeverCloseSelfClosing:
            title: 'Make Never Close Elements Self-Closing'
            description: 'Closes elements with " />" (ie &lt;br&gt; becomes &lt;br /&gt;)'
            type: 'boolean'
            default: true
