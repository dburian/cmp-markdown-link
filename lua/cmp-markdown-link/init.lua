local cmp = require 'cmp'
local Path = require 'plenary.path'
local utils = require 'cmp-markdown-link.utils'


local function create_used_ref_links_entries(opts, linked_notes)
  local entries = {}
  for note_rel_path, note_id in pairs(linked_notes) do
    local full_path = Path.new(opts.cwd, note_rel_path)

    local entry = {
      label = '[' .. note_id .. ']',
      filterText = note_id,
      kind = cmp.lsp.CompletionItemKind.Variable,
      -- TODO: Only on resolve.
      documentation = {
        kind = 'markdown',
        value = full_path:read()
      },
      insertText = note_id .. ']'
    }

    table.insert(entries, entry)
  end


  return entries
end

local function create_ref_link_entries(targets, opts, linked_notes)
  local line_count = vim.api.nvim_buf_line_count(0)
  local ref_link_loc = opts.reference_link_location == 'top' and 0 or line_count

  local entries = {}
  for _, note in ipairs(targets) do
    local link_ref = '[' .. note.id .. ']: ' .. note.rel_path

    note.id = linked_notes[note.rel_path] or note.id

    local entry = {
      label = note.rel_path,
      kind = cmp.lsp.CompletionItemKind.File,
      -- TODO: Only on resolve.
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
      -- TODO: Only on resolve.
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

local function create_wiki_link_entries(targets, opts, _)
  local entries = {}
  for _, note in ipairs(targets) do
    local link_label = note.rel_path

    if #opts.wiki_base_url > 0 and
        vim.startswith(link_label, opts.wiki_base_url) then
      link_label = string.sub(link_label, #opts.wiki_base_url + 1)
    end

    if #opts.wiki_end_url > 0 and
        vim.endswith(link_label, opts.wiki_end_url) then
      link_label = string.sub(link_label, 0, - #opts.wiki_end_url - 1)
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
  local self = setmetatable({}, { __index = source })

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
  return { '[', '(' }
end

function source:complete(params, callback)
  local opts = utils.sanitize_opts(params.option)
  opts.cwd = opts.cwd or vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':h')

  -- Only display entries for link targets
  if not utils.is_place_for_link(opts, params.context) then
    return callback()
  end

  local targets = utils.load_all_targets(opts)
  local linked_notes = utils.get_buf_links()
  local entries = create_used_ref_links_entries(opts, linked_notes)

  -- TODO: Recognize the style of links used based on context.cursor_before_line
  local new_entries = create_entries[opts.style](targets, opts, linked_notes)
  for _, entry in ipairs(new_entries) do
    table.insert(entries, entry)
  end

  callback(entries)
end

return source
