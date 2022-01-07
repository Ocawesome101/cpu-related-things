#include "registers.h"

int registers[16];

int registers_init() {
  for (int i = 0; i < 16; i++) {
    registers[i] = 0;
  }
  registers[REG_PC] = 0x4000;
  return 0;
}

int registers_get(char id) {
  return registers[id];
}

int registers_set(char id, int value) {
  registers[id] = value & 0xFFFFFF;
  return 0;
}
