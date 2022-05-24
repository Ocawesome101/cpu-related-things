#!/usr/bin/env lua
-- THLL compiler
-- A million thanks to Jack Crenshaw's excellent (if old) crash course
-- in recursive-descent parsers, at https://compilers.iecc.com/crenshaw/

local syntaxfunc = require("thll.syntax").new("thll/thll.lua")

local args = table.pack(...)

local function die(f, ...)
  io.stderr:write(string.format(f.."\n", ...))
  os.exit(1)
end

if #args == 0 then
  die("usage: thllc SRCFILE [OUTFILE]")
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

local function emit(s, ...)
  io.write(string.format(s.."\n", ...))
end

-- store a variable from the stack into 'name', which must
-- be defined in the given symbol table
local function emitStore(syms, name)
  if not syms[name] then
    die("undefined variable '%s'", name)
  end
  emit("pop r9")
  emit("store r9, .%s_%s", syms.__stab_name, name)
end

-- load a variable from its label into the given register;
-- the name must be defined in the given symbol table
local function emitLoad(syms, name, register)
  if not syms[name] then
    die(debug.traceback("undefined variable '%s'"), name)
  end
  emit("load %s, .%s_%s", register, syms.__stab_name, name)
end

function g.number()
  local tok = read()
  if (not tok) or tok.ttype ~= "number" then
    die("expected number before '%s'", tok and tok.token or "<EOF>")
  end
  return tonumber(tok.token)
end

function g.operator()
  local tok = read()
  if (not tok) or tok.ttype ~= "operator" then
    die("expected operator before '%s'", tok and tok.token or "<EOF>")
  end
  return tok.token
end

function g.word()
  local tok = read()
  if (not tok) or tok.ttype ~= "word" then
    die("expected variable name before '%s'", tok and tok.token or "<EOF>")
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

local _lid = 0
function g.newLabel()
  _lid = _lid + 1
  return ".l"..(_lid-1)
end

function g.program()
  g.entrypoint()
  g.top_level_block()
end

function g.entrypoint()
  g.match("entrypoint")
  emit("jump a5, .%s", g.word())
  g.match(";")
end

function g.top_level_block()
  local top_level_syms = {__stab_name ="",--__top_level_block",
    __funcs = {}}
  setmetatable(top_level_syms, {__index = top_level_syms.__funcs})

  while true do
    local look = g.look()
    if not look then break end

    if look == "var" then
      g.declaration(top_level_syms)

    elseif look == "fn" then
      g._function(top_level_syms)

    else
      die("invalid top-level keyword near '%s'", look)
    end
  end

  for k, v in pairs(top_level_syms) do
    if k ~= "__stab_name" and k ~= "__funcs" then
      g.allocate(top_level_syms, k, v)
    end
  end
end

function g.declaration(syms)
  g.match("var")
  local name = g.word()
  if syms[name] then
    die("attempt to redeclare variable '%s'", name)
  end

  g.match(":")

  local vtype = g.type()
  syms[name] = vtype

  if g.look() == "=" then
    g.match("=")
    g.expression(syms)
    emitStore(syms, name)
  end

  g.match(";")
end

local types = {
  int = 4,
  void = 4
}

function g.type()
  local look = g.look()
  if types[look] then
    read()
    return look
  else
    die("invalid type specifier '%s'", look)
  end
end

function g.expression(syms)
  if tonumber(g.look()) then
    emit("pushi %d", g.number())
  else
    local name = g.word()
    if g.look() == "(" then
      local ret = g.newLabel()
      emit("pushi %s", ret)
      g.f_arg_list(syms, syms.__funcs[name])
      emit("jump .%s", name)
      --emitCall(name)
      emit(ret)
    else
      if not syms[name] then
        die("undefined variable '%s'", name)
      end
      emitLoad(syms, name, "r9")
      emit("push r9")
    end
  end
end

function g.f_arg_list(syms, fdat)
  g.match("(")
  if #fdat.args == 0 then
    g.match(")")
  else
    for n=1, #fdat.args, 1 do
      if g.look() == ")" then
        die("not enough arguments to '%s'", fdat.name)
      end

      g.expression(syms)
      if n < #fdat.args then
        g.match(",")
      end
    end

    g.match(")")
  end
end

function g._function(syms)
  g.match("fn")
  local name = g.word()

  local fret_label = g.newLabel()

  local fdata = {name = name, args = {}}
  syms.__funcs[name] = fdata

  g.match("(")
  -- function's own local symbol table
  local local_stable = setmetatable({__stab_name = "",--name
    }, {__index=syms})
  g.f_param_list(local_stable, fdata)
  g.match(")")
  g.match(":")

  local rtype = g.type()
  fdata.ret = rtype

  emit(".%s", name)
  for n=#fdata.args, 1, -1 do
    local v = fdata.args[n]
    emitStore(local_stable, v.name)
  end

  g.block(local_stable, fret_label)

  for k, v in pairs(local_stable) do
    if k ~= "__stab_name" then
      g.allocate(local_stable, k, v)
    end
  end

  emit(fret_label)
  if rtype ~= "void" then
    -- the top value on the stack will always be the return value, if there
    -- is one.
    emit("pop r9")
    emit("pop r8")
    emit("push r9")
    emit("pop a5")
  end
end

function g.f_param_list(syms, fdata)
  if g.look() == ")" then return end

  local look = ","

  while true do
    local name = g.word()
    g.match(":")
    local vtype = g.type()

    fdata.args[#fdata.args+1] = {name = name, type = vtype}
    syms[name] = vtype

    look = g.look()

    if look == "," then
      read()

    elseif look == ")" then
      break

    else
      die("')' expected near '%s'", look)
    end
  end
end

local blcount = 0
local statementy_things = {["if"]=true, ["for"]=true, ["while"]=true,
  ["return"]=true, ["break"]=true, ["asm"]=true,}

function g.block(syms, fr_lab)
  g.match("{")

  local l1 = g.newLabel()

  blcount = blcount + 1
  local block_syms = setmetatable({
    __stab_name = ""--string.format("blk%d", blcount)
  }, {__index = syms})

  while true do
    local look = g.look()
    if look == "}" then
      break

    elseif look == "var" then
      g.declaration(block_syms)

    elseif statementy_things[look] then
      g.statement(block_syms, fr_lab)

    else
      g.assignment(block_syms)
    end
  end

  emit("jump a5, %s", l1)

  for k, v in pairs(block_syms) do
    if k ~= "__stab_name" then
      g.allocate(block_syms, k, v)
    end
  end

  emit(l1)

  g.match("}")
end

function g.assignment(syms)
  local name = g.word()
  if not syms[name] then
    die("undefined variable '%s'", name)
  end

  g.match("=")

  g.expression(syms)

  emitStore(syms, name)

  g.match(";")
end

function g.statement(syms, fret, bjmp)
  local tok = g.look()
  if tok == "return" then
    g.return_statement(syms, fret)
  elseif tok == "break" then
    g.break_statement(syms, bjmp)
  end
end

function g.return_statement(syms, fret)
  g.match("return")
  if g.look() ~= ";" then
    g.expression(syms)
  end
  emit("jump a5, %s", fret)
  g.match(";")
end

function g.break_statement(_, bjmp)
  g.match("break")
  emit("jump a5, %s", bjmp)
  g.match(";")
end

function g.allocate(stab, name, vtype)
  emit(".%s_%s", stab.__stab_name, name)
  emit("*dw%d 0", types[vtype])
end

g.program()
