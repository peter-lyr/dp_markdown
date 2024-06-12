local M = {}

-- [x] TODODONE: 当移动或重命名文件时,手动更新引用

local B = require 'dp_base'

M.source = B.getsource(debug.getinfo(1)['source'])
M.lua = B.getlua(M.source)

M.update_url_py = B.get_file(B.get_source_dot_dir(M.source), 'update_url.py')

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
  local is_norg_file = require 'dp_markdown.image.paste'.is_in_norg_fts(file)
  local is_cur_norg_file = B.is_file_in_extensions(B.buf_get_name(), { 'norg', })
  if not patt then
    if is_cur_norg_file then
      -- {/ /journal/2024/06/.12/12-inner_8936t-vcmbuf底噪存在电流音/20240612_165714.m4a}
      patt = '{/ /%s}'
    else
      -- `work:journal/2024/06/.12/12-inner_8936t-vcmbuf底噪存在电流音/20240612_165714.m4a`
      patt = '`%s`'
    end
  end
  local rel = B.relpath(file, file_root)
  if B.is(rel) then
    if is_cur_norg_file then
      if is_norg_file then
        -- - {:$/journal/2024/06/12-haitong_13x-switch偶尔复位以及上电音量太小的问题:}[12-haitong_13x-switch偶尔复位以及上电音量太小的问题]
        local r = vim.fn.fnamemodify(rel, ':r')
        vim.fn.append('.', string.format(patt, r .. ':}[' .. vim.fn.fnamemodify(r, ':t')))
      else
        vim.fn.append('.', string.format(patt, rel))
      end
    else
      if is_norg_file then
        -- - {:$/journal/2024/06/12-haitong_13x-switch偶尔复位以及上电音量太小的问题:}[12-haitong_13x-switch偶尔复位以及上电音量太小的问题]
        local r = vim.fn.fnamemodify(rel, ':r')
        vim.fn.append('.', string.format(patt, r .. ':}[' .. vim.fn.fnamemodify(r, ':t')))
      else
        -- 3. `2024s:w/rb/s/202406/240605-haitong_13x-海通游戏手柄切换插拔主机无声问题.md`
        vim.fn.append('.', string.format(patt, file_root_name .. ':' .. rel))
      end
    end
  else
    B.notify_info_append(string.format('not making rel: %s, %s', file, cur_file))
  end
end

function M.make_url_sel()
  local is_cur_norg_file = B.is_file_in_extensions(B.buf_get_name(), { 'norg', })
  local opt = { filetypes = { 'md', }, }
  if is_cur_norg_file then
    opt = {}
  end
  local markdown_files = B.scan_files_deep(vim.loop.cwd(), opt)
  B.ui_sel(markdown_files, 'sel as file to make url', function(file)
    if file and B.file_exists(file) then
      M.make_url(file)
    end
  end)
end

function M.update_url(root)
  if not root then
    root = vim.loop.cwd()
  end
  B.system_run('asyncrun', 'python %s %s', M.update_url_py, root)
end

require 'which-key'.register {
  ['<leader>mu'] = { name = 'markdown.url', },
  ['<leader>muu'] = { function() M.make_url() end, 'markdown.url: make relative url from clipboard', mode = { 'n', 'v', }, silent = true, },
  ['<leader>mus'] = { function() M.make_url_sel() end, 'markdown.url: make relative url from sel markdown file', mode = { 'n', 'v', }, silent = true, },
  ['<leader>mud'] = { function() M.update_url() end, 'markdown.url: update url', mode = { 'n', 'v', }, silent = true, },
}

return M
