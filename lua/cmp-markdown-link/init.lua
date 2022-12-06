local cmp = require 'cmp'
local Path = require 'plenary.path'
local utils = require 'cmp-markdown-link.utils'

local function get_reference_entries(targets, opts, linked_notes, used_target_ids)
  local line_count = vim.api.nvim_buf_line_count(0)
  local ref_link_loc = opts.reference_link_location == 'top' and 0 or line_count

  local entries = {}

  for id, path in pairs(linked_notes) do
    local entry = {
      label = '[' .. id .. ']',
      filterText = id,
      kind = cmp.lsp.CompletionItemKind.Variable,
      insertText = id .. ']',
      data = {
        path,
      }
    }

    table.insert(entries, entry)
  end

  for _, path in ipairs(targets) do
    local rel_path = utils.make_relative(path, opts.cwd)
    -- Entries from linked_notes have laready been created
    if linked_notes[rel_path] == nil then
      local target_id = utils.get_unique_target_id(rel_path, used_target_ids)

      local entry = {
        label = rel_path,
        kind = cmp.lsp.CompletionItemKind.File,
        insertText = target_id .. ']',
        data = {
          path = path,
        }
      }

      local link_ref = '[' .. target_id .. ']: ' .. rel_path
      -- TODO: May be done in custom source:execute
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

      table.insert(entries, entry)
    end
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
  opts.cwd = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':h')
  print("CWD: " .. opts.cwd)

  -- Only display entries for link targets
  if not utils.is_place_for_link(params.context) then
    return callback()
  end

  local targets = utils.scan_for_targets(opts)
  local linked_notes, used_target_ids = utils.get_buf_links()

  local entries = nil
  local cbl = params.context.cursor_before_line
  if vim.endswith(cbl, '][') then
    entries = get_reference_entries(targets, opts, linked_notes, used_target_ids)
  elseif vim.endswith(cbl, '](') then
    entries = get_inline_entries(targets, opts)
  elseif vim.endswith(cbl, '[[') then
    entries = get_wiki_entries(targets, opts)
  end

  callback(entries)
end

function source:resolve(completionItem, callback)
  if completionItem.data.path then
    local path = Path.new(completionItem.data.path)
    if path:is_file() and vim.endswith(path.filename, '.md') then
      completionItem.documentation = {
        kind = 'markdown',
        value = path:read()
      }
    end
  end

  callback(completionItem)
end

return source
