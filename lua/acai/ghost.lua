local M = {}

local ns = vim.api.nvim_create_namespace("acai_ghost")
local current_suggestion = nil
local current_extmark_id = nil

---Show ghost text at the current cursor position.
---@param text string The suggestion text (may be multi-line)
function M.show(text)
  M.clear()

  if not text or text == "" then
    return
  end

  local buf = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1 -- 0-indexed
  local col = cursor[2]

  local config = require("acai.config").get()
  local hl = config.ghost_text.hl_group

  local lines = vim.split(text, "\n", { plain = true })

  -- First line: inline virtual text at cursor position
  local virt_text = { { lines[1], hl } }
  local opts = {
    virt_text = virt_text,
    virt_text_pos = "inline",
    hl_mode = "combine",
  }

  -- Remaining lines: virtual lines below
  if #lines > 1 then
    local virt_lines = {}
    for i = 2, #lines do
      virt_lines[#virt_lines + 1] = { { lines[i], hl } }
    end
    opts.virt_lines = virt_lines
  end

  current_extmark_id = vim.api.nvim_buf_set_extmark(buf, ns, row, col, opts)
  current_suggestion = text
end

---Clear ghost text from the current buffer.
function M.clear()
  if current_extmark_id then
    local buf = vim.api.nvim_get_current_buf()
    pcall(vim.api.nvim_buf_del_extmark, buf, ns, current_extmark_id)
    current_extmark_id = nil
  end
  current_suggestion = nil
end

---Check if ghost text is currently visible.
---@return boolean
function M.is_visible()
  return current_suggestion ~= nil
end

---Get the current suggestion text.
---@return string|nil
function M.get_suggestion()
  return current_suggestion
end

---Get the first word of the current suggestion.
---@return string|nil
function M.get_first_word()
  if not current_suggestion then
    return nil
  end
  return current_suggestion:match("^(%S+)")
end

---Get the first line of the current suggestion.
---@return string|nil
function M.get_first_line()
  if not current_suggestion then
    return nil
  end
  return current_suggestion:match("^([^\n]*)")
end

return M
