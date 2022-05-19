#include "registers.h"
#include "interrupts.h"
#include "sdt.h"

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
  if (id == REG_SDT) {
    // access checks for SDT location
    sdt_Entry entry;
    sdt_get_segment(&entry, registers[REG_PC]);
    if (entry.flags & SDT_FLAG_NOSETSDT == 1) {
      interrupts_fire(INT_SDTFAULT, -1, -1);
      return 0;
    }
  }

  registers[id] = value & 0xFFFFFF;
  return 0;
}
