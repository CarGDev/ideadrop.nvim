# ideaDrop.nvim

💡 A powerful Neovim plugin for capturing, organizing, and managing your ideas with multiple view modes, tagging system, and advanced search capabilities.

## ✨ Features

- 🎯 **Multiple View Modes**: Floating windows, current buffer, or persistent right-side buffer
- 🏷️ **Smart Tagging System**: Add, remove, and filter ideas by tags
- 🔍 **Advanced Search**: Fuzzy search through titles and content
- 📁 **File Tree Browser**: Integrated nvim-tree for easy file navigation
- 📝 **Markdown Support**: Full markdown editing with syntax highlighting
- 💾 **Auto-save**: Changes saved automatically
- 📅 **Date-based Organization**: Automatic date-based file naming
- 🗂️ **Folder Support**: Nested organization with subdirectories
- 🎨 **Clean Interface**: Distraction-free writing environment

## 📦 Installation

### Using lazy.nvim

```lua
{
  "CarGDev/ideadrop.nvim",
  name = "ideaDrop",
  dependencies = {
    "nvim-tree/nvim-tree.lua",
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    require("ideaDrop").setup({
      idea_dir = "/path/to/your/ideas", -- where your ideas will be saved
    })
  end,
}
```

### Using packer

```lua
use {
  "CarGDev/ideadrop.nvim",
  requires = {
    "nvim-tree/nvim-tree.lua",
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    require("ideaDrop").setup({
      idea_dir = "/path/to/your/ideas",
    })
  end,
}
```

## ⚙️ Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `idea_dir` | string | `vim.fn.stdpath("data") .. "/ideaDrop"` | Directory where your idea files will be stored |

### Example Configuration

```lua
require("ideaDrop").setup({
  idea_dir = "/Users/carlos/Nextcloud/ObsidianVault",
})
```

## 🎮 Commands

### Core Commands

| Command | Description |
|---------|-------------|
| `:Idea` | Opens today's idea in floating window |
| `:Idea name` | Opens or creates an idea with the specified name (floating) |
| `:IdeaBuffer` | Opens today's idea in current buffer |
| `:IdeaBuffer name` | Opens or creates an idea in current buffer |
| `:IdeaRight` | Opens today's idea in persistent right-side buffer |
| `:IdeaRight name` | Opens or creates an idea in right-side buffer |
| `:IdeaTree` | Opens nvim-tree file browser on the left |

### Tag Commands

| Command | Description |
|---------|-------------|
| `:IdeaTags` | Shows tag picker to browse files by tag |
| `:IdeaAddTag tag` | Adds a tag to the current idea file |
| `:IdeaRemoveTag tag` | Removes a tag from the current idea file |
| `:IdeaSearchTag tag` | Searches for files with a specific tag |

### Search Commands

| Command | Description |
|---------|-------------|
| `:IdeaSearch query` | Fuzzy search through idea titles and content |
| `:IdeaSearchContent query` | Search only in idea content |
| `:IdeaSearchTitle query` | Search only in idea titles |

## ⌨️ Keymaps

The plugin automatically sets up convenient keymaps:

| Keymap | Command | Description |
|--------|---------|-------------|
| `<leader>id` | `:IdeaRight` | Open today's idea in right buffer |
| `<leader>in` | `:IdeaRight ` | Open named idea in right buffer |
| `<leader>it` | `:IdeaTree` | Open tree browser |
| `<leader>is` | `:IdeaSearch ` | Search ideas |
| `<leader>ig` | `:IdeaTags` | Browse tags |
| `<leader>if` | `:Idea` | Open today's idea in float |

## 🗂️ Usage Examples

### Basic Usage

```vim
:IdeaRight                    " Open today's idea in right buffer
:IdeaRight project/vision     " Open project/vision.md in right buffer
:IdeaTree                     " Browse all ideas with nvim-tree
```

### Tag Management

```vim
:IdeaAddTag #work             " Add #work tag to current idea
:IdeaAddTag #personal         " Add #personal tag to current idea
:IdeaTags                     " Browse all tags
:IdeaSearchTag #work          " Find all ideas with #work tag
```

### Search and Discovery

```vim
:IdeaSearch "machine learning"    " Search for "machine learning" in all ideas
:IdeaSearchContent "algorithm"    " Search content for "algorithm"
:IdeaSearchTitle "project"        " Search titles for "project"
```

### File Organization

```vim
:IdeaRight meetings/2024-01-15    " Create nested folder structure
:IdeaRight projects/app/features  " Organize by project and feature
```

## 🏷️ Tagging System

The plugin includes a powerful tagging system:

- **Add tags**: Use `#tag` format in your markdown files
- **Auto-completion**: Tags are automatically detected and indexed
- **Filter by tags**: Browse and filter ideas by tags
- **Tag statistics**: See how many files use each tag

### Tag Examples

```markdown
# My Idea Title

This is my idea content.

#work #project-x #feature #todo
```

## 🔍 Search Features

### Fuzzy Search
- Search through file titles and content
- Real-time results as you type
- Navigate through search results easily

### Content Search
- Search only in the body of your ideas
- Perfect for finding specific concepts or references

### Title Search
- Search only in file names
- Quick way to find specific ideas

## 📁 File Tree Integration

The plugin integrates with nvim-tree for seamless file browsing:

- **Left-side tree**: Opens on the left side of your screen
- **File selection**: Click or press Enter to open files
- **Directory navigation**: Browse through your idea folders
- **File operations**: Create, delete, rename files directly

## 🎯 View Modes

### 1. Floating Window (Original)
- Opens ideas in a floating window
- Good for quick notes
- Command: `:Idea`

### 2. Current Buffer
- Opens ideas in the current buffer
- Replaces current content
- Command: `:IdeaBuffer`

### 3. Right-Side Buffer (Recommended)
- Persistent buffer on the right side
- Stays open while you work
- Perfect for ongoing projects
- Command: `:IdeaRight`

### 4. Tree Browser
- Full file tree on the left side
- Integrated with nvim-tree
- Command: `:IdeaTree`

## 🛠️ Development

This plugin is built with:
- **Lua**: Core functionality
- **Neovim API**: Native Neovim integration
- **nvim-tree**: File tree browsing
- **telescope**: Search functionality
- **Markdown**: Rich text support

## 📄 License

MIT License - feel free to use this plugin in your own projects!

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Development Setup

1. Clone the repository
2. Install dependencies (nvim-tree, telescope)
3. Configure the plugin in your Neovim setup
4. Test with the provided commands and keymaps

## 🐛 Troubleshooting

### Common Issues

1. **Module not found errors**: Ensure all dependencies are installed
2. **Tree not opening**: Make sure nvim-tree is properly configured
3. **Search not working**: Verify telescope is installed and configured
4. **Tags not showing**: Check that your idea directory exists and contains markdown files

### Getting Help

- Check the configuration examples above
- Ensure all dependencies are installed
- Verify your idea directory path is correct
- Test with the basic commands first

---

**Happy idea capturing! 🚀**
