local M = {}

local config = require("acai.config")
local ghost = require("acai.ghost")
local trigger = require("acai.trigger")
local completion = require("acai.completion")

local enabled = false

---Accept the full suggestion: insert ghost text at cursor.
function M.accept()
  local text = ghost.get_suggestion()
  if not text then
    return false
  end

  ghost.clear()
  completion.cancel()

  local lines = vim.split(text, "\n", { plain = true })
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1
  local col = cursor[2]

  -- Get current line to split around cursor
  local current_line = vim.api.nvim_get_current_line()
  local before = current_line:sub(1, col)
  local after = current_line:sub(col + 1)

  -- Build the new lines
  local new_lines = {}
  if #lines == 1 then
    new_lines[1] = before .. lines[1] .. after
  else
    new_lines[1] = before .. lines[1]
    for i = 2, #lines - 1 do
      new_lines[#new_lines + 1] = lines[i]
    end
    new_lines[#new_lines + 1] = lines[#lines] .. after
  end

  vim.api.nvim_buf_set_lines(0, row, row + 1, false, new_lines)

  -- Place cursor at end of inserted text
  local new_row = row + #lines
  local new_col = #lines[#lines]
  if #lines == 1 then
    new_col = col + #lines[1]
  end
  vim.api.nvim_win_set_cursor(0, { new_row, new_col })

  return true
end

---Insert a partial suggestion (first word or first line) at the cursor.
---@param get_text_fn function Returns the text to insert, or nil if nothing to accept
---@return boolean
local function accept_partial(get_text_fn)
  local text = get_text_fn()
  if not text then
    return false
  end

  ghost.clear()
  completion.cancel()

  local col = vim.api.nvim_win_get_cursor(0)[2]
  local line = vim.api.nvim_get_current_line()
  vim.api.nvim_set_current_line(line:sub(1, col) .. text .. line:sub(col + 1))
  vim.api.nvim_win_set_cursor(0, { vim.api.nvim_win_get_cursor(0)[1], col + #text })

  return true
end

---Accept only the first word of the suggestion.
function M.accept_word()
  return accept_partial(ghost.get_first_word)
end

---Accept only the first line of the suggestion.
function M.accept_line()
  return accept_partial(ghost.get_first_line)
end

---Dismiss the current suggestion.
function M.dismiss()
  ghost.clear()
  completion.cancel()
end

---Manually trigger a suggestion.
function M.suggest()
  ghost.clear()
  completion.request()
end

---Enable completions.
function M.enable()
  if enabled then
    return
  end
  enabled = true
  trigger.attach()
  vim.notify("[acai] enabled", vim.log.levels.INFO)
end

---Disable completions.
function M.disable()
  if not enabled then
    return
  end
  enabled = false
  trigger.detach()
  vim.notify("[acai] disabled", vim.log.levels.INFO)
end

---Toggle completions.
function M.toggle()
  if enabled then
    M.disable()
  else
    M.enable()
  end
end

---Print current status.
function M.status()
  local cfg = config.get()
  local provider_name = cfg.provider
  local provider_cfg = cfg.providers[provider_name]
  local model = provider_cfg and provider_cfg.model or "unknown"
  local api_key_env = provider_cfg and provider_cfg.api_key_env or "unknown"
  local has_key = os.getenv(api_key_env) ~= nil

  vim.notify(
    string.format(
      "[acai] %s | provider: %s | model: %s | key (%s): %s",
      enabled and "enabled" or "disabled",
      provider_name,
      model,
      api_key_env,
      has_key and "set" or "NOT SET"
    ),
    vim.log.levels.INFO
  )
end

---Setup keymaps for insert mode.
local function setup_keymaps()
  local km = config.get().keymaps

  -- Accept: Tab (unique expr + fallthrough behavior)
  if km.accept then
    vim.keymap.set("i", km.accept, function()
      if ghost.is_visible() then
        M.accept()
        return ""
      end
      return vim.api.nvim_replace_termcodes(km.accept, true, false, true)
    end, { expr = true, silent = true, desc = "Acai: accept suggestion" })
  end

  -- Suggest: no visibility guard
  if km.suggest then
    vim.keymap.set("i", km.suggest, function()
      M.suggest()
    end, { silent = true, desc = "Acai: trigger suggestion" })
  end

  -- Visibility-gated keymaps
  local gated = {
    { key = "accept_word", action = M.accept_word, desc = "accept word" },
    { key = "accept_line", action = M.accept_line, desc = "accept line" },
    { key = "dismiss",     action = M.dismiss,     desc = "dismiss suggestion" },
  }
  for _, entry in ipairs(gated) do
    if km[entry.key] then
      local action = entry.action
      vim.keymap.set("i", km[entry.key], function()
        if ghost.is_visible() then
          action()
        end
      end, { silent = true, desc = "Acai: " .. entry.desc })
    end
  end
end

---Initialize the plugin.
---@param opts table|nil User config overrides
function M.setup(opts)
  config.merge(opts)
  setup_keymaps()
  M.enable()
end

return M
