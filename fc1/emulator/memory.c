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

int memory_get(int address, char* value) {
  for (int i = 0; i < 3; i++) {
    value[i] = memory[address + i];
  }
  return 0;
}

int memory_set(int address, char value[]) {
  for (int i = 0; i < 3; i++) {
    memory[address + i] = value[i];
  }
  return 0;
}
