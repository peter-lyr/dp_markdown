-- Copyright (c) 2024 liudepei. All Rights Reserved.
-- create at 2024/04/30 00:20:47 星期二

local M = {}

local B = require 'dp_base'

M.xxd_output_dir_path = B.getcreate_temp_dirpath { 'xxd_output', }

function M.bin_xxd(file)
  if not file then
    file = B.buf_get_name()
  end
  local bin_fname = B.rep(file)
  local bin_fname_tail = vim.fn.fnamemodify(bin_fname, ':t')
  local bin_fname_full__ = string.gsub(vim.fn.fnamemodify(bin_fname, ':h'), '\\', '_')
  bin_fname_full__ = string.gsub(bin_fname_full__, ':', '_')
  local xxd_output_sub_dir_path = M.xxd_output_dir_path:joinpath(bin_fname_full__)
  if not xxd_output_sub_dir_path:exists() then
    vim.fn.mkdir(xxd_output_sub_dir_path.filename)
  end
  local xxd = xxd_output_sub_dir_path:joinpath(bin_fname_tail .. '.xxd').filename
  local c = xxd_output_sub_dir_path:joinpath(bin_fname_tail .. '.c').filename
  local bak = xxd_output_sub_dir_path:joinpath(bin_fname_tail .. '.bak').filename
  vim.fn.system(string.format('copy /y "%s" "%s"', bin_fname, bak))
  vim.fn.system(string.format('xxd "%s" "%s"', bak, xxd))
  vim.fn.system(string.format('%s && xxd -i "%s" "%s"', B.system_cd(bak), vim.fn.fnamemodify(bak, ':t'), c))
  vim.cmd('e ' .. xxd)
  vim.cmd 'setlocal ft=xxd'
end

require 'which-key'.register {
  ['<leader>mx'] = { name = 'image.xxd', },
  ['<leader>mxx'] = { function() M.bin_xxd() end, 'image.xxd: do', mode = { 'n', 'v', }, silent = true, },
}

return M
