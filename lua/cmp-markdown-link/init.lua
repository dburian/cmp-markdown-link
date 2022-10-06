local cmp = require 'cmp'
local Path = require 'plenary.path'
local utils = require 'cmp-markdown-link.utils'

local function get_used_reference_entries(opts, linked_notes)
  local entries = {}
  for rel_path, target_id in pairs(linked_notes) do
    local full_path = nil
    if Path.new(rel_path):is_absolute() then
      full_path = rel_path
    else
      full_path = Path.new(opts.cwd, rel_path):absolute()
    end

    local entry = {
      label = '[' .. target_id .. ']',
      filterText = target_id,
      kind = cmp.lsp.CompletionItemKind.Variable,
      data = {
        path = full_path,
      },
      insertText = target_id .. ']'
    }

    table.insert(entries, entry)
  end


  return entries
end

local function get_reference_entries(targets, opts, linked_notes)
  local line_count = vim.api.nvim_buf_line_count(0)
  local ref_link_loc = opts.reference_link_location == 'top' and 0 or line_count

  local entries = {}
  for _, path in ipairs(targets) do
    -- TODO: May not be unique
    local rel_path = utils.make_relative(path, opts.cwd)
    local target_id = linked_notes[path.rel_path] or utils.get_target_id(path)
    local link_ref = '[' .. target_id .. ']: ' .. rel_path


    local entry = {
      label = rel_path,
      kind = cmp.lsp.CompletionItemKind.File,
      data = {
        path = path,
      },
      insertText = target_id .. ']'
    }

    -- TODO: May be done in custom source:execute
    if not linked_notes[rel_path] then
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

local function get_inline_entries(targets, opts)
  local entries = {}
  for _, path in ipairs(targets) do
    local rel_path = utils.make_relative(path, opts.cwd)

    local entry = {
      label = rel_path,
      kind = cmp.lsp.CompletionItemKind.File,
      data = {
        path = path,
      },
      insertText = rel_path .. ')'
    }

    table.insert(entries, entry)
  end

  return entries
end

local function get_wiki_entries(targets, opts)
  local entries = {}
  for _, path in ipairs(targets) do
    local rel_path = utils.make_relative(path, opts.cwd)
    local anchor = rel_path

    if #opts.wiki_base_url > 0 and
        vim.startswith(anchor, opts.wiki_base_url) then
      anchor = string.sub(anchor, #opts.wiki_base_url + 1)
    end

    if #opts.wiki_end_url > 0 and
        vim.endswith(anchor, opts.wiki_end_url) then
      anchor = string.sub(anchor, 0, - #opts.wiki_end_url - 1)
    end

    local entry = {
      label = rel_path,
      kind = cmp.lsp.CompletionItemKind.File,
      data = {
        path = path,
      },
      insertText = anchor .. ']]'
    }

    table.insert(entries, entry)
  end

  return entries
end

-- nvim-cmp source
local source = {}

function source.new()
  local self = setmetatable({}, { __index = source })

  return self
end

function source:get_debug_name()
  -- TODO: Add links to headings
  return 'markdown-link'
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

  P(params)
  -- Only display entries for link targets
  if not utils.is_place_for_link(params.context) then
    return callback()
  end

  local targets = utils.scan_for_targets(opts)
  local linked_notes = utils.get_buf_links()
  local entries = get_used_reference_entries(opts, linked_notes)

  local link_type_entries = nil
  local cbl = params.context.cursor_before_line
  if vim.endswith(cbl, '][') then
    link_type_entries = get_reference_entries(targets, opts, linked_notes)
  elseif vim.endswith(cbl, '](') then
    link_type_entries = get_inline_entries(targets, opts)
  elseif vim.endswith(cbl, '[[') then
    link_type_entries = get_wiki_entries(targets, opts)
  end

  if link_type_entries then
    for _, lt_entry in ipairs(link_type_entries) do
      table.insert(entries, lt_entry)
    end
  end

  callback(entries)
end

function source:resolve(completionItem, callback)
  if completionItem.data.path then
    completionItem.documentation = {
      kind = 'markdown',
      value = Path.new(completionItem.data.path):read()
    }
  end

  callback(completionItem)
end

return source
