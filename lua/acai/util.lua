local M = {}

---Create a debounced function that delays invoking `fn` until after `ms` milliseconds
---have elapsed since the last time the debounced function was invoked.
---@param fn function
---@param ms number
---@return function debounced, function cancel, function close
function M.debounce(fn, ms)
  local timer = vim.uv.new_timer()
  local function debounced(...)
    local args = { ... }
    timer:stop()
    timer:start(ms, 0, function()
      timer:stop()
      vim.schedule(function()
        fn(unpack(args))
      end)
    end)
  end
  local function cancel()
    timer:stop()
  end
  local function close()
    timer:stop()
    if not timer:is_closing() then
      timer:close()
    end
  end
  return debounced, cancel, close
end

---Trim leading/trailing whitespace.
---@param s string
---@return string
function M.trim(s)
  return s:match("^%s*(.-)%s*$")
end

return M
