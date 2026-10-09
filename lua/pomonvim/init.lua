local config = require("pomonvim.config")
local ui = require("pomonvim.ui")
local timer = require("pomonvim.timer")
local str_format = string.format

local M = {}

function M.setup(opts)
  config.setup(opts)
  local keymap = config.opts.keymap
  if keymap and keymap ~= "" then
    vim.keymap.set("n", keymap, function()
      M.toggle()
    end, { silent = true, desc = "Pomonvim Pomodoro Menu" })
  end
end

function M.open()
  ui.open()
end

function M.close()
  ui.close()
end

function M.toggle()
  ui.toggle()
end

function M.start()
  timer.start()
end

function M.pause()
  timer.pause()
end

function M.reset()
  timer.reset()
end

function M.next()
  timer.next()
end

function M.prev()
  timer.prev()
end

function M.get_status()
  return timer.get_status()
end

-- Useful helper for statusline / lualine
-- e.g. lualine_x = { require('pomonvim').statusline }
function M.statusline()
  local s = timer.get_status()
  local icon = (s.mode == "focus" or s.mode == "work") and "🍅" or "☕"
  local state_symbol = s.running and "" or "󰏤 "
  return str_format("%s %s%s", icon, state_symbol, s.formatted_time)
end

return M
