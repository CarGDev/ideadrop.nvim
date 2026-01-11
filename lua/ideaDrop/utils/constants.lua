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
	GRAPH = "🕸️",
	SUCCESS = "✅",
	ERROR = "❌",
	WARNING = "⚠️",
	INFO = "ℹ️",
	SAVE = "💾",
	REFRESH = "🔄",
	NODE = "●",
	LINK = "─",
}

-- Key mappings (default)
M.DEFAULT_KEYMAPS = {
	TOGGLE_TREE = "<C-t>",
	REFRESH_FILE = "<C-r>",
	CLOSE_WINDOW = "q",
	SELECT_ITEM = "<CR>",
	-- Graph keymaps
	GRAPH_CLOSE = "q",
	GRAPH_SELECT = "<CR>",
	GRAPH_FILTER_TAG = "t",
	GRAPH_FILTER_FOLDER = "f",
	GRAPH_RESET_FILTER = "r",
	GRAPH_TOGGLE_LABELS = "l",
	GRAPH_CENTER = "c",
	GRAPH_ZOOM_IN = "+",
	GRAPH_ZOOM_OUT = "-",
}

-- Graph visualization settings
M.GRAPH_SETTINGS = {
	-- Layout algorithm parameters
	LAYOUT = {
		-- Fruchterman-Reingold parameters
		REPULSION_STRENGTH = 5000, -- How strongly nodes repel each other
		ATTRACTION_STRENGTH = 0.01, -- Spring constant for connected nodes
		IDEAL_EDGE_LENGTH = 50, -- Ideal distance between connected nodes
		GRAVITY = 0.1, -- Pull toward center
		DAMPING = 0.85, -- Velocity damping per iteration
		MIN_VELOCITY = 0.01, -- Stop threshold
		MAX_ITERATIONS = 300, -- Maximum layout iterations
		COOLING_RATE = 0.95, -- Temperature cooling per iteration
		INITIAL_TEMPERATURE = 100, -- Initial movement freedom
	},

	-- Visual settings
	VISUAL = {
		NODE_CHAR = "●", -- Character for nodes
		NODE_CHAR_SMALL = "•", -- Character for small nodes
		EDGE_CHAR_H = "─", -- Horizontal edge
		EDGE_CHAR_V = "│", -- Vertical edge
		EDGE_CHAR_DR = "┌", -- Down-right corner
		EDGE_CHAR_DL = "┐", -- Down-left corner
		EDGE_CHAR_UR = "└", -- Up-right corner
		EDGE_CHAR_UL = "┘", -- Up-left corner
		EDGE_CHAR_CROSS = "┼", -- Crossing edges
		EDGE_CHAR_SIMPLE = "·", -- Simple edge dot
		MIN_NODE_SIZE = 1, -- Minimum node visual size
		MAX_NODE_SIZE = 3, -- Maximum node visual size (based on degree)
		LABEL_MAX_LENGTH = 20, -- Maximum label length
		PADDING = 2, -- Canvas padding
	},

	-- Window settings
	WINDOW = {
		WIDTH_RATIO = 0.8, -- Window width as ratio of editor
		HEIGHT_RATIO = 0.8, -- Window height as ratio of editor
		BORDER = "rounded",
		TITLE = " 🕸️ Graph View ",
	},

	-- Colors (highlight group names)
	COLORS = {
		NODE_DEFAULT = "IdeaDropGraphNode",
		NODE_SELECTED = "IdeaDropGraphNodeSelected",
		NODE_ORPHAN = "IdeaDropGraphNodeOrphan",
		NODE_HIGH_DEGREE = "IdeaDropGraphNodeHighDegree",
		EDGE = "IdeaDropGraphEdge",
		LABEL = "IdeaDropGraphLabel",
		BACKGROUND = "IdeaDropGraphBackground",
		FILTER_ACTIVE = "IdeaDropGraphFilterActive",
	},

	-- Node size thresholds (degree-based)
	NODE_DEGREE_THRESHOLDS = {
		SMALL = 2, -- 0-2 connections = small
		MEDIUM = 5, -- 3-5 connections = medium
		-- > 5 = large
	},
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
	GRAPH_BUILDING = "🕸️ Building graph...",
	GRAPH_LAYOUT = "🕸️ Computing layout for %d nodes...",
	GRAPH_COMPLETE = "🕸️ Graph ready: %d nodes, %d edges",
	GRAPH_REFRESHED = "🕸️ Graph refreshed",
	GRAPH_NO_NODES = "🕸️ No notes found to visualize",
	GRAPH_NO_SELECTION = "🕸️ No node selected",
}

return M 