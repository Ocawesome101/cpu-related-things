// FC-1
This is a reference implementation of the FC-1 architecture.

Run `./build.sh` while in this directory to build the emulator and accompanying devices.

Pass -DDEVICE_SCAN_DIR=\"/some/directory\" to set where device files should go - it defaults to `./devices`.  Compiled device files are always placed in `./devices` regardless of this option.

Pass `-DFC1_DEBUG` to enable very verbose debug output.  Pass `-DFC1_STEP` as well to enable single-stepping.

Devices are implemented as dynamically loaded shared object files in the defined `DEVICE_SCAN_DIR`.  See `src/devices` for a TTY device implementation.


// Lua devices
This FC-1 emulator supports implementing port devices in Lua with a little bit of stub C code.  This code is `src/luadev/luadev.c`.  Use `./mkluadev.sh` to generate them:

  - `./mkluadev.sh foo` will create `devices/foo.so` pointing to `./foo.lua` as its Lua code.
  - `./mkluadev.sh /home/user/bar` will create `devices/bar.so` pointing to `/home/user/bar.lua` as its Lua code to run.

Lua code is not bundled with the accompanying shared object file, but is instead loaded with `luaL_dofile` - something that may change in the future.


// Porting
This emulator is written in a fairly portable manner.  It does not use malloc(), nor does it use any floating-point operations; the core should be fairly easy to port to anything for which you can compile C that has at least 16.5MB or so of memory.

The TTY device uses the (possibly) glibc-specific ppoll().  I have not tested compilation on anything other than Linux.
