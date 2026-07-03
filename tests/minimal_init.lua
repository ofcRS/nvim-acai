-- Minimal init for the test harness. Loaded via `nvim -u tests/minimal_init.lua`.
vim.opt.swapfile = false
vim.opt.shadafile = "NONE"

local this = debug.getinfo(1, "S").source:sub(2)
local root = vim.fn.fnamemodify(this, ":p:h:h")
vim.opt.runtimepath:prepend(root)
