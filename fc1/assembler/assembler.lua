-- generic assembler

local function die(...)
  io.stderr:write(string.format(...), "\n")
  os.exit(1)
end

local file, destfile = ...

if not file then
  die("file argument required")
end

local label_locations = {}
local attributes = {
  -- minimum instruction size in bits (just the BINID component)
  instsize = 8,
  -- whether that size is constant
  fixedsize = true,
}
local instructions = {}

local function split(line)
  local ret = {}
  for word in line:gmatch("[^ ,]+") do
    ret[#ret+1] = tonumber(word) or word
  end
  return ret
end

local function into_bits(i, width)
  local bits = {}

  if type(i) == "string" then
    die("bad token '%s'", i)
  end

  if width then
    for _=1, width, 1 do
      bits[#bits+1] = i & 1
      --table.insert(bits, 1, i & 1)
      i = i >> 1
    end
  else
    while i > 0 do
      bits[#bits+1] = i & 1
      --table.insert(bits, 1, i & 1)
      i = i >> 1
    end
  end

  if #bits == 0 then bits[1] = 0 end

  return bits
end

-- line syntax:
--  *ATTR VALUE
-- or:
--  BINID NAME ABYTES [A1BITS [A2BITS [A3BITS [...]]]]
-- or:
--  BINID NAME *pad PADSIZE
for line in io.lines("instructions.adef") do
  local words = split(line)

  if #words > 1 then

    if type(words[1]) == "string" and words[1]:sub(1,1) == "*" then
      local attr = words[1]:sub(2)

      if attr == "instsize" then
        attributes.instsize = tonumber(words[2]) or 0

      elseif attr == "fixwidth" then
        attributes.fixedsize = words[2] == "true" or words[2] == 1

      elseif attr == "register" then
        local prefix, start, finish = words[2], tonumber(words[3]),
          tonumber(words[4])

        if not (prefix and start and finish) then
          die("invalid or missing arguments to '*register' attribute")
        end

        attributes[prefix] = {start=start, finish=finish}

      else
        die("bad attribute '%s'", words[1])
      end

    elseif #words > 2 then
      local binid, name, argcount = words[1], words[2], words[3]

      instructions[name] = function(args)
        local bits = into_bits(binid, attributes.instsize)
        local ilen = #bits
        local skipped = 0

        if argcount ~= "*pad" then
          for i=4, #words, 1 do
            local index = i - 3 - skipped

            if type(words[i]) == "string" then

              if words[i]:sub(-1) == "X" then
                for _=1, tonumber(words[i]:sub(1,-2)), 1 do
                  bits[#bits+1] = 0
                end
                skipped = skipped + 1

              elseif words[i]:find("?", nil, true) then

                local length, requires = words[i]:match("(%d+)%?(%d+)")
                length, requires = tonumber(length), tonumber(requires)

                if not (length and requires) then
                  die("invalid dependent-argument '%s'", words[i])

                else

                  if not bits[requires] then
                    die("invalid dependent-argument '%s' (bit %d not present)",
                      words[i], requires)

                  elseif bits[requires] == 1 then
                    if not args[index] then
                      die("missing argument %d to '%s'", index, name)
                    end

                    for _, bit in ipairs(into_bits(args[index], words[i])) do
                      bits[#bits+1] = bit
                    end

                  else
                    for _=1, length, 1 do
                      bits[#bits+1] = 0
                    end
                  end
                end
              end

            elseif not args[index] then
              die("missing argument %d to '%s'", index, name)

            else
              for _, bit in ipairs(into_bits(args[index], words[i])) do
                bits[#bits+1] = bit
              end
            end
          end

          if #bits - ilen ~= argcount*8 then
            die("wrong bit count for instruction '%s' (should be %d, got %d)",
              name, argcount*8, #bits)
          end

          if #bits / 8 ~= #bits // 8 then
            die("size of instruction '%s' (%d) is not a multiple of 8",
              name, #bits)
          end

        else
          for _=#bits, words[4], 1 do
            bits[#bits+1] = 0
          end
        end

        local ret = ""
        for i=1, #bits, 8 do
          local val = 0
          for n=i, i+7, 1 do
            val = val + ((bits[n] or 0) << (n-i))
          end
          ret = ret .. string.char(val)
        end

        return ret
      end
    end
  end
end

local lines = {}
local raw_lines = {}

local macros = {}

local binout_temp = ""

local function dw(line)
  if line:match('".+"') then
    line = line:gsub('"(.+)"', function(s)
      return s:gsub(".", function(c)
        return " "..tostring(string.byte(c)).." "
      end)
    end)

  elseif line:match("'.+'") then
    line = line:gsub("'(.+)'", function(s)
      return s:gsub(".", function(c)
        return " "..tostring(string.byte(c)).." "
      end)
    end)
  end

  local words = split(line)
  local ret = ""
  for i=2, #words, 1 do
    if type(words[i]) == "string" then
      if not label_locations[words[i]] then
        die("undefined label '%s'", words[i])
      end
      words[i] = label_locations[words[i]]
    end

    local bytes = math.ceil(#into_bits(words[i]) / 8)
    ret = ret .. string.pack("<I"..bytes, tonumber(words[i]))
  end

  return ret
end

-- pass 0: expand macros, *include files
local current_macro
local expanded_lines = {}

local function read_file(_file)
  for line in io.lines(_file) do
    local _, ftoi = line:match("%*include +(['\"])(.+)%1")
    if ftoi then
      read_file(ftoi)
    else
      expanded_lines[#expanded_lines+1] = line
    end
  end
end

read_file(file)

local function expand_macro(words, line, i, pre)
  local name = words[1]
  if not name then
    die("bad macro expansion '%s'", line)
  end

  if not macros[name] then
    die("undefined macro '%s'", name)
  end

  for j=1, #words, 1 do
    if words[j] == "#" then
      words[j] = macros[name].uses
    end
  end

  for n, _line in ipairs(macros[name]) do
    table.insert(expanded_lines, i + n, (pre or "") ..
      (_line:gsub("#", macros[name].uses):gsub("$([@%$%d])", function(id)
        if id == "$" and #words == 1 then
          die("macro '%s' expects at least 1 argument", name)
        end

        if id == "@" or id == "$" then
          return table.concat(words, " ", 2)
        end

        id = tonumber(id)
        if words[id+1] then
          return words[id+1]
        else
          die("macro '%s' expects at least %d arguments", name, n)
        end
      end)))
  end

  macros[name].uses = macros[name].uses + 1

  if not pre then table.remove(expanded_lines, i) end
end

do
  local i = 1
  while expanded_lines[i] do
    local line = expanded_lines[i]:gsub("^ +", "")

    if line:sub(1,2) == "*$" then
      local words = split(line:sub(3))
      expand_macro(words, line, i)

    elseif line:sub(1,7) == ";$macro" then
      local name = line:match(";$macro ([^ ]+)$")
      if not name then
        die("bad macro syntax '%s'", line)
      end

      if current_macro then
        die("dangling macro '%s'", current_macro)
      end

      current_macro = name
      macros[current_macro] = {uses = 0}

    elseif line:sub(1,5) == ";$end" then
      current_macro = nil

    elseif line:sub(1,2) == ";$" then
      table.insert(macros[current_macro], line:sub(3))
    end

    i = i + 1
  end
end

if current_macro then
  die("dangling macro '%s'", current_macro)
end

-- pass 1: determine label offsets and find macros
local offset = 0
for current_line, line in ipairs(expanded_lines) do
  line = line:gsub("^ +", ""):gsub(";.+", "")

  --if line:sub(1,1) ~= "*" then line = line:gsub(",", "") end

  if #line > 0 then
    local words = split(line)
    lines[#lines+1] = split(line)
    lines[#lines].lineno = current_line
    raw_lines[current_line] = line

    if words[1]:sub(1,1) ~= "*" and words[1]:sub(1,1) ~= "." then
      for i=1, #words, 1 do
        if type(words[i]) == "string" then
          if words[i]:sub(1,1) == "." then
            words[i] = 0

          elseif i > 1 and attributes[words[i]:sub(1,1)] then
            local attr = attributes[words[i]:sub(1,1)]

            local n = tonumber(words[i]:sub(2))
            if n then n = n + attr.start end

            if (not n) or n < attr.start or n > attr.finish then
              die("invalid register index '%s'", words[i])
            end

            words[i] = n
            lines[#lines][i] = n
          end
        end
      end

      if not instructions[words[1]] then
        die("bad instruction: '%s'", words[1])
      end

      binout_temp = binout_temp .. instructions[words[1]](
        table.pack(table.unpack(words, 2)))

    elseif words[1]:sub(1,1) == "." then
      label_locations[words[1]] = offset + #binout_temp-- + 1

    elseif words[1] == "*offset" then
      if not tonumber(words[2]) then
        die("invalid offset '%s'", words[2])
      end

      offset = tonumber(words[2]) or offset
      print("offset:", offset)

    elseif words[1] == "*dw" then
      binout_temp = binout_temp .. dw(line)

    elseif words[1]:sub(1,3) == "*dw" then
      local pad_to = tonumber(words[1]:sub(4))
      if not pad_to then
        die("invalid token '%s'", words[1])
      end

      local _dw = dw(line)
      binout_temp = binout_temp .. _dw .. string.rep("\0", pad_to - #_dw)

    else
      die("very bad syntax near '%s'", line)
    end
  end
end

local binout = ""

-- pass 2: final binary form
for _, words in ipairs(lines) do
  local line = words.lineno

  if words[1]:sub(1,1) ~= "*" and words[1]:sub(1,1) ~= "." then
    for i=2, #words, 1 do
      if type(words[i]) == "string" then
        if words[i]:sub(1,1) == "." then
          if not label_locations[words[i]] then
            die("line %d: undeclared label '%s'", line, words[i])
          end

          words[i] = label_locations[words[i]]

        else
          die("bad syntax on line %d: '%s'", line, words[i])
        end
      end
    end

    if not instructions[words[1]] then
      die("bad instruction: '%s'", words[1])
    end

    binout = binout .. instructions[words[1]](
      table.pack(table.unpack(words, 2)))

  elseif words[1]:sub(1,1) == "." then
    -- do nothing

  elseif words[1] == "*offset" then
    -- do nothing

  elseif words[1] == "*dw" then
    binout = binout .. dw(raw_lines[line])

  elseif words[1]:sub(1,3) == "*dw" then
    local pad_to = tonumber(words[1]:sub(4))
    if not pad_to then
      die("invalid token '%s'", words[1])
    end

    local _dw = dw(raw_lines[line])
    binout = binout .. _dw .. string.rep("\0", pad_to - #_dw)

  else
    die("bad syntax on line '%d'", line)
  end
end

((destfile and io.open(destfile, "w")) or io.stdout):write(binout):close()
