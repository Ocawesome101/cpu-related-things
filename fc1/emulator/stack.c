#include "memory.h"
#include "registers.h"
#include "stack.h"

void stack_init() {}

int stack_push(int value) {
  int stackroot = registers_get(REG_SR);
  int stackoff = registers_get(REG_SI);
  stackoff += 3;
  
  int address = stackroot + stackoff;
  registers_set(REG_SI, stackoff);

  memory_write(address, value, 3);
  return 0;
}

int stack_pop() {
  int stackroot = registers_get(REG_SR);
  int stackoff = registers_get(REG_SI);
  int address = stackroot + stackoff;
  int ret = memory_read(address, 3);
  memory_write(address, 0, 3);
  stackoff -= 3;
  
  registers_set(REG_SI, stackoff);
  return ret;
}
