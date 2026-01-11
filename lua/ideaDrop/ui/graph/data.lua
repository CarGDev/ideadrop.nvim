-- ideaDrop/ui/graph/data.lua
-- Graph data model: parses markdown files and builds node/edge structures

local config = require("ideaDrop.core.config")
local types = require("ideaDrop.ui.graph.types")
local cache = require("ideaDrop.ui.graph.cache")

---@class GraphDataModule
---@field build_graph fun(): GraphData
---@field extract_links fun(content: string): string[]
---@field resolve_link fun(link_text: string, base_dir: string): string|nil
---@field get_node_by_position fun(graph: GraphData, x: number, y: number, threshold: number): GraphNode|nil
local M = {}

---Extracts [[wiki-style links]] from markdown content
---@param content string The markdown content
---@return string[] Array of link targets (without brackets)
function M.extract_links(content)
	local links = {}
	local seen = {}

	-- Match [[link]] pattern
	for link in content:gmatch("%[%[([^%]]+)%]%]") do
		-- Handle [[link|alias]] format - take the link part
		local actual_link = link:match("^([^|]+)") or link
		-- Trim whitespace
		actual_link = actual_link:gsub("^%s*(.-)%s*$", "%1")

		if not seen[actual_link] and actual_link ~= "" then
			table.insert(links, actual_link)
			seen[actual_link] = true
		end
	end

	return links
end

---Resolves a link text to a file path
---@param link_text string The link text (without brackets)
---@param idea_dir string The idea directory path
---@param existing_files table<string, string> Map of normalized names to file paths
---@return string|nil Resolved file path or nil if not found
function M.resolve_link(link_text, idea_dir, existing_files)
	-- Normalize the link text
	local normalized = link_text:lower():gsub("%s+", "-")

	-- Try direct match first
	if existing_files[normalized] then
		return existing_files[normalized]
	end

	-- Try with .md extension
	if existing_files[normalized .. ".md"] then
		return existing_files[normalized .. ".md"]
	end

	-- Try fuzzy matching - match just the filename part
	local link_basename = vim.fn.fnamemodify(link_text, ":t"):lower():gsub("%s+", "-")
	for name, path in pairs(existing_files) do
		local file_basename = vim.fn.fnamemodify(name, ":t"):gsub("%.md$", "")
		if file_basename == link_basename or file_basename == normalized then
			return path
		end
	end

	return nil
end

---Builds a normalized name for a file (used as node ID)
---@param file_path string Full file path
---@param idea_dir string The idea directory
---@return string Normalized name (relative path without extension)
function M.normalize_file_name(file_path, idea_dir)
	local relative = file_path
	if file_path:sub(1, #idea_dir) == idea_dir then
		relative = file_path:sub(#idea_dir + 2) -- Remove idea_dir + "/"
	end
	-- Remove .md extension
	return relative:gsub("%.md$", "")
end

---Gets display name from a node ID
---@param node_id string The node ID
---@return string Display name
function M.get_display_name(node_id)
	-- Get just the filename part without path
	local name = vim.fn.fnamemodify(node_id, ":t")
	-- Capitalize and clean up
	return name:gsub("-", " "):gsub("^%l", string.upper)
end

---Builds the complete graph from markdown files (using cache for speed)
---@param force_rebuild boolean|nil Force cache rebuild
---@return GraphData
function M.build_graph(force_rebuild)
	-- Get idea_dir using the getter function if available, otherwise direct access
	local idea_dir = config.get_idea_dir and config.get_idea_dir() or config.options.idea_dir
	local graph = types.create_graph_data()

	-- Validate idea_dir
	if not idea_dir or idea_dir == "" then
		vim.notify("❌ idea_dir is not configured. Please set it in setup().", vim.log.levels.ERROR)
		return graph
	end

	-- Expand any environment variables or ~ in path (in case getter wasn't used)
	idea_dir = vim.fn.expand(idea_dir)

	-- Remove trailing slash if present
	idea_dir = idea_dir:gsub("/$", "")

	-- Check if directory exists
	if vim.fn.isdirectory(idea_dir) == 0 then
		vim.notify("❌ idea_dir does not exist: " .. idea_dir, vim.log.levels.ERROR)
		return graph
	end

	-- Build/update cache (only reads modified files)
	local file_cache, updated, skipped = cache.build_cache(force_rebuild)

	if not file_cache or not file_cache.files or vim.tbl_isempty(file_cache.files) then
		vim.notify(
			string.format("📂 No .md files found in: %s", idea_dir),
			vim.log.levels.WARN
		)
		return graph
	end

	-- Build file map for link resolution
	local file_map = {}
	for file_path, _ in pairs(file_cache.files) do
		local normalized = M.normalize_file_name(file_path, idea_dir):lower()
		file_map[normalized] = file_path

		-- Also map just the filename
		local basename = vim.fn.fnamemodify(file_path, ":t:r"):lower()
		if not file_map[basename] then
			file_map[basename] = file_path
		end
	end

	-- First pass: create all nodes from cache
	for file_path, file_data in pairs(file_cache.files) do
		local node_id = M.normalize_file_name(file_path, idea_dir)
		local display_name = M.get_display_name(node_id)

		local node = types.create_node(node_id, display_name, file_path)
		node.tags = file_data.tags or {}

		graph.nodes[node_id] = node
		graph.node_list[#graph.node_list + 1] = node
	end

	-- Second pass: create edges from cached links
	local edge_set = {} -- Track unique edges (undirected)

	for file_path, file_data in pairs(file_cache.files) do
		local source_id = M.normalize_file_name(file_path, idea_dir)
		local links = file_data.links or {}

		for _, link_text in ipairs(links) do
			local target_path = M.resolve_link(link_text, idea_dir, file_map)

			if target_path then
				local target_id = M.normalize_file_name(target_path, idea_dir)

				-- Skip self-links
				if source_id ~= target_id then
					-- Create undirected edge key (sorted)
					local edge_key
					if source_id < target_id then
						edge_key = source_id .. "|||" .. target_id
					else
						edge_key = target_id .. "|||" .. source_id
					end

					-- Only add if not already exists
					if not edge_set[edge_key] then
						edge_set[edge_key] = true

						local edge = types.create_edge(source_id, target_id)
						graph.edges[#graph.edges + 1] = edge

						-- Update degrees
						if graph.nodes[source_id] then
							graph.nodes[source_id].degree = graph.nodes[source_id].degree + 1
						end
						if graph.nodes[target_id] then
							graph.nodes[target_id].degree = graph.nodes[target_id].degree + 1
						end
					end
				end
			end
		end
	end

	-- Show cache stats
	local total = updated + skipped
	if updated > 0 then
		vim.notify(string.format("📊 Cache: %d updated, %d cached (%d total)", updated, skipped, total), vim.log.levels.INFO)
	end

	return graph
end

---Finds a node at a given position (for mouse/cursor interaction)
---@param graph GraphData The graph data
---@param x number X coordinate
---@param y number Y coordinate
---@param threshold number Distance threshold for hit detection
---@return GraphNode|nil Node at position or nil
function M.get_node_by_position(graph, x, y, threshold)
	local closest_node = nil
	local closest_dist = threshold + 1

	for _, node in ipairs(graph.node_list) do
		if node.visible then
			local dx = node.x - x
			local dy = node.y - y
			local dist = math.sqrt(dx * dx + dy * dy)

			if dist < closest_dist then
				closest_dist = dist
				closest_node = node
			end
		end
	end

	return closest_node
end

---Gets all unique folders from the graph
---@param graph GraphData The graph data
---@return string[] Array of folder names
function M.get_folders(graph)
	local folders = {}
	local seen = {}

	for _, node in ipairs(graph.node_list) do
		if not seen[node.folder] then
			table.insert(folders, node.folder)
			seen[node.folder] = true
		end
	end

	table.sort(folders)
	return folders
end

---Gets all unique tags from the graph
---@param graph GraphData The graph data
---@return string[] Array of tag names
function M.get_tags(graph)
	local tags = {}
	local seen = {}

	for _, node in ipairs(graph.node_list) do
		for _, tag in ipairs(node.tags) do
			if not seen[tag] then
				table.insert(tags, tag)
				seen[tag] = true
			end
		end
	end

	table.sort(tags)
	return tags
end

---Applies a filter to the graph
---@param graph GraphData The graph data
---@param filter_type string|nil "tag", "folder", or nil to clear
---@param filter_value string|nil The filter value
function M.apply_filter(graph, filter_type, filter_value)
	-- Reset all visibility first
	for _, node in ipairs(graph.node_list) do
		node.visible = true
	end
	for _, edge in ipairs(graph.edges) do
		edge.visible = true
	end

	-- Apply filter if specified
	if filter_type and filter_value then
		-- First pass: hide nodes that don't match
		for _, node in ipairs(graph.node_list) do
			local matches = false

			if filter_type == "tag" then
				for _, tag in ipairs(node.tags) do
					if tag == filter_value then
						matches = true
						break
					end
				end
			elseif filter_type == "folder" then
				matches = node.folder == filter_value
			elseif filter_type == "search" then
				local search_lower = filter_value:lower()
				matches = node.name:lower():find(search_lower, 1, true) ~= nil
					or node.id:lower():find(search_lower, 1, true) ~= nil
			end

			node.visible = matches
		end

		-- Second pass: hide edges where either endpoint is hidden
		for _, edge in ipairs(graph.edges) do
			local source_visible = graph.nodes[edge.source] and graph.nodes[edge.source].visible
			local target_visible = graph.nodes[edge.target] and graph.nodes[edge.target].visible
			edge.visible = source_visible and target_visible
		end
	end
end

---Gets graph statistics
---@param graph GraphData The graph data
---@return table Statistics
function M.get_statistics(graph)
	local total_nodes = #graph.node_list
	local visible_nodes = 0
	local orphan_nodes = 0
	local total_edges = #graph.edges
	local visible_edges = 0
	local max_degree = 0
	local total_degree = 0

	for _, node in ipairs(graph.node_list) do
		if node.visible then
			visible_nodes = visible_nodes + 1
		end
		if node.degree == 0 then
			orphan_nodes = orphan_nodes + 1
		end
		if node.degree > max_degree then
			max_degree = node.degree
		end
		total_degree = total_degree + node.degree
	end

	for _, edge in ipairs(graph.edges) do
		if edge.visible then
			visible_edges = visible_edges + 1
		end
	end

	return {
		total_nodes = total_nodes,
		visible_nodes = visible_nodes,
		orphan_nodes = orphan_nodes,
		total_edges = total_edges,
		visible_edges = visible_edges,
		max_degree = max_degree,
		avg_degree = total_nodes > 0 and (total_degree / total_nodes) or 0,
	}
end

return M
