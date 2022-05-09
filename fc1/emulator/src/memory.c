// a whole 16MB of memory

#include "memory.h"
#include "mmio.h"

char memory[MEMORY_SIZE];

// zero out all of it
int memory_init() {
  for (int i = 0; i < MEMORY_SIZE; i++) {
    memory[i] = 0;
  }
  mmio_init(&memory);
  return 0;
}

// for reading up to 4 bytes (should be plenty)
int memory_read(int address, int length) {
  int ret = 0;
  for (int i = 0; i < length; i++) {
    ret = (ret << 8) + memory[address + i];
  }
  return ret;
}

// for reading more than 4 bytes
int memory_reads(int address, int length, char* buffer) {
  for (int i = 0; i < length; i++) {
    buffer[i] = memory[address + i];
  }
  return 0;
}

// write some number of bytes
int memory_write(int address, int value, int length) {
  for (int i = 0; i < length; i++) {
    memory[address + i] = value & 0xFF;
    value >>= 8;
  }
  mmio_update();
  return 0;
}

// currently mostly used by the bios loading code
int memory_writes(int address, char* buffer, int length) {
  for (int i = 0; i < length; i++) {
    memory[address + i] = buffer[i];
  }
  return 0;
}
