local M = {}

---Create a debounced function that delays invoking `fn` until after `ms` milliseconds
---have elapsed since the last time the debounced function was invoked.
---@param fn function
---@param ms number
---@return function debounced, function cancel
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
  return debounced, cancel
end

---Trim leading/trailing whitespace
---@param s string
---@return string
function M.trim(s)
  return s:match("^%s*(.-)%s*$")
end

---Split string by newlines
---@param s string
---@return string[]
function M.split_lines(s)
  local lines = {}
  for line in s:gmatch("([^\n]*)\n?") do
    lines[#lines + 1] = line
  end
  -- Remove trailing empty string from pattern
  if #lines > 0 and lines[#lines] == "" then
    lines[#lines] = nil
  end
  return lines
end

return M
