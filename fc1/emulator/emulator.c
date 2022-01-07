// FC-1 emulator
// Compile with "gcc *.c -o emulator"

#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
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
  emulator_load_bios();
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

int emulator_load_bios() {
  int fd = open("bios.bin", O_RDONLY);
  if (fd == -1) {
    err(errno, "cannot open bios: ");
  }
  char buffer[8192];
  int size = read(fd, &buffer, 8192);
  close(fd);
  // copy buffer into memory at 0x4000
  memory_writes(0x4000, &buffer, size);
}

int emulator_halt() {
  return 0;
}
