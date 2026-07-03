-- http.post must deliver the response body byte-for-byte, including
-- newlines. A curl stub on PATH prints a known multi-line body.
local H = dofile(vim.env.ACAI_TEST_DIR .. "/helpers.lua")

vim.env.PATH = vim.env.ACAI_TEST_DIR .. "/fixtures:" .. vim.env.PATH
local http = require("acai.http")

local done = false
local got_err, got_resp

http.post("http://unused.invalid", { ["X-Test"] = "1" }, "{}", function(err, resp)
  got_err, got_resp = err, resp
  done = true
end)

vim.wait(5000, function()
  return done
end)

H.ok(done, "callback invoked")
H.eq(got_err, nil, "no error")
H.eq(got_resp, '{\n  "greeting": "hi",\n\n  "n": 1\n}\n', "newlines in response body preserved")

H.finish()
