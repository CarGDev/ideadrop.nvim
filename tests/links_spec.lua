local data = require("ideaDrop.ui.graph.data")

describe("extract_links", function()
	it("extracts simple wiki links", function()
		local links = data.extract_links("Check out [[My Note]] for details")
		assert.equals(1, #links)
		assert.equals("My Note", links[1])
	end)

	it("extracts multiple links", function()
		local links = data.extract_links("See [[Note A]] and [[Note B]] and [[Note C]]")
		assert.equals(3, #links)
		assert.equals("Note A", links[1])
		assert.equals("Note B", links[2])
		assert.equals("Note C", links[3])
	end)

	it("handles link|alias format", function()
		local links = data.extract_links("See [[actual-note|Display Name]]")
		assert.equals(1, #links)
		assert.equals("actual-note", links[1])
	end)

	it("deduplicates links", function()
		local links = data.extract_links("[[Note A]] and again [[Note A]]")
		assert.equals(1, #links)
		assert.equals("Note A", links[1])
	end)

	it("returns empty for no links", function()
		local links = data.extract_links("No links here, just plain text.")
		assert.equals(0, #links)
	end)

	it("handles links with paths", function()
		local links = data.extract_links("See [[projects/my-project]]")
		assert.equals(1, #links)
		assert.equals("projects/my-project", links[1])
	end)

	it("trims whitespace in links", function()
		local links = data.extract_links("See [[  Padded Note  ]]")
		assert.equals(1, #links)
		assert.equals("Padded Note", links[1])
	end)

	it("ignores empty brackets", function()
		local links = data.extract_links("See [[]] nothing")
		assert.equals(0, #links)
	end)
end)

describe("normalize_file_name", function()
	it("removes idea_dir prefix and .md extension", function()
		local result = data.normalize_file_name("/vault/notes/my-note.md", "/vault/notes")
		assert.equals("my-note", result)
	end)

	it("preserves nested paths", function()
		local result = data.normalize_file_name("/vault/projects/web/todo.md", "/vault")
		assert.equals("projects/web/todo", result)
	end)

	it("handles files without .md extension", function()
		local result = data.normalize_file_name("/vault/readme", "/vault")
		assert.equals("readme", result)
	end)
end)

describe("get_display_name", function()
	it("capitalizes and replaces dashes", function()
		local result = data.get_display_name("my-cool-note")
		assert.equals("My cool note", result)
	end)

	it("strips path prefix", function()
		local result = data.get_display_name("projects/web/my-note")
		assert.equals("My note", result)
	end)
end)

describe("resolve_link", function()
	it("resolves direct match", function()
		local files = { ["my-note"] = "/vault/my-note.md" }
		local result = data.resolve_link("my-note", "/vault", files)
		assert.equals("/vault/my-note.md", result)
	end)

	it("resolves with .md extension", function()
		local files = { ["my-note.md"] = "/vault/my-note.md" }
		local result = data.resolve_link("my-note", "/vault", files)
		assert.equals("/vault/my-note.md", result)
	end)

	it("normalizes spaces to dashes", function()
		local files = { ["my-note"] = "/vault/my-note.md" }
		local result = data.resolve_link("My Note", "/vault", files)
		assert.equals("/vault/my-note.md", result)
	end)

	it("returns nil for unresolvable links", function()
		local files = { ["other-note"] = "/vault/other-note.md" }
		local result = data.resolve_link("nonexistent", "/vault", files)
		assert.is_nil(result)
	end)
end)
