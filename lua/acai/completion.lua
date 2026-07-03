local M = {}

local context = require("acai.context")
local ghost = require("acai.ghost")
local http = require("acai.http")
local providers = require("acai.providers")

local request_id = 0
local current_job = nil

---Cancel any in-flight completion request.
function M.cancel()
  request_id = request_id + 1
  if current_job then
    http.cancel(current_job)
    current_job = nil
  end
end

---Request a new completion. Cancels any pending request first.
function M.request()
  M.cancel()

  local ctx = context.get()
  if not ctx then
    return
  end

  -- Skip if prefix is empty (no text typed yet on this line and no context)
  if ctx.prefix == "" and ctx.suffix == "" then
    return
  end

  local provider, provider_cfg = providers.resolve()

  local ok, req = pcall(provider.build_request, ctx, provider_cfg)
  if not ok then
    vim.notify(tostring(req), vim.log.levels.WARN)
    return
  end

  local my_request_id = request_id

  -- Snapshot the context the completion is computed for, so a response
  -- that arrives after the user typed or moved can be discarded.
  local buf = vim.api.nvim_get_current_buf()
  local tick = vim.api.nvim_buf_get_changedtick(buf)
  local cursor = vim.api.nvim_win_get_cursor(0)

  current_job = http.post(req.url, req.headers, req.body, function(err, response)
    -- Stale request — ignore. Checked first so a late callback from a
    -- cancelled job doesn't clobber the handle of the job that replaced it.
    if my_request_id ~= request_id then
      return
    end
    current_job = nil

    if err then
      vim.notify("[acai] " .. err, vim.log.levels.WARN)
      return
    end

    local text = provider.parse_response(response)
    if not text or text == "" then
      return
    end

    -- Only show if the editing context is unchanged since the request:
    -- still in insert mode, same buffer, no edits, cursor in place.
    local pos = vim.api.nvim_win_get_cursor(0)
    if
      vim.fn.mode() == "i"
      and vim.api.nvim_get_current_buf() == buf
      and vim.api.nvim_buf_get_changedtick(buf) == tick
      and pos[1] == cursor[1]
      and pos[2] == cursor[2]
    then
      ghost.show(text)
    end
  end)
end

return M
