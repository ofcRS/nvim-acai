local M = {}

local providers = {}

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
