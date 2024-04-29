local M = {}

local sta, B = pcall(require, 'dp_base')

if not sta then return print('Dp_base is required!', debug.getinfo(1)['source']) end

M.source = B.getsource(debug.getinfo(1)['source'])
M.lua = B.getlua(M.source)

vim.g.mkdp_highlight_css = B.get_file(B.get_source_dot_dir(M.source, 'preview'), 'mkdp_highlight.css')

M.markdowntable_line = 0

M.markdown_export_py = B.get_file(B.get_source_dot_dir(M.source, 'export'), 'markdown_export.py')

M.fts = {
  'pdf', 'html', 'docx',
}

M.file_stack = {}

function M.export()
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
end

B.copyright('md', function()
  vim.fn.append('$', {
    '',
    string.format('# %s', vim.fn.strftime '%y%m%d-%Hh%Mm'),
  })
  vim.lsp.buf.format()
  vim.cmd 'norm Gw'
end)

function M.cfile()
  function M.open_cfile_in_curbuf_and_stack()
    local cfile = B.get_cfile()
    if B.is(cfile) and B.file_exists(cfile) and vim.fn.filereadable(cfile) == 1 then
      local cur_file = B.buf_get_name()
      if not B.is_in_tbl(cur_file, M.file_stack) then
        M.file_stack[#M.file_stack + 1] = cur_file
      end
      B.jump_or_split(cfile)
      M.file_stack[#M.file_stack + 1] = cfile
    else
      if B.is(cfile) and B.is_dir(cfile) then
        B.cmd('e %s', cfile)
      else
        B.echo('not a file: %s', cfile)
      end
    end
  end

  function M.pop_from_stack_and_go_back_last_buffer()
    while #M.file_stack > 0 do
      local file = table.remove(M.file_stack)
      if file ~= B.buf_get_name() then
        if B.is(file) and B.file_exists(file) and vim.fn.filereadable(file) == 1 then
          B.jump_or_split(file)
          break
        end
      end
    end
  end

  function M.open_cfile_in_system()
    B.system_open_file_silent('%s', B.get_cfile())
  end

  function M.copy_cfile_url_to_clip()
    local cfile = B.get_cfile()
    local name = ''
    if not B.is(cfile) then
      cfile = ''
      local res = B.findall('\\[(.*)\\]\\((.+)\\)', vim.fn.getline '.')
      if res then
        for _, i in ipairs(res) do
          name = i[1]
          cfile = B.get_cfile(i[2])
          break
        end
      end
    end
    if B.is(cfile) and B.file_exists(cfile) and vim.fn.filereadable(cfile) == 1 then
      if not B.is(name) then
        name = string.match(vim.fn.getline '.', '%[(.+)%]%(')
      end
      if name then
        local ext = string.match(cfile, '%.([^.]+)$')
        local rename_file = name .. '.' .. ext
        local newfile = B.get_filepath(B.windows_temp, rename_file)
        vim.fn.setreg('+', newfile)
        B.notify_info(newfile .. ' path copied as text')
      else
        vim.fn.setreg('+', cfile)
        B.notify_info(cfile .. ' path copied as text')
      end
    else
      B.echo('not a file: %s', cfile)
    end
  end

  function M.copy_cfile_itself_to_clip()
    local cfile = B.get_cfile()
    local name = ''
    if not B.is(cfile) then
      cfile = ''
      local res = B.findall('\\[(.*)\\]\\((.+)\\)', vim.fn.getline '.')
      if res then
        for _, i in ipairs(res) do
          name = i[1]
          cfile = B.get_cfile(i[2])
          break
        end
      end
    end
    if B.is(cfile) and B.file_exists(cfile) and vim.fn.filereadable(cfile) == 1 then
      if not B.is(name) then
        name = string.match(vim.fn.getline '.', '%[(.+)%]%(')
      end
      if name then
        local ext = string.match(cfile, '%.([^.]+)$')
        local rename_file = name .. '.' .. ext
        local newfile = B.get_filepath(B.windows_temp, rename_file)
        B.system_run('start silent', 'copy /y "%s" "%s" && %s "%s"', B.rep(cfile), newfile, B.copy2clip_exe, newfile)
        B.notify_info(newfile .. ' copied')
      else
        B.system_run('start silent', '%s "%s"', B.copy2clip_exe, cfile)
        B.notify_info(cfile .. ' copied')
      end
    else
      B.echo('not a file: %s', cfile)
    end
  end
end

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

  function M.make_url_sel()
    local markdown_files = B.scan_files_deep(vim.loop.cwd(), { filetypes = { 'md', }, })
    B.ui_sel(markdown_files, 'sel as file to make url', function(file)
      if file and B.file_exists(file) then
        M.make_url(file)
      end
    end)
  end
end

function M.create()
  function M.create_file_from_target()
    -- 1. zoom,inner,dac推192K
    local res = B.findall([[(\d+)\. ([^,]+),([^,]+),(.+)]], vim.fn.trim(vim.fn.getline '.'))
    if B.is(res) then
      res = res[1]
      if res and #res == 4 then
        local idx = res[1]
        local chip = res[2]
        local client = res[3]
        local title = vim.fn.trim(vim.fn.split(res[4], '->')[1])
        local head_dir = B.file_parent(B.buf_get_name())
        local fname = B.getcreate_filepath(head_dir, string.format('%s-%s_%s-%s.md', vim.fn.strftime '%y%m%d', client, chip, title)).filename
        M.make_url(fname, string.format('%s. `%%s`', idx))
        local bufnr = vim.fn.bufnr()
        B.cmd('b%d', bufnr)
        vim.cmd 'norm j0'
        B.notify_info(string.format('file created: %s', fname))
      end
    end
  end
end

function M.url()
  function M.run()
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
  end
end

function M._get_paragraph()
  local paragraph = {}
  local linenr = vim.fn.line '.'
  local lines = 0
  for i = linenr, 1, -1 do
    local line = vim.fn.getline(i)
    if #line > 0 then
      lines = lines + 1
      table.insert(paragraph, 1, line)
    else
      M.markdowntable_line = i + 1
      break
    end
  end
  for i = linenr + 1, vim.fn.line '$' do
    local line = vim.fn.getline(i)
    if #line > 0 then
      table.insert(paragraph, line)
      lines = lines + 1
    else
      break
    end
  end
  return paragraph
end

function M.align_table()
  if vim.opt.modifiable:get() == 0 then
    return
  end
  if vim.opt.ft:get() ~= 'markdown' then
    return
  end
  local ll = vim.fn.getpos '.'
  local lines = M._get_paragraph()
  local cols = 0
  for _, line in ipairs(lines) do
    local cells = vim.fn.split(vim.fn.trim(line), '|')
    if string.match(line, '|') and cols < #cells then
      cols = #cells
    end
  end
  if cols == 0 then
    return
  end
  local Lines = {}
  local Matrix = {}
  for _, line in ipairs(lines) do
    local cells = vim.fn.split(vim.fn.trim(line), '|')
    local Cells = {}
    local matrix = {}
    for i = 1, cols do
      local cell = cells[i]
      if cell then
        cell = string.gsub(cells[i], '^%s*(.-)%s*$', '%1')
      else
        cell = ''
      end
      table.insert(Cells, cell)
      table.insert(matrix, { vim.fn.strlen(cell), vim.fn.strwidth(cell), })
    end
    table.insert(Lines, Cells)
    table.insert(Matrix, matrix)
  end
  local Cols = {}
  for i = 1, cols do
    local m = 0
    for j = 1, #Matrix do
      if Matrix[j][i][2] > m then
        m = Matrix[j][i][2]
      end
    end
    table.insert(Cols, m)
  end
  local newLines = {}
  for i = 1, #Lines do
    local Cells = Lines[i]
    local newCell = '|'
    for j = 1, cols do
      newCell = newCell .. string.format(string.format(' %%-%ds |', Matrix[i][j][1] + (Cols[j] - Matrix[i][j][2])), Cells[j])
    end
    table.insert(newLines, newCell)
  end
  vim.fn.setline(M.markdowntable_line, newLines)
  B.cmd('norm %dgg0%d|', ll[2], ll[3])
end

M.export()
M.cfile()
M.create()
M.run()
M.url()

require 'which-key'.register {
  ['<leader>m'] = { name = 'markdown', },
  ['<leader>mc'] = { name = 'markdown.copy/create', },
}

require 'which-key'.register {
  ['<leader>me'] = { name = 'markdown.export', },
  ['<leader>mec'] = { function() M.export_create() end, 'markdown.export: create', mode = { 'n', 'v', }, silent = true, },
  ['<leader>med'] = { function() M.export_delete() end, 'markdown.export: delete', mode = { 'n', 'v', }, silent = true, },
}

require 'which-key'.register {
  ['<leader>m<leader>'] = { function() M.open_cfile_in_curbuf_and_stack() end, 'markdown: open_cfile_in_curbuf_and_stack', mode = { 'n', 'v', }, silent = true, },
  ['<leader>mh'] = { function() M.pop_from_stack_and_go_back_last_buffer() end, 'markdown: pop_from_stack_and_go_back_last_buffer', mode = { 'n', 'v', }, silent = true, },
  ['<leader>ms'] = { function() M.open_cfile_in_system() end, 'markdown: open_cfile_in_system', mode = { 'n', 'v', }, silent = true, },
  ['<leader>mcu'] = { function() M.copy_cfile_url_to_clip() end, 'markdown.copy: copy_cfile_url_to_clip', mode = { 'n', 'v', }, silent = true, },
  ['<leader>mci'] = { function() M.copy_cfile_itself_to_clip() end, 'markdown.copy: copy_cfile_itself_to_clip', mode = { 'n', 'v', }, silent = true, },
}

require 'which-key'.register {
  ['<leader>mcf'] = { function() M.create_file_from_target() end, 'markdown.create: file from target: 1. zoom,inner,problem', mode = { 'n', 'v', }, silent = true, },
}

require 'which-key'.register {
  ['<leader>mp'] = { name = 'markdown.preview', },
  ['<leader>mpp'] = { '<cmd>MarkdownPreview<cr>', 'markdown.preview: preview', mode = { 'n', 'v', }, silent = true, },
  ['<leader>mps'] = { '<cmd>MarkdownPreviewStop<cr>', 'markdown.preview: stop', mode = { 'n', 'v', }, silent = true, },
  ['<leader>mp<leader>'] = { '<cmd>MarkdownPreviewToggle<cr>', 'markdown.preview: toggle', mode = { 'n', 'v', }, silent = true, },
}

require 'which-key'.register {
  ['<leader>mr'] = { name = 'markdown.run', },
  ['<leader>mrc'] = { function() M.run_in_cmd() end, 'markdown.run: run current line as cmd command', mode = { 'n', 'v', }, silent = true, },
  ['<leader>mrs'] = { function() M.run_in_cmd 'silent' end, 'markdown.run: run current line as cmd command silent', mode = { 'n', 'v', }, silent = true, },
}

require 'which-key'.register {
  ['<leader>mu'] = { name = 'markdown.url', },
  ['<leader>muu'] = { function() M.make_url() end, 'markdown.url: make relative url from clipboard', mode = { 'n', 'v', }, silent = true, },
  ['<leader>mus'] = { function() M.make_url_sel() end, 'markdown.url: make relative url from sel markdown file', mode = { 'n', 'v', }, silent = true, },
}

return M
