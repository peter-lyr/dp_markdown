local M = {}

local B = require 'dp_base'

M.source = B.getsource(debug.getinfo(1)['source'])
M.lua = B.getlua(M.source)

require 'dp_markdown.image.paste'

function M.image_paste()
  print 'image_paste'
end

require 'which-key'.register {
  ['<leader>mi'] = { name = 'markdown.image', },
  ['<leader>mip'] = { function() M.image_paste() end, 'markdown.image: paste', mode = { 'n', 'v', }, silent = true, },
}

return M
