-- ideaDrop/utils/keymaps.lua
local M = {}

---Setup function for keymaps
---@return nil
function M.setup()
	-- Global keymaps for ideaDrop
	-- These can be customized by users in their config
	
	-- Example: Quick access to ideaDrop commands
	-- vim.keymap.set("n", "<leader>id", ":IdeaRight<CR>", { desc = "Open today's idea" })
	-- vim.keymap.set("n", "<leader>it", ":IdeaTree<CR>", { desc = "Open idea tree" })
	-- vim.keymap.set("n", "<leader>is", ":IdeaSearch ", { desc = "Search ideas" })
	-- vim.keymap.set("n", "<leader>it", ":IdeaTags<CR>", { desc = "Browse tags" })
	
	-- Note: Keymaps are commented out by default to avoid conflicts
	-- Users can uncomment and customize these in their config
end

return M
