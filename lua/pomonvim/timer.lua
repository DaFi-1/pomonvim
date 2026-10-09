local state = require("pomonvim.state")
local config = require("pomonvim.config")

local M = {}

local uv = vim.uv or vim.loop
local timer = nil

M.running = false
M.time_left = 60 * 60
M.total_time = 60 * 60
M.listeners = {}

local math_floor = math.floor
local math_max = math.max
local math_min = math.min
local str_format = string.format

local function format_time(seconds)
  local h = math_floor(seconds / 3600)
  local m = math_floor((seconds % 3600) / 60)
  local s = seconds % 60
  if h > 0 then
    return str_format("%d:%02d:%02d", h, m, s)
  else
    return str_format("%02d:%02d", m, s)
  end
end

function M.get_status()
  local active_cycle = state.get_active_cycle()
  local cycle_idx = state.get_active_cycle_index()
  local cycles = state.get_cycles()
  local total_cycles = #cycles

  local percent = 0
  if M.total_time > 0 then
    percent = math_floor(((M.total_time - M.time_left) / M.total_time) * 100)
  end
  percent = math_max(0, math_min(100, percent))

  return {
    running = M.running,
    time_left = M.time_left,
    total_time = M.total_time,
    formatted_time = format_time(M.time_left),
    percent = percent,
    mode = active_cycle and active_cycle.type or "focus",
    active_cycle = active_cycle,
    active_cycle_idx = cycle_idx,
    total_cycles = total_cycles,
  }
end

local function notify_listeners()
  if #M.listeners == 0 then
    return
  end
  local status = M.get_status()
  for _, callback in ipairs(M.listeners) do
    pcall(callback, status)
  end
end

function M.on_tick(callback)
  table.insert(M.listeners, callback)
end

function M.remove_listener(callback)
  for i, cb in ipairs(M.listeners) do
    if cb == callback then
      table.remove(M.listeners, i)
      break
    end
  end
end

local function sync_time_with_cycle()
  local cycle = state.get_active_cycle()
  M.total_time = cycle and cycle.duration or (25 * 60)
  M.time_left = M.total_time
end

function M.sync_with_cycle()
  sync_time_with_cycle()
  notify_listeners()
end

local function on_finish()
  M.pause()
  local cycle_idx = state.get_active_cycle_index()
  local cycles = state.get_cycles()

  if config.opts.sound then
    io.write("\a")
    pcall(io.flush)
  end

  -- Mark current cycle as completed / realizado (checkin)
  if cycles[cycle_idx] then
    cycles[cycle_idx].completed = true
    state.save()
  end

  local next_cycle_idx = cycle_idx + 1

  if next_cycle_idx > #cycles then
    -- Pomodoro sequence finished!
    state.all_completed = true
    state.save()
    if config.opts.notification then
      vim.notify("🎉 Pomodoro finalizado com sucesso! Todos os ciclos foram concluídos!", vim.log.levels.INFO, { title = "Pomonvim" })
    end
    state.set_active_cycle_index(1)
    sync_time_with_cycle()
  else
    -- Next cycle: directly transition
    state.set_active_cycle_index(next_cycle_idx)
    sync_time_with_cycle()
    if config.opts.notification then
      local n_cycle = state.get_active_cycle()
      local mode_str = (n_cycle and n_cycle.type == "focus") and "Foco" or "Descanso"
      local dur_str = n_cycle and n_cycle.label or ""
      vim.notify(str_format("🍅 Ciclo concluído! Iniciando %s (%s).", mode_str, dur_str), vim.log.levels.INFO, { title = "Pomonvim" })
    end
    if config.opts.auto_start_breaks ~= false then
      M.start()
    end
  end

  notify_listeners()
end

local function tick()
  if not M.running then
    return
  end
  if M.time_left > 0 then
    M.time_left = M.time_left - 1
    notify_listeners()
    if M.time_left == 0 then
      vim.schedule(on_finish)
    end
  end
end

function M.start()
  if M.running then
    return
  end
  if #state.get_cycles() == 0 then
    return
  end
  if state.all_completed then
    state.reset_progress()
    sync_time_with_cycle()
  end
  M.running = true
  if not timer or timer:is_closing() then
    timer = uv.new_timer()
  end
  timer:start(1000, 1000, vim.schedule_wrap(tick))
  notify_listeners()
end

function M.pause()
  if not M.running then
    return
  end
  M.running = false
  if timer then
    timer:stop()
  end
  notify_listeners()
end

function M.toggle()
  if M.running then
    M.pause()
  else
    M.start()
  end
end

function M.reset()
  sync_time_with_cycle()
  notify_listeners()
end

function M.next()
  local cycles = state.get_cycles()
  if #cycles == 0 then return end
  local cycle_idx = state.get_active_cycle_index()
  if cycle_idx < #cycles then
    state.set_active_cycle_index(cycle_idx + 1)
  else
    state.set_active_cycle_index(1)
  end
  sync_time_with_cycle()
  notify_listeners()
end

function M.prev()
  local cycles = state.get_cycles()
  if #cycles == 0 then return end
  local cycle_idx = state.get_active_cycle_index()
  if cycle_idx > 1 then
    state.set_active_cycle_index(cycle_idx - 1)
  else
    state.set_active_cycle_index(#cycles)
  end
  sync_time_with_cycle()
  notify_listeners()
end

-- Initialize time
sync_time_with_cycle()

vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    if timer and not timer:is_closing() then
      pcall(function()
        timer:stop()
        timer:close()
      end)
    end
  end,
})

return M
