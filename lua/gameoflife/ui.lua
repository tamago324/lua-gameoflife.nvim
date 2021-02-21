local a = vim.api
local STATE = require'gameoflife.const'.STATE

local M = {}

local ns = a.nvim_create_namespace('gameoflife')
--- 各行の情報
local lines = {}

local content_bufnr = a.nvim_create_buf(false, true)

M.setup = function()
  local cols = vim.o.columns
  local rows = (vim.o.lines - vim.o.cmdheight)

  local win_opts = {
    relative = 'editor',
    width = cols,
    height = rows,
    focusable = true,
    style = 'minimal',
    row = 0,
    col = 0,
  }
  local winnr = a.nvim_open_win(content_bufnr, true, win_opts)
  a.nvim_win_set_option(winnr, "winhl", "Normal:Normal")
  a.nvim_buf_set_option(content_bufnr, 'filetype', 'gameoflife')

  -- vim.cmd([[augroup GameOfLifeQuit]])
  -- vim.cmd([[  autocmd!]])
  -- vim.cmd([[  autocmd WinClosed,BufDelete <buffer=%d> ++nested ++once lua require'gameoflife.timer'.reset()]]):format(content_bufnr)
  -- vim.cmd([[augroup END]])
end


--- board を読み込む
---@param board table
M.load_board = function(board)
  local content_lines = {}
  for i = 1, #board do
    table.insert(content_lines, '')
  end
  a.nvim_buf_set_lines(content_bufnr, 0, -1, false, content_lines)
  M.redraw(board)
end

--- 行のリストを virtual text の形式に変える
---@param cells table ボードの1行
---@return table virt_text virtual text に使えるテーブル
local to_virt_text = function(cells)
  local res = {}
  for _, cell in ipairs(cells) do
    if cell == STATE.LIVE then
      table.insert(res, {"  ", "GameOfLifeCell"})
    else
      table.insert(res, {"  "})
    end
  end
  return res
end

M.redraw = function(board)
  for lnum = 1, #board do
    local virt_text = to_virt_text(board[lnum])
    local line = lines[lnum] or {}
    local id = a.nvim_buf_set_extmark(content_bufnr, ns, lnum - 1, 0, {
      virt_text = virt_text,
      id = (line.id or nil)
    })
    lines[lnum] = { id = id }
  end
end


return M
