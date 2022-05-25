#!/usr/bin/env lua
-- Basic optimizer

local routines = {
  { "store r9 ?, (.-)\nload r9 ?, %1\n" },
  { "pop r9\npush r9\n" },
  { "jump [ar]%d, (.-)\n%1", "%1" }
}

local program = io.read("a")

for i=1, #routines, 1 do
  program = program:gsub(routines[i][1], routines[i][2] or "")
end

print(program)
