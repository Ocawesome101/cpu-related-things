-- "filesystem" device
_G.port = 1

local file = os.getenv("FC1_STORAGE_FILE") or "fs.bin"
local handle, err = io.open(file, "r+b")
if not handle then
  handle, err = io.open(file, "wb")
  if handle then
    -- 32MB storage device
    handle:write(string.rep("\0", 32*1024*1024))
    handle:close()
    handle, err = io.open(file, "r+b")
  end
end

if not handle then
  error(err, 0)
end

local rq = {
  -- read byte
  rbyte = 0x1,
  -- write byte
  wbyte = 0x2,
  -- seek to byte within current sector
  sbyte = 0x4,
  -- seek forward some bytes
  sfbyte = 0x5,
  -- seek backward some bytes
  sbbyte = 0x6,
  -- current position
  curpos = 0x8,
  -- read a sector (512 bytes)
  rsect = 0x10,
  -- write a sector (512 bytes)
  wsect = 0x20,
  -- seek to sector
  ssect = 0x30,
}

for k, v in pairs(rq) do rq[v] = k end

local mode = 0
local read = 0
local written = 0
local tmp_wval = 0

function _G.writer(c)
  if mode == rq.wbyte then
    handle:write(string.char(c))
    mode = 0
  elseif mode == rq.wsect then
    written = written + 1
    handle:write(string.char(c))
    if written == 512 then
      mode = 0
    end
  elseif mode == rq.ssect then
    written = written + 1
    tmp_wval = (tmp_wval << 8) + c
    if written == 2 then
      handle:seek("set", 512 * tmp_wval)
      tmp_wval = 0
      mode = 0
    end
  elseif mode == rq.sfsect then
    written = written + 1
    tmp_wval = (tmp_wval << 8) + c
    if written == 2 then
      local cur = handle:seek()
      handle:seek("set", 512 * (cur // 512 + tmp_wval))
      tmp_wval = 0
      mode = 0
    end
  elseif mode == rq.sbsect then
    written = written + 1
    tmp_wval = (tmp_wval << 8) + c
    if written == 2 then
      local cur = handle:seek()
      handle:seek("set", math.max(0, 512 * (cur // 512 - tmp_wval)))
      tmp_wval = 0
      mode = 0
    end
  elseif mode == rq.sbyte then
    written = written + 1
    tmp_wval = (tmp_wval << 8) + c
    if written == 2 then
      local cur = handle:seek()
      handle:seek("set", 512 * (cur // 512) + (tmp_wval & 0x200))
      tmp_wval = 0
      mode = 0
    end
  elseif mode == rq.sfbyte then
    written = written + 1
    tmp_wval = (tmp_wval << 8) + c
    if written == 2 then
      handle:seek("cur", (tmp_wval & 0x200))
      tmp_wval = 0
      mode = 0
    end
  elseif mode == rq.sbbyte then
    written = written + 1
    tmp_wval = (tmp_wval << 8) + c
    if written == 2 then
      handle:seek("set", -(tmp_wval & 0x200))
      tmp_wval = 0
      mode = 0
    end
  elseif rq[c] then
    mode = c
    if mode == rq.wsect then
      local cur = handle:seek()
      -- seek to beginning of sector
      handle:seek("set", 512 * (cur // 512))
    end
  end
end

function _G.reader()
  if mode == rq.rbyte then
    mode = 0
    return handle:read(1):byte()
  elseif mode == rq.rsect then
    read = read + 1
    if read == 512 then
      read = 0
      mode = 0
    end
    return handle:read(1):byte()
  elseif mode == rq.curpos then
    read = read + 1
    local cur = handle:seek()
    if read == 2 then
      mode = 0
      read = 0
      return cur & 0xFF
    end
    return cur & 0xFF00
  end
  return 0
end

function _G.getdevid()
  return 5
end

function _G.isready()
  return mode
end
