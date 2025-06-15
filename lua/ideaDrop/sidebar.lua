local config = require("ideaDrop.config")

---@class Sidebar
---@field open fun(file: string|nil, filename: string|nil): nil
---@field save_idea fun(lines: string[], file: string|nil): nil
local M = {}

---Opens a floating sidebar window with the specified file
---@param file string|nil Path to the file to open
---@param filename string|nil Name of the file (used for new files)
---@return nil
function M.open(file, filename)
	-- Create a new buffer
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(buf, "filetype", "markdown")

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

return M
