# ideaDrop.nvim

A Neovim plugin for capturing, organizing, and managing ideas inside an Obsidian-compatible vault with graph visualization, tagging, search, and project todo lists.

## Features

- **Right-Side Split Panel**: Notes open in a fixed split on the right side of your editor
- **Project Todo List**: Toggle a todo panel with checkbox toggling (`[ ]` / `[x]`)
- **Obsidian.nvim Integration**: Optional deep integration with obsidian.nvim for backlinks, search, renaming, and more
- **Smart Tagging System**: Add, remove, and filter ideas by `#tags`
- **Advanced Search**: Fuzzy search through titles and content
- **File Tree Browser**: Integrated nvim-tree for file navigation
- **Graph Visualization**: Obsidian-style force-directed graph view of `[[linked notes]]`
- **Markdown Support**: Full markdown editing with syntax highlighting
- **Auto-save**: Changes saved automatically on write and window close
- **Date-based Organization**: Automatic date-based file naming
- **Folder Support**: Nested organization with subdirectories

## Installation

### Using lazy.nvim

```lua
{
  "CarGDev/ideadrop.nvim",
  name = "ideaDrop",
  dependencies = {
    "nvim-tree/nvim-tree.lua",
    "nvim-tree/nvim-web-devicons",
    -- Optional: for enhanced vault features
    -- "epwalsh/obsidian.nvim",
  },
  config = function()
    require("ideaDrop").setup({
      idea_dir = "/path/to/your/obsidian/vault",
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

## Configuration

```lua
require("ideaDrop").setup({
  idea_dir = "/Users/carlos/Nextcloud/ObsidianVault",
  graph = {
    animate = false,      -- Set true for animated layout
    show_orphans = true,  -- Show unconnected notes
    show_labels = true,   -- Show note names
    node_colors = nil,    -- Custom colors by folder/tag
  },
  todo = {
    file = ".todo.md",    -- Todo filename in idea_dir
    width = 0.25,         -- Panel width (25% of screen)
  },
  obsidian = {
    enabled = true,       -- Enable obsidian.nvim integration
    auto_keymaps = true,  -- Set up obsidian keymaps on idea buffers
  },
})
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `idea_dir` | string | `vim.fn.stdpath("data") .. "/ideaDrop"` | Directory where files are stored |
| `graph.animate` | boolean | `false` | Enable animated graph layout |
| `graph.show_orphans` | boolean | `true` | Show nodes without connections |
| `graph.show_labels` | boolean | `true` | Show node labels by default |
| `graph.node_colors` | table | `nil` | Custom colors by folder/tag |
| `todo.file` | string | `".todo.md"` | Todo list filename |
| `todo.width` | number | `0.25` | Todo panel width ratio |
| `obsidian.enabled` | boolean | `true` | Enable obsidian.nvim integration |
| `obsidian.auto_keymaps` | boolean | `true` | Auto-set obsidian keymaps on buffers |

## Commands

### Core Commands

| Command | Description |
|---------|-------------|
| `:Idea [name]` | Open today's idea (or named idea) in right-side split |
| `:IdeaBuffer [name]` | Open idea in current buffer |
| `:IdeaRight [name]` | Alias for `:Idea` |
| `:IdeaClose` | Close the right-side panel |
| `:IdeaToggle` | Toggle the right-side panel |
| `:IdeaTree` | Open nvim-tree file browser |

### Todo Commands

| Command | Description |
|---------|-------------|
| `:IdeaTodo` | Toggle the project todo list panel |
| `:IdeaTodoAdd [text]` | Add a new todo item |

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
| `:IdeaSearch query` | Fuzzy search through titles and content |
| `:IdeaSearchContent query` | Search only in content |
| `:IdeaSearchTitle query` | Search only in titles |

### Graph Commands

| Command | Description |
|---------|-------------|
| `:IdeaGraph` | Open the graph visualization |
| `:IdeaGraph animate` | Open graph with animated layout |
| `:IdeaGraph refresh` | Refresh graph data |
| `:IdeaGraph close` | Close the graph window |
| `:IdeaGraphFilter tag name` | Filter graph by tag |
| `:IdeaGraphFilter folder name` | Filter graph by folder |
| `:IdeaGraphClearCache` | Clear graph cache |

### Obsidian Commands

| Command | Description |
|---------|-------------|
| `:IdeaObsidian backlinks` | Show backlinks for current note |
| `:IdeaObsidian search` | Search vault with obsidian.nvim |
| `:IdeaObsidian daily` | Open today's daily note |
| `:IdeaObsidian new` | Create a new note |
| `:IdeaObsidian switch` | Quick switcher |
| `:IdeaObsidian tags` | Browse tags via obsidian.nvim |
| `:IdeaObsidian paste` | Paste image from clipboard |
| `:IdeaObsidian rename` | Rename note (updates backlinks) |
| `:IdeaObsidian open` | Open in Obsidian app |
| `:IdeaObsidian status` | Show integration status |

## Todo List

The todo list opens as a fixed panel on the right side of your editor. It persists as `.todo.md` in your idea directory.

### Keymaps (inside todo panel)

| Key | Action |
|-----|--------|
| `<CR>` or `<Space>` | Toggle checkbox |
| `o` | Add new item below cursor |
| `dd` | Remove checkbox item |
| `q` | Close panel |

### Example

```markdown
# Todo

- [x] Set up project structure
- [x] Add search functionality
- [ ] Write tests for graph module
- [ ] Update deployment docs
```

## Obsidian.nvim Integration

When `epwalsh/obsidian.nvim` is installed, ideaDrop automatically detects it and provides enhanced features:

- **Link following**: `gf` on `[[wiki-links]]` uses obsidian.nvim's resolver
- **Backlinks**: `<leader>ob` shows all notes linking to the current one
- **Search**: `<leader>os` uses obsidian.nvim's search
- **New notes**: `<leader>on` creates notes with obsidian.nvim templates
- **Open in Obsidian**: `<leader>oo` opens the note in the Obsidian desktop app
- **Rename**: `<leader>or` renames notes and updates all backlinks
- **Paste images**: `<leader>op` pastes clipboard images with proper paths
- **Quick switch**: `<leader>oq` opens the quick switcher

If obsidian.nvim is not installed, all features work standalone using ideaDrop's built-in capabilities.

## Graph Visualization

The graph view visualizes connections between your notes using `[[wiki-style links]]`.

### Graph Keymaps (inside graph window)

| Key | Action |
|-----|--------|
| `h/j/k/l` | Navigate between nodes |
| `Enter` | Open selected note |
| `t` | Filter by tag |
| `f` | Filter by folder |
| `r` | Reset filter |
| `L` | Toggle labels |
| `c` | Center graph |
| `+/-` | Zoom in/out |
| `?` | Toggle help |
| `q/Esc` | Close graph |
| `R` | Refresh graph |

### Linking Notes

```markdown
# My Note

This relates to [[Another Note]] and also to [[Projects/My Project]].
Check out [[2024-01-15]] for more context.
```

## Usage Examples

### Quick Notes

```vim
:Idea                         " Open today's note in right split
:Idea project/vision          " Open project/vision.md
:IdeaToggle                   " Toggle the panel
```

### Todo Workflow

```vim
:IdeaTodo                     " Open todo panel
:IdeaTodoAdd Fix login bug    " Add item
" Press <CR> on a line to toggle [x]
```

### Tag Management

```vim
:IdeaAddTag #work
:IdeaTags                     " Browse all tags
:IdeaSearchTag #work          " Find tagged files
```

### File Organization

```vim
:Idea meetings/2024-01-15     " Nested folders auto-created
:IdeaTree                     " Browse with nvim-tree
```

### Obsidian Features

```vim
:IdeaObsidian backlinks       " Show backlinks
:IdeaObsidian daily           " Open daily note
:IdeaObsidian search          " Search vault
```

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a detailed list of changes.

## License

MIT License - feel free to use this plugin in your own projects!

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Development Setup

1. Clone the repository
2. Install dependencies (nvim-tree, optionally obsidian.nvim)
3. Run `stylua --check .` to verify formatting
4. Test with the provided commands

## Troubleshooting

### Common Issues

1. **Module not found errors**: Ensure all dependencies are installed
2. **Tree not opening**: Make sure nvim-tree is properly configured
3. **Search not working**: Verify your idea directory path is correct
4. **Tags not showing**: Check that your idea directory exists and contains markdown files
5. **Graph showing no connections**: Use `[[Note Name]]` syntax for links
6. **Graph layout looks cramped**: Zoom out with `-` or use `:IdeaGraph animate`
7. **Obsidian commands not working**: Install `epwalsh/obsidian.nvim` and check `:IdeaObsidian status`
