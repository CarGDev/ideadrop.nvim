-- ideaDrop/config.lua

---@class Config
---@field options IdeaDropOptions
---@field setup fun(user_opts: IdeaDropOptions|nil): nil

---@class GraphOptions
---@field animate boolean Whether to animate layout (default: false)
---@field show_orphans boolean Whether to show orphan nodes (default: true)
---@field show_labels boolean Whether to show node labels by default (default: true)
---@field node_colors table<string, string>|nil Custom colors for folders/tags

---@class TodoOptions
---@field file string|nil Custom todo filename (default: ".todo.md")
---@field width number|nil Panel width as ratio of screen (default: 0.25)

---@class ObsidianOptions
---@field enabled boolean Whether to enable obsidian.nvim integration (default: true)
---@field auto_keymaps boolean Whether to set up obsidian keymaps on idea buffers (default: true)

---@class IdeaDropOptions
---@field idea_dir string Directory where idea files will be stored
---@field graph GraphOptions|nil Graph visualization options
---@field todo TodoOptions|nil Todo list options
---@field obsidian ObsidianOptions|nil Obsidian.nvim integration options

local M = {}

---Default configuration options
M.options = {
	idea_dir = vim.fn.stdpath("data") .. "/ideaDrop",
	graph = {
		animate = false,
		show_orphans = true,
		show_labels = true,
		node_colors = nil,
	},
	todo = {
		file = ".todo.md",
		width = 0.25,
	},
	obsidian = {
		enabled = true,
		auto_keymaps = true,
	},
}

---Setup function to merge user options with defaults
---@param user_opts IdeaDropOptions|nil User configuration options
---@return nil
function M.setup(user_opts)
	user_opts = user_opts or {}

	if user_opts.idea_dir == nil then
		user_opts.idea_dir = M.options.idea_dir
	end

	if user_opts.idea_dir then
		user_opts.idea_dir = vim.fn.expand(user_opts.idea_dir)
	end

	M.options = vim.tbl_deep_extend("force", M.options, user_opts)
end

---Gets the idea directory path (expanded)
---@return string
function M.get_idea_dir()
	return vim.fn.expand(M.options.idea_dir or "")
end

return M
