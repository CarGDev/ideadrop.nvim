# Changelog

All notable changes to ideaDrop.nvim will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

#### 🕸️ Graph Visualization (Obsidian-style)

A new force-directed graph view that visualizes connections between your notes:

- **Graph Data Model**: Parses `[[Note Name]]` wiki-style links from markdown files
  - Supports `[[link|alias]]` format
  - Builds bidirectional edges (undirected graph)
  - Extracts tags and folder metadata for filtering

- **Force-Directed Layout**: Implements Fruchterman-Reingold algorithm
  - Spring forces attract connected nodes
  - Repulsion forces prevent node overlap
  - Gravity pulls high-degree nodes toward center
  - Inverse gravity pushes orphan nodes to periphery
  - Temperature-based cooling for stable convergence
  - Supports both synchronous and animated layout modes

- **Visual Rendering**:
  - Dark background canvas for visual clarity
  - Node size scales with degree (number of connections)
  - Color-coded nodes: blue (default), purple (hubs), gray (orphans), red (selected)
  - Semi-transparent edge lines showing connections
  - Labels for selected and high-degree nodes

- **Interactive Features**:
  - `h/j/k/l` navigation between nodes
  - `Enter` to open selected note in right-side buffer
  - `t` filter by tag, `f` filter by folder, `r` reset filter
  - `+/-` zoom in/out, `c` center graph
  - `L` toggle labels, `?` toggle help overlay
  - `q/Esc` close graph, `R` refresh graph data
  - Smooth layout reflow when nodes are filtered

- **New Commands**:
  - `:IdeaGraph` - Opens the graph visualization
  - `:IdeaGraph animate` - Opens with animated layout
  - `:IdeaGraph refresh` - Refreshes graph data
  - `:IdeaGraph close` - Closes the graph window
  - `:IdeaGraphFilter tag <name>` - Filter graph by tag
  - `:IdeaGraphFilter folder <name>` - Filter graph by folder

- **New Configuration Options**:
  - `graph.animate` - Enable animated layout (default: false)
  - `graph.show_orphans` - Show nodes without connections (default: true)
  - `graph.show_labels` - Show node labels by default (default: true)
  - `graph.node_colors` - Custom colors by folder/tag

- **New Files**:
  - `lua/ideaDrop/ui/graph/types.lua` - Type definitions
  - `lua/ideaDrop/ui/graph/data.lua` - Graph data model
  - `lua/ideaDrop/ui/graph/layout.lua` - Force-directed layout algorithm
  - `lua/ideaDrop/ui/graph/renderer.lua` - Character-based canvas renderer
  - `lua/ideaDrop/ui/graph/init.lua` - Main graph module

#### Other Additions

- Added `CHANGELOG.md` to track project changes
- Added `llms.txt` for AI/LLM context about the project
- Added graph-related constants and settings in `constants.lua`
- Added graph-related notification messages

### Changed

- Updated help documentation (`doc/ideaDrop.txt`) to include all commands: `IdeaBuffer`, `IdeaRight`, `IdeaTree`, tag commands, and search commands
- Improved nvim-tree integration to preserve user's existing nvim-tree configuration
- Updated `README.md` with comprehensive graph visualization documentation
- Extended configuration options to include graph settings

### Fixed

- **Critical**: Fixed glob pattern bug where files were not being found due to missing path separator (`/`) between directory and pattern in `list.lua`, `tags.lua`, and `search.lua`
- **Critical**: Fixed nvim-tree integration that was overriding user's nvim-tree configuration on every `:IdeaTree` call. Now uses nvim-tree API directly without calling `setup()`
- Fixed deprecated Neovim API usage: replaced `vim.api.nvim_buf_set_option()` and `vim.api.nvim_win_set_option()` with `vim.bo[]` and `vim.wo[]` in `sidebar.lua`
- Fixed missing arguments in `sidebar.open()` call in `list.lua` which could cause unexpected behavior
- Removed unused variable in `tags.lua` (`filename` in `show_files_with_tag` function)

## [1.0.0] - Initial Release

### Added

- Multiple view modes: floating window, current buffer, right-side buffer
- Smart tagging system with `#tag` format
- Advanced fuzzy search through titles and content
- nvim-tree integration for file browsing
- Markdown support with syntax highlighting
- Auto-save functionality
- Date-based file organization
- Nested folder support

### Commands

- `:Idea` - Open idea in floating window
- `:IdeaBuffer` - Open idea in current buffer
- `:IdeaRight` - Open idea in right-side buffer
- `:IdeaTree` - Open file tree browser
- `:IdeaTags` - Browse and filter by tags
- `:IdeaAddTag` / `:IdeaRemoveTag` - Manage tags
- `:IdeaSearch` / `:IdeaSearchContent` / `:IdeaSearchTitle` - Search functionality
