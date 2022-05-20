-- "filesystem" device
_G.port = 1

local file = os.getenv("FC1_STORAGE_FILE") or "fs.bin"
local handle, err = io.open(file, "r+b")
if not handle then
  handle, err = io.open(file, "wb")
  if handle then
    -- 4MB storage device
    handle:write(string.rep("\0", 4*1024*1024))
    handle:close()
    handle, err = io.open(file, "r+b")
  end
end

if not handle then
  error(err, 0)
end

function _G.reader()
  return 0
end

local requests = {
  rsect = 0x10,
  wsect = 0x20
}

function _G.writer(char)
  return 0
end

function _G.getdevid()
  return 5
end

function _G.isready()
  return 0
end
