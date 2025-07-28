-- ideaDrop/utils/utils.lua
local M = {}

---@class Utils
---@field ensure_dir fun(path: string): nil
---@field get_relative_path fun(full_path: string, base_path: string): string
---@field sanitize_filename fun(filename: string): string
---@field format_date fun(date_format: string|nil): string
---@field truncate_string fun(str: string, max_length: number): string
---@field table_contains fun(tbl: table, value: any): boolean
---@field deep_copy fun(orig: table): table

---Ensures a directory exists, creating it if necessary
---@param path string Directory path to ensure
---@return nil
function M.ensure_dir(path)
	if vim.fn.isdirectory(path) == 0 then
		vim.fn.mkdir(path, "p")
	end
end

---Gets the relative path from a full path
---@param full_path string Full file path
---@param base_path string Base directory path
---@return string Relative path
function M.get_relative_path(full_path, base_path)
	if full_path:sub(1, #base_path) == base_path then
		return full_path:sub(#base_path + 2) -- Remove base_path + "/"
	end
	return full_path
end

---Sanitizes a filename for safe file creation
---@param filename string Original filename
---@return string Sanitized filename
function M.sanitize_filename(filename)
	-- Remove or replace invalid characters
	local sanitized = filename:gsub("[<>:\"/\\|?*]", "_")
	-- Remove leading/trailing spaces and dots
	sanitized = sanitized:gsub("^[%s%.]+", ""):gsub("[%s%.]+$", "")
	-- Ensure it's not empty
	if sanitized == "" then
		sanitized = "untitled"
	end
	return sanitized
end

---Formats current date with optional format
---@param date_format string|nil Date format string (default: "%Y-%m-%d")
---@return string Formatted date string
function M.format_date(date_format)
	date_format = date_format or "%Y-%m-%d"
	return os.date(date_format)
end

---Truncates a string to specified length with ellipsis
---@param str string String to truncate
---@param max_length number Maximum length
---@return string Truncated string
function M.truncate_string(str, max_length)
	if #str <= max_length then
		return str
	end
	return str:sub(1, max_length - 3) .. "..."
end

---Checks if a table contains a specific value
---@param tbl table Table to search
---@param value any Value to find
---@return boolean True if value is found
function M.table_contains(tbl, value)
	for _, v in ipairs(tbl) do
		if v == value then
			return true
		end
	end
	return false
end

---Creates a deep copy of a table
---@param orig table Original table
---@return table Deep copy of the table
function M.deep_copy(orig)
	local copy
	if type(orig) == "table" then
		copy = {}
		for orig_key, orig_value in next, orig, nil do
			copy[M.deep_copy(orig_key)] = M.deep_copy(orig_value)
		end
		setmetatable(copy, M.deep_copy(getmetatable(orig)))
	else
		copy = orig
	end
	return copy
end

---Splits a string by delimiter
---@param str string String to split
---@param delimiter string Delimiter character
---@return table Array of substrings
function M.split_string(str, delimiter)
	delimiter = delimiter or "\n"
	local result = {}
	for match in (str .. delimiter):gmatch("(.-)" .. delimiter) do
		table.insert(result, match)
	end
	return result
end

---Joins table elements with a delimiter
---@param tbl table Table to join
---@param delimiter string Delimiter string
---@return string Joined string
function M.join_strings(tbl, delimiter)
	delimiter = delimiter or "\n"
	return table.concat(tbl, delimiter)
end

---Gets file extension from filename
---@param filename string Filename
---@return string File extension (without dot)
function M.get_file_extension(filename)
	return filename:match("%.([^%.]+)$") or ""
end

---Removes file extension from filename
---@param filename string Filename
---@return string Filename without extension
function M.remove_file_extension(filename)
	return filename:match("(.+)%.[^%.]+$") or filename
end

---Checks if a string starts with a prefix
---@param str string String to check
---@param prefix string Prefix to look for
---@return boolean True if string starts with prefix
function M.starts_with(str, prefix)
	return str:sub(1, #prefix) == prefix
end

---Checks if a string ends with a suffix
---@param str string String to check
---@param suffix string Suffix to look for
---@return boolean True if string ends with suffix
function M.ends_with(str, suffix)
	return str:sub(-#suffix) == suffix
end

---Escapes special characters in a string for shell commands
---@param str string String to escape
---@return string Escaped string
function M.escape_shell(str)
	return vim.fn.shellescape(str)
end

---Gets the current buffer's file path
---@return string|nil Current buffer file path or nil
function M.get_current_file_path()
	local buf_name = vim.api.nvim_buf_get_name(0)
	if buf_name and buf_name ~= "" then
		return buf_name
	end
	return nil
end

---Gets the current working directory
---@return string Current working directory
function M.get_cwd()
	return vim.fn.getcwd()
end

---Shows a notification with optional log level
---@param message string Message to show
---@param level string|nil Log level (INFO, WARN, ERROR)
---@return nil
function M.notify(message, level)
	level = level or vim.log.levels.INFO
	vim.notify(message, level)
end

return M
