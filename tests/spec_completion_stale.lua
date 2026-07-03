-- A completion response that arrives after the buffer or cursor changed
-- must be discarded, not rendered at the new cursor position.
local H = dofile(vim.env.ACAI_TEST_DIR .. "/helpers.lua")

vim.env.OPENROUTER_API_KEY = "test-key"
local fake = H.fake_http()
local completion = require("acai.completion")
local ghost = require("acai.ghost")

vim.api.nvim_buf_set_lines(0, 0, -1, false, { "local x = " })
vim.api.nvim_win_set_cursor(0, { 1, 10 })
vim.cmd("startinsert!")

H.seq({
  -- Stale by buffer change: user keeps typing while the request is in flight.
  function()
    completion.request()
  end,
  function()
    H.eq(#fake.posts, 1, "request captured")
    vim.api.nvim_input("foo")
  end,
  function()
    fake.posts[1].cb(nil, H.openai_response("stale_after_typing"))
    H.ok(not ghost.is_visible(), "response for old buffer content must not show ghost")
  end,

  -- Stale by cursor move: no text change, but the cursor is elsewhere.
  function()
    completion.request()
  end,
  function()
    H.eq(#fake.posts, 2, "second request captured")
    vim.api.nvim_win_set_cursor(0, { 1, 4 })
  end,
  function()
    fake.posts[2].cb(nil, H.openai_response("stale_after_cursor_move"))
    H.ok(not ghost.is_visible(), "response for old cursor position must not show ghost")
    vim.api.nvim_win_set_cursor(0, { 1, 13 })
  end,

  -- Positive control: nothing changed between request and response.
  function()
    completion.request()
  end,
  function()
    fake.posts[#fake.posts].cb(nil, H.openai_response("fresh"))
    H.ok(ghost.is_visible(), "response with unchanged buffer and cursor must show ghost")
    H.eq(ghost.get_suggestion(), "fresh", "suggestion text")
  end,

  function()
    H.finish()
  end,
})
