local a = vim.api

local ui = require'gameoflife.ui'
local STATE = require'gameoflife.const'.STATE
local rle = require'gameoflife.rle'

local M = {}

local _ctx = {}

local MAX_GENERATION = 100

local is_live = function(row, col)
  if row == 0 or row > _ctx.size.rows or
      col == 0 or col > _ctx.size.cols then
    -- 範囲外なら、dead ってことにする
    return STATE.DEAD
  end

  return _ctx.board[row][col]
end

---次の状態を求めて、返す
---@param row number
---@param col number
local next_state = function(row, col)
  local live_cnt = 0
  -- 周りを確認する
  live_cnt = live_cnt + is_live(row-1, col-1)
  live_cnt = live_cnt + is_live(row-1, col)
  live_cnt = live_cnt + is_live(row-1, col+1)
  live_cnt = live_cnt + is_live(row,   col-1)
  live_cnt = live_cnt + is_live(row,   col+1)
  live_cnt = live_cnt + is_live(row+1, col-1)
  live_cnt = live_cnt + is_live(row+1, col)
  live_cnt = live_cnt + is_live(row+1, col+1)

  if _ctx.board[row][col] == STATE.DEAD then
    -- dead
    if live_cnt == 3 then
      -- 誕生
      return STATE.LIVE
    end
  else
    if live_cnt == 2 or live_cnt == 3 then
      -- 維持
      return STATE.LIVE
    elseif live_cnt < 2 then
      -- 過疎
      return STATE.DEAD
    elseif live_cnt >= 4 then
      -- 過密
      return STATE.DEAD
    end
  end
  return STATE.DEAD
end

---次の世代の板を作成する
---@return table
local next_generation = function()
  local res = {}

  for row = 1, #_ctx.board do
    local line = {}
    for col = 1, #_ctx.board[row] do
      table.insert(line, next_state(row, col))
    end
    table.insert(res, line)
  end

  return res
end

--- ゲームが終わったか？
---@param use_limit boolean 世代の上限を使うか？
---@return boolean
local is_end_game = function(use_limit)
  use_limit = vim.F.if_nil(use_limit, true)
  if use_limit then
    if _ctx.generation > MAX_GENERATION then
      return true
    end
  end

  -- 生きているセルがなくなれば、終わり
  for row = 1, #_ctx.board do
    for col = 1, #_ctx.board[row] do
      if _ctx.board[row][col] == STATE.LIVE then
        return false
      end
    end
  end

  return true
end

M._set_context = function(context)
  _ctx = context
end

M._get_context = function()
  return _ctx
end

M._next = function()
  if is_end_game(false) then
    vim.api.nvim_echo({{'Finished', 'WarningMsg'}}, false, {})
    M.timer_stop()
    return
  end

  -- RLE 形式に変換
  _ctx.rle_boards[_ctx.generation] = rle.encode(_ctx.board)
  _ctx.board = next_generation()
  _ctx.generation = _ctx.generation + 1
  ui.redraw(_ctx.board)
  a.nvim_echo({{_ctx.generation .. '世代目', 'Normal'}}, false, {})
end

M._prev = function()
  if _ctx.generation == 1 then
    return
  end
  _ctx.generation = _ctx.generation - 1
  _ctx.board = rle.gen_board_from_rle_text(_ctx.rle_boards[_ctx.generation])
  ui.redraw(_ctx.board)
  a.nvim_echo({{_ctx.generation .. '世代目', 'Normal'}}, false, {})
end


return M
