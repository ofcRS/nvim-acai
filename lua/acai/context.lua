local M = {}

---Extract buffer context around cursor for completion.
---@return table|nil context {prefix, suffix, filetype, filename, cursor_line, cursor_col}
function M.get()
  local buf = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()
  local cursor = vim.api.nvim_win_get_cursor(win)
  local row = cursor[1] -- 1-indexed
  local col = cursor[2] -- 0-indexed byte offset

  local config = require("acai.config").get()
  local max_chars = config.completion.max_context_chars

  -- Read only the lines we could plausibly need (conservative: 1 char/line).
  -- This avoids loading the entire buffer for large files.
  local line_count = vim.api.nvim_buf_line_count(buf)
  local half = math.ceil(max_chars / 2)
  local start_idx = math.max(0, row - 1 - half) -- 0-indexed
  local end_idx = math.min(line_count, row + half) -- 0-indexed exclusive
  local lines = vim.api.nvim_buf_get_lines(buf, start_idx, end_idx, false)

  if #lines == 0 then
    return nil
  end

  -- Cursor row relative to the loaded window (1-indexed in Lua array)
  local rel_row = row - start_idx

  -- Build prefix: lines before cursor + current line up to cursor
  local prefix_parts = {}
  local prefix_chars = 0
  local current_line = lines[rel_row] or ""
  local before_cursor = current_line:sub(1, col)

  -- Collect lines before cursor (reverse, to prioritize nearby context)
  local pre_lines = {}
  for i = rel_row - 1, 1, -1 do
    local line = lines[i]
    if prefix_chars + #line + 1 > half then
      break
    end
    pre_lines[#pre_lines + 1] = line
    prefix_chars = prefix_chars + #line + 1
  end
  -- Reverse to restore order
  for i = #pre_lines, 1, -1 do
    prefix_parts[#prefix_parts + 1] = pre_lines[i]
  end
  prefix_parts[#prefix_parts + 1] = before_cursor
  local prefix = table.concat(prefix_parts, "\n")

  -- Build suffix: rest of current line after cursor + lines after
  local suffix_parts = {}
  local suffix_chars = 0
  local after_cursor = current_line:sub(col + 1)
  suffix_parts[#suffix_parts + 1] = after_cursor
  suffix_chars = suffix_chars + #after_cursor

  for i = rel_row + 1, #lines do
    local line = lines[i]
    if suffix_chars + #line + 1 > half then
      break
    end
    suffix_parts[#suffix_parts + 1] = line
    suffix_chars = suffix_chars + #line + 1
  end
  local suffix = table.concat(suffix_parts, "\n")

  return {
    prefix = prefix,
    suffix = suffix,
    filetype = vim.bo[buf].filetype,
    filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t"),
    cursor_line = row,
    cursor_col = col,
  }
end

return M
