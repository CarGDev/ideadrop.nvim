-- ideaDrop/config.lua

---@class Config
---@field options IdeaDropOptions
---@field setup fun(user_opts: IdeaDropOptions|nil): nil

---@class GraphOptions
---@field animate boolean Whether to animate layout (default: false)
---@field show_orphans boolean Whether to show orphan nodes (default: true)
---@field show_labels boolean Whether to show node labels by default (default: true)
---@field node_colors table<string, string>|nil Custom colors for folders/tags

---@class IdeaDropOptions
---@field idea_dir string Directory where idea files will be stored
---@field graph GraphOptions|nil Graph visualization options

local M = {}

---Default configuration options
M.options = {
	idea_dir = vim.fn.stdpath("data") .. "/ideaDrop", -- default path
	graph = {
		animate = false, -- Set to true for animated layout
		show_orphans = true, -- Show nodes with no connections
		show_labels = true, -- Show node labels by default
		node_colors = nil, -- Custom node colors by folder/tag
	},
}

---Setup function to merge user options with defaults
---@param user_opts IdeaDropOptions|nil User configuration options
---@return nil
function M.setup(user_opts)
	M.options = vim.tbl_deep_extend("force", M.options, user_opts or {})
end

return M
