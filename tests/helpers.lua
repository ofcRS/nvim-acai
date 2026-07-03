-- Shared test helpers. Specs load this with:
--   local H = dofile(vim.env.ACAI_TEST_DIR .. "/helpers.lua")
local M = { failures = {} }

function M.ok(cond, msg)
  if not cond then
    M.failures[#M.failures + 1] = msg or "assertion failed"
  end
end

function M.eq(got, want, msg)
  if got ~= want then
    M.failures[#M.failures + 1] =
      string.format("%s: got %s, want %s", msg or "eq", vim.inspect(got), vim.inspect(want))
  end
end

---Report results and exit nvim: exit code 0 on pass, 1 on any failure.
function M.finish()
  if #M.failures > 0 then
    io.stderr:write(table.concat(M.failures, "\n") .. "\n")
    vim.cmd("cquit! 1")
  else
    vim.cmd("qa!")
  end
end

---Run functions one per main-loop tick, so autocmds and scheduled
---callbacks settle between steps.
function M.seq(fns, gap_ms)
  gap_ms = gap_ms or 30
  local i = 0
  local function next_step()
    i = i + 1
    if fns[i] then
      local ok, err = pcall(fns[i])
      if not ok then
        M.failures[#M.failures + 1] = "step " .. i .. " errored: " .. tostring(err)
        M.finish()
        return
      end
      vim.defer_fn(next_step, gap_ms)
    end
  end
  vim.defer_fn(next_step, gap_ms)
end

---Replace acai.http with a fake that records requests and cancellations.
---Must be called before acai.completion is required.
function M.fake_http()
  local fake = { posts = {}, cancels = {} }
  function fake.post(url, headers, body, cb)
    fake.posts[#fake.posts + 1] = { url = url, headers = headers, body = body, cb = cb }
    return 1000 + #fake.posts
  end
  function fake.cancel(job_id)
    fake.cancels[#fake.cancels + 1] = job_id
  end
  package.loaded["acai.http"] = fake
  return fake
end

---A minimal OpenAI-shaped completion response.
function M.openai_response(text)
  return vim.json.encode({ choices = { { message = { content = text } } } })
end

return M
