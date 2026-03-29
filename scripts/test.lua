vim.opt.runtimepath:append(vim.fn.getcwd())

local plenary_path = vim.fn.fnamemodify(".dependencies/plenary.nvim", ":p")
if vim.fn.isdirectory(plenary_path) == 0 then
	vim.fn.system({ "git", "clone", "--depth=1", "https://github.com/nvim-lua/plenary.nvim", plenary_path })
end
vim.opt.runtimepath:append(plenary_path)

require("plenary.test_harness").test_directory("tests", { minimal_init = "", sequential = true })
