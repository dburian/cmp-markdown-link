# cmp-markdown-link

nvim-cmp source for completing markdown links (right now only to markdown
files).

## Install

cmp-markdown-link requires [plenary.nvim][plenary] to be installed.

Install with favourite package manager.

E.g. [plug][plug]:
```vim
Plug 'dburian/cmp-markdown-link'
```

## Setup

Add `markdown-link` to your nvim-cmp sources.

```lua
require'cmp'.setup {
  sources = {
    {
      name = 'markdown-link',
      option = {
        reference_link_location = 'top',
        searched_depth = 3,
        wiki_base_url = '',
        wiki_end_url = '.md',
      }
  },
}
```

#### Warning for wiki-style links

Your links should always start with `wiki_base_url` and end with `wiki_end_url`.
Otherwise the link target could become ambiguous. For more info type `:help
cmp-markdown-link`.


## Contributing

If you want a certain functionality to be implemented/changed, feel free to
create issues and PRs. I will address/merge them when I have time.


[plenary]: https://github.com/nvim-lua/plenary.nvim
[plug]: https://github.com/junegunn/vim-plug
