local M = {}

---Perform an async HTTP POST request using curl via jobstart.
---@param url string
---@param headers table<string, string>
---@param body string JSON-encoded body
---@param callback function(err: string|nil, response: string|nil)
---@return number|nil job_id (can be passed to vim.fn.jobstop)
function M.post(url, headers, body, callback)
  local cmd = { "curl", "-sS", "-X", "POST", url }

  for key, value in pairs(headers) do
    cmd[#cmd + 1] = "-H"
    cmd[#cmd + 1] = key .. ": " .. value
  end

  cmd[#cmd + 1] = "-d"
  cmd[#cmd + 1] = "@-" -- read body from stdin

  local stdout_lines = {}
  local stderr_lines = {}

  local job_id = vim.fn.jobstart(cmd, {
    stdin = "pipe",
    -- Buffered: each callback receives the complete output as a list of
    -- lines, so joining with "\n" reconstructs the body byte-for-byte.
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data then
        stdout_lines = data
      end
    end,
    on_stderr = function(_, data)
      if data then
        stderr_lines = data
      end
    end,
    on_exit = function(_, exit_code)
      vim.schedule(function()
        if exit_code ~= 0 then
          local err = table.concat(stderr_lines, "\n")
          callback("curl error (exit " .. exit_code .. "): " .. err, nil)
        else
          local response = table.concat(stdout_lines, "\n")
          callback(nil, response)
        end
      end)
    end,
  })

  if job_id <= 0 then
    callback("failed to start curl job", nil)
    return nil
  end

  -- Send body via stdin and close
  vim.fn.chansend(job_id, body)
  vim.fn.chanclose(job_id, "stdin")

  return job_id
end

---Stop an in-flight request started by M.post.
---@param job_id number
function M.cancel(job_id)
  pcall(vim.fn.jobstop, job_id)
end

return M
