local cmp = require'cmp'
local scandir = require('plenary.scandir')
local Path = require('plenary.path')

local default_option = {
  reference_link_location = 'top',
  searched_depth = 5,
  style = 'reference', -- possible: 'reference', 'wiki', 'inline'
  wiki_base_url = '',
  wiki_end_url = '',
}

-- Helper functions
local function load_all_targets(opt)
  local scanned_path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':h')
  local paths = scandir.scan_dir(scanned_path, {
    add_dirs = false,
    hidden = false,
    depth = opt.searched_depth,
    search_pattern = '.*%.md',
  })

  local notes = {}
  for _, path in ipairs(paths) do
    local rel_path = Path.new(path):make_relative(scanned_path)
    table.insert(notes, {
      path = path,
      rel_path = rel_path,
      id = vim.fn.fnamemodify(Path.new(rel_path):shorten(), ':r'),
      contents = Path.new(path):read()
    })
  end

  return notes
end

local function get_buf_links(buffer)
  if not buffer then
    buffer = 0
  end

  local buf_lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
  local lines = {}
  for _, line in ipairs(buf_lines) do
    local note_id, note_rel_path = string.match(line, '%[([^]]*)%]:%s*(.*%.md)$')
    if note_id and note_rel_path then
      lines[note_rel_path] = note_id
    end
  end

  return lines
end

local function sanitize_opts(opts)
  if opts.style ~= 'reference' and
    opts.style ~= 'wiki' and
    opts.style ~= 'inline' then
    opts.style = nil
  end

  local sanitized = vim.tbl_extend('keep', opts, default_option)

  return sanitized
end

local function place_for_link(opts, context)
  local ending = ']['
  if opts.style == 'inline' then
    ending = ']('
  elseif opts.style == 'wiki' then
    ending = '[['
  end

  return vim.endswith(context.cursor_before_line, ending)
end

local function create_ref_link_entries(targets, opts)
  local linked_notes = get_buf_links()

  local line_count = vim.api.nvim_buf_line_count(0)
  local ref_link_loc = opts.reference_link_location == 'top' and 0 or line_count

  local entries = {}
  for _, note in ipairs(targets) do
    local link_ref = '[' .. note.id .. ']: ' .. note.rel_path

    note.id = linked_notes[note.rel_path] or note.id

    local entry = {
      label = note.rel_path,
      kind = cmp.lsp.CompletionItemKind.File,
      documentation = {
        kind = 'markdown',
        value = note.contents
      },
      insertText = note.id .. ']'
    }

    if not linked_notes[note.rel_path] then
      if ref_link_loc == 0 then
        local buf_first_line = vim.api.nvim_buf_get_lines(0, 0, 1, true)[1]
        link_ref = link_ref .. '\n' .. buf_first_line
      end

      entry.additionalTextEdits = {
        {
          newText = link_ref,
          range = {
            start = {
              line = ref_link_loc,
              character = 0,
            },
            ['end'] = {
              line = ref_link_loc,
              character = string.len(link_ref)
            }
          }
        },
      }
    end

    table.insert(entries, entry)
  end

  return entries
end

local function create_inline_link_entries(targets, _)
  local entries = {}
  for _, note in ipairs(targets) do

    local entry = {
      label = note.rel_path,
      kind = cmp.lsp.CompletionItemKind.File,
      documentation = {
        kind = 'markdown',
        value = note.contents
      },
      insertText = note.rel_path .. ')'
    }

    table.insert(entries, entry)
  end

  return entries
end

local function create_wiki_link_entries(targets, opts)
  local entries = {}
  for _, note in ipairs(targets) do
    local link_label = note.rel_path

    if #opts.wiki_base_url > 0 and
      vim.startswith(link_label, opts.wiki_base_url) then
      link_label = string.sub(link_label, #opts.wiki_base_url + 1)
    end

    if #opts.wiki_end_url > 0 and
      vim.endswith(link_label, opts.wiki_end_url) then
      link_label = string.sub(link_label, 0, -#opts.wiki_end_url - 1)
    end

    local entry = {
      label = note.rel_path,
      kind = cmp.lsp.CompletionItemKind.File,
      documentation = {
        kind = 'markdown',
        value = note.contents
      },
      insertText = link_label .. ']]'
    }

    table.insert(entries, entry)
  end

  return entries
end

local create_entries = {
  reference = create_ref_link_entries,
  inline = create_inline_link_entries,
  wiki = create_wiki_link_entries,
}

-- nvim-cmp source
local source = {}

function source.new()
  local self = setmetatable({}, {__index = source})

  return self
end

function source:get_debug_name()
  -- TODO: Add links to headings
  return 'markdown link to files completion'
end

function source:is_available()
  return vim.opt.filetype:get() == 'markdown'
end

function source.get_trigger_characters()
  return {'[', '('}
end

function source:complete(params, callback)
  local opts = sanitize_opts(params.option)

  -- Only display entries for link targets
  if not place_for_link(opts, params.context) then
    return callback()
  end

  local targets = load_all_targets(opts)

  local entries = create_entries[opts.style](targets, opts)

  callback(entries)
end

return source
