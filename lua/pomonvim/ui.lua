local config = require("pomonvim.config")
local state = require("pomonvim.state")
local timer = require("pomonvim.timer")

local M = {}

local ns_id = vim.api.nvim_create_namespace("pomonvim_ui")

local win = nil
local buf = nil
local selected_idx = 1
local list_start = 1
local tick_callback = nil
local resize_autocmd = nil
local banner_msg = nil
local banner_timer = nil
local current_footer_text = nil
local save_win = nil
local save_buf = nil
local loaded_saved_idx = nil
local help_win = nil
local help_buf = nil
local current_help_lang = "pt"

-- Localized standard library functions for high-performance JIT execution
local math_floor = math.floor
local math_min = math.min
local math_max = math.max
local str_rep = string.rep
local str_format = string.format
local str_displaywidth = vim.fn.strdisplaywidth

-- Available preset times to build the pomodoro
local TIME_OPTIONS = {
  { label = "5m", duration = 5 * 60 },
  { label = "10m", duration = 10 * 60 },
  { label = "15m", duration = 15 * 60 },
  { label = "20m", duration = 20 * 60 },
  { label = "25m", duration = 25 * 60 },
  { label = "30m", duration = 30 * 60 },
  { label = "35m", duration = 35 * 60 },
  { label = "40m", duration = 40 * 60 },
  { label = "45m", duration = 45 * 60 },
  { label = "50m", duration = 50 * 60 },
  { label = "1h", duration = 60 * 60 },
  { label = "1h 15m", duration = 75 * 60 },
  { label = "1h 30m", duration = 90 * 60 },
  { label = "2h", duration = 120 * 60 },
  { label = "3h", duration = 180 * 60 },
  { label = "4h", duration = 240 * 60 },
}

local function get_total_menu_items()
  return 3 + #state.get_saved_pomodoros() + #TIME_OPTIONS + 1
end

-- Fixed 3x3 digital font with corrected 1 and 9
local DIGITS = {
  ["0"] = { "▛▀▜", "▌ ▐", "▙▄▟" },
  ["1"] = { " ▄█", "  █", "▄█▄" },
  ["2"] = { "▜▀▛", " ▞ ", "▟▄▄" },
  ["3"] = { "▀▀▜", " ▀▜", "▄▄▟" },
  ["4"] = { "▌ ▌", "▀▀▌", "  ▌" },
  ["5"] = { "▛▀▀", "▀▀▜", "▄▄▟" },
  ["6"] = { "▛▀▀", "▛▀▜", "▙▄▟" },
  ["7"] = { "▀▀▌", "  ▌", "  ▌" },
  ["8"] = { "▛▀▜", "▛▀▜", "▙▄▟" },
  ["9"] = { "▛▀▜", "▙▄█", " ▄▟" },
  [":"] = { "   ", " ▄ ", " ▄ " },
}

local function setup_highlights()
  local set_hl = vim.api.nvim_set_hl
  set_hl(0, "PomonvimNormal", { bg = "#000000", fg = "#ffffff", default = true })
  set_hl(0, "PomonvimBorder", { bg = "#000000", fg = "#ffffff", default = true })
  set_hl(0, "PomonvimDigit", { bg = "#000000", fg = "#ffffff", bold = true, default = true })
  -- Focus = VERDE, Sleep = VERMELHO
  set_hl(0, "PomonvimFocus", { bg = "#000000", fg = "#50fa7b", bold = true, default = true })
  set_hl(0, "PomonvimSleep", { bg = "#000000", fg = "#ff5555", bold = true, default = true })
  set_hl(0, "PomonvimWork", { link = "PomonvimFocus", default = true })
  set_hl(0, "PomonvimBreak", { link = "PomonvimSleep", default = true })
  -- Cor de fundo do seletor conforme a etapa de escolha
  set_hl(0, "PomonvimSelected", { bg = "#ffffff", fg = "#000000", bold = true, default = true })
  set_hl(0, "PomonvimSelectedFocus", { bg = "#50fa7b", fg = "#000000", bold = true, default = true })
  set_hl(0, "PomonvimSelectedSleep", { bg = "#ff5555", fg = "#000000", bold = true, default = true })
  set_hl(0, "PomonvimSelectedSave", { bg = "#8be9fd", fg = "#000000", bold = true, default = true })
  set_hl(0, "PomonvimSelectedSaved", { bg = "#bd93f9", fg = "#000000", bold = true, default = true })
  set_hl(0, "PomonvimSelectedHelp", { bg = "#f1fa8c", fg = "#000000", bold = true, default = true })
  set_hl(0, "PomonvimHeader", { bg = "#000000", fg = "#8be9fd", bold = true, default = true })
  set_hl(0, "PomonvimMuted", { bg = "#000000", fg = "#777777", default = true })
  set_hl(0, "PomonvimKey", { bg = "#000000", fg = "#f1fa8c", bold = true, default = true })
  set_hl(0, "PomonvimWarnIcon", { bg = "#000000", fg = "#ff5555", bold = true, default = true })
  set_hl(0, "PomonvimWarnText", { bg = "#000000", fg = "#ffffff", default = true })

  -- Backward-compatibility highlight aliases
  set_hl(0, "PomoxxNormal", { link = "PomonvimNormal", default = true })
  set_hl(0, "PomoxxBorder", { link = "PomonvimBorder", default = true })
  set_hl(0, "PomoxxFocus", { link = "PomonvimFocus", default = true })
  set_hl(0, "PomoxxSleep", { link = "PomonvimSleep", default = true })
  set_hl(0, "PomoxxHeader", { link = "PomonvimHeader", default = true })
  set_hl(0, "PomoxxMuted", { link = "PomonvimMuted", default = true })
  set_hl(0, "PomoxxKey", { link = "PomonvimKey", default = true })
  set_hl(0, "PomoxxSelectedHelp", { link = "PomonvimSelectedHelp", default = true })
  set_hl(0, "PomoxxSelectedSave", { link = "PomonvimSelectedSave", default = true })
  set_hl(0, "PomoxxSelectedSaved", { link = "PomonvimSelectedSaved", default = true })
  set_hl(0, "PomoxxSelectedFocus", { link = "PomonvimSelectedFocus", default = true })
  set_hl(0, "PomoxxSelectedSleep", { link = "PomonvimSelectedSleep", default = true })
end

local function pad_cell(text, target_width)
  text = text or ""
  local current_w = str_displaywidth(text)
  if current_w < target_width then
    return text .. str_rep(" ", target_width - current_w)
  end
  return text
end

local function center_text(text, total_width)
  local w = str_displaywidth(text)
  local pad = math_max(0, math_floor((total_width - w) / 2))
  local rem = math_max(0, total_width - w - pad)
  return str_rep(" ", pad) .. text .. str_rep(" ", rem)
end

local function format_duration(seconds)
  local h = math_floor(seconds / 3600)
  local m = math_floor((seconds % 3600) / 60)
  if h > 0 and m > 0 then
    return str_format("%dh %02dm", h, m)
  elseif h > 0 then
    return str_format("%dh 00m", h)
  else
    return str_format("%dm", m)
  end
end

local function render_digits(time_str)
  local rows = { "", "", "" }
  for i = 1, #time_str do
    local ch = time_str:sub(i, i)
    local glyph = DIGITS[ch] or { "   ", "   ", "   " }
    for r = 1, 3 do
      rows[r] = rows[r] .. glyph[r] .. " "
    end
  end
  return rows
end

local function render_progress_bar(percent, bar_len)
  local filled_len = math_floor((percent / 100) * bar_len)
  local empty_len = math_max(0, bar_len - filled_len)
  local filled = str_rep("█", filled_len)
  local empty = str_rep("░", empty_len)
  return str_format("%s%s %3d%%", filled, empty, percent)
end

local function build_header(cycles, col1_w, col2_w, is_previewing, preview_name)
  local is_next_focus = (#cycles % 2 == 0)
  local next_badge = is_next_focus and "(+Foco)" or "(+Descanso)"
  local header_left = " TEMPOS  " .. next_badge
  local header_right = is_previewing and (" CICLOS (preview: " .. (preview_name or "") .. ")") or " CICLOS"
  if str_displaywidth(header_right) > col2_w - 2 then
    header_right = is_previewing and " CICLOS (preview)" or " CICLOS"
  end
  local header_row = pad_cell(header_left, col1_w) .. "│" .. pad_cell(header_right, col2_w)
  return header_row, is_next_focus, next_badge
end

local function build_left_lines(selected_idx, is_running, content_rows, list_start, saved, col1_w)
  local left_lines = {}
  local num_saved = #saved
  local num_times = #TIME_OPTIONS
  local help_idx = 3 + num_saved + num_times + 1

  for r = 1, content_rows do
    local i = list_start + r - 1
    local marker = (i == selected_idx) and "▸ " or "  "
    if i == 1 then
      local action = is_running and "󰏤 PAUSAR POMODORO" or "▶ START POMODORO"
      left_lines[r] = " " .. marker .. action
    elseif i == 2 then
      left_lines[r] = " " .. marker .. "󰆴 LIMPAR CICLOS"
    elseif i == 3 then
      left_lines[r] = " " .. marker .. "󰆓 SALVAR POMODORO"
    elseif i > 3 and i <= 3 + num_saved then
      local s_idx = i - 3
      local s_item = saved[s_idx]
      local prefix = " " .. marker .. " "
      local pre_w = str_displaywidth(prefix)
      local max_name_w = col1_w - pre_w - 1
      local s_name = s_item.name or "Pomodoro"
      if str_displaywidth(s_name) > max_name_w then
        s_name = s_name:sub(1, math_max(1, max_name_w - 1)) .. "…"
      end
      left_lines[r] = prefix .. s_name
    elseif i > 3 + num_saved and i <= 3 + num_saved + num_times then
      local t_idx = i - 3 - num_saved
      left_lines[r] = " " .. marker .. "  " .. TIME_OPTIONS[t_idx].label
    elseif i == help_idx then
      left_lines[r] = " " .. marker .. "󰋖 HELP"
    else
      left_lines[r] = ""
    end
  end
  return left_lines
end

local function build_right_lines(cycles, active_cycle_idx, all_completed, col2_w, is_previewing)
  local right_lines = {}
  local cycle_slots = 15
  local total_focus = 0
  local total_sleep = 0

  for _, c in ipairs(cycles) do
    if c.type == "focus" then
      total_focus = total_focus + c.duration
    else
      total_sleep = total_sleep + c.duration
    end
  end

  local rendered_cycles_count = math_min(#cycles, cycle_slots)
  local check_col = col2_w - 8

  if #cycles > 0 then
    for c_idx = 1, rendered_cycles_count do
      local c = cycles[c_idx]
      local c_type_label = c.type == "focus" and "Foco" or "Descanso"
      if is_previewing then
        local left_info = str_format("  Ciclo %d: %-3s (%s)", c_idx, c.label, c_type_label)
        right_lines[c_idx] = left_info
      else
        local is_done = c.completed or all_completed or (c_idx < active_cycle_idx)
        local marker = (c_idx == active_cycle_idx and not is_done) and "▶ " or "  "
        local left_info = str_format("%sCiclo %d: %-3s (%s)", marker, c_idx, c.label, c_type_label)
        right_lines[c_idx] = is_done and (pad_cell(left_info, check_col) .. "✓") or left_info
      end
    end
  end

  for r = (#right_lines + 1), cycle_slots do
    right_lines[r] = ""
  end

  if #cycles > 0 then
    right_lines[16] = ""
    right_lines[17] = "  Total Foco:     " .. format_duration(total_focus)
    right_lines[18] = "  Total Descanso: " .. format_duration(total_sleep)
  else
    right_lines[16] = ""
    right_lines[17] = ""
    right_lines[18] = ""
  end

  return right_lines, rendered_cycles_count
end

local function apply_highlights(buf, lines, status, cycles, is_next_focus, next_badge, selected_idx, list_start, rendered_cycles_count, num_saved, is_previewing, display_cycles)
  vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)

  local current_mode_hl = status.mode == "focus" and "PomonvimFocus" or "PomonvimSleep"
  for row_idx = 1, 3 do
    vim.api.nvim_buf_add_highlight(buf, ns_id, current_mode_hl, row_idx, 0, -1)
  end
  vim.api.nvim_buf_add_highlight(buf, ns_id, current_mode_hl, 5, 0, -1)

  vim.api.nvim_buf_add_highlight(buf, ns_id, "PomonvimHeader", 7, 0, -1)
  local hl_badge = is_next_focus and "PomonvimFocus" or "PomonvimSleep"
  vim.api.nvim_buf_add_highlight(buf, ns_id, hl_badge, 7, 9, 9 + #next_badge)

  if is_previewing then
    local header_row_text = lines[8] or ""
    local sp_h = header_row_text:find("│", 1, true)
    if sp_h then
      vim.api.nvim_buf_add_highlight(buf, ns_id, "PomonvimSelectedSaved", 7, sp_h + 1, -1)
    end
  end

  if #display_cycles > 0 then
    for c_idx = 1, rendered_cycles_count do
      local target_session_row = 7 + c_idx
      local sess_row_text = lines[target_session_row + 1] or ""
      local sp = sess_row_text:find("│", 1, true)
      if sp then
        local c = display_cycles[c_idx]
        local hl = c.type == "focus" and "PomonvimFocus" or "PomonvimSleep"
        vim.api.nvim_buf_add_highlight(buf, ns_id, hl, target_session_row, sp + 2, -1)
        if not is_previewing then
          local chk_pos = sess_row_text:find("✓", sp, true)
          if chk_pos then
            vim.api.nvim_buf_add_highlight(buf, ns_id, "PomonvimFocus", target_session_row, chk_pos - 1, chk_pos - 1 + #"✓")
          end
        end
      end
    end

    local fr_text = lines[25] or ""
    local sp_f = fr_text:find("│", 1, true)
    if sp_f and fr_text:find("Total Foco", sp_f, true) then
      vim.api.nvim_buf_add_highlight(buf, ns_id, "PomonvimFocus", 24, sp_f + 2, -1)
    end

    local sr_text = lines[26] or ""
    local sp_s = sr_text:find("│", 1, true)
    if sp_s and sr_text:find("Total Descanso", sp_s, true) then
      vim.api.nvim_buf_add_highlight(buf, ns_id, "PomonvimSleep", 25, sp_s + 2, -1)
    end
  end

  local visual_selected_row = selected_idx - list_start + 1
  if visual_selected_row >= 1 and visual_selected_row <= 18 then
    local target_line_idx = 7 + visual_selected_row
    local row_text = lines[target_line_idx + 1] or ""
    local sep_col = row_text:find("│", 1, true)
    if sep_col then
      local help_idx = 3 + num_saved + #TIME_OPTIONS + 1
      local sel_hl
      if selected_idx == 1 then
        sel_hl = status.running and "PomonvimKey" or "PomonvimSelectedFocus"
      elseif selected_idx == 2 then
        sel_hl = "PomonvimSelectedSleep"
      elseif selected_idx == 3 then
        sel_hl = "PomonvimSelectedSave"
      elseif selected_idx > 3 and selected_idx <= 3 + num_saved then
        sel_hl = "PomonvimSelectedSaved"
      elseif selected_idx == help_idx then
        sel_hl = "PomonvimSelectedHelp"
      else
        sel_hl = is_next_focus and "PomonvimSelectedFocus" or "PomonvimSelectedSleep"
      end

      vim.api.nvim_buf_set_extmark(buf, ns_id, target_line_idx, 0, {
        end_row = target_line_idx,
        end_col = sep_col - 1,
        hl_group = sel_hl,
      })
    end
  end

  local help_idx = 3 + num_saved + #TIME_OPTIONS + 1
  for r = 1, 18 do
    local i = list_start + r - 1
    if i > 3 and i <= 3 + num_saved and i ~= selected_idx then
      local target_line_idx = 7 + r
      local row_text = lines[target_line_idx + 1] or ""
      local sep_col = row_text:find("│", 1, true)
      if sep_col then
        local star_pos = row_text:find("", 1, true)
        if star_pos and star_pos < sep_col then
          vim.api.nvim_buf_add_highlight(buf, ns_id, "PomonvimKey", target_line_idx, star_pos - 1, star_pos - 1 + #"")
        end
      end
    elseif i == help_idx and i ~= selected_idx then
      local target_line_idx = 7 + r
      local row_text = lines[target_line_idx + 1] or ""
      local sep_col = row_text:find("│", 1, true)
      if sep_col then
        local help_pos = row_text:find("󰋖", 1, true)
        if help_pos and help_pos < sep_col then
          vim.api.nvim_buf_add_highlight(buf, ns_id, "PomonvimKey", target_line_idx, help_pos - 1, help_pos - 1 + #"󰋖")
        end
      end
    end
  end
end

local function update_window_footer(win, banner_msg)
  if win and vim.api.nvim_win_is_valid(win) then
    if banner_msg ~= current_footer_text then
      current_footer_text = banner_msg
      if banner_msg and banner_msg ~= "" then
        local footer = {
          { " 󰀦 ", "PomonvimWarnIcon" },
          { banner_msg .. " ", "PomonvimWarnText" },
        }
        vim.api.nvim_win_set_config(win, { footer = footer, footer_pos = "center" })
      else
        vim.api.nvim_win_set_config(win, { footer = "" })
      end
    end
  end
end

local function render(status)
  if not win or not vim.api.nvim_win_is_valid(win) or not buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  local width = config.opts.width or 88
  local col1_w = 36
  local col2_w = width - col1_w - 1
  local content_rows = 18

  status = status or timer.get_status()
  local cycles = state.get_cycles()
  local saved = state.get_saved_pomodoros()
  local num_saved = #saved
  local total_items = get_total_menu_items()

  selected_idx = math_max(1, math_min(selected_idx, total_items))

  if total_items <= content_rows then
    list_start = 1
  else
    if selected_idx < list_start then
      list_start = selected_idx
    elseif selected_idx > list_start + content_rows - 1 then
      list_start = selected_idx - content_rows + 1
    end
    list_start = math_max(1, math_min(list_start, total_items - content_rows + 1))
  end

  local is_previewing = false
  local display_cycles = cycles
  local preview_name = nil

  if selected_idx > 3 and selected_idx <= 3 + num_saved then
    local s_idx = selected_idx - 3
    local s_item = saved[s_idx]
    if s_item and s_item.cycles then
      if loaded_saved_idx == s_idx and #cycles > 0 then
        is_previewing = false
        display_cycles = cycles
      else
        is_previewing = true
        display_cycles = s_item.cycles
        preview_name = s_item.name
      end
    end
  end

  local lines = {}
  table.insert(lines, str_rep(" ", width))

  local clock_rows = render_digits(status.formatted_time)
  for _, row in ipairs(clock_rows) do
    table.insert(lines, center_text(row, width))
  end
  table.insert(lines, str_rep(" ", width))
  table.insert(lines, center_text(render_progress_bar(status.percent, 36), width))
  table.insert(lines, str_rep("─", col1_w) .. "┬" .. str_rep("─", col2_w))

  local header_row, is_next_focus, next_badge = build_header(cycles, col1_w, col2_w, is_previewing, preview_name)
  table.insert(lines, header_row)

  local left_lines = build_left_lines(selected_idx, status.running, content_rows, list_start, saved, col1_w)
  local right_lines, rendered_cycles_count =
    build_right_lines(display_cycles, status.active_cycle_idx, state.all_completed, col2_w, is_previewing)

  for r = 1, content_rows do
    table.insert(lines, pad_cell(left_lines[r], col1_w) .. "│" .. pad_cell(right_lines[r], col2_w))
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  apply_highlights(buf, lines, status, cycles, is_next_focus, next_badge,
    selected_idx, list_start, rendered_cycles_count, num_saved, is_previewing, display_cycles)

  update_window_footer(win, banner_msg)
end

local function show_banner(msg)
  banner_msg = msg
  if banner_timer then
    pcall(function()
      banner_timer:stop()
      banner_timer:close()
    end)
    banner_timer = nil
  end
  banner_timer = vim.defer_fn(function()
    banner_msg = nil
    banner_timer = nil
    if M.is_open() then
      render()
    end
  end, 2500)
  render()
end

local function open_save_dialog()
  if save_win and vim.api.nvim_win_is_valid(save_win) then
    return
  end

  local dlg_w = math_min(46, vim.o.columns - 4)
  local dlg_h = 1
  local dlg_col = math_floor((vim.o.columns - dlg_w) / 2)
  local dlg_row = math_floor((vim.o.lines - dlg_h) / 2)

  save_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = save_buf })
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = save_buf })
  vim.api.nvim_set_option_value("swapfile", false, { buf = save_buf })
  vim.api.nvim_set_option_value("filetype", "pomonvim_save", { buf = save_buf })

  local save_win_opts = {
    relative = "editor",
    row = dlg_row,
    col = dlg_col,
    width = dlg_w,
    height = dlg_h,
    border = "rounded",
    style = "minimal",
    title = " Salvar Pomodoro ",
    title_pos = "center",
    footer = " <Enter> salvar • <Esc> cancelar ",
    footer_pos = "center",
  }

  save_win = vim.api.nvim_open_win(save_buf, true, save_win_opts)
  vim.api.nvim_set_option_value(
    "winhighlight",
    "Normal:PomonvimNormal,NormalFloat:PomonvimNormal,FloatBorder:PomonvimHeader,FloatTitle:PomonvimHeader,FloatFooter:PomonvimMuted",
    { win = save_win }
  )
  vim.api.nvim_set_option_value("cursorline", false, { win = save_win })
  vim.api.nvim_set_option_value("wrap", false, { win = save_win })

  vim.api.nvim_buf_set_lines(save_buf, 0, -1, false, { "" })

  local function close_save_dialog()
    vim.cmd("stopinsert")
    if save_win and vim.api.nvim_win_is_valid(save_win) then
      pcall(vim.api.nvim_win_close, save_win, true)
      save_win = nil
    end
    if save_buf and vim.api.nvim_buf_is_valid(save_buf) then
      pcall(vim.api.nvim_buf_delete, save_buf, { force = true })
      save_buf = nil
    end
    if win and vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_set_current_win(win)
    end
  end

  local function do_save()
    local text = ""
    if save_buf and vim.api.nvim_buf_is_valid(save_buf) then
      local b_lines = vim.api.nvim_buf_get_lines(save_buf, 0, 1, false)
      text = b_lines[1] or ""
    end
    local name = text:match("^%s*(.-)%s*$")
    close_save_dialog()

    if not name or name == "" then
      show_banner("Nome vazio! Pomodoro não foi salvo.")
      return
    end

    local ok, err = state.save_pomodoro(name)
    if ok then
      local saved = state.get_saved_pomodoros()
      local new_s_idx = #saved
      for idx, sp in ipairs(saved) do
        if sp.name == name then
          new_s_idx = idx
          break
        end
      end

      -- Limpa a sequência ativa para mostrar apenas o preview do item salvo
      state.clear_cycles()
      timer.sync_with_cycle()
      loaded_saved_idx = nil

      -- Posiciona a seleção no item salvo recém-criado para mostrar seu preview
      selected_idx = 3 + new_s_idx

      show_banner(str_format("Pomodoro '%s' salvo! Pressione <Enter> nele para colocar no grupo.", name))
    else
      show_banner(err or "Erro ao salvar pomodoro!")
    end
    render()
  end

  local map_dlg = function(mode, lhs, rhs)
    vim.keymap.set(mode, lhs, rhs, { buffer = save_buf, silent = true, nowait = true })
  end

  map_dlg("n", "<CR>", do_save)
  map_dlg("i", "<CR>", do_save)
  map_dlg("n", "<Esc>", close_save_dialog)
  map_dlg("i", "<Esc>", close_save_dialog)
  map_dlg("n", "q", close_save_dialog)
  map_dlg("i", "<C-c>", close_save_dialog)
  map_dlg("n", "<C-c>", close_save_dialog)

  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(save_win),
    once = true,
    callback = function()
      save_win = nil
      save_buf = nil
    end,
  })

  vim.cmd("startinsert!")
end

local function build_help_content(lang, width)
  local tab1_text = "   Português   "
  local tab2_text = "   English   "
  local sep = "│"
  local hint_text = (lang == "pt") and "       h/l: alternar idioma" or "       h/l: switch language"
  local tab_row = tab1_text .. sep .. tab2_text .. hint_text
  local div_row = str_rep("─", width)

  local lines = {}
  table.insert(lines, tab_row)
  table.insert(lines, div_row)

  if lang == "pt" then
    table.insert(lines, " 󰋖 COMO FUNCIONA O POMONVIM:")
    table.insert(lines, "  • Montagem de Ciclos:")
    table.insert(lines, "    Adicione tempos alternando entre FOCO (verde) e DESCANSO (vermelho).")
    table.insert(lines, "  • Salvar Rotinas:")
    table.insert(lines, "    Com a sequência montada, use 'SALVAR POMODORO' para guardar a rotina.")
    table.insert(lines, "  • Preview e Uso:")
    table.insert(lines, "    Passe pelas rotinas para ver o preview. Pressione <Enter> para carregar.")
    table.insert(lines, "")
    table.insert(lines, " 󰌌 TECLAS DE ATALHO:")
    table.insert(lines, "  <Space>        Iniciar / Pausar cronômetro")
    table.insert(lines, "  <Enter>        Executar ação / Carregar rotina / Adicionar tempo")
    table.insert(lines, "  j / k, ↓ / ↑   Navegar pelas opções do menu")
    table.insert(lines, "  h / l, ← / →   Alternar idioma da ajuda (Português / English)")
    table.insert(lines, "  n / p          Avançar para próximo / ciclo anterior")
    table.insert(lines, "  r              Reiniciar tempo do ciclo atual")
    table.insert(lines, "  x              Excluir rotina salva selecionada")
    table.insert(lines, "  <BS>           Remover último ciclo da sequência")
    table.insert(lines, "  d              Excluir rotina salva ou remover último ciclo")
    table.insert(lines, "  c              Limpar todos os ciclos montados")
    table.insert(lines, "  ?              Abrir esta janela de ajuda")
    table.insert(lines, "  q / <Esc>      Fechar ajuda / fechar menu")
    table.insert(lines, "")
    table.insert(lines, "             Pressione q, <Esc> ou <Enter> para fechar")
  else
    table.insert(lines, " 󰋖 HOW POMONVIM WORKS:")
    table.insert(lines, "  • Cycle Building:")
    table.insert(lines, "    Add intervals on the left alternating FOCUS (green) and BREAK (red).")
    table.insert(lines, "  • Save Routines:")
    table.insert(lines, "    Once sequence is set, use 'SALVAR POMODORO' to save your routine.")
    table.insert(lines, "  • Preview & Load:")
    table.insert(lines, "    Hover over saved routines for preview. Press <Enter> to load them.")
    table.insert(lines, "")
    table.insert(lines, " 󰌌 KEYBINDINGS:")
    table.insert(lines, "  <Space>        Start / Pause timer")
    table.insert(lines, "  <Enter>        Execute action / Load routine / Add interval")
    table.insert(lines, "  j / k, ↓ / ↑   Navigate menu options")
    table.insert(lines, "  h / l, ← / →   Switch help language (Português / English)")
    table.insert(lines, "  n / p          Next / previous cycle")
    table.insert(lines, "  r              Restart current cycle timer")
    table.insert(lines, "  x              Delete selected saved routine")
    table.insert(lines, "  <BS>           Remove last cycle from sequence")
    table.insert(lines, "  d              Delete saved routine or remove last cycle")
    table.insert(lines, "  c              Clear all configured cycles")
    table.insert(lines, "  ?              Open this help window")
    table.insert(lines, "  q / <Esc>      Close help / close menu")
    table.insert(lines, "")
    table.insert(lines, "             Press q, <Esc> or <Enter> to close")
  end

  return lines, tab1_text, tab2_text, sep
end

local function render_help(h_buf, lang, width)
  local lines, tab1_text, tab2_text, sep = build_help_content(lang, width)
  vim.api.nvim_buf_set_lines(h_buf, 0, -1, false, lines)

  local help_ns = vim.api.nvim_create_namespace("pomonvim_help")
  vim.api.nvim_buf_clear_namespace(h_buf, help_ns, 0, -1)

  local tab1_len = #tab1_text
  local sep_len = #sep
  local tab2_len = #tab2_text

  local t1_hl = (lang == "pt") and "PomonvimSelectedHelp" or "PomonvimMuted"
  local t2_hl = (lang == "en") and "PomonvimSelectedHelp" or "PomonvimMuted"

  vim.api.nvim_buf_add_highlight(h_buf, help_ns, t1_hl, 0, 0, tab1_len)
  vim.api.nvim_buf_add_highlight(h_buf, help_ns, "PomonvimBorder", 0, tab1_len, tab1_len + sep_len)
  vim.api.nvim_buf_add_highlight(h_buf, help_ns, t2_hl, 0, tab1_len + sep_len, tab1_len + sep_len + tab2_len)

  local hint_start = tab1_len + sep_len + tab2_len
  vim.api.nvim_buf_add_highlight(h_buf, help_ns, "PomonvimMuted", 0, hint_start, -1)

  local tab_row_text = lines[1] or ""
  local hl_pos = tab_row_text:find("h/l", hint_start, true)
  if hl_pos then
    vim.api.nvim_buf_add_highlight(h_buf, help_ns, "PomonvimKey", 0, hl_pos - 1, hl_pos - 1 + 3)
  end

  vim.api.nvim_buf_add_highlight(h_buf, help_ns, "PomonvimBorder", 1, 0, -1)

  for line_idx = 3, #lines do
    local r = line_idx - 1
    local line = lines[line_idx]

    if line:find("󰋖", 1, true) or line:find("󰌌", 1, true) then
      vim.api.nvim_buf_add_highlight(h_buf, help_ns, "PomonvimHeader", r, 0, -1)
    elseif line:find("•", 1, true) then
      local colon = line:find(":", 1, true)
      if colon then
        vim.api.nvim_buf_add_highlight(h_buf, help_ns, "PomonvimKey", r, 0, colon)
      end
    elseif line:find("Pressione q", 1, true) or line:find("Press q", 1, true) then
      vim.api.nvim_buf_add_highlight(h_buf, help_ns, "PomonvimMuted", r, 0, -1)
    else
      local key_pat = line:match("^  (%S.-)%s%s+")
      if key_pat then
        local sp_end = line:find("  ", 3, true)
        if sp_end then
          vim.api.nvim_buf_add_highlight(h_buf, help_ns, "PomonvimKey", r, 2, sp_end)
        end
      end
    end

    local f_start = line:find("FOCO", 1, true) or line:find("FOCUS", 1, true)
    if f_start then
      local f_len = line:find("FOCO", 1, true) and #"FOCO" or #"FOCUS"
      vim.api.nvim_buf_add_highlight(h_buf, help_ns, "PomonvimFocus", r, f_start - 1, f_start - 1 + f_len)
    end

    local d_start = line:find("DESCANSO", 1, true) or line:find("BREAK", 1, true)
    if d_start then
      local d_len = line:find("DESCANSO", 1, true) and #"DESCANSO" or #"BREAK"
      vim.api.nvim_buf_add_highlight(h_buf, help_ns, "PomonvimSleep", r, d_start - 1, d_start - 1 + d_len)
    end
  end
end

local function open_help_dialog()
  if help_win and vim.api.nvim_win_is_valid(help_win) then
    vim.api.nvim_set_current_win(help_win)
    return
  end

  local sample_lines = build_help_content(current_help_lang, 74)
  local width = math_min(74, vim.o.columns - 4)
  local height = math_min(#sample_lines, vim.o.lines - 4)
  local col = math_floor((vim.o.columns - width) / 2)
  local row = math_floor((vim.o.lines - height) / 2) - 1

  help_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = help_buf })
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = help_buf })
  vim.api.nvim_set_option_value("swapfile", false, { buf = help_buf })
  vim.api.nvim_set_option_value("filetype", "pomonvim_help", { buf = help_buf })

  local title_str = current_help_lang == "pt" and " Ajuda & Atalhos " or " Help & Keybindings "
  local win_opts = {
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    border = config.opts.border or "rounded",
    style = "minimal",
    title = title_str,
    title_pos = "center",
  }

  help_win = vim.api.nvim_open_win(help_buf, true, win_opts)
  vim.api.nvim_set_option_value("winhighlight", "Normal:PomonvimNormal,NormalFloat:PomonvimNormal,FloatBorder:PomonvimBorder", { win = help_win })
  vim.api.nvim_set_option_value("cursorline", false, { win = help_win })
  vim.api.nvim_set_option_value("wrap", false, { win = help_win })

  render_help(help_buf, current_help_lang, width)

  local function close_help_dialog()
    if help_win and vim.api.nvim_win_is_valid(help_win) then
      pcall(vim.api.nvim_win_close, help_win, true)
      help_win = nil
    end
    if help_buf and vim.api.nvim_buf_is_valid(help_buf) then
      pcall(vim.api.nvim_buf_delete, help_buf, { force = true })
      help_buf = nil
    end
    if win and vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_set_current_win(win)
    end
  end

  local function switch_lang(new_lang)
    current_help_lang = new_lang
    if help_win and vim.api.nvim_win_is_valid(help_win) then
      local t_str = current_help_lang == "pt" and " Ajuda & Atalhos " or " Help & Keybindings "
      vim.api.nvim_win_set_config(help_win, {
        title = t_str,
        title_pos = "center",
      })
    end
    render_help(help_buf, current_help_lang, width)
  end

  local map_hlp = function(lhs, rhs)
    vim.keymap.set("n", lhs, rhs, { buffer = help_buf, silent = true, nowait = true })
  end

  map_hlp("q", close_help_dialog)
  map_hlp("<Esc>", close_help_dialog)
  map_hlp("<CR>", close_help_dialog)
  map_hlp("?", close_help_dialog)

  map_hlp("h", function()
    switch_lang("pt")
  end)
  map_hlp("<Left>", function()
    switch_lang("pt")
  end)
  map_hlp("l", function()
    switch_lang("en")
  end)
  map_hlp("<Right>", function()
    switch_lang("en")
  end)
  map_hlp("<Tab>", function()
    switch_lang(current_help_lang == "pt" and "en" or "pt")
  end)

  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(help_win),
    once = true,
    callback = function()
      help_win = nil
      help_buf = nil
    end,
  })
end

local function close()
  loaded_saved_idx = nil
  if banner_timer then
    pcall(function()
      banner_timer:stop()
      banner_timer:close()
    end)
    banner_timer = nil
  end
  banner_msg = nil
  current_footer_text = nil
  if save_win and vim.api.nvim_win_is_valid(save_win) then
    vim.cmd("stopinsert")
    pcall(vim.api.nvim_win_close, save_win, true)
    save_win = nil
  end
  if save_buf and vim.api.nvim_buf_is_valid(save_buf) then
    pcall(vim.api.nvim_buf_delete, save_buf, { force = true })
    save_buf = nil
  end
  if help_win and vim.api.nvim_win_is_valid(help_win) then
    pcall(vim.api.nvim_win_close, help_win, true)
    help_win = nil
  end
  if help_buf and vim.api.nvim_buf_is_valid(help_buf) then
    pcall(vim.api.nvim_buf_delete, help_buf, { force = true })
    help_buf = nil
  end
  if tick_callback then
    timer.remove_listener(tick_callback)
    tick_callback = nil
  end
  if resize_autocmd then
    pcall(vim.api.nvim_del_autocmd, resize_autocmd)
    resize_autocmd = nil
  end
  if win and vim.api.nvim_win_is_valid(win) then
    pcall(vim.api.nvim_win_close, win, true)
    win = nil
  end
  if buf and vim.api.nvim_buf_is_valid(buf) then
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
    buf = nil
  end
end

function M.is_open()
  return win ~= nil and vim.api.nvim_win_is_valid(win)
end

function M.open()
  if M.is_open() then
    return
  end

  setup_highlights()

  local width = math.min(config.opts.width or 88, vim.o.columns - 4)
  local height = math.min(config.opts.height or 26, vim.o.lines - 4)
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2) - 1

  buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
  vim.api.nvim_set_option_value("swapfile", false, { buf = buf })
  vim.api.nvim_set_option_value("filetype", "pomonvim", { buf = buf })

  local win_opts = {
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    border = config.opts.border or "rounded",
    style = "minimal",
    title = " pomonvim ",
    title_pos = "center",
  }

  win = vim.api.nvim_open_win(buf, true, win_opts)
  vim.api.nvim_set_option_value("winhighlight", "Normal:PomonvimNormal,NormalFloat:PomonvimNormal,FloatBorder:PomonvimBorder", { win = win })
  vim.api.nvim_set_option_value("cursorline", false, { win = win })
  vim.api.nvim_set_option_value("wrap", false, { win = win })

  selected_idx = 1
  list_start = 1
  banner_msg = nil
  current_footer_text = nil

  render()

  tick_callback = function(status)
    if M.is_open() then
      vim.schedule(function()
        if M.is_open() then
          render(status)
        end
      end)
    end
  end
  timer.on_tick(tick_callback)

  -- Keybindings
  local map = function(lhs, rhs, desc)
    vim.keymap.set("n", lhs, rhs, { buffer = buf, silent = true, nowait = true, desc = desc })
  end

  map("q", close, "Fechar menu")
  map("<Esc>", close, "Fechar menu")

  map("j", function()
    selected_idx = math_min(get_total_menu_items(), selected_idx + 1)
    render()
  end, "Descer na lista")
  map("<Down>", function()
    selected_idx = math_min(get_total_menu_items(), selected_idx + 1)
    render()
  end, "Descer na lista")

  map("k", function()
    selected_idx = math_max(1, selected_idx - 1)
    render()
  end, "Subir na lista")
  map("<Up>", function()
    selected_idx = math_max(1, selected_idx - 1)
    render()
  end, "Subir na lista")

  map("<Space>", function()
    if not timer.running and #state.get_cycles() == 0 then
      show_banner("Adicione ao menos um tempo (foco) antes de iniciar!")
    else
      timer.toggle()
    end
    render()
  end, "Iniciar / Pausar timer")

  map("<CR>", function()
    local saved = state.get_saved_pomodoros()
    local num_saved = #saved

    if selected_idx == 1 then
      -- START / PAUSE option
      if timer.running then
        timer.pause()
      else
        local cycles = state.get_cycles()
        if #cycles == 0 then
          show_banner("Adicione ao menos um tempo (foco) antes de iniciar!")
        else
          timer.start()
        end
      end
      render()
    elseif selected_idx == 2 then
      -- CLEAR option (não permite limpar sem pausar primeiro)
      if timer.running then
        show_banner("Pause o pomodoro antes de limpar os ciclos!")
      else
        loaded_saved_idx = nil
        state.clear_cycles()
        timer.sync_with_cycle()
        render()
      end
    elseif selected_idx == 3 then
      -- SAVE option
      if timer.running then
        show_banner("Pause o pomodoro antes de salvar!")
      elseif #state.get_cycles() == 0 then
        show_banner("Monte uma sequência de ciclos antes de salvar!")
      else
        open_save_dialog()
      end
    elseif selected_idx > 3 and selected_idx <= 3 + num_saved then
      -- LOAD saved routine into group
      if timer.running then
        show_banner("Pause o pomodoro antes de carregar uma rotina!")
      else
        local s_idx = selected_idx - 3
        local s_item = saved[s_idx]
        if s_item then
          state.load_saved_pomodoro(s_idx)
          timer.sync_with_cycle()
          loaded_saved_idx = s_idx
          show_banner(str_format("Rotina '%s' colocada no grupo de ciclos!", s_item.name))
          render()
        end
      end
    elseif selected_idx > 3 + num_saved and selected_idx <= 3 + num_saved + #TIME_OPTIONS then
      -- Add selected duration to routine (alternating focus/sleep)
      if timer.running then
        show_banner("Pause o pomodoro antes de adicionar mais ciclos!")
      else
        local opt = TIME_OPTIONS[selected_idx - 3 - num_saved]
        if opt then
          loaded_saved_idx = nil
          state.add_cycle(opt.duration, opt.label)
          if not timer.running and #state.get_cycles() == 1 then
            timer.sync_with_cycle()
          end
          render()
        end
      end
    elseif selected_idx == 3 + num_saved + #TIME_OPTIONS + 1 then
      -- HELP option
      open_help_dialog()
    end
  end, "Executar ação / Carregar rotina / Adicionar tempo / Ajuda")

  map("<BS>", function()
    if timer.running then
      show_banner("Pause o pomodoro antes de alterar os ciclos!")
    else
      loaded_saved_idx = nil
      state.remove_last_cycle()
      timer.sync_with_cycle()
      render()
    end
  end, "Remover último ciclo")

  map("d", function()
    if timer.running then
      show_banner("Pause o pomodoro antes de alterar os ciclos!")
    else
      local saved = state.get_saved_pomodoros()
      local num_saved = #saved
      if selected_idx > 3 and selected_idx <= 3 + num_saved then
        local s_idx = selected_idx - 3
        local s_item = saved[s_idx]
        local s_name = s_item and s_item.name or "Pomodoro"
        state.delete_saved_pomodoro(s_idx)
        if loaded_saved_idx == s_idx then
          loaded_saved_idx = nil
        end
        selected_idx = math_min(selected_idx, get_total_menu_items())
        show_banner(str_format("Rotina '%s' excluída!", s_name))
        render()
      else
        loaded_saved_idx = nil
        state.remove_last_cycle()
        timer.sync_with_cycle()
        render()
      end
    end
  end, "Remover último ciclo ou excluir rotina salva")

  map("x", function()
    local saved = state.get_saved_pomodoros()
    local num_saved = #saved
    if selected_idx > 3 and selected_idx <= 3 + num_saved then
      if timer.running then
        show_banner("Pause o pomodoro antes de excluir uma rotina!")
      else
        local s_idx = selected_idx - 3
        local s_item = saved[s_idx]
        local s_name = s_item and s_item.name or "Pomodoro"
        state.delete_saved_pomodoro(s_idx)
        if loaded_saved_idx == s_idx then
          loaded_saved_idx = nil
        end
        selected_idx = math_min(selected_idx, get_total_menu_items())
        show_banner(str_format("Rotina '%s' excluída!", s_name))
        render()
      end
    else
      show_banner("Selecione uma rotina salva para excluir com 'x'")
    end
  end, "Excluir rotina salva selecionada")

  map("c", function()
    if timer.running then
      show_banner("Pause o pomodoro antes de limpar os ciclos!")
    else
      loaded_saved_idx = nil
      state.clear_cycles()
      timer.sync_with_cycle()
      render()
    end
  end, "Limpar todos os ciclos")

  map("r", function()
    timer.reset()
    render()
  end, "Reiniciar timer")

  map("n", function()
    timer.next()
    render()
  end, "Próximo ciclo")

  map("p", function()
    timer.prev()
    render()
  end, "Ciclo anterior")

  map("?", function()
    open_help_dialog()
  end, "Ajuda e atalhos")

  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(win),
    once = true,
    callback = close,
  })

  resize_autocmd = vim.api.nvim_create_autocmd("VimResized", {
    callback = function()
      if not win or not vim.api.nvim_win_is_valid(win) then
        return
      end
      local w = math.min(config.opts.width or 88, vim.o.columns - 4)
      local h = math.min(config.opts.height or 26, vim.o.lines - 4)
      local c = math.floor((vim.o.columns - w) / 2)
      local r = math.floor((vim.o.lines - h) / 2) - 1
      vim.api.nvim_win_set_config(win, {
        relative = "editor",
        row = r,
        col = c,
        width = w,
        height = h,
      })
      if save_win and vim.api.nvim_win_is_valid(save_win) then
        local dw = math_min(46, vim.o.columns - 4)
        local dh = 1
        local dc = math_floor((vim.o.columns - dw) / 2)
        local dr = math_floor((vim.o.lines - dh) / 2)
        vim.api.nvim_win_set_config(save_win, {
          relative = "editor",
          row = dr,
          col = dc,
          width = dw,
          height = dh,
        })
      end
      if help_win and vim.api.nvim_win_is_valid(help_win) then
        local hw = math_min(74, vim.o.columns - 4)
        local hh = math_min(25, vim.o.lines - 4)
        local hc = math_floor((vim.o.columns - hw) / 2)
        local hr = math_floor((vim.o.lines - hh) / 2) - 1
        vim.api.nvim_win_set_config(help_win, {
          relative = "editor",
          row = hr,
          col = hc,
          width = hw,
          height = hh,
        })
        if help_buf and vim.api.nvim_buf_is_valid(help_buf) then
          render_help(help_buf, current_help_lang, hw)
        end
      end
      render()
    end,
  })
end

function M.close()
  close()
end

function M.toggle()
  if M.is_open() then
    M.close()
  else
    M.open()
  end
end

return M
