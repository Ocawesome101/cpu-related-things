#include "interrupts.h"
#include "memory.h"
#include "registers.h"
#include "stack.h"

int enabled = 0;

void interrupts_init() {}

int interrupts_fire(int code, int par1, int par2) {
  if (!enabled)
    return 0;

  stack_push(registers_get(REG_PC));
  
  if (par2 > -1)
    stack_push(par2);
  if (par1 > -1)
    stack_push(par1);
  
  int base = registers_get(REG_IVT);
  registers_set(REG_PC, base + code * 4);
  
  return 0;
}

int interrupts_set(int enable) {
  enabled = enable;
  return 0;
}
