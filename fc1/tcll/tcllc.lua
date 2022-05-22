#!/usr/bin/env lua
-- TCLL compiler
-- This version does not optimize at all.

local syntaxfunc = require("tcll.syntax").new("tcll/tcll.lua")

local args = table.pack(...)

local function die(f, ...)
  io.stderr:write(string.format(f.."\n", ...))
  os.exit(1)
end

if #args == 0 then
  die("usage: tcllc SRCFILE [OUTFILE]")
end

local function readfile(f)
  local h, e = io.open(f)
  if not h then die("%s", e) end
  return h:read("a"), h:close()
end

local tokens = {}
for token, ttype in syntaxfunc(readfile(args[1])) do
  if not ttype then
    die("bad token '%s'", token)
  end
  if ttype ~= "whitespace" and ttype ~= "comment" then
    tokens[#tokens+1] = {token=token, ttype=ttype}
  end
end

---- some form of recursive descent parser ----

local i = 1
local function peek()
  return tokens[i]
end

local function read()
  i = i + 1
  return tokens[i - 1]
end

-- grammar definitions
local g = {}

local function err(s, ...)
  io.stderr:write(string.format(s.."\n", ...))
end

local function die(s, ...)
  err(s, ...)
  os.exit(1)
end

local function emit(s, ...)
  io.write(string.format(s.."\n", ...))
end

function g.number()
  local tok = read()
  if tok.ttype ~= "number" then
    die("expected number near '%s'", tok.token)
  end
  return tonumber(tok.token)
end

function g.operator()
  local tok = read()
  if (not tok) or tok.ttype ~= "operator" then
    die("expected operator near '%s'", tok and tok.token or "<EOF>")
  end
  return tok.token
end

function g.word()
  local tok = read()
  if (not tok) or tok.ttype ~= "word" then
    die("expected variable name near '%s'", tok and tok.token or "<EOF>")
  end
  return tok.token
end

function g.look()
  return peek() and peek().token
end

function g.looktype()
  return peek() and peek().ttype
end

function g.match(c)
  if g.look() == c then
    read()
  else
    die("expected '%s' near '%s'", c, g.look() or "<EOF>")
  end
end

--[[
local function is_add(c)
  return c == "+" or c == "-"
end

local function is_mul(c)
  return c and c == "*" or c == "/"
end
--]]

function g.other()
  emit(read().token)
end

function g.expression()
  emit(read().token)
end

local terminators = {
  ["}"] = true
}

local _lid = 0
function g.newLabel()
  _lid = _lid + 1
  return ".l"..(_lid-1)
end

function g.block(label, nomatch)
  if not nomatch then g.match("{") end
  local look = g.look()
  while look and not terminators[look] do
    if look == "if" then
      g.doif(label)
    elseif look == "while" then
      g.dowhile()
    elseif look == "break" then
      g.dobreak(label)
    else
      g.other()
    end
    look = g.look()
  end
  if not nomatch then g.match("}") end
end

function g.boolExpression()
end

function g.condition()
  emit("<condition>")
end

function g.doif(label)
  g.match("if")
  local l1 = g.newLabel()
  local l2 = l1
  g.condition()
  emit("imm r9, 0x10")
  emit("jump r9, %s", l1)
  g.block(label)
  if g.look() == "else" then
    g.match("else")
    l2 = g.newLabel()
    emit("jump a5, %s", l2)
    emit(l1)
    g.block(label)
  end

  emit("%s", l2)
end

function g.dowhile()
  g.match("while")
  local l1, l2 = g.newLabel(), g.newLabel()
  emit(l1)
  g.condition()
  emit("imm r9, 0x10")
  emit("jump r9, %s", l2)
  g.block(l2)
  emit("jump a5, %s", l1)
  emit(l2)
end

-- no for-loops *yet*

function g.dobreak(label)
  g.match("break")
  if not label then
    die("cannot break outside loop")
  end
  emit("jump a5, %s", label)
end

repeat
  g.block(nil, true)
until not g.look()
