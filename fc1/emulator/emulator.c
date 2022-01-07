// FC-1 emulator
// Compile with "gcc *.c -o emulator"

#include <stdio.h>
#include <stdlib.h>
#include <err.h>
#include "registers.h"
#include "memory.h"
#include "stack.h"
#include "sdt.h"
#include "interrupts.h"
#include "mmio.h"
#include "ports.h"

int main() {
  emulator_init();
  // TODO: load custom ports and IO and whatnot with dlopen()/dlsym()
  return 0;
}

int emulator_init() {
  registers_init();
  memory_init();
  interrupts_init();
  ports_init();
  stack_init();
  sdt_init();
  return 0;
}
