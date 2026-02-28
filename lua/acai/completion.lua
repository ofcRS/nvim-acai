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
    pcall(vim.fn.jobstop, current_job)
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

  current_job = http.post(req.url, req.headers, req.body, function(err, response)
    current_job = nil

    -- Stale request — ignore
    if my_request_id ~= request_id then
      return
    end

    if err then
      vim.notify("[acai] " .. err, vim.log.levels.WARN)
      return
    end

    local text = provider.parse_response(response)
    if text and text ~= "" then
      -- Only show if still in insert mode
      if vim.fn.mode() == "i" then
        ghost.show(text)
      end
    end
  end)
end

return M
