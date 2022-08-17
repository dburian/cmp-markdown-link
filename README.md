# cmp-markdown-link

nvim-cmp source for completing markdown links (right now only to files).

## Install

cmp-markdown-link requires [plenary.nvim][plenary] to be installed.

Install with favourite package manager.

E.g. [plug][plug]:
```vim
Plug 'dburian/cmp-markdown-link'
```

## Setup

Add to your nvim-cmp sources.

For reference-style links:

```lua
require'cmp'.setup {
  sources = {
    {
      name = 'markdown-link',
      option = {
        reference_link_location = 'top',
        searched_depth = 3,
        style = 'reference',
      }
  },
}
```

For inline links:
```lua
require'cmp'.setup {
  sources = {
    {
      name = 'markdown-link',
      option = {
        searched_depth = 3,
        style = 'inline',
      }
  },
}
```

For wiki-style links:

> Warning: Your links should always start with `wiki_base_url` and end with
> `wiki_end_url`. Otherwise the link target could become ambiguous. For more
> info type `:help cmp-markdown-link`.

```lua
require'cmp'.setup {
  sources = {
    {
      name = 'markdown-link',
      option = {
        searched_depth = 3,
        style = 'wiki',
        wiki_base_url = '',
        wiki_end_url = '.md',
      }
  },
}
```


## Contributing

This package is in a side project, meaning it is not my priority number 1. Also
right now it does not do much. There are multitude of improvements which could
(and maybe will) be done (e.g. linking to headlines). Nevertheless if you want a
certain functionality to be implemented, feel free to create issues and PRs. I
will address/merge them when I have time.


[plenary]: https://github.com/nvim-lua/plenary.nvim
[plug]: https://github.com/junegunn/vim-plug
