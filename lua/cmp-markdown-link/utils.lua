local scandir = require('plenary.scandir')
local Path = require('plenary.path')

local M = {}


function M.load_all_targets(opt)
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
