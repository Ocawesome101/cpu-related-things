// where most of the heavy lifting happens

#include "memory.h"
#include "ports.h"
#include "registers.h"
#include "cmpflags.h"
#include "stack.h"
#include "interrupts.h"

// read and execute one instruction
int instructions_read_and_execute() {
  int pc = registers_get(REG_PC);
  char code = (char)memory_read(pc++, 1);
  char srcdest = (char)memory_read(pc++, 1);
  char src = (srcdest & 0xF0) >> 4;
  char dest = srcdest & 0x0F;
  int value = 0;
  if (code & 0x1 == 0x1) {
    value = memory_read(pc, 3);
    pc += 3;
  }

  int result = instructions_execute(code, src, dest, value);
  if (result == 0)
    registers_set(REG_PC, pc);
  return 0;
}

int instructions_execute(char code, char src, char dest, int value) {
  switch (code) {
    case INST_NOP:
      break;
    
    case INST_IDLOAD:
      registers_set(dest, memory_read(registers_get(src), 3));
      break;
    
    case INST_LOAD:
      registers_set(dest, memory_read(value, 3));
      break;
    
    case INST_MOVE:
      registers.set(dest, registers.get(src));
      break;
    
    case INST_IMM:
      registers.set(dest, value);
      break;
    
    case INST_IDSTORE:
      memory_write(registers_get(dest), registers_get(src), 3);
      break;
    
    case INST_STORE:
      memory_write(value, registers_get(src), 3);
      break;
    
    case INST_PUSH:
      stack_push(registers_get(src));
      break;
    
    case INST_PUSHI:
      stack_push(value);
      break;
    
    case INST_POP:
      registers_set(dest, stack_pop());
      break;
    
    case INST_COMPARE:
      int flags = 0;
      int sval = registers_get(src), dval = registers_get(dest);
      
      if (sval > dval)
        flags |= CMPFLAGS_GREATER;
      if (sval < dval)
        flags |= CMPFLAGS_LESS;
      if (sval == dval)
        flags |= CMPFLAGS_EQUAL;

      registers_set(REG_CMP, flags);
      break;
    
    case INST_JUMP:
      if (registers_get(REG_CMP) == registers_get(src))
        registers_set(REG_PC, value);
      break;
    
    case INST_IDJUMP:
      if (registers_get(REG_CMP) == registers_get(src))
        registers_set(REG_PC, registers_get(dest));
      break;

    case INST_RJUMP:
      if (registers_get(REG_CMP) == registers_get(src))
        registers_set(REG_PC, registers_get(REG_PC) + value);
      break;

    case INST_ADD:
      int tmp = registers_get(dest) + registers_get(src);
      if (tmp > 0xFFFFFF)
        registers_set(REG_CMP, CMPFLAGS_OVERFLOW);
      registers_set(dest, tmp);
      break;

    case INST_ADDI:
      int tmp = registers_get(dest) + value;
      if (tmp > 0xFFFFFF)
        registers_set(REG_CMP, CMPFLAGS_OVERFLOW);
      registers_set(dest, tmp);
      break;

    case INST_SUB:
      int tmp = registers_get(dest) - registers_get(src);
      if (tmp < 0)
        registers_set(REG_CMP, CMPFLAGS_UNDERFLOW);
      registers_set(dest, tmp);
      break;

    case INST_SUBI:
      int tmp = registers_get(dest) - value;
      if (tmp < 0)
        registers_set(REG_CMP, CMPFLAGS_UNDERFLOW);
      registers_set(dest, tmp);
      break;

    case INST_MULT:
      registers_set(dest, registers_get(dest) * registers_get(src));
      break;

    case INST_MULTI:
      registers_set(dest, registers_get(dest) * value);
      break;

    case INST_DIV:
      registers_set(dest, (int)(registers_get(dest) / registers_get(src)));
      break;

    case INST_DIVI:
      registers_set(dest, (int)(registers_get(dest) / value));
      break;

    case INST_LSHIFT:
      registers_set(dest, registers_get(dest) << registers_get(src));
      break;

    case INST_LSHIFTI:
      registers_set(dest, registers_get(dest) << value);
      break;

    case INST_RSHIFT:
      registers_set(dest, registers_get(dest) >> registers_get(src));
      break;

    case INST_RSHIFTI:
      registers_set(dest, registers_get(dest) >> value);
      break;

    case INST_NOT:
      registers_set(dest, ~registers_get(dest));
      break;

    case INST_AND:
      registers_set(dest, registers_get(dest) & registers_get(src));
      break;

    case INST_ANDI:
      registers_set(dest, registers_get(dest) & value);
      break;

    case INST_OR:
      registers_set(dest, registers_get(dest) | registers_get(src));
      break;

    case INST_ORI:
      registers_set(dest, registers_get(dest) | value);
      break;

    case INST_XOR:
      registers_set(dest, registers_get(dest) ~ registers_get(src));
      break;

    case INST_XORI:
      registers_set(dest, registers_get(dest) ~ value);
      break;

    case INST_PREAD:
      
      break;

    case INST_PWRITE:
      break;

    case INST_SETI:
      break;

    case INST_IRQ:
      break;

    case INST_CLRI:
      break;

    case INST_HALT:
      break;
    
    default:
      interrupts_fire(INT_FAULT, FAULT_ILGLINST, -1);
      return -1;
  }

  return 0;
}
