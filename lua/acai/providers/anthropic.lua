local M = {}

local shared = require("acai.providers")

---Build an Anthropic Messages API request.
---@param ctx table {prefix, suffix, filetype, filename}
---@param cfg table {api_key_env, api_base, model, max_tokens, temperature}
---@return table {url, headers, body}
function M.build_request(ctx, cfg)
  local api_key = shared.get_api_key(cfg)

  local body = vim.json.encode({
    model = cfg.model,
    max_tokens = cfg.max_tokens,
    temperature = cfg.temperature,
    system = shared.SYSTEM_PROMPT,
    messages = {
      { role = "user", content = shared.build_user_content(ctx) },
    },
  })

  return {
    url = cfg.api_base .. "/messages",
    headers = {
      ["Content-Type"] = "application/json",
      ["x-api-key"] = api_key,
      ["anthropic-version"] = "2023-06-01",
    },
    body = body,
  }
end

---Parse an Anthropic Messages API response.
---@param raw string JSON response
---@return string|nil completion text
function M.parse_response(raw)
  return shared.parse_response(raw, function(data)
    local content = data.content
    if not content or #content == 0 then
      return nil
    end
    for _, block in ipairs(content) do
      if block.type == "text" then
        return block.text
      end
    end
    return nil
  end)
end

return M
