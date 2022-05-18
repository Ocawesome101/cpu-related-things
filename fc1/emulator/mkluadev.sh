#!/bin/bash
# Compile a Lua device

if [ "$#" = 0 ]; then
  printf "usage: mkluadev NAME\n" 1>&2
  exit 1
fi

sofile=$(basename $1).so

if ! [ -f "$1.lua" ]; then
  printf "missing lua file\n" 1>&2
  exit 1
fi

gcc "src/luadev/luadev.c" -DDEVICE_FILE=\"$1.lua\" -Iinclude -llua -shared -fPIC -o devices/$sofile
