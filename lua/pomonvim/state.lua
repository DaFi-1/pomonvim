local M = {}

local data_file = vim.fn.stdpath("data") .. "/pomonvim_sessions.json"
local legacy_file = vim.fn.stdpath("data") .. "/pomoxx_sessions.json"
local math_max = math.max
local math_min = math.min

M.cycles = {}
M.active_cycle_idx = 1
M.all_completed = false
M.saved_pomodoros = {}

function M.save()
  local ok, encoded = pcall(vim.json.encode, {
    cycles = M.cycles,
    active_cycle_idx = M.active_cycle_idx,
    all_completed = M.all_completed,
    saved_pomodoros = M.saved_pomodoros,
  })
  if ok and encoded then
    local f = io.open(data_file, "w")
    if f then
      f:write(encoded)
      f:close()
    end
  end
end

function M.load()
  local f = io.open(data_file, "r")
  if not f then
    -- Fallback to legacy pomoxx file to preserve saved pomodoros
    f = io.open(legacy_file, "r")
  end
  if f then
    local content = f:read("*a")
    f:close()
    if content and content ~= "" then
      local ok, decoded = pcall(vim.json.decode, content)
      if ok and decoded and type(decoded) == "table" then
        if type(decoded.cycles) == "table" then
          M.cycles = decoded.cycles
          M.active_cycle_idx = math_max(1, math_min(decoded.active_cycle_idx or 1, math_max(1, #M.cycles)))
          M.all_completed = decoded.all_completed or false
        else
          M.cycles = {}
          M.active_cycle_idx = 1
          M.all_completed = false
        end

        if type(decoded.saved_pomodoros) == "table" then
          M.saved_pomodoros = decoded.saved_pomodoros
        else
          M.saved_pomodoros = {}
        end
        return
      end
    end
  end
  M.cycles = {}
  M.active_cycle_idx = 1
  M.all_completed = false
  M.saved_pomodoros = {}
end

function M.get_cycles()
  return M.cycles
end

-- Alternates focus -> sleep -> focus -> sleep...
function M.add_cycle(duration, label)
  local ptype = (#M.cycles % 2 == 0) and "focus" or "sleep"
  table.insert(M.cycles, {
    type = ptype,
    duration = duration,
    label = label,
    completed = false,
  })
  M.all_completed = false
  M.save()
  return #M.cycles
end

function M.remove_last_cycle()
  if #M.cycles > 0 then
    table.remove(M.cycles)
    if M.active_cycle_idx > #M.cycles then
      M.active_cycle_idx = math_max(1, #M.cycles)
    end
    M.save()
  end
end

function M.clear_cycles()
  M.cycles = {}
  M.active_cycle_idx = 1
  M.all_completed = false
  M.save()
end

function M.reset_progress()
  for _, c in ipairs(M.cycles) do
    c.completed = false
  end
  M.all_completed = false
  M.active_cycle_idx = 1
  M.save()
end

function M.get_active_cycle()
  if #M.cycles == 0 then
    return { type = "focus", duration = 25 * 60, label = "25m" }
  end
  local idx = math_max(1, math_min(M.active_cycle_idx or 1, #M.cycles))
  return M.cycles[idx]
end

function M.get_active_cycle_index()
  return M.active_cycle_idx
end

function M.set_active_cycle_index(idx)
  if #M.cycles > 0 then
    M.active_cycle_idx = math_max(1, math_min(idx, #M.cycles))
    M.save()
  end
end

function M.get_saved_pomodoros()
  return M.saved_pomodoros or {}
end

function M.save_pomodoro(name)
  if #M.cycles == 0 then
    return false, "Monte uma sequência de ciclos antes de salvar!"
  end

  local copied_cycles = {}
  for _, c in ipairs(M.cycles) do
    table.insert(copied_cycles, {
      type = c.type,
      duration = c.duration,
      label = c.label,
      completed = false,
    })
  end

  M.saved_pomodoros = M.saved_pomodoros or {}

  local found_idx = nil
  for idx, sp in ipairs(M.saved_pomodoros) do
    if sp.name == name then
      found_idx = idx
      break
    end
  end

  local entry = {
    name = name,
    cycles = copied_cycles,
  }

  if found_idx then
    M.saved_pomodoros[found_idx] = entry
  else
    table.insert(M.saved_pomodoros, entry)
  end

  M.save()
  return true
end

function M.load_saved_pomodoro(idx)
  M.saved_pomodoros = M.saved_pomodoros or {}
  local sp = M.saved_pomodoros[idx]
  if not sp or not sp.cycles then
    return false, "Rotina não encontrada"
  end

  local copied = {}
  for _, c in ipairs(sp.cycles) do
    table.insert(copied, {
      type = c.type,
      duration = c.duration,
      label = c.label,
      completed = false,
    })
  end

  M.cycles = copied
  M.active_cycle_idx = 1
  M.all_completed = false
  M.save()
  return true
end

function M.delete_saved_pomodoro(idx)
  M.saved_pomodoros = M.saved_pomodoros or {}
  if M.saved_pomodoros[idx] then
    table.remove(M.saved_pomodoros, idx)
    M.save()
    return true
  end
  return false
end

M.load()

return M
