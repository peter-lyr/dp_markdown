local M = {}

local B = require 'dp_base'

M.source = B.getsource(debug.getinfo(1)['source'])
M.lua = B.getlua(M.source)

vim.g.mkdp_highlight_css = B.get_file(B.get_source_dot_dir(M.source), 'mkdp_highlight.css')

require 'which-key'.register {
  ['<leader>mp'] = { name = 'markdown.preview', },
  ['<leader>mpp'] = { '<cmd>MarkdownPreview<cr>', 'markdown.preview: preview', mode = { 'n', 'v', }, silent = true, },
  ['<leader>mps'] = { '<cmd>MarkdownPreviewStop<cr>', 'markdown.preview: stop', mode = { 'n', 'v', }, silent = true, },
  ['<leader>mp<leader>'] = { '<cmd>MarkdownPreviewToggle<cr>', 'markdown.preview: toggle', mode = { 'n', 'v', }, silent = true, },
}

return M
