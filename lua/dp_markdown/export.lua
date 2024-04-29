local M = {}

local B = require 'dp_base'

M.markdown_export_py = B.get_file(B.get_source_dot_dir(M.source), 'markdown_export.py')

M.fts = {
  'pdf', 'html', 'docx',
}

function M.export_create()
  B.system_run('asyncrun', 'python %s %s & pause', M.markdown_export_py, B.buf_get_name())
end

function M.export_delete()
  local files = B.scan_files_deep(nil, { filetypes = M.fts, })
  for _, file in ipairs(files) do
    B.delete_file(file)
  end
  B.notify_info(#files .. ' files deleting.')
end

require 'which-key'.register {
  ['<leader>me'] = { name = 'markdown.export', },
  ['<leader>mec'] = { function() M.export_create() end, 'markdown.export: create', mode = { 'n', 'v', }, silent = true, },
  ['<leader>med'] = { function() M.export_delete() end, 'markdown.export: delete', mode = { 'n', 'v', }, silent = true, },
}

return M
