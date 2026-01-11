-- ideaDrop/ui/graph/renderer.lua
-- Character-based canvas renderer for graph visualization

local constants = require("ideaDrop.utils.constants")
local types = require("ideaDrop.ui.graph.types")

---@class GraphRendererModule
---@field render fun(graph: GraphData, view: GraphViewState, width: number, height: number): GraphCanvas
---@field canvas_to_lines fun(canvas: GraphCanvas): string[]
local M = {}

local VISUAL = constants.GRAPH_SETTINGS.VISUAL
local COLORS = constants.GRAPH_SETTINGS.COLORS
local THRESHOLDS = constants.GRAPH_SETTINGS.NODE_DEGREE_THRESHOLDS

---Gets the visual size of a node based on its degree
---@param degree number Node degree
---@return number Size (1-3)
local function get_node_size(degree)
	if degree <= THRESHOLDS.SMALL then
		return VISUAL.MIN_NODE_SIZE
	elseif degree <= THRESHOLDS.MEDIUM then
		return 2
	else
		return VISUAL.MAX_NODE_SIZE
	end
end

---Gets the character for a node based on its size
---@param size number Node size
---@return string Character
local function get_node_char(size)
	if size <= 1 then
		return VISUAL.NODE_CHAR_SMALL
	else
		return VISUAL.NODE_CHAR
	end
end

---Gets the highlight group for a node
---@param node GraphNode The node
---@param view GraphViewState The view state
---@return string Highlight group name
local function get_node_highlight(node, view)
	if node.selected or node.id == view.selected_node then
		return COLORS.NODE_SELECTED
	elseif node.degree == 0 then
		return COLORS.NODE_ORPHAN
	elseif node.degree > THRESHOLDS.MEDIUM then
		return COLORS.NODE_HIGH_DEGREE
	else
		return COLORS.NODE_DEFAULT
	end
end

---Draws a line between two points using Bresenham's algorithm
---@param canvas GraphCanvas The canvas
---@param x1 number Start X
---@param y1 number Start Y
---@param x2 number End X
---@param y2 number End Y
---@param char string|nil Character to use (default: edge char)
local function draw_line(canvas, x1, y1, x2, y2, char)
	char = char or VISUAL.EDGE_CHAR_SIMPLE

	-- Round coordinates
	x1 = math.floor(x1 + 0.5)
	y1 = math.floor(y1 + 0.5)
	x2 = math.floor(x2 + 0.5)
	y2 = math.floor(y2 + 0.5)

	local dx = math.abs(x2 - x1)
	local dy = math.abs(y2 - y1)
	local sx = x1 < x2 and 1 or -1
	local sy = y1 < y2 and 1 or -1
	local err = dx - dy

	local max_iterations = math.max(dx, dy) * 2 + 10
	local iterations = 0

	while true do
		iterations = iterations + 1
		if iterations > max_iterations then
			break
		end

		-- Draw point if within bounds
		if x1 >= 1 and x1 <= canvas.width and y1 >= 1 and y1 <= canvas.height then
			-- Don't overwrite nodes (marked with special characters)
			local current = canvas.buffer[y1][x1]
			if current == " " or current == VISUAL.EDGE_CHAR_SIMPLE then
				canvas.buffer[y1][x1] = char

				-- Add highlight
				table.insert(canvas.highlights, {
					group = COLORS.EDGE,
					line = y1 - 1, -- 0-indexed
					col_start = x1 - 1,
					col_end = x1,
				})
			end
		end

		if x1 == x2 and y1 == y2 then
			break
		end

		local e2 = 2 * err
		if e2 > -dy then
			err = err - dy
			x1 = x1 + sx
		end
		if e2 < dx then
			err = err + dx
			y1 = y1 + sy
		end
	end
end

---Draws a node on the canvas
---@param canvas GraphCanvas The canvas
---@param node GraphNode The node
---@param view GraphViewState The view state
local function draw_node(canvas, node, view)
	if not node.visible then
		return
	end

	local x = math.floor(node.x + 0.5)
	local y = math.floor(node.y + 0.5)

	-- Check bounds
	if x < 1 or x > canvas.width or y < 1 or y > canvas.height then
		return
	end

	local size = get_node_size(node.degree)
	local char = get_node_char(size)
	local highlight = get_node_highlight(node, view)

	-- Draw the node
	canvas.buffer[y][x] = char

	-- Add highlight for the node
	table.insert(canvas.highlights, {
		group = highlight,
		line = y - 1, -- 0-indexed
		col_start = x - 1,
		col_end = x + #char - 1,
	})

	-- Draw larger nodes as multiple characters
	if size >= 2 then
		-- Draw adjacent characters for larger nodes
		local offsets = { { -1, 0 }, { 1, 0 } }
		if size >= 3 then
			table.insert(offsets, { 0, -1 })
			table.insert(offsets, { 0, 1 })
		end

		for _, offset in ipairs(offsets) do
			local ox, oy = x + offset[1], y + offset[2]
			if ox >= 1 and ox <= canvas.width and oy >= 1 and oy <= canvas.height then
				canvas.buffer[oy][ox] = VISUAL.NODE_CHAR_SMALL
				table.insert(canvas.highlights, {
					group = highlight,
					line = oy - 1,
					col_start = ox - 1,
					col_end = ox,
				})
			end
		end
	end
end

---Draws a label for a node
---@param canvas GraphCanvas The canvas
---@param node GraphNode The node
---@param view GraphViewState The view state
local function draw_label(canvas, node, view)
	if not node.visible or not view.show_labels then
		return
	end

	local x = math.floor(node.x + 0.5)
	local y = math.floor(node.y + 0.5)

	-- Only show labels for selected node or high-degree nodes
	local show_this_label = node.id == view.selected_node
		or node.id == view.hovered_node
		or node.degree > THRESHOLDS.MEDIUM

	if not show_this_label then
		return
	end

	-- Truncate label if too long
	local label = node.name
	if #label > VISUAL.LABEL_MAX_LENGTH then
		label = label:sub(1, VISUAL.LABEL_MAX_LENGTH - 3) .. "..."
	end

	-- Position label to the right of the node
	local label_x = x + 2
	local label_y = y

	-- Adjust if label would go off canvas
	if label_x + #label > canvas.width then
		label_x = x - #label - 1
	end

	-- Draw label characters
	if label_y >= 1 and label_y <= canvas.height then
		for i = 1, #label do
			local char_x = label_x + i - 1
			if char_x >= 1 and char_x <= canvas.width then
				local current = canvas.buffer[label_y][char_x]
				-- Only draw if space is empty or has edge
				if current == " " or current == VISUAL.EDGE_CHAR_SIMPLE then
					canvas.buffer[label_y][char_x] = label:sub(i, i)

					table.insert(canvas.highlights, {
						group = COLORS.LABEL,
						line = label_y - 1,
						col_start = char_x - 1,
						col_end = char_x,
					})
				end
			end
		end
	end
end

---Renders the graph to a canvas
---@param graph GraphData The graph data
---@param view GraphViewState The view state
---@param width number Canvas width
---@param height number Canvas height
---@return GraphCanvas The rendered canvas
function M.render(graph, view, width, height)
	local canvas = types.create_canvas(width, height)

	-- Apply zoom and offset transformations
	local function transform_x(x)
		return (x - width / 2) * view.zoom + width / 2 + view.offset_x
	end

	local function transform_y(y)
		return (y - height / 2) * view.zoom + height / 2 + view.offset_y
	end

	-- First pass: draw edges (so they appear behind nodes)
	for _, edge in ipairs(graph.edges) do
		if edge.visible then
			local source = graph.nodes[edge.source]
			local target = graph.nodes[edge.target]

			if source and target and source.visible and target.visible then
				local x1 = transform_x(source.x)
				local y1 = transform_y(source.y)
				local x2 = transform_x(target.x)
				local y2 = transform_y(target.y)

				draw_line(canvas, x1, y1, x2, y2)
			end
		end
	end

	-- Second pass: draw nodes
	for _, node in ipairs(graph.node_list) do
		if node.visible then
			-- Create a temporary node with transformed coordinates
			local transformed_node = {
				id = node.id,
				name = node.name,
				degree = node.degree,
				visible = node.visible,
				selected = node.selected,
				x = transform_x(node.x),
				y = transform_y(node.y),
			}
			draw_node(canvas, transformed_node, view)
		end
	end

	-- Third pass: draw labels
	for _, node in ipairs(graph.node_list) do
		if node.visible then
			local transformed_node = {
				id = node.id,
				name = node.name,
				degree = node.degree,
				visible = node.visible,
				x = transform_x(node.x),
				y = transform_y(node.y),
			}
			draw_label(canvas, transformed_node, view)
		end
	end

	return canvas
end

---Converts a canvas to an array of strings for buffer display
---@param canvas GraphCanvas The canvas
---@return string[] Array of lines
function M.canvas_to_lines(canvas)
	local lines = {}

	for y = 1, canvas.height do
		local line = table.concat(canvas.buffer[y], "")
		table.insert(lines, line)
	end

	return lines
end

---Applies highlights to a buffer
---@param buf number Buffer handle
---@param canvas GraphCanvas The canvas with highlights
---@param ns_id number Namespace ID for highlights
function M.apply_highlights(buf, canvas, ns_id)
	-- Clear existing highlights
	vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)

	-- Apply new highlights
	for _, hl in ipairs(canvas.highlights) do
		pcall(vim.api.nvim_buf_add_highlight, buf, ns_id, hl.group, hl.line, hl.col_start, hl.col_end)
	end
end

---Creates the highlight groups for the graph
function M.setup_highlights()
	-- Node colors
	vim.api.nvim_set_hl(0, COLORS.NODE_DEFAULT, { fg = "#7aa2f7", bold = true })
	vim.api.nvim_set_hl(0, COLORS.NODE_SELECTED, { fg = "#f7768e", bold = true, underline = true })
	vim.api.nvim_set_hl(0, COLORS.NODE_ORPHAN, { fg = "#565f89" })
	vim.api.nvim_set_hl(0, COLORS.NODE_HIGH_DEGREE, { fg = "#bb9af7", bold = true })

	-- Edge color (semi-transparent effect via dimmed color)
	vim.api.nvim_set_hl(0, COLORS.EDGE, { fg = "#3b4261" })

	-- Label color
	vim.api.nvim_set_hl(0, COLORS.LABEL, { fg = "#9ece6a", italic = true })

	-- Background (for the window)
	vim.api.nvim_set_hl(0, COLORS.BACKGROUND, { bg = "#1a1b26" })

	-- Filter indicator
	vim.api.nvim_set_hl(0, COLORS.FILTER_ACTIVE, { fg = "#e0af68", bold = true })
end

---Generates a status line string showing graph stats and controls
---@param graph GraphData The graph data
---@param view GraphViewState The view state
---@return string Status line
function M.get_status_line(graph, view)
	local visible_nodes = 0
	local visible_edges = 0

	for _, node in ipairs(graph.node_list) do
		if node.visible then
			visible_nodes = visible_nodes + 1
		end
	end

	for _, edge in ipairs(graph.edges) do
		if edge.visible then
			visible_edges = visible_edges + 1
		end
	end

	local status = string.format(" Nodes: %d | Edges: %d", visible_nodes, visible_edges)

	if view.filter.active then
		status = status .. string.format(" | Filter: %s=%s", view.filter.type, view.filter.value)
	end

	if view.selected_node then
		local node = graph.nodes[view.selected_node]
		if node then
			status = status .. string.format(" | Selected: %s (deg: %d)", node.name, node.degree)
		end
	end

	status = status .. " | [q]uit [t]ag [f]older [r]eset [l]abels [c]enter [Enter]open"

	return status
end

---Renders help overlay
---@param width number Canvas width
---@param height number Canvas height
---@return string[] Help lines
function M.render_help()
	return {
		"╭──────────────────────────────────────╮",
		"│        🕸️ Graph View Help            │",
		"├──────────────────────────────────────┤",
		"│  Navigation:                         │",
		"│    h/j/k/l  - Move selection         │",
		"│    Enter    - Open selected note     │",
		"│    c        - Center graph           │",
		"│    +/-      - Zoom in/out            │",
		"│                                      │",
		"│  Filtering:                          │",
		"│    t        - Filter by tag          │",
		"│    f        - Filter by folder       │",
		"│    r        - Reset filter           │",
		"│                                      │",
		"│  Display:                            │",
		"│    l        - Toggle labels          │",
		"│    ?        - Toggle this help       │",
		"│    q        - Close graph view       │",
		"│                                      │",
		"│  Legend:                             │",
		"│    ● Large  - High connectivity      │",
		"│    • Small  - Low connectivity       │",
		"│    · Dots   - Edge connections       │",
		"╰──────────────────────────────────────╯",
	}
end

return M
