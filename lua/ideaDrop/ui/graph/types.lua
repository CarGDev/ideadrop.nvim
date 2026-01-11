-- ideaDrop/ui/graph/types.lua
-- Type definitions for the graph visualization system

---@class GraphNode
---@field id string Unique identifier (file path without extension)
---@field name string Display name
---@field file_path string Full file path
---@field folder string Parent folder name
---@field tags string[] Tags from the file
---@field degree number Number of connections
---@field x number X position in layout
---@field y number Y position in layout
---@field vx number X velocity
---@field vy number Y velocity
---@field fx number|nil Fixed X position (for pinning)
---@field fy number|nil Fixed Y position (for pinning)
---@field visible boolean Whether node is visible (filtering)
---@field selected boolean Whether node is selected

---@class GraphEdge
---@field source string Source node ID
---@field target string Target node ID
---@field visible boolean Whether edge is visible (filtering)

---@class GraphData
---@field nodes table<string, GraphNode> Map of node ID to node
---@field edges GraphEdge[] Array of edges
---@field node_list GraphNode[] Array of nodes for iteration

---@class GraphLayoutState
---@field temperature number Current temperature for simulated annealing
---@field iteration number Current iteration
---@field converged boolean Whether layout has converged
---@field running boolean Whether simulation is running
---@field timer any Timer handle for animation

---@class GraphFilter
---@field type string|nil Filter type: "tag", "folder", "search", or nil
---@field value string|nil Filter value
---@field active boolean Whether filter is active

---@class GraphViewState
---@field zoom number Zoom level (1.0 = default)
---@field offset_x number X offset for panning
---@field offset_y number Y offset for panning
---@field selected_node string|nil Currently selected node ID
---@field hovered_node string|nil Currently hovered node ID
---@field show_labels boolean Whether to show node labels
---@field filter GraphFilter Current filter state

---@class GraphCanvas
---@field width number Canvas width in characters
---@field height number Canvas height in characters
---@field buffer string[][] 2D buffer of characters
---@field highlights table[] Array of highlight regions

---@class GraphConfig
---@field node_colors table<string, string> Map of folder/tag to color
---@field default_node_color string Default node color
---@field show_orphans boolean Whether to show orphan nodes
---@field animate boolean Whether to animate layout
---@field animation_speed number Animation speed (ms per frame)

local M = {}

---Creates a new GraphNode
---@param id string Node ID
---@param name string Display name
---@param file_path string Full file path
---@return GraphNode
function M.create_node(id, name, file_path)
	return {
		id = id,
		name = name,
		file_path = file_path,
		folder = vim.fn.fnamemodify(file_path, ":h:t"),
		tags = {},
		degree = 0,
		x = 0,
		y = 0,
		vx = 0,
		vy = 0,
		fx = nil,
		fy = nil,
		visible = true,
		selected = false,
	}
end

---Creates a new GraphEdge
---@param source string Source node ID
---@param target string Target node ID
---@return GraphEdge
function M.create_edge(source, target)
	return {
		source = source,
		target = target,
		visible = true,
	}
end

---Creates empty GraphData
---@return GraphData
function M.create_graph_data()
	return {
		nodes = {},
		edges = {},
		node_list = {},
	}
end

---Creates initial GraphLayoutState
---@param initial_temperature number
---@return GraphLayoutState
function M.create_layout_state(initial_temperature)
	return {
		temperature = initial_temperature,
		iteration = 0,
		converged = false,
		running = false,
		timer = nil,
	}
end

---Creates initial GraphViewState
---@return GraphViewState
function M.create_view_state()
	return {
		zoom = 1.0,
		offset_x = 0,
		offset_y = 0,
		selected_node = nil,
		hovered_node = nil,
		show_labels = true,
		filter = {
			type = nil,
			value = nil,
			active = false,
		},
	}
end

---Creates empty GraphCanvas
---@param width number
---@param height number
---@return GraphCanvas
function M.create_canvas(width, height)
	local buffer = {}
	for y = 1, height do
		buffer[y] = {}
		for x = 1, width do
			buffer[y][x] = " "
		end
	end
	return {
		width = width,
		height = height,
		buffer = buffer,
		highlights = {},
	}
end

return M
