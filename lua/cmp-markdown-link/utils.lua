local scandir = require('plenary.scandir')
local Path = require('plenary.path')

local M = {}

function M.scan_for_targets(opts)
  local scan_opts = {
    add_dirs = false,
    hidden = false,
    depth = opts.searched_depth,
    search_pattern = '.*%.md',
  }

  local scan_dirs = vim.tbl_map(vim.fn.expand, opts.searched_dirs)
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

  return paths
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
  searched_dirs = { '%:h' },
  searched_depth = 5,
  wiki_base_url = '',
  wiki_end_url = '',
}

function M.sanitize_opts(opts)
  local sanitized = vim.tbl_extend('keep', opts, default_option)

  return sanitized
end

--- Makes path relative to cwd. Useless once issue plenary.nvim/issues/411 is
--solved.
function M.make_relative(path, cwd)
  local relative = Path.new(path):make_relative(cwd)
  -- TODO: Is not really relative.
  return relative

  -- if not Path.new(relative).is_absolute() then
  --   return relative
  -- end

end

function M.get_target_id(rel_path)
  return vim.fn.fnamemodify(Path.new(rel_path):shorten(), ':r')
end

function M.is_place_for_link(context)
  local cbl = context.cursor_before_line
  return #cbl >= 2 and (vim.endswith(cbl, '][') or
      vim.endswith(cbl, '](') or
      vim.endswith(cbl, '[['))
end

return M
