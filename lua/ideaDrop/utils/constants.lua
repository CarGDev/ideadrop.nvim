-- ideaDrop/utils/constants.lua
local M = {}

-- File extensions
M.FILE_EXTENSIONS = {
	MARKDOWN = ".md",
	LUA = ".lua",
}

-- Default file templates
M.DEFAULT_TEMPLATES = {
	IDEA = {
		"# %s",
		"",
		"- ",
	},
	MEETING = {
		"# Meeting: %s",
		"",
		"## Date: %s",
		"## Attendees:",
		"- ",
		"",
		"## Agenda:",
		"- ",
		"",
		"## Notes:",
		"- ",
		"",
		"## Action Items:",
		"- [ ] ",
	},
	PROJECT = {
		"# Project: %s",
		"",
		"## Overview:",
		"",
		"## Goals:",
		"- ",
		"",
		"## Tasks:",
		"- [ ] ",
		"",
		"## Notes:",
		"- ",
	},
}

-- Window dimensions (as percentages of screen)
M.WINDOW_DIMENSIONS = {
	RIGHT_SIDE_WIDTH = 0.3,    -- 30% of screen width
	TREE_WIDTH = 0.25,         -- 25% of screen width
	FLOATING_HEIGHT = 0.8,     -- 80% of screen height
}

-- Buffer options
M.BUFFER_OPTIONS = {
	IDEA_BUFFER = {
		filetype = "markdown",
		buftype = "acwrite",
		bufhidden = "hide",
	},
	TREE_BUFFER = {
		filetype = "ideaDrop-tree",
		buftype = "nofile",
		modifiable = false,
		bufhidden = "hide",
	},
}

-- Window options
M.WINDOW_OPTIONS = {
	RIGHT_SIDE = {
		wrap = true,
		number = true,
		relativenumber = false,
		cursorline = true,
	},
	TREE = {
		wrap = false,
		number = false,
		relativenumber = false,
		cursorline = true,
	},
}

-- Search settings
M.SEARCH_SETTINGS = {
	MAX_RESULTS = 20,
	CONTEXT_LENGTH = 80,
	FUZZY_SCORE_BONUS = 10,
}

-- Tag settings
M.TAG_SETTINGS = {
	PATTERN = "#([%w%-_]+)",
	MAX_DEPTH = 10,
}

-- Common words to exclude from tags
M.COMMON_WORDS = {
	"the", "and", "or", "but", "in", "on", "at", "to", "for", "of", "with",
	"by", "is", "are", "was", "were", "be", "been", "have", "has", "had",
	"do", "does", "did", "will", "would", "could", "should", "may", "might",
	"can", "this", "that", "these", "those", "i", "you", "he", "she", "it",
	"we", "they", "me", "him", "her", "us", "them", "my", "your", "his",
	"her", "its", "our", "their", "mine", "yours", "hers", "ours", "theirs"
}

-- Icons for different file types and actions
M.ICONS = {
	FILE = "📄",
	DIRECTORY = "📁",
	IDEA = "💡",
	SEARCH = "🔍",
	TAG = "🏷️",
	TREE = "🌳",
	SUCCESS = "✅",
	ERROR = "❌",
	WARNING = "⚠️",
	INFO = "ℹ️",
	SAVE = "💾",
	REFRESH = "🔄",
}

-- Key mappings (default)
M.DEFAULT_KEYMAPS = {
	TOGGLE_TREE = "<C-t>",
	REFRESH_FILE = "<C-r>",
	CLOSE_WINDOW = "q",
	SELECT_ITEM = "<CR>",
}

-- Notification messages
M.MESSAGES = {
	PLUGIN_LOADED = "ideaDrop loaded!",
	NO_FILES_FOUND = "📂 No idea files found",
	NO_TAGS_FOUND = "🏷️ No tags found in your ideas",
	NO_SEARCH_RESULTS = "🔍 No results found for '%s'",
	FILE_SAVED = "💾 Idea saved to %s",
	FILE_REFRESHED = "🔄 File refreshed",
	TAG_ADDED = "✅ Added tag '%s' to %s",
	TAG_REMOVED = "✅ Removed tag '%s' from %s",
	TAG_EXISTS = "🏷️ Tag '%s' already exists in file",
	TAG_NOT_FOUND = "🏷️ Tag '%s' not found in file",
	NO_ACTIVE_FILE = "❌ No active idea file. Open an idea first.",
	PROVIDE_TAG = "❌ Please provide a tag name",
	PROVIDE_QUERY = "❌ Please provide a search query",
}

return M 