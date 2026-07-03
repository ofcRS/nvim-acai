-- ghost.clear() must remove the extmark from the buffer it was created in,
-- even if the user has since switched to another buffer.
local H = dofile(vim.env.ACAI_TEST_DIR .. "/helpers.lua")

local ghost = require("acai.ghost")
local ns = vim.api.nvim_create_namespace("acai_ghost")

local buf_a = vim.api.nvim_get_current_buf()
vim.api.nvim_buf_set_lines(buf_a, 0, -1, false, { "aaa" })
vim.api.nvim_win_set_cursor(0, { 1, 3 })

ghost.show("suggestion")
H.eq(#vim.api.nvim_buf_get_extmarks(buf_a, ns, 0, -1, {}), 1, "extmark created in buffer A")

vim.cmd("enew")
ghost.clear()

H.eq(#vim.api.nvim_buf_get_extmarks(buf_a, ns, 0, -1, {}), 0, "extmark removed from buffer A after switching away")
H.ok(not ghost.is_visible(), "ghost no longer visible")

H.finish()
