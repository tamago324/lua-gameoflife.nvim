-- RLE (Run Length Encoding)
local a = vim.api

local STATE = require'gameoflife.const'.STATE

-- 最初の行は以下のようになっている
-- x = m, y = n, rule = b3/s23

-- # から始まる行はコメント

-- <run_count><tag> の形式になっている
-- <tag>
--  b : dead
--  o : live (b 以外は o とする)
--  $ : 行の終わり

local M = {}

---
---@param line string RLEでエンコードされたテキスト
---@return string デコードしたテキスト
local decode = function(line)
  local ret = ''
  -- キャプチャしつつ、ループできる
  for len, c in string.gmatch(line, '(%d*)(.)') do
    len = (len == '' and 1) or len
    ret = ret .. string.rep(c, len)
  end
  return ret
end

---
---@param decoded_line string RLEをデコードしたテキスト (b と o のテキスト)
---@param cols number カラム数 (もし、足りなければ、dead で補う)
---@return table board_line baord の行のtable
local convert_board_line = function(decoded_line, cols)
  local res = {}

  local line = decoded_line
  -- もし、桁数が足りなければ、dead で補う
  if #decoded_line ~= cols then
    line = decoded_line .. string.rep('b', cols - #decoded_line)
  end

  -- b: dead, o: live
  for c in string.gmatch(line, '(.)') do
    local state = (c == 'b' and 0) or 1
    table.insert(res, state)
  end
  return res
end

local to_board = function(text)
  local lines = vim.split(text, '\n')

  -- コメントをスキップ
  lines = vim.tbl_filter(function(v)
    return not vim.startswith(v, '#')
  end, lines)

  local x, y = nil, nil
  local rle_text = ''
  for _, line in ipairs(lines) do
    if x == nil then
      -- 最初の行
      x, y = string.match(line, '^x = (%d+), y = (%d+)')
    else
      -- 2行目以降は、行をつなげる
      rle_text = rle_text .. line
    end
  end

  local board = {}
  -- rle_text をデコードする
  -- $ もエンコードされた文字に含める
  --   2$ は $$ になるため
  local decoded = decode(rle_text)
  -- 2bo$ や 2$ や 2o! とかを取得する
  for line in string.gmatch(decoded, '([^$!]*[$!]?)') do
    -- 末尾の $ と ! を削除する
    line = string.sub(line, 1, #line-1)
    table.insert(board, convert_board_line(line, x))
  end

  return board
end

--- dead のセルで囲んだ baord を返す
---  周りは dead として
---@param board table
---@param spaces number 囲むセルの数
---@return table 0で囲んだ board
local wrap_dead_cells = function(board, spaces)
  spaces = spaces or 1

  local new_board = vim.deepcopy(board)
  -- まずは、各行の先頭と末尾に dead を追加
  for y = 1, #board do
    for i = 1, spaces do
      table.insert(new_board[y], 1, STATE.DEAD)
      table.insert(new_board[y], #new_board[y] + 1, STATE.DEAD)
    end
  end

  -- 先頭と末尾に dead の行を追加
  local top_line, bot_line = {}, {}
  for i = 1, #new_board[1] do
    table.insert(top_line, STATE.DEAD)
    table.insert(bot_line, STATE.DEAD)
  end
  for i = 1, spaces do
    table.insert(new_board, 1, vim.deepcopy(top_line))
    table.insert(new_board, #new_board+1, vim.deepcopy(bot_line))
  end
  return new_board
end

-- -- リストの比較
-- local equals
-- equals = function(t1, t2)
--   for i = 1, #t1 do
--     -- テーブルなら、長さを確認
--     if type(t1[i]) == 'table' and type(t2[i]) == 'table' then
--       if #t1[i] ~= #t2[i] then
--         return false
--       end
--     end
--
--     if type(t1[i]) == 'table' and type(t2[i]) == 'table' then
--       -- テーブルの要素のチェック
--       return equals(t1[i], t2[i])
--     end
--     -- 要素の1つ1つを確認
--     if t1[i] ~= t2[i] then
--       return false
--     end
--   end
--   return true
-- end

-- assert(equals(wrap_dead_cells({{1}}), {{0, 0, 0}, {0, 1, 0}, {0, 0, 0}}), 'failed')

---
---@param pattern_text string conwaylife のパターンのテキスト
---@param margin number 周りの dead のセル
---@return table board
M.gen_board_from_pattern_text = function(pattern_text, margin)
  margin = margin or 15
  return wrap_dead_cells(to_board(pattern_text), margin)
end


return M
