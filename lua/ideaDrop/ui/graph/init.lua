-- ideaDrop/ui/graph/init.lua
-- Main graph visualization module - ties together data, layout, and rendering

local constants = require("ideaDrop.utils.constants")
local types = require("ideaDrop.ui.graph.types")
local data = require("ideaDrop.ui.graph.data")
local layout = require("ideaDrop.ui.graph.layout")
local renderer = require("ideaDrop.ui.graph.renderer")

---@class GraphModule
---@field open fun(opts: table|nil): nil
---@field close fun(): nil
---@field refresh fun(): nil
local M = {}

-- Module state
local state = {
	buf = nil, ---@type number|nil
	win = nil, ---@type number|nil
	ns_id = nil, ---@type number|nil
	graph = nil, ---@type GraphData|nil
	view = nil, ---@type GraphViewState|nil
	layout_state = nil, ---@type GraphLayoutState|nil
	canvas_width = 0,
	canvas_height = 0,
	show_help = false,
	node_positions = {}, -- Maps screen positions to node IDs
}

local SETTINGS = constants.GRAPH_SETTINGS

---Calculates window dimensions
---@return number width, number height, number row, number col
local function get_window_dimensions()
	local width = math.floor(vim.o.columns * SETTINGS.WINDOW.WIDTH_RATIO)
	local height = math.floor(vim.o.lines * SETTINGS.WINDOW.HEIGHT_RATIO)
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	return width, height, row, col
end

---Updates the buffer content with the current graph state
local function update_display()
	if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
		return
	end

	if not state.graph or not state.view then
		return
	end

	-- Render the graph
	local canvas = renderer.render(state.graph, state.view, state.canvas_width, state.canvas_height - 2) -- Reserve 2 lines for status

	-- Convert to lines
	local lines = renderer.canvas_to_lines(canvas)

	-- Add status line
	local status = renderer.get_status_line(state.graph, state.view)
	table.insert(lines, string.rep("─", state.canvas_width))
	table.insert(lines, status)

	-- Show help overlay if enabled
	if state.show_help then
		local help_lines = renderer.render_help()
		local help_start_y = math.floor((state.canvas_height - #help_lines) / 2)
		local help_start_x = math.floor((state.canvas_width - 42) / 2) -- Help box is ~42 chars wide

		for i, help_line in ipairs(help_lines) do
			local y = help_start_y + i
			if y >= 1 and y <= #lines then
				-- Overlay help on top of graph
				local current_line = lines[y]
				local new_line = current_line:sub(1, help_start_x - 1)
					.. help_line
					.. current_line:sub(help_start_x + #help_line + 1)
				lines[y] = new_line
			end
		end
	end

	-- Update buffer
	vim.api.nvim_buf_set_option(state.buf, "modifiable", true)
	vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(state.buf, "modifiable", false)

	-- Apply highlights
	renderer.apply_highlights(state.buf, canvas, state.ns_id)

	-- Build node position map for cursor navigation
	state.node_positions = {}
	for _, node in ipairs(state.graph.node_list) do
		if node.visible then
			local x = math.floor((node.x - state.canvas_width / 2) * state.view.zoom + state.canvas_width / 2 + state.view.offset_x + 0.5)
			local y = math.floor((node.y - state.canvas_height / 2) * state.view.zoom + state.canvas_height / 2 + state.view.offset_y + 0.5)

			if x >= 1 and x <= state.canvas_width and y >= 1 and y <= state.canvas_height - 2 then
				local key = string.format("%d,%d", y, x)
				state.node_positions[key] = node.id

				-- Also register nearby positions for easier selection
				for dy = -1, 1 do
					for dx = -1, 1 do
						local nkey = string.format("%d,%d", y + dy, x + dx)
						if not state.node_positions[nkey] then
							state.node_positions[nkey] = node.id
						end
					end
				end
			end
		end
	end
end

---Finds the node nearest to the cursor
---@return GraphNode|nil
local function get_node_at_cursor()
	if not state.win or not vim.api.nvim_win_is_valid(state.win) then
		return nil
	end

	local cursor = vim.api.nvim_win_get_cursor(state.win)
	local row, col = cursor[1], cursor[2] + 1 -- Convert to 1-indexed

	local key = string.format("%d,%d", row, col)
	local node_id = state.node_positions[key]

	if node_id and state.graph then
		return state.graph.nodes[node_id]
	end

	return nil
end

---Moves selection to the nearest node in a direction
---@param direction string "up", "down", "left", "right"
local function move_selection(direction)
	if not state.graph or not state.view then
		return
	end

	local current_node = nil
	if state.view.selected_node then
		current_node = state.graph.nodes[state.view.selected_node]
	end

	-- If no selection, select the first visible node
	if not current_node then
		for _, node in ipairs(state.graph.node_list) do
			if node.visible then
				state.view.selected_node = node.id
				update_display()
				return
			end
		end
		return
	end

	-- Find the nearest node in the given direction
	local best_node = nil
	local best_score = math.huge

	for _, node in ipairs(state.graph.node_list) do
		if node.visible and node.id ~= current_node.id then
			local dx = node.x - current_node.x
			local dy = node.y - current_node.y

			local valid = false
			local score = 0

			if direction == "up" and dy < 0 then
				valid = true
				score = math.abs(dy) + math.abs(dx) * 2 -- Prefer vertical alignment
			elseif direction == "down" and dy > 0 then
				valid = true
				score = math.abs(dy) + math.abs(dx) * 2
			elseif direction == "left" and dx < 0 then
				valid = true
				score = math.abs(dx) + math.abs(dy) * 2
			elseif direction == "right" and dx > 0 then
				valid = true
				score = math.abs(dx) + math.abs(dy) * 2
			end

			if valid and score < best_score then
				best_score = score
				best_node = node
			end
		end
	end

	if best_node then
		state.view.selected_node = best_node.id
		update_display()
	end
end

---Opens the selected node's file
local function open_selected_node()
	if not state.view or not state.view.selected_node or not state.graph then
		-- Try to get node at cursor
		local node = get_node_at_cursor()
		if node then
			state.view.selected_node = node.id
		else
			vim.notify("No node selected", vim.log.levels.WARN)
			return
		end
	end

	local node = state.graph.nodes[state.view.selected_node]
	if not node then
		return
	end

	-- Close graph window
	M.close()

	-- Open the file in right-side buffer
	local sidebar = require("ideaDrop.ui.sidebar")
	local filename = vim.fn.fnamemodify(node.file_path, ":t")
	sidebar.open_right_side(node.file_path, filename)
end

---Shows tag filter picker
local function show_tag_filter()
	if not state.graph then
		return
	end

	local tags = data.get_tags(state.graph)

	if #tags == 0 then
		vim.notify("No tags found in graph", vim.log.levels.INFO)
		return
	end

	-- Add "Clear filter" option
	table.insert(tags, 1, "(Clear filter)")

	vim.ui.select(tags, { prompt = "🏷️ Filter by tag:" }, function(choice)
		if choice then
			if choice == "(Clear filter)" then
				data.apply_filter(state.graph, nil, nil)
				state.view.filter.active = false
			else
				data.apply_filter(state.graph, "tag", choice)
				state.view.filter = { type = "tag", value = choice, active = true }

				-- Re-run layout for filtered graph
				layout.adjust_after_filter(state.graph, state.canvas_width, state.canvas_height - 2, 100)
				layout.center_graph(state.graph, state.canvas_width, state.canvas_height - 2)
			end
			update_display()
		end
	end)
end

---Shows folder filter picker
local function show_folder_filter()
	if not state.graph then
		return
	end

	local folders = data.get_folders(state.graph)

	if #folders == 0 then
		vim.notify("No folders found in graph", vim.log.levels.INFO)
		return
	end

	-- Add "Clear filter" option
	table.insert(folders, 1, "(Clear filter)")

	vim.ui.select(folders, { prompt = "📁 Filter by folder:" }, function(choice)
		if choice then
			if choice == "(Clear filter)" then
				data.apply_filter(state.graph, nil, nil)
				state.view.filter.active = false
			else
				data.apply_filter(state.graph, "folder", choice)
				state.view.filter = { type = "folder", value = choice, active = true }

				-- Re-run layout for filtered graph
				layout.adjust_after_filter(state.graph, state.canvas_width, state.canvas_height - 2, 100)
				layout.center_graph(state.graph, state.canvas_width, state.canvas_height - 2)
			end
			update_display()
		end
	end)
end

---Resets the filter
local function reset_filter()
	if not state.graph or not state.view then
		return
	end

	data.apply_filter(state.graph, nil, nil)
	state.view.filter = { type = nil, value = nil, active = false }

	-- Re-run layout
	layout.adjust_after_filter(state.graph, state.canvas_width, state.canvas_height - 2, 50)
	update_display()
end

---Toggles label display
local function toggle_labels()
	if state.view then
		state.view.show_labels = not state.view.show_labels
		update_display()
	end
end

---Centers the graph in the view
local function center_graph()
	if state.graph then
		layout.center_graph(state.graph, state.canvas_width, state.canvas_height - 2)
		state.view.offset_x = 0
		state.view.offset_y = 0
		update_display()
	end
end

---Zooms in
local function zoom_in()
	if state.view then
		state.view.zoom = math.min(state.view.zoom * 1.2, 3.0)
		update_display()
	end
end

---Zooms out
local function zoom_out()
	if state.view then
		state.view.zoom = math.max(state.view.zoom / 1.2, 0.3)
		update_display()
	end
end

---Toggles help display
local function toggle_help()
	state.show_help = not state.show_help
	update_display()
end

---Sets up keymaps for the graph buffer
local function setup_keymaps()
	if not state.buf then
		return
	end

	local opts = { noremap = true, silent = true, buffer = state.buf }

	-- Navigation
	vim.keymap.set("n", "k", function()
		move_selection("up")
	end, opts)
	vim.keymap.set("n", "j", function()
		move_selection("down")
	end, opts)
	vim.keymap.set("n", "h", function()
		move_selection("left")
	end, opts)
	vim.keymap.set("n", "l", function()
		move_selection("right")
	end, opts)

	-- Actions
	vim.keymap.set("n", "<CR>", open_selected_node, opts)
	vim.keymap.set("n", "o", open_selected_node, opts)

	-- Filtering
	vim.keymap.set("n", "t", show_tag_filter, opts)
	vim.keymap.set("n", "f", show_folder_filter, opts)
	vim.keymap.set("n", "r", reset_filter, opts)

	-- Display
	vim.keymap.set("n", "L", toggle_labels, opts) -- Changed to uppercase to avoid conflict
	vim.keymap.set("n", "c", center_graph, opts)
	vim.keymap.set("n", "+", zoom_in, opts)
	vim.keymap.set("n", "=", zoom_in, opts) -- Also = for convenience
	vim.keymap.set("n", "-", zoom_out, opts)
	vim.keymap.set("n", "?", toggle_help, opts)

	-- Close
	vim.keymap.set("n", "q", M.close, opts)
	vim.keymap.set("n", "<Esc>", M.close, opts)

	-- Refresh
	vim.keymap.set("n", "R", M.refresh, opts) -- Uppercase R for refresh
end

---Opens the graph visualization window
---@param opts table|nil Options
function M.open(opts)
	opts = opts or {}

	-- Close existing window if open
	if state.win and vim.api.nvim_win_is_valid(state.win) then
		M.close()
	end

	-- Setup highlight groups
	renderer.setup_highlights()

	-- Create namespace for highlights
	state.ns_id = vim.api.nvim_create_namespace("ideadrop_graph")

	-- Calculate dimensions
	local width, height, row, col = get_window_dimensions()
	state.canvas_width = width - 2 -- Account for border
	state.canvas_height = height - 2

	-- Create buffer
	state.buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(state.buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(state.buf, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(state.buf, "filetype", "ideadrop-graph")

	-- Create window
	state.win = vim.api.nvim_open_win(state.buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		border = SETTINGS.WINDOW.BORDER,
		title = SETTINGS.WINDOW.TITLE,
		title_pos = "center",
		style = "minimal",
	})

	-- Set window options for dark background
	vim.api.nvim_win_set_option(state.win, "winhl", "Normal:" .. SETTINGS.COLORS.BACKGROUND)
	vim.api.nvim_win_set_option(state.win, "cursorline", false)

	-- Build graph data
	local config = require("ideaDrop.core.config")
	local idea_dir = vim.fn.expand(config.options.idea_dir or "")
	vim.notify(string.format("🕸️ Loading graph from: %s", idea_dir), vim.log.levels.INFO)
	
	state.graph = data.build_graph(opts.force_rebuild)

	if #state.graph.node_list == 0 then
		vim.notify(
			string.format("No notes found to visualize in: %s", idea_dir),
			vim.log.levels.WARN
		)
		M.close()
		return
	end

	-- Initialize view state
	state.view = types.create_view_state()

	-- Run layout algorithm
	vim.notify(string.format("Laying out %d nodes...", #state.graph.node_list), vim.log.levels.INFO)

	if opts.animate then
		-- Animated layout
		state.layout_state = layout.start_animated_layout(
			state.graph,
			state.canvas_width,
			state.canvas_height - 2,
			function(converged)
				update_display()
				if converged then
					vim.notify("Graph layout complete", vim.log.levels.INFO)
				end
			end,
			32 -- ~30fps for smoother animation
		)
	else
		-- Synchronous layout
		layout.run_layout(state.graph, state.canvas_width, state.canvas_height - 2)
		layout.center_graph(state.graph, state.canvas_width, state.canvas_height - 2)
	end

	-- Setup keymaps
	setup_keymaps()

	-- Initial render
	update_display()

	-- Auto-close when window loses focus (optional)
	vim.api.nvim_create_autocmd("WinLeave", {
		buffer = state.buf,
		once = true,
		callback = function()
			-- Don't close if a picker is open
			vim.defer_fn(function()
				local current_win = vim.api.nvim_get_current_win()
				if current_win ~= state.win and state.win and vim.api.nvim_win_is_valid(state.win) then
					-- Check if we're in a picker/popup
					local win_config = vim.api.nvim_win_get_config(current_win)
					if not win_config.relative or win_config.relative == "" then
						-- Not in a floating window, might want to close
						-- But let's keep it open for better UX
					end
				end
			end, 100)
		end,
	})

	-- Show stats
	local stats = data.get_statistics(state.graph)
	vim.notify(
		string.format("Graph: %d nodes, %d edges, %d orphans", stats.total_nodes, stats.total_edges, stats.orphan_nodes),
		vim.log.levels.INFO
	)
end

---Closes the graph visualization window
function M.close()
	-- Stop animated layout if running
	if state.layout_state then
		layout.stop_animated_layout(state.layout_state)
		state.layout_state = nil
	end

	-- Close window
	if state.win and vim.api.nvim_win_is_valid(state.win) then
		vim.api.nvim_win_close(state.win, true)
	end

	-- Clean up state
	state.win = nil
	state.buf = nil
	state.graph = nil
	state.view = nil
	state.node_positions = {}
	state.show_help = false
end

---Refreshes the graph data and re-renders
function M.refresh()
	if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
		return
	end

	vim.notify("Refreshing graph...", vim.log.levels.INFO)

	-- Rebuild graph
	state.graph = data.build_graph()

	if #state.graph.node_list == 0 then
		vim.notify("No notes found to visualize", vim.log.levels.WARN)
		return
	end

	-- Re-apply filter if active
	if state.view and state.view.filter.active then
		data.apply_filter(state.graph, state.view.filter.type, state.view.filter.value)
	end

	-- Re-run layout
	layout.run_layout(state.graph, state.canvas_width, state.canvas_height - 2)
	layout.center_graph(state.graph, state.canvas_width, state.canvas_height - 2)

	-- Update display
	update_display()

	vim.notify("Graph refreshed", vim.log.levels.INFO)
end

---Gets the current graph data (for external use)
---@return GraphData|nil
function M.get_graph()
	return state.graph
end

---Checks if the graph window is open
---@return boolean
function M.is_open()
	return state.win ~= nil and vim.api.nvim_win_is_valid(state.win)
end

return M
