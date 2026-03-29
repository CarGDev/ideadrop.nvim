-- ideaDrop/features/todo.lua
-- Project-scoped todo list with checkbox toggling in a right-side split

local config = require("ideaDrop.core.config")

---@class Todo
---@field open fun(): nil
---@field close fun(): nil
---@field toggle fun(): nil
---@field toggle_item fun(): nil
---@field add_item fun(text: string): nil
---@field remove_item fun(): nil
local M = {}

local todo_buf = nil
local todo_win = nil

---Returns the path to the todo file for the current project
---@return string
local function get_todo_file()
	local idea_dir = config.options.idea_dir
	local filename = config.options.todo and config.options.todo.file or ".todo.md"
	return idea_dir .. "/" .. filename
end

---Creates default todo content
---@return string[]
local function default_content()
	return {
		"# Todo",
		"",
		"- [ ] ",
	}
end

---Loads todo content from file or creates default
---@param buf number
local function load_todo(buf)
	local file = get_todo_file()
	if vim.fn.filereadable(file) == 1 then
		local content = vim.fn.readfile(file)
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
	else
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, default_content())
	end
end

---Saves the todo buffer to disk
local function save_todo()
	if not todo_buf or not vim.api.nvim_buf_is_valid(todo_buf) then
		return
	end
	local file = get_todo_file()
	local folder = vim.fn.fnamemodify(file, ":h")
	if vim.fn.isdirectory(folder) == 0 then
		vim.fn.mkdir(folder, "p")
	end

	local lines = vim.api.nvim_buf_get_lines(todo_buf, 0, -1, false)
	local f, err = io.open(file, "w")
	if not f then
		vim.notify("Failed to save todo: " .. tostring(err), vim.log.levels.ERROR)
		return
	end
	f:write(table.concat(lines, "\n") .. "\n")
	f:close()
end

---Toggle the checkbox on the current line
---@return nil
function M.toggle_item()
	if not todo_buf or not vim.api.nvim_buf_is_valid(todo_buf) then
		return
	end

	local cursor = vim.api.nvim_win_get_cursor(todo_win or 0)
	local row = cursor[1] - 1 -- 0-indexed
	local line = vim.api.nvim_buf_get_lines(todo_buf, row, row + 1, false)[1]
	if not line then
		return
	end

	local new_line
	if line:match("%- %[ %]") then
		new_line = line:gsub("%- %[ %]", "- [x]", 1)
	elseif line:match("%- %[x%]") then
		new_line = line:gsub("%- %[x%]", "- [ ]", 1)
	else
		return -- not a checkbox line
	end

	vim.api.nvim_buf_set_lines(todo_buf, row, row + 1, false, { new_line })
	save_todo()
end

---Add a new todo item below the cursor
---@param text string|nil item text (empty checkbox if nil)
---@return nil
function M.add_item(text)
	if not todo_buf or not vim.api.nvim_buf_is_valid(todo_buf) then
		return
	end

	local item = "- [ ] " .. (text or "")
	local cursor = vim.api.nvim_win_get_cursor(todo_win or 0)
	local row = cursor[1] -- 1-indexed, insert after current line
	vim.api.nvim_buf_set_lines(todo_buf, row, row, false, { item })

	-- Move cursor to the new line, at end of text
	if todo_win and vim.api.nvim_win_is_valid(todo_win) then
		vim.api.nvim_win_set_cursor(todo_win, { row + 1, #item })
	end
	save_todo()
end

---Remove the current todo item line
---@return nil
function M.remove_item()
	if not todo_buf or not vim.api.nvim_buf_is_valid(todo_buf) then
		return
	end

	local cursor = vim.api.nvim_win_get_cursor(todo_win or 0)
	local row = cursor[1] - 1
	local line = vim.api.nvim_buf_get_lines(todo_buf, row, row + 1, false)[1]
	if not line then
		return
	end

	-- Only remove checkbox lines
	if line:match("^%s*%- %[.%]") then
		vim.api.nvim_buf_set_lines(todo_buf, row, row + 1, false, {})
		save_todo()
	end
end

---Setup keymaps for the todo buffer
---@param buf number
local function setup_keymaps(buf)
	local kopts = { noremap = true, silent = true }

	-- Toggle checkbox with <CR> or <Space>
	vim.api.nvim_buf_set_keymap(
		buf,
		"n",
		"<CR>",
		"",
		vim.tbl_extend("force", kopts, {
			callback = function()
				M.toggle_item()
			end,
			desc = "Toggle todo checkbox",
		})
	)
	vim.api.nvim_buf_set_keymap(
		buf,
		"n",
		"<Space>",
		"",
		vim.tbl_extend("force", kopts, {
			callback = function()
				M.toggle_item()
			end,
			desc = "Toggle todo checkbox",
		})
	)

	-- Add new item with 'o'
	vim.api.nvim_buf_set_keymap(
		buf,
		"n",
		"o",
		"",
		vim.tbl_extend("force", kopts, {
			callback = function()
				M.add_item("")
				-- Enter insert mode at end of line
				vim.cmd("startinsert!")
			end,
			desc = "Add new todo item",
		})
	)

	-- Remove item with 'dd' on checkbox lines
	vim.api.nvim_buf_set_keymap(
		buf,
		"n",
		"dd",
		"",
		vim.tbl_extend("force", kopts, {
			callback = function()
				local cursor = vim.api.nvim_win_get_cursor(0)
				local row = cursor[1] - 1
				local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1]
				if line and line:match("^%s*%- %[.%]") then
					M.remove_item()
				else
					-- Fallback to normal dd for non-checkbox lines
					vim.api.nvim_feedkeys('"_dd', "n", false)
				end
			end,
			desc = "Remove todo item",
		})
	)

	-- Close with q
	vim.api.nvim_buf_set_keymap(
		buf,
		"n",
		"q",
		"",
		vim.tbl_extend("force", kopts, {
			callback = function()
				M.close()
			end,
			desc = "Close todo panel",
		})
	)
end

---Opens the todo list in a fixed right-side split
---@return nil
function M.open()
	-- If already open, focus it
	if todo_win and vim.api.nvim_win_is_valid(todo_win) then
		vim.api.nvim_set_current_win(todo_win)
		return
	end

	-- Create buffer if needed
	if not todo_buf or not vim.api.nvim_buf_is_valid(todo_buf) then
		todo_buf = vim.api.nvim_create_buf(false, false)
		vim.bo[todo_buf].filetype = "markdown"
		vim.bo[todo_buf].buftype = "acwrite"
		vim.bo[todo_buf].bufhidden = "hide"

		vim.api.nvim_buf_set_name(todo_buf, "ideaDrop://todo")

		-- Save on :w
		vim.api.nvim_create_autocmd("BufWriteCmd", {
			buffer = todo_buf,
			callback = function()
				save_todo()
				vim.bo[todo_buf].modified = false
			end,
		})

		setup_keymaps(todo_buf)
	end

	-- Load content
	load_todo(todo_buf)

	-- Create right-side vertical split
	vim.cmd("botright vsplit")
	todo_win = vim.api.nvim_get_current_win()

	local width_ratio = config.options.todo and config.options.todo.width or 0.25
	local width = math.floor(vim.o.columns * width_ratio)
	vim.api.nvim_win_set_width(todo_win, width)
	vim.api.nvim_win_set_buf(todo_win, todo_buf)

	-- Window options
	vim.wo[todo_win].wrap = true
	vim.wo[todo_win].number = false
	vim.wo[todo_win].relativenumber = false
	vim.wo[todo_win].cursorline = true
	vim.wo[todo_win].winfixwidth = true
	-- Redirect any foreign buffer that lands in this window back to the main editor
	vim.api.nvim_create_autocmd("BufEnter", {
		callback = function()
			if not todo_win or not vim.api.nvim_win_is_valid(todo_win) then
				return true -- delete autocmd when window is gone
			end
			if vim.api.nvim_get_current_win() ~= todo_win then
				return
			end
			local cur_buf = vim.api.nvim_win_get_buf(todo_win)
			if cur_buf == todo_buf then
				return
			end
			local intruding_buf = cur_buf
			vim.api.nvim_win_set_buf(todo_win, todo_buf)
			vim.schedule(function()
				local target_win = nil
				for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
					if win ~= todo_win and vim.api.nvim_win_is_valid(win) then
						local win_buf = vim.api.nvim_win_get_buf(win)
						local bt = vim.bo[win_buf].buftype
						if bt == "" or bt == nil then
							target_win = win
							break
						end
					end
				end
				if target_win then
					vim.api.nvim_set_current_win(target_win)
					vim.api.nvim_win_set_buf(target_win, intruding_buf)
				else
					vim.cmd("aboveleft vsplit")
					vim.api.nvim_win_set_buf(vim.api.nvim_get_current_win(), intruding_buf)
				end
			end)
		end,
	})
	vim.wo[todo_win].signcolumn = "no"
	vim.wo[todo_win].foldcolumn = "0"
	vim.wo[todo_win].statusline = "%#StatusLine# Todo %=%l/%L "

	vim.bo[todo_buf].modified = false

	-- Auto-save on close
	vim.api.nvim_create_autocmd("WinClosed", {
		pattern = tostring(todo_win),
		once = true,
		callback = function()
			save_todo()
			todo_win = nil
		end,
	})
end

---Closes the todo panel
---@return nil
function M.close()
	if todo_win and vim.api.nvim_win_is_valid(todo_win) then
		save_todo()
		vim.api.nvim_win_close(todo_win, true)
		todo_win = nil
	end
end

---Toggles the todo panel open/closed
---@return nil
function M.toggle()
	if todo_win and vim.api.nvim_win_is_valid(todo_win) then
		M.close()
	else
		M.open()
	end
end

---Returns whether the todo panel is open
---@return boolean
function M.is_open()
	return todo_win ~= nil and vim.api.nvim_win_is_valid(todo_win)
end

return M
