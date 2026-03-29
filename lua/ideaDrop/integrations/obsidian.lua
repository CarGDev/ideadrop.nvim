-- ideaDrop/integrations/obsidian.lua
-- Optional obsidian.nvim integration for enhanced vault capabilities

local config = require("ideaDrop.core.config")

---@class ObsidianIntegration
local M = {}

---Check if obsidian.nvim is available
---@return boolean
function M.is_available()
	local ok, _ = pcall(require, "obsidian")
	return ok
end

---Get the obsidian client if available
---@return table|nil obsidian client
function M.get_client()
	local ok, obsidian = pcall(require, "obsidian")
	if not ok then
		return nil
	end

	-- Try to get the current client
	local client_ok, client = pcall(function()
		return obsidian.get_client()
	end)
	if client_ok and client then
		return client
	end
	return nil
end

---Follow a [[wiki link]] under cursor using obsidian.nvim
---Falls back to ideaDrop's own link handling if obsidian.nvim is not available
---@return boolean true if obsidian.nvim handled it
function M.follow_link()
	if not M.is_available() then
		return false
	end

	local ok = pcall(vim.cmd, "ObsidianFollowLink")
	return ok
end

---Open obsidian.nvim's link picker for the current note
---@return boolean true if obsidian.nvim handled it
function M.backlinks()
	if not M.is_available() then
		return false
	end

	local ok = pcall(vim.cmd, "ObsidianBacklinks")
	return ok
end

---Use obsidian.nvim's search
---@param query string|nil
---@return boolean
function M.search(query)
	if not M.is_available() then
		return false
	end

	if query then
		local ok = pcall(vim.cmd, "ObsidianSearch " .. query)
		return ok
	else
		local ok = pcall(vim.cmd, "ObsidianSearch")
		return ok
	end
end

---Open obsidian.nvim's daily note
---@return boolean
function M.daily_note()
	if not M.is_available() then
		return false
	end

	local ok = pcall(vim.cmd, "ObsidianToday")
	return ok
end

---Create a new note using obsidian.nvim
---@param title string|nil
---@return boolean
function M.new_note(title)
	if not M.is_available() then
		return false
	end

	if title then
		local ok = pcall(vim.cmd, "ObsidianNew " .. title)
		return ok
	else
		local ok = pcall(vim.cmd, "ObsidianNew")
		return ok
	end
end

---Open obsidian.nvim's quick switcher
---@return boolean
function M.quick_switch()
	if not M.is_available() then
		return false
	end

	local ok = pcall(vim.cmd, "ObsidianQuickSwitch")
	return ok
end

---Get tags from obsidian.nvim if available
---@return boolean
function M.tags()
	if not M.is_available() then
		return false
	end

	local ok = pcall(vim.cmd, "ObsidianTags")
	return ok
end

---Paste image from clipboard using obsidian.nvim
---@return boolean
function M.paste_image()
	if not M.is_available() then
		return false
	end

	local ok = pcall(vim.cmd, "ObsidianPasteImg")
	return ok
end

---Rename the current note using obsidian.nvim (updates all backlinks)
---@return boolean
function M.rename()
	if not M.is_available() then
		return false
	end

	local ok = pcall(vim.cmd, "ObsidianRename")
	return ok
end

---Open the current note in the Obsidian app
---@return boolean
function M.open_in_obsidian()
	if not M.is_available() then
		return false
	end

	local ok = pcall(vim.cmd, "ObsidianOpen")
	return ok
end

---Setup obsidian.nvim-enhanced keymaps on a buffer
---@param buf number buffer handle
function M.setup_buf_keymaps(buf)
	if not M.is_available() then
		return
	end

	local kopts = { noremap = true, silent = true }

	vim.api.nvim_buf_set_keymap(
		buf,
		"n",
		"gf",
		"",
		vim.tbl_extend("force", kopts, {
			callback = function()
				M.follow_link()
			end,
			desc = "Follow obsidian link",
		})
	)
	vim.api.nvim_buf_set_keymap(
		buf,
		"n",
		"<leader>ob",
		"",
		vim.tbl_extend("force", kopts, {
			callback = function()
				M.backlinks()
			end,
			desc = "Show backlinks (obsidian)",
		})
	)
	vim.api.nvim_buf_set_keymap(
		buf,
		"n",
		"<leader>os",
		"",
		vim.tbl_extend("force", kopts, {
			callback = function()
				M.search()
			end,
			desc = "Obsidian search",
		})
	)
	vim.api.nvim_buf_set_keymap(
		buf,
		"n",
		"<leader>on",
		"",
		vim.tbl_extend("force", kopts, {
			callback = function()
				M.new_note()
			end,
			desc = "New obsidian note",
		})
	)
	vim.api.nvim_buf_set_keymap(
		buf,
		"n",
		"<leader>oo",
		"",
		vim.tbl_extend("force", kopts, {
			callback = function()
				M.open_in_obsidian()
			end,
			desc = "Open in Obsidian app",
		})
	)
	vim.api.nvim_buf_set_keymap(
		buf,
		"n",
		"<leader>or",
		"",
		vim.tbl_extend("force", kopts, {
			callback = function()
				M.rename()
			end,
			desc = "Rename note (obsidian)",
		})
	)
	vim.api.nvim_buf_set_keymap(
		buf,
		"n",
		"<leader>op",
		"",
		vim.tbl_extend("force", kopts, {
			callback = function()
				M.paste_image()
			end,
			desc = "Paste image (obsidian)",
		})
	)
	vim.api.nvim_buf_set_keymap(
		buf,
		"n",
		"<leader>oq",
		"",
		vim.tbl_extend("force", kopts, {
			callback = function()
				M.quick_switch()
			end,
			desc = "Quick switch (obsidian)",
		})
	)
end

---Returns a status string about obsidian.nvim integration
---@return string
function M.status()
	if M.is_available() then
		local client = M.get_client()
		if client then
			return "obsidian.nvim: connected"
		end
		return "obsidian.nvim: available (no client)"
	end
	return "obsidian.nvim: not installed"
end

return M
