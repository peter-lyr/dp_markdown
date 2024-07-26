local M = {}

local sta, B = pcall(require, 'dp_base')

if not sta then return print('Dp_base is required!', debug.getinfo(1)['source']) end

if B.check_plugins {
      'folke/which-key.nvim',
      'git@github.com:peter-lyr/sha2',
      'git@github.com:peter-lyr/dp_nvimtree',
      'git@github.com:peter-lyr/dp_git',
    } then
  return
end

require 'dp_markdown.export'
require 'dp_markdown.preview'
require 'dp_markdown.cfile'
require 'dp_markdown.url'
-- require 'dp_markdown.create'
require 'dp_markdown.run'
require 'dp_markdown.image'

-- B.copyright('md', function()
--   vim.fn.append('$', {
--     '',
--     string.format('# %s', vim.fn.strftime '%y%m%d-%Hh%Mm'),
--   })
--   vim.lsp.buf.format()
--   vim.cmd 'norm Gw'
-- end)

require 'which-key'.register {
  ['<leader>m'] = { name = 'markdown', },
  ['<leader>mc'] = { name = 'markdown.cfile/create', },
}

return M
