local M = {}

local B = require 'dp_base'

M.source = B.getsource(debug.getinfo(1)['source'])
M.lua = B.getlua(M.source)

function M.make_url(file, patt)
  if not file then
    file = vim.fn.getreg '+'
  end
  if not B.file_exists(file) then
    return
  end
  local file_root = B.get_proj_root(file)
  local temp = vim.split(file_root, '\\')
  local file_root_name = temp[#temp]
  if not B.is(file_root) then
    return
  end
  if not patt then
    patt = '`%s`'
  end
  local rel = B.relpath(file, file_root)
  if B.is(rel) then
    vim.fn.append('.', string.format(patt, file_root_name .. ':' .. rel))
  else
    B.notify_info_append(string.format('not making rel: %s, %s', file, cur_file))
  end
end

function M.make_url_sel()
  local markdown_files = B.scan_files_deep(vim.loop.cwd(), { filetypes = { 'md', }, })
  B.ui_sel(markdown_files, 'sel as file to make url', function(file)
    if file and B.file_exists(file) then
      M.make_url(file)
    end
  end)
end

require 'which-key'.register {
  ['<leader>mu'] = { name = 'markdown.url', },
  ['<leader>muu'] = { function() M.make_url() end, 'markdown.url: make relative url from clipboard', mode = { 'n', 'v', }, silent = true, },
  ['<leader>mus'] = { function() M.make_url_sel() end, 'markdown.url: make relative url from sel markdown file', mode = { 'n', 'v', }, silent = true, },
}

return M
