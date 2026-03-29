local config = require("ideaDrop.core.config")

describe("config", function()
	before_each(function()
		-- Reset to defaults before each test
		config.options = {
			idea_dir = vim.fn.stdpath("data") .. "/ideaDrop",
			graph = {
				animate = false,
				show_orphans = true,
				show_labels = true,
				node_colors = nil,
			},
			todo = {
				file = ".todo.md",
				width = 0.25,
			},
			obsidian = {
				enabled = true,
				auto_keymaps = true,
			},
		}
	end)

	it("uses default idea_dir when none provided", function()
		config.setup({})
		assert.is_not_nil(config.options.idea_dir)
		assert.truthy(config.options.idea_dir:match("ideaDrop$"))
	end)

	it("merges user options with defaults", function()
		config.setup({ idea_dir = "/tmp/test-ideas" })
		assert.equals("/tmp/test-ideas", config.options.idea_dir)
		-- Defaults should be preserved
		assert.equals(false, config.options.graph.animate)
		assert.equals(true, config.options.graph.show_orphans)
	end)

	it("deep merges graph options", function()
		config.setup({
			idea_dir = "/tmp/test",
			graph = { animate = true },
		})
		assert.equals(true, config.options.graph.animate)
		assert.equals(true, config.options.graph.show_orphans) -- preserved
		assert.equals(true, config.options.graph.show_labels) -- preserved
	end)

	it("deep merges todo options", function()
		config.setup({
			idea_dir = "/tmp/test",
			todo = { width = 0.3 },
		})
		assert.equals(0.3, config.options.todo.width)
		assert.equals(".todo.md", config.options.todo.file) -- preserved
	end)

	it("deep merges obsidian options", function()
		config.setup({
			idea_dir = "/tmp/test",
			obsidian = { enabled = false },
		})
		assert.equals(false, config.options.obsidian.enabled)
		assert.equals(true, config.options.obsidian.auto_keymaps) -- preserved
	end)

	it("expands ~ in idea_dir", function()
		config.setup({ idea_dir = "~/test-ideas" })
		assert.is_not_nil(config.options.idea_dir:match("^/"))
		assert.falsy(config.options.idea_dir:match("~"))
	end)

	it("get_idea_dir returns expanded path", function()
		config.setup({ idea_dir = "/tmp/test-ideas" })
		assert.equals("/tmp/test-ideas", config.get_idea_dir())
	end)
end)
