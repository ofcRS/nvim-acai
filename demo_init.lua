-- Clean, reproducible environment for recording the nvim-acai demo GIF.
-- Loads ONLY acai (no copilot, no blink popup) so the ghost text is the only
-- thing on screen. Run from the repo root:
--
--     nvim -u demo_init.lua demo.ts
--
vim.cmd("syntax on")
vim.opt.termguicolors = true
vim.opt.number = false
vim.opt.relativenumber = false
vim.opt.signcolumn = "no"
vim.opt.laststatus = 0
vim.opt.showmode = false
vim.opt.ruler = false
vim.opt.fillchars = { eob = " " }
vim.opt.scrolloff = 4
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.expandtab = true
vim.opt.swapfile = false -- VHS kills nvim without :q; no swap = no "recover?" prompt
vim.opt.autoindent = false
vim.opt.smartindent = false

-- Keep every newly-typed line at column 0 and stop comment auto-continuation,
-- so the scripted beats can't cascade-indent or smear a `//` onto code.
-- Scheduled so it wins against the filetype plugin / treesitter indentexpr.
vim.api.nvim_create_autocmd("FileType", {
  callback = function()
    vim.schedule(function()
      pcall(function()
        vim.opt_local.formatoptions:remove({ "r", "o" })
        vim.opt_local.autoindent = false
        vim.opt_local.smartindent = false
        vim.opt_local.cindent = false
        vim.opt_local.indentexpr = ""
      end)
    end)
  end,
})

-- Reuse your installed tokyonight theme if present; fall back to a dark builtin.
local tn = vim.fn.stdpath("data") .. "/lazy/tokyonight.nvim"
if vim.fn.isdirectory(tn) == 1 then
  vim.opt.rtp:prepend(tn)
  pcall(vim.cmd.colorscheme, "tokyonight-night")
else
  pcall(vim.cmd.colorscheme, "habamax")
end

-- Rich TS highlighting via treesitter if your parser is installed.
local treesitter = vim.fn.stdpath("data") .. "/lazy/nvim-treesitter"
if vim.fn.isdirectory(treesitter) == 1 then
  vim.opt.rtp:prepend(treesitter)
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "typescript",
    callback = function(ev) pcall(vim.treesitter.start, ev.buf, "typescript") end,
  })
end

-- Load acai from the working tree + the OpenRouter key from .env.
local repo = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h")
vim.opt.rtp:prepend(repo)
local env = io.open(repo .. "/.env", "r")
if env then
  for line in env:lines() do
    local k, v = line:match("^%s*([%w_]+)%s*=%s*(.-)%s*$")
    if k then vim.env[k] = (v:gsub('^"(.*)"$', "%1"):gsub("^'(.*)'$", "%1")) end
  end
  env:close()
end

require("acai").setup({
  provider = "openrouter",
  providers = { openrouter = { model = "openai/gpt-4.1-mini" } },
  keymaps = { accept = "<C-l>", dismiss = "<C-]>", accept_word = false, accept_line = false, suggest = "<M-Bslash>" },
})
