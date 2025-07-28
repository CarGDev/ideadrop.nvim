-- ideaDrop/config.lua

---@class Config
---@field options IdeaDropOptions
---@field setup fun(user_opts: IdeaDropOptions|nil): nil

---@class IdeaDropOptions
---@field idea_dir string Directory where idea files will be stored

local M = {}

---Default configuration options
M.options = {
  idea_dir = vim.fn.stdpath("data") .. "/ideaDrop"  -- default path
}

---Setup function to merge user options with defaults
---@param user_opts IdeaDropOptions|nil User configuration options
---@return nil
function M.setup(user_opts)
  M.options = vim.tbl_deep_extend("force", M.options, user_opts or {})
end

return M
