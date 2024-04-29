-- Copyright (c) 2024 liudepei. All Rights Reserved.
-- create at 2024/04/29 22:59:21 星期一

local M = {}

local B = require 'dp_base'

M.source = B.getsource(debug.getinfo(1)['source'])
M.lua = B.getlua(M.source)

M.image_root_dir_name = '.images'
M.image_root_dir_md_name = '_.md'
-- M.image_paste_temp_name = 'nvim_paste_temp'

M.last_file = ''
M.last_lnr = 1

M.MARKDOWN_EXTS = {
  'md',
}

M.IMAGE_EXTS = {
  'jpg', 'png',
}

function M.is_in_markdown_fts(file)
  return B.is_file_in_extensions(file, M.MARKDOWN_EXTS)
end

function M.is_in_image_fts(file)
  return B.is_file_in_extensions(file, M.IMAGE_EXTS)
end

function M.paste_image(image_file, markdown_file, lnr)
  local proj_root = vim.fn['ProjectRootGet'](markdown_file)
  if not B.is(proj_root) then
    B.notify_info('not in a project root: ' .. markdown_file)
    return
  end
  local image_root_dir = B.getcreate_dirpath { proj_root, M.image_root_dir_name, }.filename
  local image_root_dir_md_path = B.getcreate_filepath(image_root_dir, M.image_root_dir_md_name)
  local image_hash_64 = B.get_hash(image_file)
  local image_hash_8 = string.sub(image_hash_64, 1, 8)
  local image_fname_tail = vim.fn.fnamemodify(image_file, ':t')
  local image_fname_tail_root = vim.fn.fnamemodify(image_fname_tail, ':r')
  -- if image_fname_tail_root == M.image_paste_temp_name then
  --   image_fname_tail_root = vim.fn.strftime '%Y%m%d-%A-%H%M%S'
  -- end
  local image_fname_tail_ext = vim.fn.fnamemodify(image_fname_tail, ':e')
  local image_hash_name = image_hash_8 .. '.' .. image_fname_tail_ext
  local image_target_file = B.getcreate_filepath(image_root_dir, image_hash_name).filename
  vim.fn.system(string.format('copy /y "%s" "%s"', image_file, image_target_file))
  local image_root_dir_md_url = string.format('![%s](%s)\n', image_fname_tail_root, image_hash_name)
  image_root_dir_md_path:write(image_root_dir_md_url, 'a')
  local relative = vim.fn['repeat']('../', B.count_char(B.rep_slash(string.sub(markdown_file, #proj_root + 2, #markdown_file)), '\\'))
  local image_root_dir_md_url_relative = string.format('![%s](%s%s/%s)', image_fname_tail_root, relative, M.image_root_dir_name, image_hash_name)
  B.cmd('e %s', markdown_file)
  vim.fn.append(lnr, image_root_dir_md_url_relative)
  vim.cmd 'norm j'
end

B.aucmd('BufEnter', 'markdown.image.paste.BufEnter', {
  callback = function(ev)
    if B.file_exists(ev.file) then
      M.last_file = ev.file
    end
  end,
})

B.aucmd('CursorHold', 'markdown.image.paste.CursorHold', {
  callback = function(ev)
    if B.file_exists(ev.file) then
      M.last_lnr = vim.fn.line '.'
    end
  end,
})

B.aucmd('FocusLost', 'markdown.image.paste.FocusLost', {
  callback = function()
    M._dragging = 1
  end,
})

B.aucmd('FocusGained', 'markdown.image.paste.FocusGained', {
  callback = function()
    B.set_timeout(500, function()
      M._dragging = nil
    end)
  end,
})

B.aucmd('BufReadPost', 'markdown.image.paste.BufReadPost', {
  callback = function(ev)
    M._cur_file = B.buf_get_name(ev.buf)
    if M.is_in_markdown_fts(M.last_file) and M._dragging then
      if M.is_in_image_fts(M._cur_file) then
        M.paste_image(M._cur_file, M.last_file, M.last_lnr)
        return
      end
    end
  end,
})

return M
