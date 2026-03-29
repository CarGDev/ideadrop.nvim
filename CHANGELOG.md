# Changelog

All notable changes to ideaDrop.nvim will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.0] - 2026-03-29

### Fixed

- Idea sidebar and todo panel no longer hijack file opens — foreign buffers are
  intercepted via `BufEnter` and redirected to the main editor window, so
  `:edit`, `gf`, obsidian.nvim links, and plugin navigations never land inside
  the panel (works on all Neovim versions)

## [2.0.0]

### Added

#### Right-Side Split Windows (replaces floating windows)

All note editing now uses proper `botright vsplit` windows instead of floating windows:

- `:Idea` now opens in a fixed right-side split (was floating window)
- `:IdeaRight` uses the same right-side split behavior
- New `:IdeaClose` command to close the right-side panel
- New `:IdeaToggle` command to toggle the panel open/closed
- Panel has `winfixwidth` set so it stays at 30% width when resizing
- Auto-save on window close preserved

#### Project Todo List

A new project-scoped todo list that opens in a fixed right-side split:

- `:IdeaTodo` toggles the todo panel (25% width)
- `:IdeaTodoAdd [text]` adds a new todo item
- Toggle checkboxes with `<CR>` or `<Space>` on any `- [ ]` / `- [x]` line
- `o` to add a new item below cursor and enter insert mode
- `dd` to remove a checkbox item
- `q` to close the panel
- Auto-saves to `.todo.md` in your idea directory
- Persists across sessions

#### Obsidian.nvim Integration

Optional integration with `epwalsh/obsidian.nvim` for enhanced vault capabilities:

- `:IdeaObsidian` command with subcommands: backlinks, search, daily, new, switch, tags, paste, rename, open, status
- Auto-detects obsidian.nvim at startup
- `gf` follows `[[wiki-links]]` via obsidian.nvim when available
- `<leader>ob` shows backlinks, `<leader>os` searches, `<leader>on` creates new notes
- `<leader>oo` opens current note in Obsidian app
- `<leader>or` renames note with backlink updates
- `<leader>op` pastes images from clipboard
- Graceful fallback when obsidian.nvim is not installed

#### CI/CD and Project Tooling

- GitHub Actions CI workflow: Stylua lint check and panvimdoc generation
- GitHub Actions release workflow: release-please for semantic versioning
- GitHub Actions TODO-to-issue workflow: auto-creates issues from TODO comments
- `.stylua.toml` for consistent Lua formatting
- `.editorconfig` for editor-agnostic settings
- `.luarc.json` for Lua language server configuration
- `.pre-commit-config.yaml` with Stylua hook
- `llm.txt` for AI/LLM context about the project

#### Other

- New `lua/ideaDrop/features/todo.lua` module
- New `lua/ideaDrop/integrations/obsidian.lua` module
- Added `todo` and `obsidian` configuration sections
- `sidebar.is_open()` function to check panel state
- `sidebar.close()` and `sidebar.toggle()` functions

### Changed

- `:Idea` command now opens in right-side split instead of floating window
- `sidebar.open()` delegates to `open_right_side()` by default (was floating)
- Removed floating window code from sidebar module
- Extracted `resolve_file()` and `load_content()` helpers in sidebar
- Extracted `resolve_idea_path()` helper in core/init.lua to reduce duplication
- Updated configuration types to include todo and obsidian options
- Simplified notification messages (removed emoji prefixes for cleaner logs)

### Removed

- Floating window mode for `:Idea` command (use `:IdeaBuffer` for inline editing)
- `relative = "editor"` floating window positioning code

## [1.1.0] - Graph Visualization and Performance

### Added

#### Graph Visualization (Obsidian-style)

A force-directed graph view that visualizes connections between notes:

- **Graph Data Model**: Parses `[[Note Name]]` wiki-style links from markdown files
  - Supports `[[link|alias]]` format
  - Builds bidirectional edges (undirected graph)
  - Extracts tags and folder metadata for filtering

- **Force-Directed Layout**: Implements Fruchterman-Reingold algorithm
  - Spring forces attract connected nodes
  - Repulsion forces prevent node overlap
  - Gravity pulls high-degree nodes toward center
  - Temperature-based cooling for stable convergence
  - Supports both synchronous and animated layout modes

- **Visual Rendering**:
  - Dark background canvas for visual clarity
  - Node size scales with degree (number of connections)
  - Color-coded nodes: blue (default), purple (hubs), gray (orphans), red (selected)
  - Semi-transparent edge lines showing connections

- **Interactive Features**:
  - `h/j/k/l` navigation, `Enter` to open note
  - `t` filter by tag, `f` filter by folder, `r` reset filter
  - `+/-` zoom, `c` center, `L` toggle labels, `?` help
  - `q/Esc` close, `R` refresh

- **Commands**: `:IdeaGraph`, `:IdeaGraph animate/refresh/rebuild/close`, `:IdeaGraphFilter`, `:IdeaGraphClearCache`
- **Configuration**: `graph.animate`, `graph.show_orphans`, `graph.show_labels`, `graph.node_colors`

#### Graph Performance Optimizations

- Caching system with `.ideadrop-graph-cache.json` (mtime-based invalidation)
- Reduced max iterations (300 -> 100) for faster convergence
- Barnes-Hut approximation for large graphs (100+ nodes)
- Local math function caching

### Fixed

- Glob pattern bug in `list.lua`, `tags.lua`, `search.lua`
- nvim-tree integration overriding user config
- Deprecated Neovim API usage in `sidebar.lua`

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
