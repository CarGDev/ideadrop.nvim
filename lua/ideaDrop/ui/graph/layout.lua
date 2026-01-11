-- ideaDrop/ui/graph/layout.lua
-- Force-directed graph layout using Fruchterman-Reingold algorithm

local constants = require("ideaDrop.utils.constants")
local types = require("ideaDrop.ui.graph.types")

---@class GraphLayoutModule
---@field initialize_positions fun(graph: GraphData, width: number, height: number): nil
---@field step fun(graph: GraphData, state: GraphLayoutState, width: number, height: number): boolean
---@field run_layout fun(graph: GraphData, width: number, height: number, max_iterations: number|nil): nil
local M = {}

local SETTINGS = constants.GRAPH_SETTINGS.LAYOUT

---Initializes node positions randomly within the canvas bounds
---@param graph GraphData The graph data
---@param width number Canvas width
---@param height number Canvas height
function M.initialize_positions(graph, width, height)
	local padding = constants.GRAPH_SETTINGS.VISUAL.PADDING
	local effective_width = width - 2 * padding
	local effective_height = height - 2 * padding
	local center_x = width / 2
	local center_y = height / 2

	-- Seed random for reproducible layouts (based on node count)
	math.randomseed(#graph.node_list * 12345)

	for _, node in ipairs(graph.node_list) do
		-- Initialize in a circular pattern with some randomness
		local angle = math.random() * 2 * math.pi
		local radius = math.random() * math.min(effective_width, effective_height) / 3

		node.x = center_x + radius * math.cos(angle)
		node.y = center_y + radius * math.sin(angle)
		node.vx = 0
		node.vy = 0
	end

	-- Special handling: place high-degree nodes closer to center initially
	local max_degree = 0
	for _, node in ipairs(graph.node_list) do
		if node.degree > max_degree then
			max_degree = node.degree
		end
	end

	if max_degree > 0 then
		for _, node in ipairs(graph.node_list) do
			local centrality = node.degree / max_degree
			-- Move high-degree nodes toward center
			node.x = center_x + (node.x - center_x) * (1 - centrality * 0.5)
			node.y = center_y + (node.y - center_y) * (1 - centrality * 0.5)
		end
	end
end

---Calculates the repulsive force between two nodes
---@param dx number X distance
---@param dy number Y distance
---@param distance number Euclidean distance
---@return number, number Force components (fx, fy)
local function repulsive_force(dx, dy, distance)
	if distance < 0.1 then
		distance = 0.1 -- Prevent division by zero
	end

	local force = SETTINGS.REPULSION_STRENGTH / (distance * distance)

	return (dx / distance) * force, (dy / distance) * force
end

---Calculates the attractive force between connected nodes
---@param dx number X distance
---@param dy number Y distance
---@param distance number Euclidean distance
---@return number, number Force components (fx, fy)
local function attractive_force(dx, dy, distance)
	if distance < 0.1 then
		distance = 0.1
	end

	local force = SETTINGS.ATTRACTION_STRENGTH * (distance - SETTINGS.IDEAL_EDGE_LENGTH)

	return (dx / distance) * force, (dy / distance) * force
end

---Calculates gravity force pulling nodes toward center
---@param node GraphNode The node
---@param center_x number Center X coordinate
---@param center_y number Center Y coordinate
---@return number, number Force components (fx, fy)
local function gravity_force(node, center_x, center_y)
	local dx = center_x - node.x
	local dy = center_y - node.y
	local distance = math.sqrt(dx * dx + dy * dy)

	if distance < 0.1 then
		return 0, 0
	end

	-- Gravity is stronger for orphan/low-degree nodes (pushes them to periphery)
	-- and weaker for high-degree nodes (lets them stay in center)
	local degree_factor = 1 / (1 + node.degree * 0.5)
	local force = SETTINGS.GRAVITY * distance * degree_factor

	-- Invert for orphans - push them away from center
	if node.degree == 0 then
		force = -force * 0.5
	end

	return (dx / distance) * force, (dy / distance) * force
end

---Performs one iteration of the force-directed layout
---@param graph GraphData The graph data
---@param state GraphLayoutState The layout state
---@param width number Canvas width
---@param height number Canvas height
---@return boolean True if layout has converged
function M.step(graph, state, width, height)
	local padding = constants.GRAPH_SETTINGS.VISUAL.PADDING
	local center_x = width / 2
	local center_y = height / 2

	-- Count visible nodes
	local visible_nodes = {}
	for _, node in ipairs(graph.node_list) do
		if node.visible then
			table.insert(visible_nodes, node)
		end
	end

	if #visible_nodes == 0 then
		state.converged = true
		return true
	end

	-- Reset forces
	for _, node in ipairs(visible_nodes) do
		node.vx = 0
		node.vy = 0
	end

	-- Calculate repulsive forces between all pairs of visible nodes
	for i = 1, #visible_nodes do
		local node1 = visible_nodes[i]
		for j = i + 1, #visible_nodes do
			local node2 = visible_nodes[j]

			local dx = node1.x - node2.x
			local dy = node1.y - node2.y
			local distance = math.sqrt(dx * dx + dy * dy)

			local fx, fy = repulsive_force(dx, dy, distance)

			node1.vx = node1.vx + fx
			node1.vy = node1.vy + fy
			node2.vx = node2.vx - fx
			node2.vy = node2.vy - fy
		end
	end

	-- Calculate attractive forces for visible edges
	for _, edge in ipairs(graph.edges) do
		if edge.visible then
			local source = graph.nodes[edge.source]
			local target = graph.nodes[edge.target]

			if source and target and source.visible and target.visible then
				local dx = target.x - source.x
				local dy = target.y - source.y
				local distance = math.sqrt(dx * dx + dy * dy)

				local fx, fy = attractive_force(dx, dy, distance)

				source.vx = source.vx + fx
				source.vy = source.vy + fy
				target.vx = target.vx - fx
				target.vy = target.vy - fy
			end
		end
	end

	-- Apply gravity force
	for _, node in ipairs(visible_nodes) do
		local gx, gy = gravity_force(node, center_x, center_y)
		node.vx = node.vx + gx
		node.vy = node.vy + gy
	end

	-- Apply forces with temperature-limited displacement
	local max_displacement = 0

	for _, node in ipairs(visible_nodes) do
		-- Skip fixed nodes
		if node.fx then
			node.x = node.fx
		else
			local displacement = math.sqrt(node.vx * node.vx + node.vy * node.vy)

			if displacement > 0 then
				-- Limit displacement by temperature
				local limited_displacement = math.min(displacement, state.temperature)
				local factor = limited_displacement / displacement

				local dx = node.vx * factor
				local dy = node.vy * factor

				node.x = node.x + dx
				node.y = node.y + dy

				if math.abs(dx) > max_displacement then
					max_displacement = math.abs(dx)
				end
				if math.abs(dy) > max_displacement then
					max_displacement = math.abs(dy)
				end
			end
		end

		if node.fy then
			node.y = node.fy
		end

		-- Keep nodes within bounds
		node.x = math.max(padding, math.min(width - padding, node.x))
		node.y = math.max(padding, math.min(height - padding, node.y))
	end

	-- Cool down temperature
	state.temperature = state.temperature * SETTINGS.COOLING_RATE
	state.iteration = state.iteration + 1

	-- Check convergence
	state.converged = max_displacement < SETTINGS.MIN_VELOCITY
		or state.iteration >= SETTINGS.MAX_ITERATIONS

	return state.converged
end

---Runs the complete layout algorithm synchronously
---@param graph GraphData The graph data
---@param width number Canvas width
---@param height number Canvas height
---@param max_iterations number|nil Maximum iterations (defaults to SETTINGS.MAX_ITERATIONS)
function M.run_layout(graph, width, height, max_iterations)
	max_iterations = max_iterations or SETTINGS.MAX_ITERATIONS

	-- Initialize positions
	M.initialize_positions(graph, width, height)

	-- Create layout state
	local state = types.create_layout_state(SETTINGS.INITIAL_TEMPERATURE)

	-- Run until convergence
	while not state.converged and state.iteration < max_iterations do
		M.step(graph, state, width, height)
	end
end

---Creates an animated layout that updates incrementally
---@param graph GraphData The graph data
---@param width number Canvas width
---@param height number Canvas height
---@param on_step fun(converged: boolean): nil Callback after each step
---@param frame_delay number|nil Delay between frames in ms (default 16ms ~60fps)
---@return GraphLayoutState The layout state (can be used to stop animation)
function M.start_animated_layout(graph, width, height, on_step, frame_delay)
	frame_delay = frame_delay or 16

	-- Initialize positions
	M.initialize_positions(graph, width, height)

	-- Create layout state
	local state = types.create_layout_state(SETTINGS.INITIAL_TEMPERATURE)
	state.running = true

	-- Animation function
	local function animate()
		if not state.running then
			return
		end

		local converged = M.step(graph, state, width, height)

		if on_step then
			on_step(converged)
		end

		if not converged and state.running then
			state.timer = vim.defer_fn(animate, frame_delay)
		else
			state.running = false
		end
	end

	-- Start animation
	vim.defer_fn(animate, 0)

	return state
end

---Stops an animated layout
---@param state GraphLayoutState The layout state
function M.stop_animated_layout(state)
	state.running = false
	if state.timer then
		-- Timer will naturally stop on next check
		state.timer = nil
	end
end

---Adjusts layout after filter changes (re-runs partial layout)
---@param graph GraphData The graph data
---@param width number Canvas width
---@param height number Canvas height
---@param iterations number|nil Number of adjustment iterations
function M.adjust_after_filter(graph, width, height, iterations)
	iterations = iterations or 50

	local state = types.create_layout_state(SETTINGS.INITIAL_TEMPERATURE * 0.3)

	for _ = 1, iterations do
		if M.step(graph, state, width, height) then
			break
		end
	end
end

---Centers the visible graph within the canvas
---@param graph GraphData The graph data
---@param width number Canvas width
---@param height number Canvas height
function M.center_graph(graph, width, height)
	local min_x, max_x = math.huge, -math.huge
	local min_y, max_y = math.huge, -math.huge
	local visible_count = 0

	for _, node in ipairs(graph.node_list) do
		if node.visible then
			min_x = math.min(min_x, node.x)
			max_x = math.max(max_x, node.x)
			min_y = math.min(min_y, node.y)
			max_y = math.max(max_y, node.y)
			visible_count = visible_count + 1
		end
	end

	if visible_count == 0 then
		return
	end

	local graph_center_x = (min_x + max_x) / 2
	local graph_center_y = (min_y + max_y) / 2
	local canvas_center_x = width / 2
	local canvas_center_y = height / 2

	local offset_x = canvas_center_x - graph_center_x
	local offset_y = canvas_center_y - graph_center_y

	for _, node in ipairs(graph.node_list) do
		if node.visible then
			node.x = node.x + offset_x
			node.y = node.y + offset_y
		end
	end
end

return M
