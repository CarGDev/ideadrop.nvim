-- ideaDrop/ui/tree.lua
local config = require("ideaDrop.core.config")

---@class Tree
---@field open_tree_window fun(callback: fun(file_path: string): nil): nil
local M = {}

-- Tree state
local tree_callback = nil
local original_cwd = nil
local ideadrop_tree_autocmd_group = nil

---Opens nvim-tree focused on the idea directory
---@param callback fun(file_path: string): nil Callback function when a file is selected
---@return nil
function M.open_tree_window(callback)
	tree_callback = callback
	
	-- Check if nvim-tree is available
	local has_nvim_tree_api, nvim_tree_api = pcall(require, "nvim-tree.api")
	if not has_nvim_tree_api then
		vim.notify("❌ nvim-tree is not installed. Please install nvim-tree to use this feature.", vim.log.levels.ERROR)
		return
	end
	
	-- Store original working directory
	original_cwd = vim.fn.getcwd()
	
	-- Change to idea directory
	local idea_path = config.options.idea_dir
	if vim.fn.isdirectory(idea_path) == 0 then
		-- Create the directory if it doesn't exist
		vim.fn.mkdir(idea_path, "p")
	end
	
	-- Create autocmd group for ideaDrop tree handling
	if ideadrop_tree_autocmd_group then
		vim.api.nvim_del_augroup_by_id(ideadrop_tree_autocmd_group)
	end
	ideadrop_tree_autocmd_group = vim.api.nvim_create_augroup("IdeaDropTree", { clear = true })
	
	-- Set up autocmd to handle file selection from nvim-tree
	vim.api.nvim_create_autocmd("BufEnter", {
		group = ideadrop_tree_autocmd_group,
		callback = function(args)
			local bufname = vim.api.nvim_buf_get_name(args.buf)
			-- Check if this is a markdown file in the idea directory
			if bufname:match("%.md$") and bufname:find(idea_path, 1, true) then
				-- Call our callback with the selected file
				if tree_callback then
					-- Close nvim-tree
					nvim_tree_api.tree.close()
					-- Restore original working directory
					if original_cwd then
						vim.cmd("cd " .. vim.fn.fnameescape(original_cwd))
					end
					-- Use vim.schedule to avoid issues with buffer switching
					vim.schedule(function()
						tree_callback(bufname)
					end)
					-- Clear the autocmd group after handling
					vim.api.nvim_del_augroup_by_id(ideadrop_tree_autocmd_group)
					ideadrop_tree_autocmd_group = nil
				end
			end
		end,
	})
	
	-- Set up autocmd to restore cwd when nvim-tree is closed
	vim.api.nvim_create_autocmd("BufLeave", {
		group = ideadrop_tree_autocmd_group,
		pattern = "NvimTree_*",
		callback = function()
			-- Restore original working directory when leaving nvim-tree
			if original_cwd then
				vim.schedule(function()
					-- Only restore if we're not in an idea file
					local current_buf = vim.api.nvim_get_current_buf()
					local bufname = vim.api.nvim_buf_get_name(current_buf)
					if not (bufname:match("%.md$") and bufname:find(idea_path, 1, true)) then
						vim.cmd("cd " .. vim.fn.fnameescape(original_cwd))
					end
				end)
			end
		end,
	})
	
	-- Open nvim-tree in the idea directory (without calling setup)
	-- This preserves the user's nvim-tree configuration
	nvim_tree_api.tree.open({ path = idea_path })
end

return M 