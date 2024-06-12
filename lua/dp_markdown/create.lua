local M = {}

local B = require 'dp_base'

M.source = B.getsource(debug.getinfo(1)['source'])
M.lua = B.getlua(M.source)

function M.create_file_from_target()
  -- 1. zoom,inner,dac推192K
  local res = B.findall([[(\d+)\. ([^,]+),([^,]+),(.+)]], vim.fn.trim(vim.fn.getline '.'))
  if B.is(res) and res[1] then
    res = res[1]
    if res and #res == 4 then
      local idx = res[1]
      local chip = res[2]
      local client = res[3]
      local title = vim.fn.trim(vim.fn.split(res[4], '->')[1])
      local head_dir = B.file_parent(B.buf_get_name())
      local fname = B.getcreate_filepath(head_dir, string.format('%s-%s_%s-%s.md', vim.fn.strftime '%y%m%d', client, chip, title)).filename
      require 'dp_markdown.url'.make_url(fname, string.format('%s. `%%s`', idx))
      local bufnr = vim.fn.bufnr()
      B.cmd('b%d', bufnr)
      vim.cmd 'norm j0'
      B.notify_info(string.format('file created: %s', fname))
    end
  else
    -- ~ zoom,inner,dac推192K
    res = B.findall([[ *[~] ([^,]+),([^,]+),(.+)]], vim.fn.trim(vim.fn.getline '.'))
    if B.is(res) and res[1] then
      res = res[1]
      if res and #res == 3 then
        local chip = res[1]
        local client = res[2]
        local title = vim.fn.trim(vim.fn.split(res[3], '->')[1])
        local head_dir = B.file_parent(B.buf_get_name())
        local fname = B.getcreate_filepath(head_dir, string.format('%s-%s_%s-%s.norg', vim.fn.strftime '%d', client, chip, title)).filename
        require 'dp_markdown.url'.make_url(fname, '- {:$/%s]')
        local bufnr = vim.fn.bufnr()
        B.cmd('b%d', bufnr)
        vim.cmd 'norm j0'
        B.notify_info(string.format('file created: %s', fname))
      end
    end
  end
end

require 'which-key'.register {
  ['<leader>mcf'] = { function() M.create_file_from_target() end, 'markdown.create: file from target: 1. zoom,inner,problem', mode = { 'n', 'v', }, silent = true, },
}

return M
