-- ideaDrop/ui/tree.lua
local config = require("ideaDrop.core.config")

---@class Tree
---@field open_tree_window fun(callback: fun(file_path: string): nil): nil
local M = {}

-- Tree state
local tree_callback = nil
local original_cwd = nil

---Opens nvim-tree focused on the idea directory
---@param callback fun(file_path: string): nil Callback function when a file is selected
---@return nil
function M.open_tree_window(callback)
	tree_callback = callback
	
	-- Check if nvim-tree is available
	local has_nvim_tree, nvim_tree = pcall(require, "nvim-tree")
	if not has_nvim_tree then
		vim.notify("❌ nvim-tree is not installed. Please install nvim-tree to use this feature.", vim.log.levels.ERROR)
		return
	end
	
	-- Store original working directory
	original_cwd = vim.fn.getcwd()
	
	-- Change to idea directory
	local idea_path = config.options.idea_dir
	if vim.fn.isdirectory(idea_path) == 1 then
		vim.cmd("cd " .. vim.fn.fnameescape(idea_path))
	else
		vim.notify("❌ Idea directory not found: " .. idea_path, vim.log.levels.ERROR)
		return
	end
	
	-- Set up nvim-tree to open on the left side
	nvim_tree.setup({
		view = {
			side = "left",
			width = 30,
		},
		actions = {
			open_file = {
				quit_on_open = false,
			},
		},
		on_attach = function(bufnr)
			-- Override the default file opening behavior
			local api = require("nvim-tree.api")
			
			-- Map Enter to custom handler
			vim.keymap.set("n", "<CR>", function()
				local node = api.tree.get_node_under_cursor()
				if node and node.type == "file" then
					-- Call our callback with the selected file
					if tree_callback then
						tree_callback(node.absolute_path)
					end
					-- Close nvim-tree
					api.tree.close()
					-- Restore original working directory
					if original_cwd then
						vim.cmd("cd " .. vim.fn.fnameescape(original_cwd))
					end
				else
					-- Default behavior for directories
					api.node.open.edit()
				end
			end, { buffer = bufnr, noremap = true, silent = true })
			
			-- Map 'q' to close tree and restore directory
			vim.keymap.set("n", "q", function()
				api.tree.close()
				if original_cwd then
					vim.cmd("cd " .. vim.fn.fnameescape(original_cwd))
				end
			end, { buffer = bufnr, noremap = true, silent = true })
			
			-- Keep other default mappings
			vim.keymap.set("n", "<C-]>", api.tree.change_root_to_node, { buffer = bufnr, noremap = true, silent = true })
			vim.keymap.set("n", "<C-e>", api.node.open.replace_tree_buffer, { buffer = bufnr, noremap = true, silent = true })
			vim.keymap.set("n", "<C-k>", api.node.show_info_popup, { buffer = bufnr, noremap = true, silent = true })
			vim.keymap.set("n", "<C-r>", api.fs.rename_sub, { buffer = bufnr, noremap = true, silent = true })
			vim.keymap.set("n", "<C-t>", api.node.open.tab, { buffer = bufnr, noremap = true, silent = true })
			vim.keymap.set("n", "<C-v>", api.node.open.vertical, { buffer = bufnr, noremap = true, silent = true })
			vim.keymap.set("n", "<C-x>", api.node.open.horizontal, { buffer = bufnr, noremap = true, silent = true })
			vim.keymap.set("n", "<BS>", api.node.navigate.parent_close, { buffer = bufnr, noremap = true, silent = true })
			vim.keymap.set("n", "<Tab>", api.node.open.preview, { buffer = bufnr, noremap = true, silent = true })
			vim.keymap.set("n", ">", api.node.navigate.sibling.next, { buffer = bufnr, noremap = true, silent = true })
			vim.keymap.set("n", "<", api.node.navigate.sibling.prev, { buffer = bufnr, noremap = true, silent = true })
			vim.keymap.set("n", ".", api.node.run.cmd, { buffer = bufnr, noremap = true, silent = true })
			vim.keymap.set("n", "-", api.tree.change_root_to_parent, { buffer = bufnr, noremap = true, silent = true })
			vim.keymap.set("n", "a", api.fs.create, { buffer = bufnr, noremap = true, silent = true })
			vim.keymap.set("n", "bmv", api.marks.bulk.move, { buffer = bufnr, noremap = true, silent = true })
			vim.keymap.set("n", "B", api.tree.toggle_no_buffer_filter, { buffer = bufnr, noremap = true, silent = true })
			vim.keymap.set("n", "c", api.fs.copy.node, { buffer = bufnr, noremap = true, silent = true })
			vim.keymap.set("n", "C", api.tree.toggle_git_clean_filter, { buffer = bufnr, noremap = true, silent = true })
			vim.keymap.set("n", "[c", api.node.navigate.git.prev, { buffer = bufnr, noremap = true, silent = true })
			vim.keymap.set("n", "]c", api.node.navigate.git.next, { buffer = bufnr, noremap = true, silent = true })
			vim.keymap.set("n", "d", api.fs.remove, { buffer = bufnr, noremap = true, silent = true })
			vim.keymap.set("n", "D", api.fs.trash, { buffer = bufnr, noremap = true, silent = true })
			vim.keymap.set("n", "E", api.tree.expand_all, { buffer = bufnr, noremap = true, silent = true })
			vim.keymap.set("n", "e", api.fs.rename_basename, { buffer = bufnr, noremap = true, silent = true })
			vim.keymap.set("n", "]e", api.node.navigate.diagnostics.next, { buffer = bufnr, noremap = true, silent = true })
			vim.keymap.set("n", "[e", api.node.navigate.diagnostics.prev, { buffer = bufnr, noremap = true, silent = true })
			vim.keymap.set("n", "F", api.live_filter.clear, { buffer = bufnr, noremap = true, silent = true })
			vim.keymap.set("n", "f", api.live_filter.start, { buffer = bufnr, noremap = true, silent = true })
			vim.keymap.set("n", "g?", api.tree.toggle_help, { buffer = bufnr, noremap = true, silent = true })
			vim.keymap.set("n", "gy", api.fs.copy.absolute_path, { buffer = bufnr, noremap = true, silent = true })
			vim.keymap.set("n", "H", api.tree.toggle_hidden_filter, { buffer = bufnr, noremap = true, silent = true })
			vim.keymap.set("n", "I", api.tree.toggle_gitignore_filter, { buffer = bufnr, noremap = true, silent = true })
			vim.keymap.set("n", "J", api.node.navigate.sibling.last, { buffer = bufnr, noremap = true, silent = true })
			vim.keymap.set("n", "K", api.node.navigate.sibling.first, { buffer = bufnr, noremap = true, silent = true })
			vim.keymap.set("n", "m", api.marks.toggle, { buffer = bufnr, noremap = true, silent = true })
			vim.keymap.set("n", "o", api.node.open.edit, { buffer = bufnr, noremap = true, silent = true })
			vim.keymap.set("n", "O", api.node.open.no_window_picker, { buffer = bufnr, noremap = true, silent = true })
			vim.keymap.set("n", "P", api.node.navigate.parent, { buffer = bufnr, noremap = true, silent = true })
			vim.keymap.set("n", "r", api.fs.rename, { buffer = bufnr, noremap = true, silent = true })
			vim.keymap.set("n", "R", api.tree.reload, { buffer = bufnr, noremap = true, silent = true })
			vim.keymap.set("n", "s", api.node.run.system, { buffer = bufnr, noremap = true, silent = true })
			vim.keymap.set("n", "S", api.tree.search_node, { buffer = bufnr, noremap = true, silent = true })
			vim.keymap.set("n", "U", api.tree.toggle_custom_filter, { buffer = bufnr, noremap = true, silent = true })
			vim.keymap.set("n", "W", api.tree.collapse_all, { buffer = bufnr, noremap = true, silent = true })
			vim.keymap.set("n", "x", api.fs.cut, { buffer = bufnr, noremap = true, silent = true })
			vim.keymap.set("n", "y", api.fs.copy.filename, { buffer = bufnr, noremap = true, silent = true })
			vim.keymap.set("n", "Y", api.fs.copy.relative_path, { buffer = bufnr, noremap = true, silent = true })
			vim.keymap.set("n", "<2-LeftMouse>", api.node.open.edit, { buffer = bufnr, noremap = true, silent = true })
			vim.keymap.set("n", "<2-RightMouse>", api.tree.change_root_to_node, { buffer = bufnr, noremap = true, silent = true })
		end,
	})
	
	-- Open nvim-tree using the correct API
	local api = require("nvim-tree.api")
	api.tree.open()
end

return M 