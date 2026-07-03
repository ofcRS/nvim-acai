-- Partial-accept extraction: get_first_word must handle suggestions that
-- start with indentation (very common for code), and never return text
-- containing a newline (accept_partial inserts into a single line).
local H = dofile(vim.env.ACAI_TEST_DIR .. "/helpers.lua")

local ghost = require("acai.ghost")
local acai = require("acai")

vim.api.nvim_buf_set_lines(0, 0, -1, false, { "x = " })
vim.api.nvim_win_set_cursor(0, { 1, 4 })

ghost.show("foo bar")
H.eq(ghost.get_first_word(), "foo", "plain first word")

ghost.show("  foo bar")
H.eq(ghost.get_first_word(), "  foo", "leading indentation kept with the first word")

ghost.show("\nfoo bar")
H.eq(ghost.get_first_word(), nil, "suggestion starting with a newline has no first word")

ghost.show("abc\ndef")
H.eq(ghost.get_first_line(), "abc", "first line of multi-line suggestion")

-- End to end (in insert mode, cursor at end of line, like a real accept).
vim.cmd("startinsert!")
H.seq({
  -- Accepting the first word of an indented suggestion inserts it.
  function()
    vim.api.nvim_win_set_cursor(0, { 1, 4 })
    ghost.show("  foo bar")
    local accepted = acai.accept_word()
    H.ok(accepted, "accept_word succeeds on an indented suggestion")
    H.eq(vim.api.nvim_get_current_line(), "x =   foo", "indent + word inserted at cursor")
    H.eq(vim.api.nvim_win_get_cursor(0)[2], 9, "cursor after inserted text")
  end,
  -- A newline-leading suggestion must not crash accept_word.
  function()
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "x = " })
    vim.api.nvim_win_set_cursor(0, { 1, 4 })
    ghost.show("\nfoo")
    local ok, err = pcall(acai.accept_word)
    H.ok(ok, "accept_word must not error on newline-leading suggestion: " .. tostring(err))
  end,
  function()
    H.finish()
  end,
})
