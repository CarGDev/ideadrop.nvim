-- ideaDrop/utils/keymaps.lua
local M = {}

---Setup function for keymaps
---@return nil
function M.setup()
	-- Global keymaps for ideaDrop
	-- These can be customized by users in their config
	
	-- Example: Quick access to ideaDrop commands
	-- vim.keymap.set("n", "<leader>id", ":IdeaRight<CR>", { desc = "Open today's idea" })
	-- vim.keymap.set("n", "<leader>in", ":IdeaRight ", { desc = "Open named idea" })
	-- vim.keymap.set("n", "<leader>it", ":IdeaTree<CR>", { desc = "Open idea tree" })
	-- vim.keymap.set("n", "<leader>is", ":IdeaSearch ", { desc = "Search ideas" })
	-- vim.keymap.set("n", "<leader>ig", ":IdeaTags<CR>", { desc = "Browse tags" })
	-- vim.keymap.set("n", "<leader>if", ":Idea<CR>", { desc = "Open today's idea in float" })
	-- vim.keymap.set("n", "<leader>iG", ":IdeaGraph<CR>", { desc = "Open graph visualization" })
	
	-- Note: Keymaps are commented out by default to avoid conflicts
	-- Users can uncomment and customize these in their config
end

return M
