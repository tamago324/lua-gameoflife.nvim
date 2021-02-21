local a = vim.api
local curl = require'plenary.curl'

-- https://www.conwaylife.com/wiki/Category:Patterns

-- 以下の形式に対応
--   https://www.conwaylife.com/patterns/hogehoge.rle

--- TODO: どうにかして、一覧化とかできないのかな

local M = {}

---
---@param url string
---@return string|nil pattern_text パターンのテキスト
M.get_pattern = function(url)
  local res = curl.get(url)
  if res.status ~= 200 then
    a.nvim_echo({{string.format('Could not get pattern from %s', url), 'ErrorMsg'}}, true, {})
    return nil
  end

  return res.body
end


return M
