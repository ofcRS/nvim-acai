if vim.g.loaded_acai then
  return
end
vim.g.loaded_acai = true

if vim.fn.has("nvim-0.10") ~= 1 then
  vim.notify("[acai] requires Neovim 0.10+", vim.log.levels.ERROR)
  return
end

vim.api.nvim_set_hl(0, "AcaiGhostText", { link = "Comment", default = true })

vim.api.nvim_create_user_command("AcaiEnable", function()
  require("acai").enable()
end, { desc = "Enable acai completions" })

vim.api.nvim_create_user_command("AcaiDisable", function()
  require("acai").disable()
end, { desc = "Disable acai completions" })

vim.api.nvim_create_user_command("AcaiToggle", function()
  require("acai").toggle()
end, { desc = "Toggle acai completions" })

vim.api.nvim_create_user_command("AcaiStatus", function()
  require("acai").status()
end, { desc = "Show acai status" })
