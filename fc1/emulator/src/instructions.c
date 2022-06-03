// where most of the heavy lifting happens

#include "memory.h"
#include "ports.h"
#include "registers.h"
#include "cmpflags.h"
#include "stack.h"
#include "interrupts.h"
#include "instructions.h"
#include "emulator.h"

#include <stdio.h>
#include <stdlib.h>

#ifdef FC1_DEBUG
#define FC1_DEBUG_JUMP
#define FC1_DEBUG_COMPARE
#endif

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
      int _pop_value = stack_pop();
#ifdef FC1_DEBUG
      printf("pop value=%d into reg=%d\n", _pop_value, dest);
#endif
      registers_set(dest, _pop_value);
      break;

    case INST_COMPARE:
      int flags = 0;
      int sval = (int)registers_get(src), dval = (int)registers_get(dest);
#ifdef FC1_DEBUG_COMPARE
      printf("compare sval=%d, dval=%d\n", sval, dval);
#endif
      if (sval > dval)
        flags |= CMPFLAGS_GREATER;
      if (sval < dval)
        flags |= CMPFLAGS_LESS;
      if (sval == dval)
        flags |= CMPFLAGS_EQUAL;

      registers_set(REG_CMP, flags);
      break;

    case INST_JUMP:
      tmp = registers_get(src);

      if ((registers_get(REG_CMP) & tmp) == tmp) {
#ifdef FC1_DEBUG_JUMP
        printf("JUMP to %d\n", (int)value);
#endif
        registers_set(REG_PC, (int)value);
        return -1;
      }
      break;

    case INST_IDJUMP:
      tmp = registers_get(src);

      if ((registers_get(REG_CMP) & tmp) == tmp) {
#ifdef FC1_DEBUG
        printf("IDJUMP to %d\n", registers_get(dest));
#endif
        registers_set(REG_PC, registers_get(dest));
        return -1;
      }
      break;

    case INST_RJUMP:
      tmp = registers_get(src);

      if ((registers_get(REG_CMP) & tmp) == tmp) {
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

    case INST_DEVID:
      registers_set(dest, port_getdevid(registers_get(src) & PORT_FLAG_PSEL));
      break;

    case INST_PREAD:
      port = value & PORT_FLAG_PSEL;
      nbytes = 1 + ((value & PORT_FLAG_NBYTE) >> 3);
      int reallyread = (value & PORT_FLAG_USEREG) == 0;

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

    case INST_PISREADY:
      registers_set(dest, port_isready(registers_get(src) & PORT_FLAG_PSEL));
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
#ifdef FC1_DEBUG
      printf("enable interrupts\n");
#endif
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
      if (interrupts_fire(INT_ILGLINST, -1, -1) != 0) {
        printf("illegal instruction 0x%x\n", code);
        exit(1);
      }
      return -1;
  }

  return 0;
}

// read and execute one instruction
int instructions_read_and_execute() {
  int pc = (int)registers_get(REG_PC);
  unsigned char code = (unsigned char)memory_read(pc++, 1);
  char srcdest = (char)memory_read(pc++, 1);

  char src  =  srcdest & 0x0F;
  char dest = (srcdest & 0xF0) >> 4;

  unsigned int value = 0;
  if ((code & 0x1) == 0x1) {
    value = memory_read(pc, 3);
    pc += 3;
  }

#ifdef FC1_DEBUG
  printf("inst code=%d(src=%d,dest=%d,value=%u)\n",
      code, src, dest, value);
#endif
  int result = instructions_execute(code, src, dest, value);
#ifdef FC1_DEBUG
  printf(" -> result=%d (pc=%d)\n", result, pc);
#endif

  if (result == 0)
    registers_set(REG_PC, pc);
  return 0;
}
