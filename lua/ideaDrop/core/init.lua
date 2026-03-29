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
local todo = require("ideaDrop.features.todo")

-- Integration modules
local obsidian = require("ideaDrop.integrations.obsidian")

-- Utility modules
local keymaps = require("ideaDrop.utils.keymaps")

local M = {}

---@class IdeaDrop
---@field setup fun(user_opts: IdeaDropConfig): nil

---@class IdeaDropConfig
---@field idea_dir string Directory where idea files will be stored

---Helper to resolve idea file path from command args
---@param arg string command argument
---@param idea_dir string base directory
---@return string full_path, string filename
local function resolve_idea_path(arg, idea_dir)
	local filename = arg:match("%.md$") and arg or (arg .. ".md")
	local full_path = idea_dir .. "/" .. filename
	local folder = vim.fn.fnamemodify(full_path, ":h")
	if vim.fn.isdirectory(folder) == 0 then
		vim.fn.mkdir(folder, "p")
	end
	return full_path, filename
end

---Setup function for ideaDrop.nvim
---@param user_opts IdeaDropConfig|nil User configuration options
---@return nil
function M.setup(user_opts)
	config.setup(user_opts)

	-- ── Idea commands (all open in right-side split by default) ──

	vim.api.nvim_create_user_command("Idea", function(opts)
		local arg = opts.args
		local idea_dir = config.options.idea_dir

		if arg == "listAll" then
			list.list_all()
		elseif arg ~= "" then
			local full_path, filename = resolve_idea_path(arg, idea_dir)
			sidebar.open_right_side(full_path, filename)
		else
			local path = string.format("%s/%s.md", idea_dir, os.date("%Y-%m-%d"))
			sidebar.open_right_side(path, nil)
		end
	end, {
		nargs = "?",
		complete = function()
			return { "listAll" }
		end,
		desc = "Open today's idea or a named idea in right-side split",
	})

	vim.api.nvim_create_user_command("IdeaBuffer", function(opts)
		local arg = opts.args
		local idea_dir = config.options.idea_dir

		if arg == "listAll" then
			list.list_all()
		elseif arg ~= "" then
			local full_path, filename = resolve_idea_path(arg, idea_dir)
			sidebar.open(full_path, filename, true)
		else
			local path = string.format("%s/%s.md", idea_dir, os.date("%Y-%m-%d"))
			sidebar.open(path, nil, true)
		end
	end, {
		nargs = "?",
		complete = function()
			return { "listAll" }
		end,
		desc = "Open today's idea or a named idea in current buffer",
	})

	vim.api.nvim_create_user_command("IdeaRight", function(opts)
		local arg = opts.args
		local idea_dir = config.options.idea_dir

		if arg == "listAll" then
			list.list_all()
		elseif arg ~= "" then
			local full_path, filename = resolve_idea_path(arg, idea_dir)
			sidebar.open_right_side(full_path, filename)
		else
			local path = string.format("%s/%s.md", idea_dir, os.date("%Y-%m-%d"))
			sidebar.open_right_side(path, nil)
		end
	end, {
		nargs = "?",
		complete = function()
			return { "listAll" }
		end,
		desc = "Open today's idea in persistent right-side split",
	})

	vim.api.nvim_create_user_command("IdeaClose", function()
		sidebar.close()
	end, {
		desc = "Close the idea right-side split",
	})

	vim.api.nvim_create_user_command("IdeaToggle", function()
		sidebar.toggle()
	end, {
		desc = "Toggle the idea right-side split",
	})

	-- ── Tree ──

	vim.api.nvim_create_user_command("IdeaTree", function()
		tree.open_tree_window(function(selected_file)
			if selected_file then
				local filename = vim.fn.fnamemodify(selected_file, ":t")
				sidebar.open_right_side(selected_file, filename)
			end
		end)
	end, {
		desc = "Open tree view to browse and select idea files",
	})

	-- ── Tags ──

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
			vim.notify("Please provide a tag name", vim.log.levels.ERROR)
			return
		end
		local current_file = sidebar.get_current_file()
		if current_file then
			tags.add_tag(current_file, tag)
		else
			vim.notify("No active idea file. Open an idea first.", vim.log.levels.ERROR)
		end
	end, {
		nargs = 1,
		desc = "Add a tag to the current idea file",
	})

	vim.api.nvim_create_user_command("IdeaRemoveTag", function(opts)
		local tag = opts.args
		if tag == "" then
			vim.notify("Please provide a tag name", vim.log.levels.ERROR)
			return
		end
		local current_file = sidebar.get_current_file()
		if current_file then
			tags.remove_tag(current_file, tag)
		else
			vim.notify("No active idea file. Open an idea first.", vim.log.levels.ERROR)
		end
	end, {
		nargs = 1,
		desc = "Remove a tag from the current idea file",
	})

	vim.api.nvim_create_user_command("IdeaSearchTag", function(opts)
		local tag = opts.args
		if tag == "" then
			vim.notify("Please provide a tag name", vim.log.levels.ERROR)
			return
		end
		tags.show_files_with_tag(tag)
	end, {
		nargs = 1,
		desc = "Search for files with a specific tag",
	})

	-- ── Search ──

	vim.api.nvim_create_user_command("IdeaSearch", function(opts)
		local query = opts.args
		if query == "" then
			vim.notify("Please provide a search query", vim.log.levels.ERROR)
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
			vim.notify("Please provide a search query", vim.log.levels.ERROR)
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
			vim.notify("Please provide a search query", vim.log.levels.ERROR)
			return
		end
		search.search_by_title(query)
	end, {
		nargs = 1,
		desc = "Search only in idea titles",
	})

	-- ── Graph ──

	vim.api.nvim_create_user_command("IdeaGraph", function(opts)
		local arg = opts.args
		if arg == "close" then
			graph.close()
		elseif arg == "refresh" then
			graph.refresh()
		elseif arg == "animate" then
			graph.open({ animate = true })
		elseif arg == "rebuild" then
			graph.open({ force_rebuild = true })
		else
			graph.open()
		end
	end, {
		nargs = "?",
		complete = function()
			return { "close", "refresh", "animate", "rebuild" }
		end,
		desc = "Open Obsidian-style graph visualization of notes and links",
	})

	vim.api.nvim_create_user_command("IdeaGraphClearCache", function()
		local cache = require("ideaDrop.ui.graph.cache")
		cache.clear()
		vim.notify("Graph cache cleared", vim.log.levels.INFO)
	end, {
		desc = "Clear the graph cache to force full rebuild",
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
		if graph.is_open() then
			local graph_data = graph.get_graph()
			if graph_data then
				local data_module = require("ideaDrop.ui.graph.data")
				data_module.apply_filter(graph_data, filter_type, filter_value)
				graph.refresh()
			end
		else
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

	-- ── Todo ──

	vim.api.nvim_create_user_command("IdeaTodo", function()
		todo.toggle()
	end, {
		desc = "Toggle the project todo list panel",
	})

	vim.api.nvim_create_user_command("IdeaTodoAdd", function(opts)
		local text = opts.args
		if not todo.is_open() then
			todo.open()
		end
		todo.add_item(text ~= "" and text or nil)
	end, {
		nargs = "?",
		desc = "Add a new todo item",
	})

	-- ── Obsidian integration ──

	vim.api.nvim_create_user_command("IdeaObsidian", function(opts)
		local arg = opts.args
		if not obsidian.is_available() then
			vim.notify(
				"obsidian.nvim is not installed. Install epwalsh/obsidian.nvim for enhanced features.",
				vim.log.levels.WARN
			)
			return
		end
		if arg == "backlinks" then
			obsidian.backlinks()
		elseif arg == "search" then
			obsidian.search()
		elseif arg == "daily" then
			obsidian.daily_note()
		elseif arg == "new" then
			obsidian.new_note()
		elseif arg == "switch" then
			obsidian.quick_switch()
		elseif arg == "tags" then
			obsidian.tags()
		elseif arg == "paste" then
			obsidian.paste_image()
		elseif arg == "rename" then
			obsidian.rename()
		elseif arg == "open" then
			obsidian.open_in_obsidian()
		elseif arg == "status" then
			vim.notify(obsidian.status(), vim.log.levels.INFO)
		else
			vim.notify(obsidian.status(), vim.log.levels.INFO)
		end
	end, {
		nargs = "?",
		complete = function()
			return { "backlinks", "search", "daily", "new", "switch", "tags", "paste", "rename", "open", "status" }
		end,
		desc = "Obsidian.nvim integration commands",
	})

	-- ── Keymaps ──

	keymaps.setup()

	-- Log obsidian.nvim status on load
	if obsidian.is_available() then
		vim.notify("ideaDrop loaded! (obsidian.nvim detected)", vim.log.levels.INFO)
	else
		vim.notify("ideaDrop loaded!", vim.log.levels.INFO)
	end
end

return M
