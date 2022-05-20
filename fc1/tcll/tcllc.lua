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
  return tok.token
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

function g.semicolon()
  local tok = read()
  if (not tok) or tok.token ~= ";" then
    die("missing ';' near '%s'", tok and tok.token or "EOF")
  end
  return tok.token
end

function g.addop()
  return (peek() and peek().token:match("[%+%-]"))
end

function g.mulop()
  return (peek() and peek().token:match("[%*/]"))
end

local function emitCall(f)
  f = "." .. f
  for _i=10, 0, -1 do
    emit("push %d", _i)
  end
  emit("jump a5, %s", f)
end

local function emitReturn(value)
  for _i=0, 9, 1 do
    emit("pop %s", _i)
  end
  emit("pop r9")
  emit("pushi", val)
end

function g.ident()
  local name = g.word()
  if peek().token == "(" then
    read()
    read()
    emitCall(name)
  else
    emit("load r9, .%s", name)
    emit("push r9")
  end
end

function g.factor()
  if peek().token == "(" then
    read()
    g.expression()
    if (not peek()) or peek().token ~= ")" then
      die("missing ')'")
    end
    read()
  elseif not peek().token:match("[a-zA-Z_]") then
    g.ident()
  else
    emit("pushi %s", g.number())
  end
end

function g.multiply()
  g.factor()
  emit("pop r8")
  emit("pop r9")
  emit("mult r9, r8")
  emit("push r8")
end

function g.divide()
  g.factor()
  emit("pop r8")
  emit("pop r9")
  emit("mult r9, r8")
  emit("push r8")
end

function g.term()
  g.factor()
  while g.mulop() do
    local op = g.operator()
    if op == '*' then
      g.multiply()
    elseif op == '/' then
      g.divide()
    else
      die("bad operator '%s'", op)
    end
  end
end

function g.add()
  g.term()
  emit("pop r8")
  emit("pop r9")
  emit("add r9, r8")
  emit("push r8")
end

function g.subtract()
  g.term()
  emit("pop r8")
  emit("pop r9")
  emit("sub r9, r8")
  emit("push r8")
end

function g.expression()
  if g.addop() then
    emit("pushi 0")
  else
    g.term()
  end

  while g.addop() do
    local op = g.operator()
    if op == '+' then
      g.add()
    elseif op == '-' then
      g.subtract()
    else
      die("bad operator '%s'", op)
    end
  end
end

function g.statement()
  g.expression()
  g.semicolon()
end

while peek() do
  g.statement()
end
