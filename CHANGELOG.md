# Changelog

All notable changes to ideaDrop.nvim will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- **Critical**: Fixed glob pattern bug where files were not being found due to missing path separator (`/`) between directory and pattern in `list.lua`, `tags.lua`, and `search.lua`
- **Critical**: Fixed nvim-tree integration that was overriding user's nvim-tree configuration on every `:IdeaTree` call. Now uses nvim-tree API directly without calling `setup()`
- Fixed deprecated Neovim API usage: replaced `vim.api.nvim_buf_set_option()` and `vim.api.nvim_win_set_option()` with `vim.bo[]` and `vim.wo[]` in `sidebar.lua`
- Fixed missing arguments in `sidebar.open()` call in `list.lua` which could cause unexpected behavior
- Removed unused variable in `tags.lua` (`filename` in `show_files_with_tag` function)

### Changed

- Updated help documentation (`doc/ideaDrop.txt`) to include all commands: `IdeaBuffer`, `IdeaRight`, `IdeaTree`, tag commands, and search commands
- Improved nvim-tree integration to preserve user's existing nvim-tree configuration

### Added

- Added `CHANGELOG.md` to track project changes
- Added `llms.txt` for AI/LLM context about the project

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
