local M = {}

local B = require 'dp_base'

M.source = B.getsource(debug.getinfo(1)['source'])
M.lua = B.getlua(M.source)

M.file_stack = {}

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
      require 'dp_nvimtree'.open(cfile)
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

require 'which-key'.register {
  ['<leader>m<leader>'] = { function() M.open_cfile_in_curbuf_and_stack() end, 'markdown.cfile: open_cfile_in_curbuf_and_stack', mode = { 'n', 'v', }, silent = true, },
  ['<leader>mh'] = { function() M.pop_from_stack_and_go_back_last_buffer() end, 'markdown.cfile: pop_from_stack_and_go_back_last_buffer', mode = { 'n', 'v', }, silent = true, },
  ['<leader>ms'] = { function() M.open_cfile_in_system() end, 'markdown.cfile: open_cfile_in_system', mode = { 'n', 'v', }, silent = true, },
  ['<leader>mcu'] = { function() M.copy_cfile_url_to_clip() end, 'markdown.cfile: copy_cfile_url_to_clip', mode = { 'n', 'v', }, silent = true, },
  ['<leader>mci'] = { function() M.copy_cfile_itself_to_clip() end, 'markdown.cfile: copy_cfile_itself_to_clip', mode = { 'n', 'v', }, silent = true, },
}

return M
