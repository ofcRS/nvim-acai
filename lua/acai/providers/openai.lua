local M = {}

local shared = require("acai.providers")

---Build an OpenAI-compatible chat completions request.
---@param ctx table {prefix, suffix, filetype, filename}
---@param cfg table {api_key_env, api_base, model, max_tokens, temperature}
---@return table {url, headers, body}
function M.build_request(ctx, cfg)
  local api_key = shared.get_api_key(cfg)

  local body = vim.json.encode({
    model = cfg.model,
    max_tokens = cfg.max_tokens,
    temperature = cfg.temperature,
    messages = {
      { role = "system", content = shared.SYSTEM_PROMPT },
      { role = "user", content = shared.build_user_content(ctx) },
    },
  })

  return {
    url = cfg.api_base .. "/chat/completions",
    headers = {
      ["Content-Type"] = "application/json",
      ["Authorization"] = "Bearer " .. api_key,
    },
    body = body,
  }
end

---Parse an OpenAI-compatible chat completions response.
---@param raw string JSON response
---@return string|nil completion text
function M.parse_response(raw)
  local ok, data = pcall(vim.json.decode, raw)
  if not ok or not data then
    return nil
  end

  if data.error then
    shared.notify_api_error(data.error)
    return nil
  end

  local choices = data.choices
  if not choices or #choices == 0 then
    return nil
  end

  local text = choices[1].message and choices[1].message.content
  if not text then
    return nil
  end

  return shared.clean_response(text)
end

return M
