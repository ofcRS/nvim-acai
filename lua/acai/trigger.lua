local M = {}

local util = require("acai.util")
local ghost = require("acai.ghost")
local completion = require("acai.completion")

local augroup = vim.api.nvim_create_augroup("acai_trigger", { clear = true })
local debounced_request = nil
local cancel_debounce = nil
local close_debounce = nil
local attached = false

---Check if a completion menu (blink.cmp or nvim-cmp) popup is visible.
---@return boolean
local function popup_visible()
  -- blink.cmp
  local blink_ok, blink = pcall(require, "blink.cmp")
  if blink_ok and blink.is_visible and blink.is_visible() then
    return true
  end

  -- nvim-cmp
  local cmp_ok, cmp = pcall(require, "cmp")
  if cmp_ok and cmp.visible and cmp.visible() then
    return true
  end

  return false
end

---Check if current filetype is excluded.
---@return boolean
local function is_excluded()
  local config = require("acai.config").get()
  local ft = vim.bo.filetype
  for _, excluded in ipairs(config.completion.filetypes_exclude) do
    if ft == excluded then
      return true
    end
  end
  return false
end

---Attach autocmds for triggering completions.
function M.attach()
  if attached then
    return
  end
  attached = true

  local config = require("acai.config").get()
  debounced_request, cancel_debounce, close_debounce = util.debounce(function()
    if popup_visible() or is_excluded() then
      return
    end
    completion.request()
  end, config.completion.debounce_ms)

  vim.api.nvim_create_autocmd("TextChangedI", {
    group = augroup,
    callback = function()
      if not require("acai.config").get().completion.auto_trigger then
        return
      end
      -- Clear existing ghost text immediately on new input
      ghost.clear()
      debounced_request()
    end,
  })

  vim.api.nvim_create_autocmd("InsertLeave", {
    group = augroup,
    callback = function()
      if cancel_debounce then
        cancel_debounce()
      end
      completion.cancel()
      ghost.clear()
    end,
  })

  vim.api.nvim_create_autocmd("CursorMovedI", {
    group = augroup,
    callback = function()
      -- Clear ghost text when cursor moves without text change
      -- (e.g., arrow keys). TextChangedI handles the typing case.
      ghost.clear()
    end,
  })
end

---Detach all autocmds and release the debounce timer.
function M.detach()
  if not attached then
    return
  end
  attached = false
  vim.api.nvim_clear_autocmds({ group = augroup })
  if close_debounce then
    close_debounce()
    close_debounce = nil
    cancel_debounce = nil
    debounced_request = nil
  end
  completion.cancel()
  ghost.clear()
end

return M
