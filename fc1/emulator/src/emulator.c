// FC-1 emulator
// Main source file

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
#include "devices.h"
#include "instructions.h"

#define BIOS_PATH "./bios.bin"
#define TIMER_TICKS_PER_SECOND 250

// don't change this
#define TIMER_TICKS (int)(1000000000/TIMER_TICKS_PER_SECOND)

int emulator_init() {
  registers_init();
  memory_init();
  interrupts_init();
  stack_init();
  sdt_init();
  ports_init();
  devices_init();
  return 0;
}

int emulator_load_bios() {
  int fd = open(BIOS_PATH, O_RDONLY);
  if (fd == -1) {
    err(errno, "cannot load bios from %s", BIOS_PATH);
  }
  char buffer[8192];
  int size = read(fd, &buffer, 8192);
  close(fd);
  // copy buffer into memory at 0x4000
  memory_writes(0x4000, &buffer, size);
  return 0;
}

int emulator_halt() {
  return 0;
}

int main() {
  emulator_init();
  emulator_load_bios();

  // timer setup
  struct timespec time_a;
  struct timespec time_b;
  clock_gettime(CLOCK_MONOTONIC, &time_a);

  while (1) {
    // check if we need to fire a timer interrupt
    clock_gettime(CLOCK_MONOTONIC, &time_b);

    if ((time_b.tv_nsec - time_a.tv_nsec) > TIMER_TICKS) {
#ifdef FC1_DEBUG
      printf("fire timer interrupt (%d)\n", time_b.tv_nsec - time_a.tv_nsec);
#endif
      interrupts_fire(INT_TIMER, -1, -1);
      time_a.tv_sec = time_b.tv_sec;
      time_a.tv_nsec = time_b.tv_nsec;
    }

    // self explanatory
    instructions_read_and_execute();
#ifdef FC1_DEBUG
    printf("%8d %8d %8d %8d\n"
        "%8d %8d %8d %8d\n"
        "%8d %8d %8d %8d\n"
        "%8d %8d %8d %8d\n",
        registers_get(0), registers_get(1), registers_get(2), registers_get(3),
        registers_get(4), registers_get(5), registers_get(6), registers_get(7),
        registers_get(8), registers_get(9), registers_get(10), registers_get(11),
        registers_get(12), registers_get(13), registers_get(14), registers_get(15));
#ifdef FC1_STEP
    getchar();
#endif // FC1_STEP
#endif // FC1_DEBUG
  }
  return 0;
}

