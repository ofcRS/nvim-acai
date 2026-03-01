local M = {}

local providers = {}

M.SYSTEM_PROMPT = [[You are a code completion engine. You are given the current file context with a cursor position marked by <CURSOR>.
Output ONLY the code that should be inserted at the cursor position.
Rules:
- Do NOT include any explanation, comments about the completion, or markdown formatting
- Do NOT repeat code that already exists before or after the cursor
- Output ONLY the raw code to insert
- If no completion is appropriate, output nothing]]

---Build the user message content shared by all providers.
---@param ctx table {prefix, suffix, filetype, filename}
---@return string
function M.build_user_content(ctx)
  return string.format(
    "File: %s (filetype: %s)\n\n%s<CURSOR>%s",
    ctx.filename or "untitled",
    ctx.filetype or "text",
    ctx.prefix,
    ctx.suffix
  )
end

---Read and validate an API key from the environment.
---Errors if the key is missing or empty.
---@param cfg table {api_key_env: string}
---@return string api_key
function M.get_api_key(cfg)
  local key = os.getenv(cfg.api_key_env)
  if not key or key == "" then
    error("[acai] " .. cfg.api_key_env .. " is not set")
  end
  return key
end

---Schedule a notification for an API error response.
---@param err table {message?: string}
function M.notify_api_error(err)
  vim.schedule(function()
    vim.notify("[acai] API error: " .. (err.message or vim.inspect(err)), vim.log.levels.WARN)
  end)
end

---Strip markdown fences and preamble from an AI response.
---@param text string
---@return string
function M.clean_response(text)
  local util = require("acai.util")
  text = util.trim(text)
  text = text:gsub("^```%w*\n?(.-)\n?```$", "%1")
  text = text:gsub("^[Hh]ere%s+is[^\n]*\n", "")
  text = text:gsub("^[Hh]ere's[^\n]*\n", "")
  return util.trim(text)
end

---Register a provider module.
---@param name string
---@param provider table Must implement build_request(ctx, cfg) and parse_response(raw)
function M.register(name, provider)
  providers[name] = provider
end

---Get a provider by name.
---@param name string
---@return table|nil
function M.get(name)
  -- Lazy-load built-in providers
  if not providers[name] then
    local ok, mod = pcall(require, "acai.providers." .. name)
    if ok then
      providers[name] = mod
    end
  end
  return providers[name]
end

---Resolve the active provider and its config.
---@return table provider, table provider_cfg
function M.resolve()
  local config = require("acai.config").get()
  local name = config.provider

  -- openrouter uses the openai provider (same API format)
  local provider_module = name
  if name == "openrouter" then
    provider_module = "openai"
  end

  local provider = M.get(provider_module)
  if not provider then
    error("[acai] unknown provider: " .. name)
  end

  local provider_cfg = config.providers[name]
  if not provider_cfg then
    error("[acai] no config for provider: " .. name)
  end

  return provider, provider_cfg
end

return M
