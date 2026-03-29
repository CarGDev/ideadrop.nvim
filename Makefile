.PHONY: lint format format-check docs test clean check-deps

lint:
	luacheck lua/

format:
	stylua lua/

format-check:
	stylua --check lua/

test:
	nvim --headless --clean -u ./scripts/test.lua

docs:
	nvim --headless -c "helptags doc/" -c "qa"

clean:
	rm -rf .luacache/ .dependencies/
	find . -name "*.orig" -delete

check-deps:
	@command -v nvim >/dev/null 2>&1 || { echo "neovim is required"; exit 1; }
	@command -v luacheck >/dev/null 2>&1 || { echo "luacheck is required: luarocks install luacheck"; exit 1; }
	@command -v stylua >/dev/null 2>&1 || { echo "stylua is required: cargo install stylua"; exit 1; }
	@echo "All dependencies found"
