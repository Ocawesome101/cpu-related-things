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
    die("expected operator near '%s'", tok and tok.token or "EOF")
  end
  return tok.token
end

function g.word()
  local tok = read()
  if (not tok) or tok.ttype ~= "word" then
    die("expected variable name near '%s'", tok and tok.token or "EOF")
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
    die("expected '%s' near '%s", c, g.look())
  end
end

local function is_add(c)
  return c == "+" or c == "-"
end

local function is_mul(c)
  return c and c == "*" or c == "/"
end

local variables = {}

function g.factor()
  local value

  if g.look() == "(" then
    g.match("(")
    value = g.expression()
    g.match(")")

  elseif variables[g.look()] then
    value = variables[g.look()]
    read()

  elseif g.looktype() == "number" then
    value = g.number()

  else
    die("bad identifier '%s'", g.look())
  end

  return value
end

function g.term()
  local value = g.factor()

  while is_mul(g.look()) do
    local tok = read().token
    if tok == "*" then
      value = value * g.factor()
    elseif tok == "/" then
      value = math.floor(value / g.factor() + 0.5)
    end
  end

  return value
end

function g.expression()
  local value
  if is_add(g.look()) then
    value = 0
  else
    value = g.term()
  end

  while is_add(g.look()) do
    local tok = read().token
    if tok == "+" then
      value = value + g.term()
    elseif tok == "-" then
      value = value - g.term()
    end
  end

  return value
end

function g.assignment()
  local name = g.word()
  g.match("=")
  variables[name] = g.expression()
end

-- i/o
function g.input()
  g.match("in")
  variables[g.word()] = io.read()
end

function g.output()
  g.match("out")
  print(variables[g.word()])
end

repeat
  local tok = g.look()

  if tok == "out" then
    g.output()
  elseif tok == "in" then
    g.input()
  else
    g.assignment()
  end

  g.match(";")
until not g.look()
