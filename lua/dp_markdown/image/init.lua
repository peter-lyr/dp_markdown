local M = {}

local B = require 'dp_base'

M.source = B.getsource(debug.getinfo(1)['source'])
M.lua = B.getlua(M.source)

require 'dp_markdown.image.paste'

require 'which-key'.register {
  ['<leader>mi'] = { name = 'markdown.image', },
}

return M
