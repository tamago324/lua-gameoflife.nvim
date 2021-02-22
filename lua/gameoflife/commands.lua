local a = vim.api
local ui = require'gameoflife.ui'
local conwaylife = require'gameoflife.conwaylife'
local rle = require'gameoflife.rle'
local main = require'gameoflife.main'
local timer = require'gameoflife.timer'
local STATE = require'gameoflife.const'.STATE

local M = {}

-- ランダムの準備
math.randomseed(os.time())

local partial = function(func, ...)
  local vargs = {...}
  return function(...)
    local inner_vargs = {...}
    return func(unpack(vargs), unpack(inner_vargs))
  end
end

M.start = function(load_random)
  ui.setup()
  if load_random then
    M.load_random_board()
  end
end

local init = function(board)
  ctx = {
    board = board,
    size = {
      rows = #board,
      cols = #board[1]
    },
    generation = 1,
    -- 各世代ごとのboardのRLEのテキストを格納
    rle_boards = {}
  }
  main._set_context(ctx)
  timer.reset()

  ui.setup()
  ui.load_board(board)
end

---
---@param url string conwaylife のパターンの url
M.load_pattern = function(url)
  local pattern = conwaylife.get_pattern(url)
  if pattern == nil then return end

  local board = rle.gen_board_from_pattern_text(pattern)
  init(board)
end


local gen_random_board = function(rows, cols)
  -- ウィンドウに表示できるだけの rows x cols のboardを生成する
  local res = {}
  for y = 1, rows do
    local line = {}
    for x = 1, cols do
      -- 0 or 1
      table.insert(line, math.random(2) - 1)
    end
    table.insert(res, line)
  end
  return res
end

M.load_random_board = function()
  local rows = (vim.o.lines - vim.o.cmdheight)
  local cols = vim.o.columns
  local board = gen_random_board(rows, cols)
  init(board)
end


M.next = main._next
M.prev = main._prev

M.timer_start = partial(timer.start, main._next)
M.timer_pause = timer.pause
M.timer_toggle = partial(timer.toggle, main._next)

M.set_step_per_sec = partial(timer.set_step_per_sec, main._next)

M.speed_up = function()
  timer.set_step_per_sec(main._next, timer.get_step_per_sec() + 1)
end

M.speed_down = function()
  local step_per_sec = timer.get_step_per_sec()
  if step_per_sec - 1 == 0 then
    return
  end
  timer.set_step_per_sec(main._next, step_per_sec - 1)
end

return M
