// FC-1 emulator
// Compile with "gcc *.c -o emulator"

#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <err.h>
#include <time.h>
#include "registers.h"
#include "memory.h"
#include "stack.h"
#include "sdt.h"
#include "interrupts.h"
#include "mmio.h"
#include "ports.h"

#define TIMER_TICKS_PER_SECOND 250 

// don't change this
#define TIMER_TICKS (int)(1/TIMER_TICKS_PER_SECOND)

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
    err(errno, "cannot load bios");
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

int main() {
  emulator_init();
  emulator_load_bios();
  // TODO: load custom ports and IO and whatnot with dlopen()/dlsym()
  struct timespec time_a;
  clock_gettime(CLOCK_MONOTONIC, &time_a);
  struct timespec time_b;
  while (1) {
    clock_gettime(CLOCK_MONOTONIC, &time_b);
    if (time_b.tv_nsec - time_a.tv_nsec) {
      interrupts_fire(INT_TIMER);
      time_a.tv_sec = time_b.tv_sec;
      time_a.tv_nsec = time_b.tv_nsec;
    }
    instructions_read_and_execute();
  }
  return 0;
}

