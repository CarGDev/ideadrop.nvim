std = "luajit"

globals = {
  "vim",
  "_",
}

read_globals = {
  "describe",
  "it",
  "before_each",
  "after_each",
  "assert",
}

max_line_length = false

ignore = {
  "211", -- unused function
  "212", -- unused argument
  "213", -- unused loop variable
  "311", -- unused assignment
  "312", -- unused argument value
  "411", -- variable redefines
  "421", -- shadowing local
  "431", -- shadowing upvalue
  "432", -- shadowing upvalue argument
  "542", -- empty if branch
  "631", -- max line length
}

exclude_files = {
  ".luarocks/",
  ".luacache/",
}
