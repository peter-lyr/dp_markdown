local M = {}

local B = require 'dp_base'

M.source = B.getsource(debug.getinfo(1)['source'])
M.lua = B.getlua(M.source)

function M.run_in_cmd(silent)
  local head = B.get_head_dir()
  local line = vim.fn.trim(vim.fn.getline '.')
  if B.is(head) and B.is(line) then
    if silent then
      B.system_run_histadd('start silent', '%s && %s', B.system_cd(head), line)
    else
      B.system_run_histadd('start', '%s && %s', B.system_cd(head), line)
    end
  end
end

require 'which-key'.register {
  ['<leader>mr'] = { name = 'markdown.run', },
  ['<leader>mrc'] = { function() M.run_in_cmd() end, 'markdown.run: run current line as cmd command', mode = { 'n', 'v', }, silent = true, },
  ['<leader>mrs'] = { function() M.run_in_cmd 'silent' end, 'markdown.run: run current line as cmd command silent', mode = { 'n', 'v', }, silent = true, },
}

return M
