-- ideaDrop.nvim/core/init.lua
-- Core modules
local config = require("ideaDrop.core.config")

-- UI modules
local sidebar = require("ideaDrop.ui.sidebar")
local tree = require("ideaDrop.ui.tree")
local graph = require("ideaDrop.ui.graph")

-- Feature modules
local list = require("ideaDrop.features.list")
local tags = require("ideaDrop.features.tags")
local search = require("ideaDrop.features.search")

-- Utility modules
local keymaps = require("ideaDrop.utils.keymaps")

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

	-- Command to open ideas in floating window (original behavior)
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

			sidebar.open(full_path, filename, false)
		else
			-- Default to today's idea file
			local path = string.format("%s/%s.md", idea_dir, os.date("%Y-%m-%d"))
			sidebar.open(path, nil, false)
		end
	end, {
		nargs = "?",
		complete = function()
			return { "listAll" }
		end,
		desc = "Open today's idea, a named idea, or list all (in floating window)",
	})

	-- Command to open ideas in current buffer
	vim.api.nvim_create_user_command("IdeaBuffer", function(opts)
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

			sidebar.open(full_path, filename, true)
		else
			-- Default to today's idea file
			local path = string.format("%s/%s.md", idea_dir, os.date("%Y-%m-%d"))
			sidebar.open(path, nil, true)
		end
	end, {
		nargs = "?",
		complete = function()
			return { "listAll" }
		end,
		desc = "Open today's idea, a named idea, or list all (in current buffer)",
	})

	-- Command to open ideas in persistent right-side buffer
	vim.api.nvim_create_user_command("IdeaRight", function(opts)
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

			sidebar.open_right_side(full_path, filename)
		else
			-- Default to today's idea file
			local path = string.format("%s/%s.md", idea_dir, os.date("%Y-%m-%d"))
			sidebar.open_right_side(path, nil)
		end
	end, {
		nargs = "?",
		complete = function()
			return { "listAll" }
		end,
		desc = "Open today's idea, a named idea, or list all (in persistent right-side buffer)",
	})

	-- Command to open the tree view for browsing ideas
	vim.api.nvim_create_user_command("IdeaTree", function()
		tree.open_tree_window(function(selected_file)
			-- When a file is selected from the tree, open it in the right-side buffer
			if selected_file then
				local filename = vim.fn.fnamemodify(selected_file, ":t")
				sidebar.open_right_side(selected_file, filename)
			end
		end)
	end, {
		desc = "Open tree view to browse and select idea files",
	})

	-- Tag-related commands
	vim.api.nvim_create_user_command("IdeaTags", function()
		tags.show_tag_picker(function(selected_tag)
			if selected_tag then
				tags.show_files_with_tag(selected_tag)
			end
		end)
	end, {
		desc = "Show all tags and browse files by tag",
	})

	vim.api.nvim_create_user_command("IdeaAddTag", function(opts)
		local tag = opts.args
		if tag == "" then
			vim.notify("❌ Please provide a tag name", vim.log.levels.ERROR)
			return
		end
		
		-- Get current file from right-side buffer or prompt for file
		local current_file = sidebar.get_current_file()
		if current_file then
			tags.add_tag(current_file, tag)
		else
			vim.notify("❌ No active idea file. Open an idea first.", vim.log.levels.ERROR)
		end
	end, {
		nargs = 1,
		desc = "Add a tag to the current idea file",
	})

	vim.api.nvim_create_user_command("IdeaRemoveTag", function(opts)
		local tag = opts.args
		if tag == "" then
			vim.notify("❌ Please provide a tag name", vim.log.levels.ERROR)
			return
		end
		
		-- Get current file from right-side buffer or prompt for file
		local current_file = sidebar.get_current_file()
		if current_file then
			tags.remove_tag(current_file, tag)
		else
			vim.notify("❌ No active idea file. Open an idea first.", vim.log.levels.ERROR)
		end
	end, {
		nargs = 1,
		desc = "Remove a tag from the current idea file",
	})

	vim.api.nvim_create_user_command("IdeaSearchTag", function(opts)
		local tag = opts.args
		if tag == "" then
			vim.notify("❌ Please provide a tag name", vim.log.levels.ERROR)
			return
		end
		
		tags.show_files_with_tag(tag)
	end, {
		nargs = 1,
		desc = "Search for files with a specific tag",
	})

	-- Search-related commands
	vim.api.nvim_create_user_command("IdeaSearch", function(opts)
		local query = opts.args
		if query == "" then
			vim.notify("❌ Please provide a search query", vim.log.levels.ERROR)
			return
		end
		
		search.fuzzy_search(query)
	end, {
		nargs = 1,
		desc = "Fuzzy search through idea titles and content",
	})

	vim.api.nvim_create_user_command("IdeaSearchContent", function(opts)
		local query = opts.args
		if query == "" then
			vim.notify("❌ Please provide a search query", vim.log.levels.ERROR)
			return
		end
		
		search.search_in_content(query)
	end, {
		nargs = 1,
		desc = "Search only in idea content",
	})

	vim.api.nvim_create_user_command("IdeaSearchTitle", function(opts)
		local query = opts.args
		if query == "" then
			vim.notify("❌ Please provide a search query", vim.log.levels.ERROR)
			return
		end
		
		search.search_by_title(query)
	end, {
		nargs = 1,
		desc = "Search only in idea titles",
	})

	-- Graph visualization commands
	vim.api.nvim_create_user_command("IdeaGraph", function(opts)
		local arg = opts.args
		
		if arg == "close" then
			graph.close()
		elseif arg == "refresh" then
			graph.refresh()
		elseif arg == "animate" then
			graph.open({ animate = true })
		else
			graph.open()
		end
	end, {
		nargs = "?",
		complete = function()
			return { "close", "refresh", "animate" }
		end,
		desc = "Open Obsidian-style graph visualization of notes and links",
	})

	vim.api.nvim_create_user_command("IdeaGraphFilter", function(opts)
		local args = vim.split(opts.args, " ", { trimempty = true })
		
		if #args < 2 then
			vim.notify("Usage: :IdeaGraphFilter <tag|folder> <value>", vim.log.levels.ERROR)
			return
		end
		
		local filter_type = args[1]
		local filter_value = args[2]
		
		if filter_type ~= "tag" and filter_type ~= "folder" then
			vim.notify("Filter type must be 'tag' or 'folder'", vim.log.levels.ERROR)
			return
		end
		
		-- If graph is open, apply filter
		if graph.is_open() then
			local graph_data = graph.get_graph()
			if graph_data then
				local data_module = require("ideaDrop.ui.graph.data")
				data_module.apply_filter(graph_data, filter_type, filter_value)
				graph.refresh()
			end
		else
			-- Open graph with filter
			graph.open()
			vim.defer_fn(function()
				local graph_data = graph.get_graph()
				if graph_data then
					local data_module = require("ideaDrop.ui.graph.data")
					data_module.apply_filter(graph_data, filter_type, filter_value)
					graph.refresh()
				end
			end, 100)
		end
	end, {
		nargs = "+",
		complete = function(_, cmd_line, _)
			local args = vim.split(cmd_line, " ", { trimempty = true })
			if #args <= 2 then
				return { "tag", "folder" }
			end
			return {}
		end,
		desc = "Filter graph by tag or folder",
	})

	-- Set up keymaps
	keymaps.setup()

	vim.notify("ideaDrop loaded!", vim.log.levels.INFO)
end

return M
