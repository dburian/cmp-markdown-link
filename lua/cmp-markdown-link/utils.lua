local scandir = require('plenary.scandir')
local Path = require('plenary.path')

local M = {}

function M.load_all_targets(opts)
  local scan_opts = {
    add_dirs = false,
    hidden = false,
    depth = opts.searched_depth,
    -- TODO: Add option for searching custom dirs
    search_pattern = '.*%.md',
  }

  local scan_dirs = opts.searched_dirs or {}
  table.insert(scan_dirs, opts.cwd)
  scan_dirs = vim.tbl_map(vim.fn.expand, scan_dirs)
  scan_dirs = vim.fn.sort(scan_dirs)
  scan_dirs = vim.fn.uniq(scan_dirs)

  local paths = {}
  for _, dir in ipairs(scan_dirs) do
    table.insert(paths, scandir.scan_dir(dir, scan_opts))
  end

  paths = vim.tbl_flatten(paths)
  -- In case some scan_dir was parent of another one and searched_depth was
  -- large enough.
  paths = vim.fn.sort(paths)
  paths = vim.fn.uniq(paths)

  local notes = {}
  for _, path in ipairs(paths) do
    -- TODO: It is not relative really...
    local rel_path = Path.new(path):make_relative(opts.cwd)
    table.insert(notes, {
      path = path,
      rel_path = rel_path,
      id = vim.fn.fnamemodify(Path.new(rel_path):shorten(), ':r'),
      contents = Path.new(path):read()
    })
  end

  return notes
end

function M.get_buf_links(buffer)
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

local default_option = {
  reference_link_location = 'top',
  searched_depth = 5,
  style = 'reference', -- possible: 'reference', 'wiki', 'inline'
  wiki_base_url = '',
  wiki_end_url = '',
}

function M.sanitize_opts(opts)
  if opts.style ~= 'reference' and
      opts.style ~= 'wiki' and
      opts.style ~= 'inline' then
    opts.style = nil
  end

  local sanitized = vim.tbl_extend('keep', opts, default_option)

  return sanitized
end

function M.is_place_for_link(opts, context)
  local ending = ']['
  if opts.style == 'inline' then
    ending = ']('
  elseif opts.style == 'wiki' then
    ending = '[['
  end

  return vim.endswith(context.cursor_before_line, ending)
end

return M
