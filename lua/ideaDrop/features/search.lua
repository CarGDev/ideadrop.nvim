-- ideaDrop/features/search.lua
local config = require("ideaDrop.core.config")
local sidebar = require("ideaDrop.ui.sidebar")

---@class Search
---@field fuzzy_search fun(query: string): nil
---@field search_in_content fun(query: string): nil
---@field search_by_title fun(query: string): nil
---@field show_search_results fun(results: table[]): nil
local M = {}

-- Simple fuzzy matching function
local function fuzzy_match(str, pattern)
	local str_lower = str:lower()
	local pattern_lower = pattern:lower()
	
	local str_idx = 1
	local pattern_idx = 1
	
	while str_idx <= #str_lower and pattern_idx <= #pattern_lower do
		if str_lower:sub(str_idx, str_idx) == pattern_lower:sub(pattern_idx, pattern_idx) then
			pattern_idx = pattern_idx + 1
		end
		str_idx = str_idx + 1
	end
	
	return pattern_idx > #pattern_lower
end

-- Calculate fuzzy match score (lower is better)
local function fuzzy_score(str, pattern)
	local str_lower = str:lower()
	local pattern_lower = pattern:lower()
	
	local score = 0
	local str_idx = 1
	local pattern_idx = 1
	local consecutive_bonus = 0
	
	while str_idx <= #str_lower and pattern_idx <= #pattern_lower do
		if str_lower:sub(str_idx, str_idx) == pattern_lower:sub(pattern_idx, pattern_idx) then
			score = score + 1 + consecutive_bonus
			consecutive_bonus = consecutive_bonus + 1
			pattern_idx = pattern_idx + 1
		else
			consecutive_bonus = 0
		end
		str_idx = str_idx + 1
	end
	
	if pattern_idx <= #pattern_lower then
		return 999999 -- No match
	end
	
	-- Penalize longer strings
	score = score - (#str_lower - #pattern_lower) * 0.1
	
	return -score -- Negative so lower scores are better
end

---Performs fuzzy search across all idea files
---@param query string Search query
---@return nil
function M.fuzzy_search(query)
	if query == "" then
		vim.notify("❌ Please provide a search query", vim.log.levels.ERROR)
		return
	end
	
	local idea_path = config.options.idea_dir
	local results = {}
	
	-- Find all .md files recursively
	local files = vim.fn.glob(idea_path .. "**/*.md", false, true)
	
	for _, file in ipairs(files) do
		if vim.fn.filereadable(file) == 1 then
			local filename = vim.fn.fnamemodify(file, ":t")
			local relative_path = file:sub(#idea_path + 2) -- Remove idea_path + "/"
			
			-- Search in filename
			local filename_score = fuzzy_score(filename, query)
			if filename_score < 999999 then
				table.insert(results, {
					file = file,
					relative_path = relative_path,
					filename = filename,
					score = filename_score,
					match_type = "filename",
					context = filename
				})
			end
			
			-- Search in content
			local content = vim.fn.readfile(file)
			local content_str = table.concat(content, "\n")
			
			-- Search for query in content
			local content_lower = content_str:lower()
			local query_lower = query:lower()
			
			if content_lower:find(query_lower, 1, true) then
				-- Find the line with the match
				for line_num, line in ipairs(content) do
					if line:lower():find(query_lower, 1, true) then
						local context = line:gsub("^%s*(.-)%s*$", "%1") -- Trim whitespace
						if #context > 80 then
							context = context:sub(1, 77) .. "..."
						end
						
						table.insert(results, {
							file = file,
							relative_path = relative_path,
							filename = filename,
							score = fuzzy_score(context, query) - 10, -- Slight bonus for content matches
							match_type = "content",
							context = context,
							line_number = line_num
						})
						break
					end
				end
			end
		end
	end
	
	-- Sort by score (best matches first)
	table.sort(results, function(a, b)
		return a.score < b.score
	end)
	
	-- Limit results
	if #results > 20 then
		results = vim.list_slice(results, 1, 20)
	end
	
	if #results == 0 then
		vim.notify("🔍 No results found for '" .. query .. "'", vim.log.levels.INFO)
		return
	end
	
	M.show_search_results(results, query)
end

---Shows search results in a picker
---@param results table[] Array of search results
---@param query string Original search query
---@return nil
function M.show_search_results(results, query)
	local choices = {}
	
	for _, result in ipairs(results) do
		local icon = result.match_type == "filename" and "📄" or "📝"
		local line_info = result.line_number and (" (line " .. result.line_number .. ")") or ""
		local choice = icon .. " " .. result.relative_path .. line_info
		
		if result.context and result.context ~= result.filename then
			choice = choice .. "\n   " .. result.context
		end
		
		table.insert(choices, choice)
	end
	
	vim.ui.select(choices, { 
		prompt = "🔍 Search results for '" .. query .. "':",
		format_item = function(item)
			return item
		end
	}, function(choice, idx)
		if choice and idx then
			local selected_result = results[idx]
			-- Open the selected file in the right-side buffer
			local filename = vim.fn.fnamemodify(selected_result.file, ":t")
			sidebar.open_right_side(selected_result.file, filename)
			
			-- If it was a content match, jump to the line
			if selected_result.line_number then
				-- Wait a bit for the buffer to load, then jump to line
				vim.defer_fn(function()
					if sidebar.get_current_file() == selected_result.file then
						vim.api.nvim_win_set_cursor(0, {selected_result.line_number, 0})
					end
				end, 100)
			end
		end
	end)
end

---Searches only in file content
---@param query string Search query
---@return nil
function M.search_in_content(query)
	if query == "" then
		vim.notify("❌ Please provide a search query", vim.log.levels.ERROR)
		return
	end
	
	local idea_path = config.options.idea_dir
	local results = {}
	
	-- Find all .md files recursively
	local files = vim.fn.glob(idea_path .. "**/*.md", false, true)
	
	for _, file in ipairs(files) do
		if vim.fn.filereadable(file) == 1 then
			local content = vim.fn.readfile(file)
			local content_str = table.concat(content, "\n")
			
			-- Search for query in content
			local content_lower = content_str:lower()
			local query_lower = query:lower()
			
			if content_lower:find(query_lower, 1, true) then
				local filename = vim.fn.fnamemodify(file, ":t")
				local relative_path = file:sub(#idea_path + 2)
				
				-- Find the line with the match
				for line_num, line in ipairs(content) do
					if line:lower():find(query_lower, 1, true) then
						local context = line:gsub("^%s*(.-)%s*$", "%1")
						if #context > 80 then
							context = context:sub(1, 77) .. "..."
						end
						
						table.insert(results, {
							file = file,
							relative_path = relative_path,
							filename = filename,
							context = context,
							line_number = line_num
						})
						break
					end
				end
			end
		end
	end
	
	if #results == 0 then
		vim.notify("🔍 No content matches found for '" .. query .. "'", vim.log.levels.INFO)
		return
	end
	
	M.show_search_results(results, query)
end

---Searches only in file titles
---@param query string Search query
---@return nil
function M.search_by_title(query)
	if query == "" then
		vim.notify("❌ Please provide a search query", vim.log.levels.ERROR)
		return
	end
	
	local idea_path = config.options.idea_dir
	local results = {}
	
	-- Find all .md files recursively
	local files = vim.fn.glob(idea_path .. "**/*.md", false, true)
	
	for _, file in ipairs(files) do
		if vim.fn.filereadable(file) == 1 then
			local filename = vim.fn.fnamemodify(file, ":t")
			local relative_path = file:sub(#idea_path + 2)
			
			-- Search in filename
			if fuzzy_match(filename, query) then
				table.insert(results, {
					file = file,
					relative_path = relative_path,
					filename = filename,
					score = fuzzy_score(filename, query),
					match_type = "filename",
					context = filename
				})
			end
		end
	end
	
	-- Sort by score
	table.sort(results, function(a, b)
		return a.score < b.score
	end)
	
	if #results == 0 then
		vim.notify("🔍 No title matches found for '" .. query .. "'", vim.log.levels.INFO)
		return
	end
	
	M.show_search_results(results, query)
end

return M 