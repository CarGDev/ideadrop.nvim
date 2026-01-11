-- ideaDrop/ui/sidebar.lua
local config = require("ideaDrop.core.config")
local tree = require("ideaDrop.ui.tree")

---@class Sidebar
---@field open fun(file: string|nil, filename: string|nil, use_buffer: boolean|nil): nil
---@field open_in_buffer fun(file: string|nil, filename: string|nil): nil
---@field open_right_side fun(file: string|nil, filename: string|nil): nil
---@field toggle_tree fun(): nil
---@field get_current_file fun(): string|nil
---@field save_idea fun(lines: string[], file: string|nil): nil
local M = {}

-- Global variables to track the right-side buffer and window
local right_side_buf = nil
local right_side_win = nil
local current_file = nil

---Opens a floating sidebar window with the specified file
---@param file string|nil Path to the file to open
---@param filename string|nil Name of the file (used for new files)
---@param use_buffer boolean|nil If true, opens in current buffer instead of floating window
---@return nil
function M.open(file, filename, use_buffer)
	if use_buffer then
		M.open_in_buffer(file, filename)
		return
	end

	-- Create a new buffer
	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].filetype = "markdown"

	-- Calculate window dimensions (30% of screen width, 80% of screen height)
	local width = math.floor(vim.o.columns * 0.3)
	local height = math.floor(vim.o.lines * 0.8)

	-- Create and configure the floating window
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = 1,
		col = 1,
		border = "rounded",
		style = "minimal",
	})

	-- Load file content or create new file template
	if file and vim.fn.filereadable(file) == 1 then
		local content = vim.fn.readfile(file)
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
	else
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
			"# " .. (filename or "Idea for " .. os.date("%Y-%m-%d")),
			"",
			"- ",
		})
	end

	-- Set up autosave on window close
	vim.api.nvim_create_autocmd("WinClosed", {
		pattern = tostring(win),
		once = true,
		callback = function()
			local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
			M.save_idea(lines, file)
		end,
	})
end

---Opens the idea file in the current buffer
---@param file string|nil Path to the file to open
---@param filename string|nil Name of the file (used for new files)
---@return nil
function M.open_in_buffer(file, filename)
	-- Create default path if none provided
	if not file then
		local idea_path = config.options.idea_dir
		if vim.fn.isdirectory(idea_path) == 0 then
			vim.fn.mkdir(idea_path, "p")
		end
		file = string.format("%s/%s.md", idea_path, os.date("%Y-%m-%d"))
	end

	-- Open the file in the current buffer
	vim.cmd("edit " .. vim.fn.fnameescape(file))

	-- If it's a new file, add template content
	if vim.fn.filereadable(file) == 0 then
		local template_lines = {
			"# " .. (filename or "Idea for " .. os.date("%Y-%m-%d")),
			"",
			"- ",
		}
		vim.api.nvim_buf_set_lines(0, 0, -1, false, template_lines)
	end

	-- Set up autosave on buffer write
	vim.api.nvim_create_autocmd("BufWritePost", {
		buffer = 0,
		callback = function()
			vim.notify("💾 Idea saved to " .. file, vim.log.levels.INFO)
		end,
	})
end

---Opens the idea file in a persistent right-side buffer
---@param file string|nil Path to the file to open
---@param filename string|nil Name of the file (used for new files)
---@return nil
function M.open_right_side(file, filename)
	-- Create default path if none provided
	if not file then
		local idea_path = config.options.idea_dir
		if vim.fn.isdirectory(idea_path) == 0 then
			vim.fn.mkdir(idea_path, "p")
		end
		file = string.format("%s/%s.md", idea_path, os.date("%Y-%m-%d"))
	end

	current_file = file

	-- Create buffer if it doesn't exist
	if not right_side_buf or not vim.api.nvim_buf_is_valid(right_side_buf) then
		right_side_buf = vim.api.nvim_create_buf(false, false)
		vim.bo[right_side_buf].filetype = "markdown"
		vim.bo[right_side_buf].buftype = "acwrite"
		vim.bo[right_side_buf].bufhidden = "hide"
		
		-- Set up autosave for the right-side buffer
		vim.api.nvim_create_autocmd("BufWriteCmd", {
			buffer = right_side_buf,
			callback = function()
				local lines = vim.api.nvim_buf_get_lines(right_side_buf, 0, -1, false)
				M.save_idea(lines, current_file)
				-- Prevent the default write behavior
				vim.api.nvim_command("setlocal nomodified")
			end,
		})
		
		-- Set up key mappings for the right-side buffer
		vim.api.nvim_buf_set_keymap(right_side_buf, "n", "<C-t>", "", {
			callback = function()
				M.toggle_tree()
			end,
			noremap = true,
			silent = true,
		})
		
		vim.api.nvim_buf_set_keymap(right_side_buf, "n", "<C-r>", "", {
			callback = function()
				M.refresh_current_file()
			end,
			noremap = true,
			silent = true,
		})
	end

	-- Load file content or create new file template
	if vim.fn.filereadable(file) == 1 then
		local content = vim.fn.readfile(file)
		vim.api.nvim_buf_set_lines(right_side_buf, 0, -1, false, content)
	else
		vim.api.nvim_buf_set_lines(right_side_buf, 0, -1, false, {
			"# " .. (filename or "Idea for " .. os.date("%Y-%m-%d")),
			"",
			"- ",
		})
	end

	-- Set the buffer name to show the current file
	vim.api.nvim_buf_set_name(right_side_buf, "ideaDrop://" .. (filename or os.date("%Y-%m-%d")))

	-- Create or update the right-side window
	if not right_side_win or not vim.api.nvim_win_is_valid(right_side_win) then
		-- Calculate window dimensions (30% of screen width, full height)
		local width = math.floor(vim.o.columns * 0.3)
		local height = vim.o.lines - 2 -- Full height minus status line

		-- Create the right-side window
		right_side_win = vim.api.nvim_open_win(right_side_buf, false, {
			relative = "editor",
			width = width,
			height = height,
			row = 0,
			col = vim.o.columns - width,
			border = "single",
			style = "minimal",
		})

		-- Set window options
		vim.wo[right_side_win].wrap = true
		vim.wo[right_side_win].number = true
		vim.wo[right_side_win].relativenumber = false
		vim.wo[right_side_win].cursorline = true
		vim.wo[right_side_win].winhl = "Normal:Normal,FloatBorder:FloatBorder"

		-- Set up autosave on window close
		vim.api.nvim_create_autocmd("WinClosed", {
			pattern = tostring(right_side_win),
			once = true,
			callback = function()
				local lines = vim.api.nvim_buf_get_lines(right_side_buf, 0, -1, false)
				M.save_idea(lines, current_file)
				right_side_win = nil
			end,
		})
	else
		-- Window exists, just switch to it
		vim.api.nvim_set_current_win(right_side_win)
	end

	-- Focus on the right-side window
	vim.api.nvim_set_current_win(right_side_win)
end

---Toggles the tree view
---@return nil
function M.toggle_tree()
	tree.open_tree_window(function(selected_file)
		-- Callback when a file is selected from the tree
		if selected_file then
			local filename = vim.fn.fnamemodify(selected_file, ":t")
			M.open_right_side(selected_file, filename)
		end
	end)
end

---Refreshes the current file in the right-side buffer
---@return nil
function M.refresh_current_file()
	if current_file and right_side_buf and vim.api.nvim_buf_is_valid(right_side_buf) then
		if vim.fn.filereadable(current_file) == 1 then
			local content = vim.fn.readfile(current_file)
			vim.api.nvim_buf_set_lines(right_side_buf, 0, -1, false, content)
			vim.notify("🔄 File refreshed", vim.log.levels.INFO)
		end
	end
end

---Saves the idea content to a file
---@param lines string[] Array of lines to save
---@param file string|nil Path where to save the file
---@return nil
function M.save_idea(lines, file)
	local idea_path = config.options.idea_dir

	-- Create default path if none provided
	if not file then
		if vim.fn.isdirectory(idea_path) == 0 then
			vim.fn.mkdir(idea_path, "p")
		end
		file = string.format("%s/%s.md", idea_path, os.date("%Y-%m-%d"))
	end

	-- Write content to file
	local f, err = io.open(file, "w")
	if not f then
		vim.notify("❌ Failed to write idea: " .. tostring(err), vim.log.levels.ERROR)
		return
	end

	f:write(table.concat(lines, "\n") .. "\n")
	f:close()
	vim.notify("💾 Idea saved to " .. file, vim.log.levels.INFO)
end

---Gets the current file path from the right-side buffer
---@return string|nil Current file path or nil if no file is open
function M.get_current_file()
	return current_file
end

return M
