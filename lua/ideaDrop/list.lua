-- ideaDrop/list.lua
local config = require("ideaDrop.config")
local sidebar = require("ideaDrop.sidebar")

---@class List
---@field list_all fun(): nil
local M = {}

---Lists all idea files and allows user to select one to open
---@return nil
function M.list_all()
  local path = config.options.idea_dir
  -- Find all .md files recursively
  local files = vim.fn.glob(path .. "**/*.md", false, true)

  if #files == 0 then
    vim.notify("📂 No idea files found", vim.log.levels.INFO)
    return
  end

  -- Present file selection UI
  vim.ui.select(files, { prompt = "📂 Select an idea file to open:" }, function(choice)
    if choice then
      sidebar.open(choice) -- Open the selected file in sidebar
    end
  end)
end

return M

