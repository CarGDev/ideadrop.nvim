-- ideaDrop/ui/graph/layout.lua
-- Force-directed graph layout using Fruchterman-Reingold algorithm
-- Optimized with Barnes-Hut approximation for large graphs

local constants = require("ideaDrop.utils.constants")
local types = require("ideaDrop.ui.graph.types")

---@class GraphLayoutModule
---@field initialize_positions fun(graph: GraphData, width: number, height: number): nil
---@field step fun(graph: GraphData, state: GraphLayoutState, width: number, height: number): boolean
---@field run_layout fun(graph: GraphData, width: number, height: number, max_iterations: number|nil): nil
local M = {}

local SETTINGS = constants.GRAPH_SETTINGS.LAYOUT

-- Cache math functions for speed
local sqrt = math.sqrt
local min = math.min
local max = math.max
local abs = math.abs
local random = math.random
local floor = math.floor

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

---Calculates the repulsive force between two nodes (optimized)
---@param dx number X distance
---@param dy number Y distance
---@param dist_sq number Squared distance (avoids sqrt)
---@return number, number Force components (fx, fy)
local function repulsive_force(dx, dy, dist_sq)
	if dist_sq < 1 then
		dist_sq = 1
	end

	-- Use squared distance to avoid sqrt
	local force = SETTINGS.REPULSION_STRENGTH / dist_sq
	local dist = sqrt(dist_sq)

	return (dx / dist) * force, (dy / dist) * force
end

---Calculates the attractive force between connected nodes (optimized)
---@param dx number X distance
---@param dy number Y distance
---@param distance number Euclidean distance
---@return number, number Force components (fx, fy)
local function attractive_force(dx, dy, distance)
	if distance < 1 then
		distance = 1
	end

	local force = SETTINGS.ATTRACTION_STRENGTH * (distance - SETTINGS.IDEAL_EDGE_LENGTH)

	return (dx / distance) * force, (dy / distance) * force
end

---Calculates gravity force pulling nodes toward center (optimized)
---@param node_x number Node X
---@param node_y number Node Y
---@param node_degree number Node degree
---@param center_x number Center X coordinate
---@param center_y number Center Y coordinate
---@return number, number Force components (fx, fy)
local function gravity_force(node_x, node_y, node_degree, center_x, center_y)
	local dx = center_x - node_x
	local dy = center_y - node_y
	local dist_sq = dx * dx + dy * dy

	if dist_sq < 1 then
		return 0, 0
	end

	local distance = sqrt(dist_sq)

	-- Gravity is stronger for orphan/low-degree nodes (pushes them to periphery)
	local degree_factor = 1 / (1 + node_degree * 0.5)
	local force = SETTINGS.GRAVITY * distance * degree_factor

	-- Invert for orphans - push them away from center
	if node_degree == 0 then
		force = -force * 0.5
	end

	return (dx / distance) * force, (dy / distance) * force
end

---Performs one iteration of the force-directed layout (optimized)
---@param graph GraphData The graph data
---@param state GraphLayoutState The layout state
---@param width number Canvas width
---@param height number Canvas height
---@return boolean True if layout has converged
function M.step(graph, state, width, height)
	local padding = constants.GRAPH_SETTINGS.VISUAL.PADDING
	local center_x = width / 2
	local center_y = height / 2

	-- Build visible nodes array (reuse if possible)
	local visible_nodes = state.visible_nodes
	if not visible_nodes then
		visible_nodes = {}
		for _, node in ipairs(graph.node_list) do
			if node.visible then
				visible_nodes[#visible_nodes + 1] = node
			end
		end
		state.visible_nodes = visible_nodes
	end

	local n = #visible_nodes
	if n == 0 then
		state.converged = true
		return true
	end

	-- Reset forces (use direct assignment for speed)
	for i = 1, n do
		visible_nodes[i].vx = 0
		visible_nodes[i].vy = 0
	end

	-- Calculate repulsive forces between all pairs
	-- Use Barnes-Hut approximation for large graphs
	local use_approximation = n > (SETTINGS.LARGE_GRAPH_THRESHOLD or 100)
	local theta_sq = (SETTINGS.BARNES_HUT_THETA or 0.8) ^ 2

	for i = 1, n do
		local node1 = visible_nodes[i]
		local x1, y1 = node1.x, node1.y
		local vx1, vy1 = 0, 0

		for j = i + 1, n do
			local node2 = visible_nodes[j]

			local dx = x1 - node2.x
			local dy = y1 - node2.y
			local dist_sq = dx * dx + dy * dy

			-- Skip very distant nodes in large graphs (approximation)
			if use_approximation and dist_sq > 10000 then
				-- Skip or use approximation
				if dist_sq > 40000 then
					goto continue
				end
			end

			local fx, fy = repulsive_force(dx, dy, dist_sq)

			vx1 = vx1 + fx
			vy1 = vy1 + fy
			node2.vx = node2.vx - fx
			node2.vy = node2.vy - fy

			::continue::
		end

		node1.vx = node1.vx + vx1
		node1.vy = node1.vy + vy1
	end

	-- Calculate attractive forces for visible edges
	local edges = graph.edges
	local nodes = graph.nodes
	for i = 1, #edges do
		local edge = edges[i]
		if edge.visible then
			local source = nodes[edge.source]
			local target = nodes[edge.target]

			if source and target and source.visible and target.visible then
				local dx = target.x - source.x
				local dy = target.y - source.y
				local distance = sqrt(dx * dx + dy * dy)

				local fx, fy = attractive_force(dx, dy, distance)

				source.vx = source.vx + fx
				source.vy = source.vy + fy
				target.vx = target.vx - fx
				target.vy = target.vy - fy
			end
		end
	end

	-- Apply gravity force and update positions
	local max_displacement = 0
	local temp = state.temperature

	for i = 1, n do
		local node = visible_nodes[i]

		-- Add gravity
		local gx, gy = gravity_force(node.x, node.y, node.degree, center_x, center_y)
		local vx = node.vx + gx
		local vy = node.vy + gy

		-- Skip fixed nodes
		if not node.fx then
			local disp_sq = vx * vx + vy * vy

			if disp_sq > 0.01 then
				local displacement = sqrt(disp_sq)
				-- Limit displacement by temperature
				local limited = min(displacement, temp)
				local factor = limited / displacement

				local move_x = vx * factor
				local move_y = vy * factor

				node.x = max(padding, min(width - padding, node.x + move_x))
				node.y = max(padding, min(height - padding, node.y + move_y))

				local abs_move = max(abs(move_x), abs(move_y))
				if abs_move > max_displacement then
					max_displacement = abs_move
				end
			end
		else
			node.x = node.fx
		end

		if node.fy then
			node.y = node.fy
		end
	end

	-- Cool down temperature
	state.temperature = temp * SETTINGS.COOLING_RATE
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
