local M = {}

M.defaults = {
  work_duration = 25 * 60,   -- 25 minutes in seconds
  short_break = 5 * 60,      -- 5 minutes in seconds
  long_break = 15 * 60,      -- 15 minutes in seconds
  width = 88,                -- Width of the floating window
  height = 26,               -- Height of the floating window
  border = "rounded",
  keymap = "<space>p",
  auto_start_breaks = true,
  notification = true,
  sound = true,
}

M.opts = {}

function M.setup(opts)
  M.opts = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

M.setup()

return M
