-- ideaDrop/ui/graph/cache.lua
-- Graph cache system for fast loading - compatible with Obsidian vaults

local config = require("ideaDrop.core.config")

---@class GraphCache
---@field load fun(): table|nil
---@field save fun(data: table): nil
---@field get_file_mtime fun(path: string): number
---@field is_stale fun(cached_entry: table, file_path: string): boolean
local M = {}

-- Cache filename
local CACHE_FILE = ".ideadrop-graph-cache.json"
local OBSIDIAN_CACHE = ".obsidian/graph.json"

---Gets the cache file path
---@return string
local function get_cache_path()
	local idea_dir = config.get_idea_dir and config.get_idea_dir() or config.options.idea_dir
	idea_dir = vim.fn.expand(idea_dir or "")
	return idea_dir .. "/" .. CACHE_FILE
end

---Gets the Obsidian cache file path
---@return string
local function get_obsidian_cache_path()
	local idea_dir = config.get_idea_dir and config.get_idea_dir() or config.options.idea_dir
	idea_dir = vim.fn.expand(idea_dir or "")
	return idea_dir .. "/" .. OBSIDIAN_CACHE
end

---Gets file modification time
---@param path string File path
---@return number Modification time (0 if file doesn't exist)
function M.get_file_mtime(path)
	local stat = vim.loop.fs_stat(path)
	if stat then
		return stat.mtime.sec
	end
	return 0
end

---Checks if a cached entry is stale (file has been modified)
---@param cached_entry table Cached file data
---@param file_path string Current file path
---@return boolean True if cache is stale
function M.is_stale(cached_entry, file_path)
	if not cached_entry or not cached_entry.mtime then
		return true
	end
	local current_mtime = M.get_file_mtime(file_path)
	return current_mtime ~= cached_entry.mtime
end

---Loads the cache from disk
---@return table|nil Cache data or nil if not found/invalid
function M.load()
	local cache_path = get_cache_path()

	-- Check if cache file exists
	if vim.fn.filereadable(cache_path) == 0 then
		return nil
	end

	-- Read and parse cache
	local ok, content = pcall(vim.fn.readfile, cache_path)
	if not ok or #content == 0 then
		return nil
	end

	local json_str = table.concat(content, "\n")
	local ok2, data = pcall(vim.fn.json_decode, json_str)
	if not ok2 or type(data) ~= "table" then
		return nil
	end

	return data
end

---Saves the cache to disk
---@param data table Cache data to save
function M.save(data)
	local cache_path = get_cache_path()

	local ok, json_str = pcall(vim.fn.json_encode, data)
	if not ok then
		return
	end

	-- Write cache file
	local file = io.open(cache_path, "w")
	if file then
		file:write(json_str)
		file:close()
	end
end

---Tries to load Obsidian's graph cache
---@return table|nil Obsidian graph data or nil
function M.load_obsidian_cache()
	local obsidian_path = get_obsidian_cache_path()

	if vim.fn.filereadable(obsidian_path) == 0 then
		return nil
	end

	local ok, content = pcall(vim.fn.readfile, obsidian_path)
	if not ok or #content == 0 then
		return nil
	end

	local json_str = table.concat(content, "\n")
	local ok2, data = pcall(vim.fn.json_decode, json_str)
	if not ok2 or type(data) ~= "table" then
		return nil
	end

	return data
end

---Extracts links from content (fast version)
---@param content string File content
---@return string[] Array of link targets
function M.extract_links_fast(content)
	local links = {}
	local seen = {}

	-- Fast pattern matching for [[link]] and [[link|alias]]
	for link in content:gmatch("%[%[([^%]|]+)") do
		link = link:gsub("^%s+", ""):gsub("%s+$", "") -- trim
		if link ~= "" and not seen[link] then
			links[#links + 1] = link
			seen[link] = true
		end
	end

	return links
end

---Extracts tags from content (fast version)
---@param content string File content
---@return string[] Array of tags
function M.extract_tags_fast(content)
	local tags = {}
	local seen = {}

	for tag in content:gmatch("#([%w%-_]+)") do
		if not seen[tag] and #tag > 1 then
			tags[#tags + 1] = tag
			seen[tag] = true
		end
	end

	return tags
end

---Builds cache data for a single file
---@param file_path string File path
---@return table|nil File cache entry
function M.build_file_cache(file_path)
	local mtime = M.get_file_mtime(file_path)
	if mtime == 0 then
		return nil
	end

	-- Read file content
	local ok, lines = pcall(vim.fn.readfile, file_path)
	if not ok then
		return nil
	end

	local content = table.concat(lines, "\n")

	return {
		mtime = mtime,
		links = M.extract_links_fast(content),
		tags = M.extract_tags_fast(content),
	}
end

---Gets all markdown files using fast directory scan
---@param idea_dir string Directory to scan
---@return string[] Array of file paths
function M.scan_files_fast(idea_dir)
	local files = {}

	-- Use vim.fs.find for faster scanning (Neovim 0.8+)
	if vim.fs and vim.fs.find then
		local found = vim.fs.find(function(name)
			return name:match("%.md$")
		end, {
			path = idea_dir,
			type = "file",
			limit = math.huge,
		})
		return found
	end

	-- Fallback to glob
	files = vim.fn.glob(idea_dir .. "/**/*.md", false, true)
	if #files == 0 then
		files = vim.fn.glob(idea_dir .. "/*.md", false, true)
	end

	return files
end

---Builds or updates the complete cache
---@param force boolean|nil Force full rebuild
---@return table Cache data with files map
function M.build_cache(force)
	local idea_dir = config.get_idea_dir and config.get_idea_dir() or config.options.idea_dir
	idea_dir = vim.fn.expand(idea_dir or ""):gsub("/$", "")

	-- Load existing cache
	local cache = nil
	if not force then
		cache = M.load()
	end
	cache = cache or { files = {}, version = 1 }

	-- Get all current files
	local current_files = M.scan_files_fast(idea_dir)
	local current_files_set = {}
	for _, f in ipairs(current_files) do
		current_files_set[f] = true
	end

	-- Remove deleted files from cache
	local new_files_cache = {}
	for path, entry in pairs(cache.files or {}) do
		if current_files_set[path] then
			new_files_cache[path] = entry
		end
	end
	cache.files = new_files_cache

	-- Update cache for new/modified files
	local updated = 0
	local skipped = 0

	for _, file_path in ipairs(current_files) do
		local cached = cache.files[file_path]

		if M.is_stale(cached, file_path) then
			local entry = M.build_file_cache(file_path)
			if entry then
				cache.files[file_path] = entry
				updated = updated + 1
			end
		else
			skipped = skipped + 1
		end
	end

	-- Save updated cache
	if updated > 0 then
		M.save(cache)
	end

	return cache, updated, skipped
end

---Clears the cache
function M.clear()
	local cache_path = get_cache_path()
	if vim.fn.filereadable(cache_path) == 1 then
		vim.fn.delete(cache_path)
	end
end

return M
