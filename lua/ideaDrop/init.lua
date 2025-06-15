-- ideaDrop.nvim/init.lua
local config = require("ideaDrop.config")
local sidebar = require("ideaDrop.sidebar")
local list = require("ideaDrop.list")
local M = {}

---@class IdeaDrop
---@field setup fun(user_opts: IdeaDropConfig): nil

---@class IdeaDropConfig
---@field idea_dir string Directory where idea files will be stored

---Setup function for ideaDrop.nvim
---@param user_opts IdeaDropConfig|nil User configuration options
---@return nil
function M.setup(user_opts)
	config.setup(user_opts)

	vim.api.nvim_create_user_command("Idea", function(opts)
		local arg = opts.args
		local idea_dir = config.options.idea_dir

		if arg == "listAll" then
			list.list_all()
		elseif arg ~= "" then
			-- Ensure directory exists (even for nested folders)
			local filename = arg:match("%.md$") and arg or (arg .. ".md")
			local full_path = idea_dir .. "/" .. filename

			-- Create parent folders if needed
			local folder = vim.fn.fnamemodify(full_path, ":h")
			if vim.fn.isdirectory(folder) == 0 then
				vim.fn.mkdir(folder, "p")
			end

			sidebar.open(full_path, filename)
		else
			-- Default to today's idea file
			local path = string.format("%s/%s.md", idea_dir, os.date("%Y-%m-%d"))
			sidebar.open(path)
		end
	end, {
		nargs = "?",
		complete = function()
			return { "listAll" }
		end,
		desc = "Open today's idea, a named idea, or list all",
	})

	vim.notify("ideaDrop loaded!", vim.log.levels.INFO)
end

return M
