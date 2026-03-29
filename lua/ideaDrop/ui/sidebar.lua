-- ideaDrop/ui/sidebar.lua
local config = require("ideaDrop.core.config")
local tree = require("ideaDrop.ui.tree")
local obsidian = require("ideaDrop.integrations.obsidian")

---@class Sidebar
---@field open fun(file: string|nil, filename: string|nil, use_buffer: boolean|nil): nil
---@field open_in_buffer fun(file: string|nil, filename: string|nil): nil
---@field open_right_side fun(file: string|nil, filename: string|nil): nil
---@field toggle_tree fun(): nil
---@field get_current_file fun(): string|nil
---@field save_idea fun(lines: string[], file: string|nil): nil
local M = {}

-- Track the right-side buffer and window
local right_side_buf = nil
local right_side_win = nil
local current_file = nil

---Resolves the file path, creating directories as needed
---@param file string|nil
---@param filename string|nil
---@return string file path
local function resolve_file(file, filename)
	if not file then
		local idea_path = config.options.idea_dir
		if vim.fn.isdirectory(idea_path) == 0 then
			vim.fn.mkdir(idea_path, "p")
		end
		file = string.format("%s/%s.md", idea_path, os.date("%Y-%m-%d"))
	end
	-- Ensure parent directory exists
	local folder = vim.fn.fnamemodify(file, ":h")
	if vim.fn.isdirectory(folder) == 0 then
		vim.fn.mkdir(folder, "p")
	end
	return file
end

---Loads content into a buffer from file or template
---@param buf number buffer handle
---@param file string file path
---@param filename string|nil display name
local function load_content(buf, file, filename)
	if vim.fn.filereadable(file) == 1 then
		local content = vim.fn.readfile(file)
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
	else
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
			"# " .. (filename or "Idea for " .. os.date("%Y-%m-%d")),
			"",
			"- ",
		})
	end
end

---Opens the idea file in a right-side vertical split (default mode)
---@param file string|nil Path to the file to open
---@param filename string|nil Name of the file (used for new files)
---@param use_buffer boolean|nil If true, opens in current buffer instead
---@return nil
function M.open(file, filename, use_buffer)
	if use_buffer then
		M.open_in_buffer(file, filename)
		return
	end
	-- Default: open in right-side split
	M.open_right_side(file, filename)
end

---Opens the idea file in the current buffer
---@param file string|nil Path to the file to open
---@param filename string|nil Name of the file (used for new files)
---@return nil
function M.open_in_buffer(file, filename)
	file = resolve_file(file, filename)

	vim.cmd("edit " .. vim.fn.fnameescape(file))

	if vim.fn.filereadable(file) == 0 then
		local template_lines = {
			"# " .. (filename or "Idea for " .. os.date("%Y-%m-%d")),
			"",
			"- ",
		}
		vim.api.nvim_buf_set_lines(0, 0, -1, false, template_lines)
	end

	vim.api.nvim_create_autocmd("BufWritePost", {
		buffer = 0,
		callback = function()
			vim.notify("Idea saved to " .. file, vim.log.levels.INFO)
		end,
	})
end

---Opens the idea file in a persistent right-side vertical split
---@param file string|nil Path to the file to open
---@param filename string|nil Name of the file (used for new files)
---@return nil
function M.open_right_side(file, filename)
	file = resolve_file(file, filename)
	current_file = file

	-- If the window already exists and is valid, reuse it
	if right_side_win and vim.api.nvim_win_is_valid(right_side_win) then
		vim.api.nvim_set_current_win(right_side_win)
		-- Load the new file into the existing buffer
		if right_side_buf and vim.api.nvim_buf_is_valid(right_side_buf) then
			load_content(right_side_buf, file, filename)
			vim.api.nvim_buf_set_name(right_side_buf, file)
			vim.bo[right_side_buf].modified = false
		end
		return
	end

	-- Create a new right-side vertical split
	vim.cmd("botright vsplit")
	right_side_win = vim.api.nvim_get_current_win()

	-- Calculate width: 30% of screen
	local width = math.floor(vim.o.columns * 0.3)
	vim.api.nvim_win_set_width(right_side_win, width)

	-- Create or reuse the buffer
	if not right_side_buf or not vim.api.nvim_buf_is_valid(right_side_buf) then
		right_side_buf = vim.api.nvim_create_buf(false, false)
		vim.bo[right_side_buf].filetype = "markdown"
		vim.bo[right_side_buf].buftype = "acwrite"
		vim.bo[right_side_buf].bufhidden = "hide"

		-- Auto-save on :w
		vim.api.nvim_create_autocmd("BufWriteCmd", {
			buffer = right_side_buf,
			callback = function()
				local lines = vim.api.nvim_buf_get_lines(right_side_buf, 0, -1, false)
				M.save_idea(lines, current_file)
				vim.bo[right_side_buf].modified = false
			end,
		})

		-- Keymaps for the buffer
		local kopts = { noremap = true, silent = true }
		vim.api.nvim_buf_set_keymap(
			right_side_buf,
			"n",
			"<C-t>",
			"",
			vim.tbl_extend("force", kopts, {
				callback = function()
					M.toggle_tree()
				end,
			})
		)
		vim.api.nvim_buf_set_keymap(
			right_side_buf,
			"n",
			"<C-r>",
			"",
			vim.tbl_extend("force", kopts, {
				callback = function()
					M.refresh_current_file()
				end,
			})
		)

		-- Set up obsidian.nvim keymaps if enabled
		if config.options.obsidian and config.options.obsidian.enabled and config.options.obsidian.auto_keymaps then
			obsidian.setup_buf_keymaps(right_side_buf)
		end
	end

	-- Set the buffer in the window
	vim.api.nvim_win_set_buf(right_side_win, right_side_buf)
	vim.api.nvim_buf_set_name(right_side_buf, file)

	-- Load content
	load_content(right_side_buf, file, filename)
	vim.bo[right_side_buf].modified = false

	-- Window options
	vim.wo[right_side_win].wrap = true
	vim.wo[right_side_win].number = true
	vim.wo[right_side_win].relativenumber = false
	vim.wo[right_side_win].cursorline = true
	vim.wo[right_side_win].winfixwidth = true
	-- Prevent other buffers from opening in this window
	if vim.fn.has("nvim-0.10") == 1 then
		vim.wo[right_side_win].winfixbuf = true
	else
		vim.api.nvim_create_autocmd("BufWinEnter", {
			callback = function()
				if right_side_win and vim.api.nvim_win_is_valid(right_side_win) then
					local cur_win = vim.api.nvim_get_current_win()
					if cur_win == right_side_win then
						local cur_buf = vim.api.nvim_win_get_buf(right_side_win)
						if cur_buf ~= right_side_buf then
							-- Move the intruding buffer to a previous window and restore ours
							vim.cmd("wincmd p")
							vim.api.nvim_win_set_buf(right_side_win, right_side_buf)
						end
					end
				else
					return true -- delete autocmd when window is gone
				end
			end,
		})
	end

	-- Save on window close
	vim.api.nvim_create_autocmd("WinClosed", {
		pattern = tostring(right_side_win),
		once = true,
		callback = function()
			if right_side_buf and vim.api.nvim_buf_is_valid(right_side_buf) then
				local lines = vim.api.nvim_buf_get_lines(right_side_buf, 0, -1, false)
				M.save_idea(lines, current_file)
			end
			right_side_win = nil
		end,
	})
end

---Closes the right-side panel if open
---@return nil
function M.close()
	if right_side_win and vim.api.nvim_win_is_valid(right_side_win) then
		-- Save before closing
		if right_side_buf and vim.api.nvim_buf_is_valid(right_side_buf) then
			local lines = vim.api.nvim_buf_get_lines(right_side_buf, 0, -1, false)
			M.save_idea(lines, current_file)
		end
		vim.api.nvim_win_close(right_side_win, true)
		right_side_win = nil
	end
end

---Toggles the right-side panel open/closed
---@return nil
function M.toggle()
	if right_side_win and vim.api.nvim_win_is_valid(right_side_win) then
		M.close()
	else
		M.open_right_side()
	end
end

---Toggles the tree view
---@return nil
function M.toggle_tree()
	tree.open_tree_window(function(selected_file)
		if selected_file then
			local fname = vim.fn.fnamemodify(selected_file, ":t")
			M.open_right_side(selected_file, fname)
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
			vim.notify("File refreshed", vim.log.levels.INFO)
		end
	end
end

---Saves the idea content to a file
---@param lines string[] Array of lines to save
---@param file string|nil Path where to save the file
---@return nil
function M.save_idea(lines, file)
	file = resolve_file(file, nil)

	local f, err = io.open(file, "w")
	if not f then
		vim.notify("Failed to write idea: " .. tostring(err), vim.log.levels.ERROR)
		return
	end

	f:write(table.concat(lines, "\n") .. "\n")
	f:close()
	vim.notify("Idea saved to " .. file, vim.log.levels.INFO)
end

---Gets the current file path from the right-side buffer
---@return string|nil Current file path or nil if no file is open
function M.get_current_file()
	return current_file
end

---Returns whether the right-side window is currently open
---@return boolean
function M.is_open()
	return right_side_win ~= nil and vim.api.nvim_win_is_valid(right_side_win)
end

return M
