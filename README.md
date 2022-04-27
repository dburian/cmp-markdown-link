# cmp-markdown-link

nvim-cmp source for completing markdown links.

## Install

cmp-markdown-link requires [plenary.nvim][plenary] to be installed.

Install with favourite package manager.

E.g. plug:
```vim
Plug 'dburian/cmp-markdown-link'
```

## Setup

Add to your nvim-cmp sources.

```lua
require'cmp'.setup {
  sources = {
    {
      name = 'markdown-link',
      -- Optionally provide options
      option = {
        reference_link_location = 'bottom',
        searched_depth = 3,
      }
  },
}
```

### Options

- `reference_link_location` [`'top'` | `'bottom'`] - where should the reference
  links be placed in the document. The default is `'bottom'`.
- `searched_depth` [`int`] - max depth searched for markdown files counting from
  the containing folder of currently open markdown file. The default is `5`.


## Contributing

This package is in a side project, meaning it is not my priority number 1. Also
right now it does not do much. There are multitude of improvements which could
be done (e.g. linking to headlines, supporting in-line links).

Feel free to create issues and PRs, I will address them/merge them when I have
time.


[plenary]: https://github.com/nvim-lua/plenary.nvim
