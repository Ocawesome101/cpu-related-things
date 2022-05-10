#include "interrupts.h"
#include "memory.h"
#include "registers.h"
#include "stack.h"
#ifdef FC1_DEBUG
#include <stdio.h>
#endif

int enabled = 0;

void interrupts_init() {}

int interrupts_fire(int code, int par1, int par2) {
  if (!enabled) {
    return 0;
  }

#ifdef FC1_DEBUG
  printf("fire interrupt %d(pc=%d)\n", code, registers_get(REG_PC));
#endif
  stack_push(registers_get(REG_PC));
  
  if (par2 > -1)
    stack_push(par2);
  if (par1 > -1)
    stack_push(par1);
  
  int base = registers_get(REG_IVT);
#ifdef FC1_DEBUG
  printf("IVT index: base=%d index=%d address=%d\n", base, code*4, base+code*4);
#endif
  unsigned int address = memory_read(base + code * 4, 4);
  registers_set(REG_PC, address);
  
  return 0;
}

int interrupts_set(int enable) {
  enabled = enable;
  return 0;
}
