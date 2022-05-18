// Support for implementing port devices in Lua

#include "ports.h"
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#include <stdio.h>
#include <stdlib.h>

#ifndef DEVICE_FILE
#define DEVICE_FILE "ldev_example.lua"
#endif

lua_State* L;

unsigned char ldev_reader() {
  lua_getglobal(L, "reader");
  lua_call(L, 0, 1);
  return (unsigned char)luaL_checkinteger(L, 1);
}

int ldev_writer(unsigned char byte) {
  lua_getglobal(L, "writer");
  lua_pushinteger(L, (lua_Integer)byte);
  lua_call(L, 1, 1);
  return (int)luaL_checkinteger(L, 1);
}

int ldev_isready() {
  lua_getglobal(L, "isready");
  lua_call(L, 0, 1);
  return (int)luaL_checkinteger(L, 1);
}

int ldev_getdevid() {
  lua_getglobal(L, "getdevid");
  lua_call(L, 0, 1);
  return (int)luaL_checkinteger(L, 1);
}

void check_exists(const char* func) {
  lua_getglobal(L, func);
  if (lua_isnil(L, 1) == 1) {
    printf("[luadev] missing field '%s'\n", func);
    exit(1);
  }
  lua_pop(L, 1);
}

int device_open(void) {
  printf("[luadev] Loading Lua port definition from %s\n", DEVICE_FILE);
  L = luaL_newstate();
  luaL_openlibs(L);

  int success = luaL_dofile(L, DEVICE_FILE);

  if (success != LUA_OK) {
    printf("[luadev] %s\n", luaL_checklstring(L, 1, NULL));
    exit(1);
  }

  check_exists("port");
  check_exists("reader");
  check_exists("writer");
  check_exists("isready");
  check_exists("getdevid");
  
  lua_getglobal(L, "port");
  port_register_device((int)luaL_checkinteger(L, 1), &ldev_reader,
      &ldev_writer, &ldev_isready, &ldev_getdevid);

  return 0;
}
