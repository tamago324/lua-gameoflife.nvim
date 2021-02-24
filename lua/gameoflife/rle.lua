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
  local ret = {}
  -- キャプチャしつつ、ループできる
  for len, c in string.gmatch(line, '(%d*)(.)') do
    len = (len == '' and 1) or len
    table.insert(ret, string.rep(c, len))
  end
  return table.concat(res)
end

---
---@param decoded_line string RLEをデコードしたテキスト (b と o のテキスト)
---@param cols number カラム数 (もし、足りなければ、dead で補う)
---@return table board_line baord の行のtable
local convert_board_line = function(decoded_line, cols)
  local res = {}
  cols = cols or #decoded_line

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

--- RLE のテキストから、boardを生成
---@param rle_text string
---@return table
local rle2board = function(rle_text, x)
  local board = {}
  -- rle_text をデコードする
  -- $ もエンコードされた文字に含める
  --   2$ は $$ になるため
  local decoded = decode(rle_text)
  -- 2bo$ や 2$ や 2o! とかを取得する
  for line in string.gmatch(decoded, '([^$!]*[$!])') do
    -- 末尾の $ と ! を削除する
    line = string.sub(line, 1, #line-1)
    table.insert(board, convert_board_line(line, x))
  end

  return board
end

--- RLEのパターンから、boardを生成
---@param text string
---@return table
local pattern2board = function(text)
  local lines = vim.split(text, '\n')

  -- コメントをスキップ
  lines = vim.tbl_filter(function(v)
    return not vim.startswith(v, '#')
  end, lines)

  local x, y = nil, nil
  local rle_text_tbl = {}
  for _, line in ipairs(lines) do
    if x == nil then
      -- 最初の行
      x, y = string.match(line, '^x = (%d+), y = (%d+)')
    else
      -- 2行目以降は、行をつなげる
      table.insert(rle_text_tbl, line)
    end
  end
  return rle2board(table.concat(rle_text_tbl), x)
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
  return wrap_dead_cells(pattern2board(pattern_text), margin)
end

M.gen_board_from_rle_text = function(rle_text)
  return rle2board(rle_text)
end


---
---@param board table
---@return string rle_encoded_text
M.encode = function(board)
  -- まずは 0 と 1 のtableを bo$! のいずれかの文字列にする
  local list = {}
  for row = 1, #board do
    for col = 1, #board[row] do
      local c = (board[row][col] == 0 and 'b') or 'o'
      table.insert(list, c)
    end
    table.insert(list, '$')
  end
  -- 最後の $ を取り除く
  table.remove(list, #list)
  table.insert(list, '!')

  local result = {}
  local save_c = ''
  local cnt = 0

  for _, c in ipairs(list) do
    if save_c == c then
      cnt = cnt + 1
    else
      if save_c ~= '' then
        if cnt ~= 1 then
          table.insert(result, tostring(cnt))
        end
        table.insert(result, save_c)
      end
      -- リセット
      cnt = 1
    end
    save_c = c
  end

  -- 最後は、必ず '!' だから、これでOK
  table.insert(result, save_c)
  return table.concat(result)
end


return M
