local M = {}

local SYSTEM_PROMPT = [[You are a code completion engine. You are given the current file context with a cursor position marked by <CURSOR>.
Output ONLY the code that should be inserted at the cursor position.
Rules:
- Do NOT include any explanation, comments about the completion, or markdown formatting
- Do NOT repeat code that already exists before or after the cursor
- Output ONLY the raw code to insert
- If no completion is appropriate, output nothing]]

---Build an Anthropic Messages API request.
---@param ctx table {prefix, suffix, filetype, filename}
---@param cfg table {api_key_env, api_base, model, max_tokens, temperature}
---@return table {url, headers, body}
function M.build_request(ctx, cfg)
  local api_key = os.getenv(cfg.api_key_env)
  if not api_key or api_key == "" then
    error("[acai] " .. cfg.api_key_env .. " is not set")
  end

  local user_content = string.format(
    "File: %s (filetype: %s)\n\n%s<CURSOR>%s",
    ctx.filename or "untitled",
    ctx.filetype or "text",
    ctx.prefix,
    ctx.suffix
  )

  local body = vim.json.encode({
    model = cfg.model,
    max_tokens = cfg.max_tokens,
    temperature = cfg.temperature,
    system = SYSTEM_PROMPT,
    messages = {
      { role = "user", content = user_content },
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
  local ok, data = pcall(vim.json.decode, raw)
  if not ok or not data then
    return nil
  end

  if data.error then
    vim.schedule(function()
      vim.notify("[acai] API error: " .. (data.error.message or vim.inspect(data.error)), vim.log.levels.WARN)
    end)
    return nil
  end

  local content = data.content
  if not content or #content == 0 then
    return nil
  end

  local text = nil
  for _, block in ipairs(content) do
    if block.type == "text" then
      text = block.text
      break
    end
  end

  if not text then
    return nil
  end

  -- Reuse the same cleaning logic from openai provider
  return require("acai.providers.openai").clean_response(text)
end

return M
