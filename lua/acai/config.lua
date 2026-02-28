local M = {}

local defaults = {
  provider = "openrouter",
  providers = {
    openrouter = {
      api_key_env = "OPENROUTER_API_KEY",
      api_base = "https://openrouter.ai/api/v1",
      model = "anthropic/claude-sonnet-4",
      max_tokens = 256,
      temperature = 0.0,
    },
    openai = {
      api_key_env = "OPENAI_API_KEY",
      api_base = "https://api.openai.com/v1",
      model = "gpt-4o-mini",
      max_tokens = 256,
      temperature = 0.0,
    },
    anthropic = {
      api_key_env = "ANTHROPIC_API_KEY",
      api_base = "https://api.anthropic.com/v1",
      model = "claude-sonnet-4-20250514",
      max_tokens = 256,
      temperature = 0.0,
    },
  },
  completion = {
    debounce_ms = 200,
    max_context_chars = 4096,
    auto_trigger = true,
    filetypes_exclude = {},
  },
  ghost_text = {
    hl_group = "AcaiGhostText",
  },
  keymaps = {
    accept = "<Tab>",
    accept_word = "<M-Right>",
    accept_line = "<C-e>",
    dismiss = "<C-]>",
    suggest = "<M-Bslash>",
  },
}

---@type table
local current = vim.deepcopy(defaults)

function M.merge(user_opts)
  current = vim.tbl_deep_extend("force", vim.deepcopy(defaults), user_opts or {})
end

function M.get()
  return current
end

return M
