// a whole 16MB of memory

#include "memory.h"

char memory[MEMORY_SIZE];

// zero out all of it
int memory_init() {
  for (int i = 0; i < MEMORY_SIZE; i++) {
    memory[i] = 0;
  }
  return 0;
}

int memory_read(int address, int length) {
  int ret = 0;
  for (int i = 0; i < length; i++) {
    ret = (ret << 8) + memory[address + i];
  }
  return ret;
}

int memory_reads(int address, int length, char* buffer) {
  for (int i = 0; i < length; i++) {
    buffer[i] = memory[address + i];
  }
  return 0;
}

int memory_write(int address, int value, int length) {
  for (int i = 0; i < length; i++) {
    memory[address + i] = value & 0xFF;
    value >>= 8;
  }
  return 0;
}
