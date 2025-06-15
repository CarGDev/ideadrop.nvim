-- ideaDrop/keymaps.lua
---@class Keymaps
---@field setup fun(): nil
local M = {}

---Sets up default keymaps for ideaDrop
---Currently only sets up a demo keymap
---@return nil
function M.setup()
  -- Demo keymap for idea capture
  vim.keymap.set("n", "<leader>id", function()
    vim.notify("💡 Idea captured!")
  end, { desc = "Drop idea (demo)" })
end

return M
