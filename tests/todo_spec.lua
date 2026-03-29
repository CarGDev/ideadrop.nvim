describe("todo checkbox parsing", function()
	-- Test the checkbox toggle logic in isolation
	local function toggle_line(line)
		if line:match("%- %[ %]") then
			return line:gsub("%- %[ %]", "- [x]", 1)
		elseif line:match("%- %[x%]") then
			return line:gsub("%- %[x%]", "- [ ]", 1)
		end
		return nil -- not a checkbox line
	end

	it("toggles unchecked to checked", function()
		local result = toggle_line("- [ ] Buy groceries")
		assert.equals("- [x] Buy groceries", result)
	end)

	it("toggles checked to unchecked", function()
		local result = toggle_line("- [x] Buy groceries")
		assert.equals("- [ ] Buy groceries", result)
	end)

	it("preserves indentation", function()
		local result = toggle_line("  - [ ] Nested item")
		assert.equals("  - [x] Nested item", result)
	end)

	it("returns nil for non-checkbox lines", function()
		assert.is_nil(toggle_line("# Header"))
		assert.is_nil(toggle_line("Just a paragraph"))
		assert.is_nil(toggle_line("- Regular list item"))
	end)

	it("only toggles first checkbox on a line", function()
		local result = toggle_line("- [ ] First - [ ] Second")
		assert.equals("- [x] First - [ ] Second", result)
	end)
end)

describe("todo item detection", function()
	local function is_checkbox_line(line)
		return line:match("^%s*%- %[.%]") ~= nil
	end

	it("detects unchecked items", function()
		assert.is_true(is_checkbox_line("- [ ] Item"))
	end)

	it("detects checked items", function()
		assert.is_true(is_checkbox_line("- [x] Item"))
	end)

	it("detects indented items", function()
		assert.is_true(is_checkbox_line("  - [ ] Item"))
		assert.is_true(is_checkbox_line("\t- [x] Item"))
	end)

	it("rejects non-checkbox lines", function()
		assert.is_false(is_checkbox_line("# Header"))
		assert.is_false(is_checkbox_line("- Regular item"))
		assert.is_false(is_checkbox_line(""))
		assert.is_false(is_checkbox_line("Some text - [ ] not at start"))
	end)
end)
