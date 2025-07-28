-- ideaDrop/features/tags.lua
local config = require("ideaDrop.core.config")

---@class Tags
---@field extract_tags fun(content: string): string[]
---@field get_all_tags fun(): string[]
---@field add_tag fun(file_path: string, tag: string): nil
---@field remove_tag fun(file_path: string, tag: string): nil
---@field get_files_by_tag fun(tag: string): string[]
---@field show_tag_picker fun(callback: fun(tag: string): nil): nil
local M = {}

-- Cache for all tags
local tag_cache = {}
local tag_cache_dirty = true

---Extracts tags from content using #tag pattern
---@param content string The content to extract tags from
---@return string[] Array of tags found
function M.extract_tags(content)
	local tags = {}
	local lines = vim.split(content, "\n")
	
	for _, line in ipairs(lines) do
		-- Find all #tag patterns in the line
		for tag in line:gmatch("#([%w%-_]+)") do
			-- Filter out common words that shouldn't be tags
			if not M.is_common_word(tag) then
				table.insert(tags, tag)
			end
		end
	end
	
	-- Remove duplicates and sort
	local unique_tags = {}
	local seen = {}
	for _, tag in ipairs(tags) do
		if not seen[tag] then
			table.insert(unique_tags, tag)
			seen[tag] = true
		end
	end
	
	table.sort(unique_tags)
	return unique_tags
end

---Checks if a word is too common to be a meaningful tag
---@param word string The word to check
---@return boolean True if it's a common word
function M.is_common_word(word)
	local common_words = {
		"the", "and", "or", "but", "in", "on", "at", "to", "for", "of", "with",
		"by", "is", "are", "was", "were", "be", "been", "have", "has", "had",
		"do", "does", "did", "will", "would", "could", "should", "may", "might",
		"can", "this", "that", "these", "those", "i", "you", "he", "she", "it",
		"we", "they", "me", "him", "her", "us", "them", "my", "your", "his",
		"her", "its", "our", "their", "mine", "yours", "hers", "ours", "theirs"
	}
	
	word = word:lower()
	for _, common in ipairs(common_words) do
		if word == common then
			return true
		end
	end
	
	return false
end

---Gets all unique tags from all idea files
---@return string[] Array of all tags
function M.get_all_tags()
	if not tag_cache_dirty and #tag_cache > 0 then
		return tag_cache
	end
	
	local idea_path = config.options.idea_dir
	local all_tags = {}
	local seen = {}
	
	-- Find all .md files recursively
	local files = vim.fn.glob(idea_path .. "**/*.md", false, true)
	
	for _, file in ipairs(files) do
		if vim.fn.filereadable(file) == 1 then
			local content = vim.fn.readfile(file)
			local file_tags = M.extract_tags(table.concat(content, "\n"))
			
			for _, tag in ipairs(file_tags) do
				if not seen[tag] then
					table.insert(all_tags, tag)
					seen[tag] = true
				end
			end
		end
	end
	
	table.sort(all_tags)
	tag_cache = all_tags
	tag_cache_dirty = false
	
	return all_tags
end

---Adds a tag to a file
---@param file_path string Path to the file
---@param tag string Tag to add
---@return nil
function M.add_tag(file_path, tag)
	if vim.fn.filereadable(file_path) == 0 then
		vim.notify("❌ File not found: " .. file_path, vim.log.levels.ERROR)
		return
	end
	
	local content = vim.fn.readfile(file_path)
	local existing_tags = M.extract_tags(table.concat(content, "\n"))
	
	-- Check if tag already exists
	for _, existing_tag in ipairs(existing_tags) do
		if existing_tag == tag then
			vim.notify("🏷️ Tag '" .. tag .. "' already exists in file", vim.log.levels.INFO)
			return
		end
	end
	
	-- Add tag to the end of the file
	table.insert(content, "")
	table.insert(content, "#" .. tag)
	
	-- Write back to file
	local f, err = io.open(file_path, "w")
	if not f then
		vim.notify("❌ Failed to write file: " .. tostring(err), vim.log.levels.ERROR)
		return
	end
	
	f:write(table.concat(content, "\n") .. "\n")
	f:close()
	
	-- Invalidate cache
	tag_cache_dirty = true
	
	vim.notify("✅ Added tag '" .. tag .. "' to " .. vim.fn.fnamemodify(file_path, ":t"), vim.log.levels.INFO)
end

---Removes a tag from a file
---@param file_path string Path to the file
---@param tag string Tag to remove
---@return nil
function M.remove_tag(file_path, tag)
	if vim.fn.filereadable(file_path) == 0 then
		vim.notify("❌ File not found: " .. file_path, vim.log.levels.ERROR)
		return
	end
	
	local content = vim.fn.readfile(file_path)
	local new_content = {}
	local tag_found = false
	
	for _, line in ipairs(content) do
		-- Check if line contains the tag
		local has_tag = false
		for found_tag in line:gmatch("#([%w%-_]+)") do
			if found_tag == tag then
				has_tag = true
				tag_found = true
				break
			end
		end
		
		if not has_tag then
			table.insert(new_content, line)
		end
	end
	
	if not tag_found then
		vim.notify("🏷️ Tag '" .. tag .. "' not found in file", vim.log.levels.INFO)
		return
	end
	
	-- Write back to file
	local f, err = io.open(file_path, "w")
	if not f then
		vim.notify("❌ Failed to write file: " .. tostring(err), vim.log.levels.ERROR)
		return
	end
	
	f:write(table.concat(new_content, "\n") .. "\n")
	f:close()
	
	-- Invalidate cache
	tag_cache_dirty = true
	
	vim.notify("✅ Removed tag '" .. tag .. "' from " .. vim.fn.fnamemodify(file_path, ":t"), vim.log.levels.INFO)
end

---Gets all files that contain a specific tag
---@param tag string The tag to search for
---@return string[] Array of file paths
function M.get_files_by_tag(tag)
	local idea_path = config.options.idea_dir
	local matching_files = {}
	
	-- Find all .md files recursively
	local files = vim.fn.glob(idea_path .. "**/*.md", false, true)
	
	for _, file in ipairs(files) do
		if vim.fn.filereadable(file) == 1 then
			local content = vim.fn.readfile(file)
			local file_tags = M.extract_tags(table.concat(content, "\n"))
			
			for _, file_tag in ipairs(file_tags) do
				if file_tag == tag then
					table.insert(matching_files, file)
					break
				end
			end
		end
	end
	
	return matching_files
end

---Shows a tag picker UI for selecting tags
---@param callback fun(tag: string): nil Callback function when a tag is selected
---@return nil
function M.show_tag_picker(callback)
	local all_tags = M.get_all_tags()
	
	if #all_tags == 0 then
		vim.notify("🏷️ No tags found in your ideas", vim.log.levels.INFO)
		return
	end
	
	-- Format tags for display
	local tag_choices = {}
	for _, tag in ipairs(all_tags) do
		local files = M.get_files_by_tag(tag)
		table.insert(tag_choices, tag .. " (" .. #files .. " files)")
	end
	
	vim.ui.select(tag_choices, { prompt = "🏷️ Select a tag:" }, function(choice)
		if choice then
			local tag = choice:match("^([%w%-_]+)")
			if tag and callback then
				callback(tag)
			end
		end
	end)
end

---Shows all files with a specific tag
---@param tag string The tag to show files for
---@return nil
function M.show_files_with_tag(tag)
	local files = M.get_files_by_tag(tag)
	
	if #files == 0 then
		vim.notify("📂 No files found with tag '" .. tag .. "'", vim.log.levels.INFO)
		return
	end
	
	-- Format file names for display
	local file_choices = {}
	for _, file in ipairs(files) do
		local filename = vim.fn.fnamemodify(file, ":t")
		local relative_path = file:sub(#config.options.idea_dir + 2) -- Remove idea_dir + "/"
		table.insert(file_choices, relative_path)
	end
	
	vim.ui.select(file_choices, { prompt = "📂 Files with tag '" .. tag .. "':" }, function(choice)
		if choice then
			local full_path = config.options.idea_dir .. "/" .. choice
			-- Open the selected file in the right-side buffer
			local sidebar = require("ideaDrop.ui.sidebar")
			local filename = vim.fn.fnamemodify(full_path, ":t")
			sidebar.open_right_side(full_path, filename)
		end
	end)
end

return M 