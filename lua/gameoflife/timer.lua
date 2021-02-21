local a = vim.api

local M = {}

local _timer = nil
local _timer_on = false
local _save_timer_on = nil

--- 1秒に何ステップすすめるか
local _step_per_sec = 10

--- 再生
M.start = function(cb)
  if _timer == nil then
    _timer = vim.loop.new_timer()
    local interval = 1000 / _step_per_sec
    _timer:start(0, interval, vim.schedule_wrap(cb))
  else
    -- 再開
    _timer:again()
  end
  _timer_on = true
end


--- 一時停止
M.pause = function()
  if _timer then
    _timer:stop()
    _timer_on = false
  end
end

--- 切り替え
M.toggle = function(cb)
  if _timer_on then
    M.pause()
  else
    M.start(cb)
  end
end


--- 停止
M.reset = function()
  if _timer then
    _timer:stop()
    _timer:close()
    _timer = nil
  end
end

M.set_step_per_sec = function(cb, step_per_sec)
  _step_per_sec = step_per_sec
  _timer:set_repeat(1000 / _step_per_sec)
end

M.get_step_per_sec = function()
  return _step_per_sec
end


-- 入ったら、止める
M._onCmdlineEnter = function()
  _save_timer_on = _timer_on
  if _timer and _timer_on then
    M.pause()
  end
end

-- 出たら、開始
M._onCmdlineLeave = function()
  if _timer ~= nil and _save_timer_on then
    M.start()
  end
  _save_timer_on = nil
end

return M
