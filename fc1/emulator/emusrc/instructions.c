// where most of the heavy lifting happens

#include "memory.h"
#include "ports.h"
#include "registers.h"
#include "cmpflags.h"
#include "stack.h"
#include "interrupts.h"
#include "instructions.h"
#include "emulator.h"

int instructions_execute(unsigned char code, char src, char dest, int value) {
  char port;
  int tmp, nbytes;
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
      registers_set(dest, registers_get(src));
      break;
    
    case INST_IMM:
      registers_set(dest, value);
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
      if (registers_get(REG_CMP) == registers_get(src)) {
        registers_set(REG_PC, value);
        return -1;
      }
      break;
    
    case INST_IDJUMP:
      if (registers_get(REG_CMP) == registers_get(src)) {
        registers_set(REG_PC, registers_get(dest));
        return -1;
      }
      break;

    case INST_RJUMP:
      if (registers_get(REG_CMP) == registers_get(src)) {
        registers_set(REG_PC, registers_get(REG_PC) + value);
        return -1;
      }
      break;

    case INST_ADD:
      tmp = registers_get(dest) + registers_get(src);
      if (tmp > 0xFFFFFF)
        registers_set(REG_CMP, CMPFLAGS_OVERFLOW);
      registers_set(dest, tmp);
      break;

    case INST_ADDI:
      tmp = registers_get(dest) + value;
      if (tmp > 0xFFFFFF)
        registers_set(REG_CMP, CMPFLAGS_OVERFLOW);
      registers_set(dest, tmp);
      break;

    case INST_SUB:
      tmp = registers_get(dest) - registers_get(src);
      if (tmp < 0)
        registers_set(REG_CMP, CMPFLAGS_UNDERFLOW);
      registers_set(dest, tmp);
      break;

    case INST_SUBI:
      tmp = registers_get(dest) - value;
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
      registers_set(dest, registers_get(dest) ^ registers_get(src));
      break;

    case INST_XORI:
      registers_set(dest, registers_get(dest) ^ value);
      break;

    case INST_PREAD:
      port = value & PORT_FLAG_PSEL;
      nbytes = 1 + ((value & PORT_FLAG_NBYTE) >> 3);
      int reallyread = (value & PORT_FLAG_USEREG) != 0;

      int _interim;
      if (nbytes == 1) {
        unsigned char input = port_read(port);
        _interim = (int)input;
      } else {
        unsigned short input = port_read2(port);
        _interim = (int)input;
      }

      if (reallyread) {
        registers_set(dest, _interim);
      }

      break;

    case INST_PWRITE:
      port = value & PORT_FLAG_PSEL;
      nbytes = 1 + ((value & PORT_FLAG_NBYTE) >> 3);
      int useregister = (value & PORT_FLAG_USEREG) == 0;

      int output;
      if (useregister) {
        output = registers_get(src);
      } else {
        output = (value & PORT_FLAG_REMAIN) >> 8;
      }

      if (nbytes == 1) {
        unsigned char real_output = (unsigned char)(output);
        port_write(port, real_output);
      } else {
        unsigned short real_output = (unsigned short)(output);
        port_write2(port, real_output);
      }

      break;

    case INST_SETI:
      interrupts_set(1);
      break;

    case INST_IRQ:
      interrupts_fire(value, -1, -1);
      return -1;

    case INST_CLRI:
      interrupts_set(0);
      break;

    case INST_HALT:
      emulator_halt();
      break;
    
    default:
      interrupts_fire(INT_ILGLINST, -1, -1);
      return -1;
  }

  return 0;
}

// read and execute one instruction
int instructions_read_and_execute() {
  int pc = registers_get(REG_PC);
  unsigned char code = (unsigned char)memory_read(pc++, 1);
  char srcdest = (char)memory_read(pc++, 1);
  char src = (srcdest & 0xF0) >> 4;
  char dest = srcdest & 0x0F;
  int value = 0;
  if ((code & 0x1) == 0x1) {
    value = memory_read(pc, 3);
    pc += 3;
  }

  int result = instructions_execute(code, src, dest, value);
  if (result == 0)
    registers_set(REG_PC, pc);
  return 0;
}
