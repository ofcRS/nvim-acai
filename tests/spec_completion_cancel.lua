-- A late callback from an already-cancelled job must not clobber the
-- handle of the job that replaced it: the newer job must stay cancellable.
local H = dofile(vim.env.ACAI_TEST_DIR .. "/helpers.lua")

vim.env.OPENROUTER_API_KEY = "test-key"
local fake = H.fake_http()
local completion = require("acai.completion")

vim.api.nvim_buf_set_lines(0, 0, -1, false, { "local x = " })
vim.api.nvim_win_set_cursor(0, { 1, 10 })

H.seq({
  function()
    completion.request() -- job 1001
  end,
  function()
    completion.request() -- cancels 1001, starts job 1002
  end,
  function()
    H.eq(fake.cancels[1], 1001, "first job cancelled when a new request starts")
    -- late on_exit callback from the killed job arrives now
    fake.posts[1].cb("curl error (exit 143): killed", nil)
  end,
  function()
    completion.cancel()
  end,
  function()
    H.eq(fake.cancels[2], 1002, "second job still cancellable after the stale callback")
    H.finish()
  end,
})
