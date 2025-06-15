# ideaDrop.nvim

💡 A simple Neovim plugin to drop and organize your ideas in floating Markdown sidebars.

## 📦 Installation

Using **lazy.nvim**:

```lua
{
  dir = "/Users/carlos/Documents/SSD_Documents/personals/ideaDrop",
  name = "ideaDrop",
  config = function()
    require("ideaDrop").setup({
      idea_dir = "/Users/carlos/Nextcloud/ObsidianVault", -- where your ideas will be saved
    })
  end,
}
```

## ⚙️ Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `idea_dir` | string | `vim.fn.stdpath("data") .. "/ideaDrop"` | Directory where your idea files will be stored |

## 🧪 Commands

| Command | Description |
|---------|-------------|
| `:Idea` | Opens today's idea file |
| `:Idea name` | Opens or creates an idea with the specified name |
| `:Idea listAll` | Opens a fuzzy picker to select from existing ideas |

## 📌 Features

- 📝 Markdown editor in a floating sidebar
- 💾 Automatic save on close
- 📅 Date-based and custom named notes
- 📁 Folder support (e.g., `project/vision.md`)
- 🔍 Fuzzy finder for existing ideas
- 🎨 Clean and distraction-free interface

## 🗂 Example Usage

```vim
:Idea project/nextgen    " Opens or creates project/nextgen.md
:Idea listAll           " Opens fuzzy finder for all ideas
```

## 📚 Documentation

For detailed documentation, run `:help ideaDrop` in Neovim.

## 🛠 Development

This plugin is built with:
- Lua
- Neovim API
- Markdown support
- Fuzzy finding capabilities

## 📄 License

MIT License - feel free to use this plugin in your own projects!

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.