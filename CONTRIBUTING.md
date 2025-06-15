# Contributing to ideaDrop.nvim

Thank you for your interest in contributing to ideaDrop.nvim! This document provides guidelines and instructions for contributing to this project.

## 🎯 Development Setup

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/ideaDrop.nvim.git
   cd ideaDrop.nvim
   ```
3. Create a new branch for your feature/fix:
   ```bash
   git checkout -b feature/your-feature-name
   ```

## 📝 Code Style

- Follow the [Lua Style Guide](https://github.com/lunarmodules/lua-style-guide)
- Use TypeScript-style type annotations in comments
- Keep functions small and focused
- Write meaningful commit messages following [Conventional Commits](https://www.conventionalcommits.org/)

Example of type annotations:
```lua
---@param config table Configuration table
---@field idea_dir string Directory to store ideas
---@return nil
local function setup(config)
  -- function implementation
end
```

## 🧪 Testing

1. Test your changes in a clean Neovim environment
2. Ensure all commands work as expected
3. Test edge cases and error handling
4. Update documentation if necessary

## 📚 Documentation

- Update `doc/ideaDrop.txt` for any new commands or features
- Add examples for new functionality
- Keep the README.md up to date
- Document any breaking changes

## 🔄 Pull Request Process

1. Update the README.md and documentation with details of changes
2. Update the version number in any relevant files
3. The PR must pass all checks
4. Get a review from at least one maintainer
5. Once approved, your PR will be merged

## 🐛 Bug Reports

When reporting bugs, please include:

1. Neovim version
2. Operating system
3. Steps to reproduce
4. Expected behavior
5. Actual behavior
6. Relevant error messages
7. Your configuration

## ✨ Feature Requests

When suggesting features:

1. Describe the feature in detail
2. Explain why it would be useful
3. Provide examples of how it would work
4. Consider potential edge cases

## 📋 Code of Conduct

- Be respectful and inclusive
- Be patient and welcoming
- Be thoughtful
- Be collaborative
- When disagreeing, try to understand why

## 🎉 Your First Contribution

1. Look for issues labeled `good first issue`
2. Comment on the issue to let us know you're working on it
3. Follow the development setup steps above
4. Submit your PR

## 📄 License

By contributing to ideaDrop.nvim, you agree that your contributions will be licensed under the project's MIT License.

---

Thank you for contributing to ideaDrop.nvim! 🚀 