#!/usr/bin/env lua
-- THLL compiler
-- A million thanks to Jack Crenshaw's excellent (if old) crash course
-- in recursive-descent parsers, at https://compilers.iecc.com/crenshaw/

local syntaxfunc = require("thll.syntax").new("thll/thll.lua")

local args = table.pack(...)

local offset = 0x4000

local function die(f, ...)
  io.stderr:write(string.format(f.."\n", ...))
  os.exit(1)
end

while true do
  if args[1] == "-h" then
    args = {}
    break
  elseif args[1] == "-offset" then
    table.remove(args, 1)
    offset = tonumber(table.remove(args, 1))
    if not offset then
      die("option '-offset' expects a number (pass -h for help)")
    end
  else
    break
  end
end

if #args == 0 then
  die("usage: thllc [options] SRCFILE [OUTFILE]\n\z
  options:\n  \z
  -offset NUMBER  sets the program offset (default 0x4000)\n  \z
  -h              show this help message\n\z
  outputs FC-1 assembly (NOT bytecode).\n\z
  copyright (c) 2022 Ocawesome101 under the GPLv3.")
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

local g = {}

local out_text = ""
local function emit(s, ...)
  out_text = out_text .. string.format(s.."\n", ...)
end

-- store a variable from the stack into 'name', which must
-- be defined in the given symbol table
local function emitStore(syms, name)
  if not syms[name] then
    die("undefined variable '%s'", name)
  end
  emit("pop r9")
  emit("store r9, .%s_%s", syms[name].__stab_name, name)
end

-- load a variable from its label into the given register;
-- the name must be defined in the given symbol table
local function emitLoad(syms, name, register)
  if not syms[name] then
    die(debug.traceback("undefined variable '%s'"), name)
  end
  emit("load %s, .%s_%s", register, syms[name].__stab_name, name)
end

-- check if the top of the stack is 0, and if it isn't then
-- jump to the given label
local function emitUntrueJump(label)
  emit("imm r7, 0x10")
  emit("imm r8, 0")
  emit("pop r9")
  emit("compare r8, r9")
  emit("xori a5, 0x10")
  emit("jump r7, %s", label)
end

local global_syms = {}

-- random symbol table name generator
local function rand_name(x)
  if os.getenv("NOOBF") then
    return x
  end
  local base = "_"
  for _=1, 5, 1 do
    local n = math.random(0, 2)
    base = base .. string.char(n == 0 and math.random(65, 90) or
      n == 1 and math.random(97, 122) or
      n == 2 and math.random(48, 57))
  end
  return base
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
  local top_level_syms = {__stab_name = rand_name("__tlb"), __funcs = {}}
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
end

function g.declaration(syms)
  g.match("var")
  local name = g.word()
  if syms[name] then
    die("attempt to redeclare variable '%s'", name)
  end

  g.match(":")

  local vtype = g.type()
  syms[name] = {__stab_name = syms.__stab_name, type = vtype}
  global_syms[syms.__stab_name.."_"..name] = syms[name]

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

local function is_add(c)
  return c == "+" or c == "-"
end

local function is_mul(c)
  return c == "*" or c == "/"
end

local function is_bool(c)
  return c == "==" or c == ">" or c == "<" or c == "!="
end

-- in order: rshift, lshift, band, bor, bxor
local function is_bit(c)
  return c == ">>" or c == "<<" or c == "&" or c == "|" or c == "^"
end

function g.expression(syms)
  g.term(syms)

  while is_add(g.look()) do
    local tok = read().token
    g.term(syms)
    emit("pop r8")
    emit("pop r9")
    if tok == "+" then
      emit("add r8, r9")
    elseif tok == "-" then
      g.term(syms)
      emit("sub r8, r9")
    end
    emit("push r9")
  end
end

function g.term(syms)
  g.bitexp(syms)

  while is_mul(g.look()) do
    local tok = read().token
    g.bitexp(syms)
    emit("pop r8")
    emit("pop r9")
    if tok == "*" then
      emit("mult r8, r9")
    elseif tok == "/" then
      emit("div r8, r9")
    end
    emit("push r9")
  end
end

function g.bitexp(syms)
  g.boolexp(syms)

  while is_bit(g.look()) do
    local tok = read().token
    g.boolexp(syms)
    emit("pop r8")
    emit("pop r9")
    if tok == ">>" then
      emit("rshift r8, r9")
    elseif tok == "<<" then
      emit("lshift r8, r9")
    elseif tok == "&" then
      emit("and r8, r9")
    elseif tok == "|" then
      emit("or r8, r9")
    elseif tok == "^" then
      emit("xor r8, r9")
    end
    emit("push r9")
  end
end

-- TRUE is 0, FALSE is 1
function g.boolexp(syms)
  g.factor(syms)

  while is_bool(g.look()) do
    local tok = read().token
    g.factor(syms)
    emit("pop r8")
    emit("pop r9")
    emit("compare r8, r9")
    if tok == "==" then
      emit("imm r7, 0x10")
    elseif tok == ">" then
      emit("imm r7, 0x4")
    elseif tok == "<" then
      emit("imm r7, 0x8")
    elseif tok == "!=" then
      emit("xori a5, 0x10")
      emit("imm r7, 0x10")
    end
    local l1, l2 = g.newLabel(), g.newLabel()
    emit("jump r7, %s", l1)
    emit("imm r9, 1")
    emit("jump a5, %s", l2)
    emit(l1)
    emit("imm r9, 0")
    emit(l2)
    emit("push r9")
  end
end

function g.factor(syms)
  if g.look() == "(" then
    g.match("(")
    g.expression(syms)
    g.match(")")
  elseif tonumber(g.look()) then
    emit("pushi %d", g.number())
  else
    local name = g.word()
    if g.look() == "(" then
      g.func_call(syms, name)
    else
      if not syms[name] then
        die("undefined variable '%s'", name)
      end
      emitLoad(syms, name, "r9")
      emit("push r9")
    end
  end
end

function g.func_call(syms, name)
  local ret = g.newLabel()
  emit("pushi %s", ret)
  g.f_arg_list(syms, syms.__funcs[name])
  emit("jump a5, .%s", name)
  emit(ret)
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
  local local_stable = setmetatable({__stab_name = rand_name(name)},
    {__index=syms})
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

  emit(fret_label)
  if rtype ~= "void" then
    -- the top value on the stack will always be the return value, if there
    -- is one.
    -- pop return value
    emit("pop r9")
    -- pop return address
    emit("pop r8")
    -- push return value
    emit("push r9")
    -- jump!
    emit("idjump a5, r8")
  else
    emit("pop r9")
    emit("idjump a5, r9")
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
    syms[name] = {__stab_name = syms.__stab_name, type = vtype}
    global_syms[syms.__stab_name.."_"..name] = syms[name]

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

function g.block(syms, fr_lab, br_lab)
  g.match("{")

  blcount = blcount + 1
  local block_syms = setmetatable({
    __stab_name = rand_name(string.format("blk%d", blcount))},
    {__index = syms})

  while true do
    local look = g.look()
    if look == "}" then
      break

    elseif look == "var" then
      g.declaration(block_syms)

    elseif statementy_things[look] then
      g.statement(block_syms, fr_lab, br_lab)

    elseif tokens[i+1].token == "(" then
      local name = g.word()
      g.func_call(block_syms, name)
      g.match(";")

    else
      g.assignment(block_syms)
    end
  end

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
  elseif tok == "while" then
    g.while_statement(syms, fret)
  elseif tok == "asm" then
    g.asm_statement(syms)
  elseif tok == "if" then
    g.if_statement(syms, fret, bjmp)
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
  if not bjmp then
    die("attempt to 'break' outside of loop")
  end
  g.match("break")
  emit("jump a5, %s", bjmp)
  g.match(";")
end

function g.while_statement(syms, fret)
  g.match("while")
  local loop = g.newLabel()
  emit(loop)
  g.expression(syms)
  local bjmp = g.newLabel()
  emitUntrueJump(bjmp)
  g.block(syms, fret, bjmp)
  emit("jump a5, %s", loop)
  emit(bjmp)
  g.match(";")
end

function g.asm_statement(syms)
  g.match("asm")
  g.asm_block(syms)
  g.match(";")
end

function g.asm_block(syms)
  g.match("{")
  while g.look() and g.look() ~= "}" do
    g.asm_line(syms)
  end
  g.match("}")
end

function g.if_statement(syms, fret, bjmp)
  g.match("if")
  g.expression(syms)
  local ifelse = g.newLabel()
  local endif = g.newLabel()
  emitUntrueJump(ifelse)
  g.block(syms, fret, bjmp)
  emit("jump a5, %s", endif)
  emit(ifelse)
  if g.look() == "else" then
    g.match("else")
    g.block(syms, fret, bjmp)
  end
  emit(endif)
  g.match(";")
end

local insts = {nop=true,idload=true,load=true,move=true,imm=true,
  idstore=true,store=true,push=true,pushi=true,pop=true,compare=true,jump=true,
  idjump=true,rjump=true,add=true,addi=true,sub=true,subi=true,mult=true,
  multi=true,div=true,divi=true,lshift=true,lshifti=true,rshift=true,
  rshifti=true,["not"]=true,["and"]=true,andi=true,["or"]=true,ori=true,
  xor=true,xori=true,devid=true,pread=true,pisready=true,pwrite=true,seti=true,
  irq=true,clri=true,halt=true}

function g.asm_line(syms)
  local look = g.look()
  if (not look) or not insts[look] then
    die("bad assembly instruction '%s'", look or "<EOF>")
  end

  local line = { g.word() }
  repeat
    look = g.look()
    local ltype = g.looktype()

    if look == "." then
      look = look .. (read() and g.look())
      ltype = "foo"
    end

    if ltype == "separator" and look ~= "," and look ~= ";" then
      die("invalid assembly token '%s'", look)
    end

    if syms[look] then
      look = string.format(".%s_%s", syms[look].__stab_name, look)
    end

    if look ~= ";" then
      read()
      line[#line+1] = look
    end
  until look == ";"

  g.match(";")
  emit("%s", table.concat(line, " "))
end

function g.allocate(name, vtype)
  emit(".%s", name)
  emit("*dw%d 0", types[vtype.type])
end

emit("*offset %d", offset)
g.program()
emit("halt")

for k, v in pairs(global_syms) do
  g.allocate(k, v)
end

local out = io.stdout
if args[2] then
  out = assert(io.open(args[2], "w"))
end
out:write(out_text)
out:close()
