if vim.g.loaded_pomonvim then
  return
end
vim.g.loaded_pomonvim = 1

vim.api.nvim_create_user_command("Pomonvim", function()
  require("pomonvim").toggle()
end, { desc = "Toggle Pomonvim Pomodoro menu" })

vim.api.nvim_create_user_command("PomoNvim", function()
  require("pomonvim").toggle()
end, { desc = "Toggle Pomonvim Pomodoro menu" })

vim.api.nvim_create_user_command("Pomo", function()
  require("pomonvim").toggle()
end, { desc = "Toggle Pomonvim Pomodoro menu" })

vim.api.nvim_create_user_command("Pomoxx", function()
  require("pomonvim").toggle()
end, { desc = "Toggle Pomonvim Pomodoro menu" })

-- Map <space>p in Normal mode
vim.keymap.set("n", "<space>p", function()
  require("pomonvim").toggle()
end, { silent = true, desc = "Pomonvim Pomodoro Menu" })
