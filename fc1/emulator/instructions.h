#ifndef instructions_h
#define instructions_h

/* symbolic names for all the instructions */
/* General instructions */
#define INST_NOP      0
#define INST_IDLOAD   2
#define INST_LOAD     3
#define INST_MOVE     4
#define INST_IMM      5
#define INST_IDSTORE  6
#define INST_STORE    7
#define INST_PUSH     8
#define INST_PUSHI    9
#define INST_POP      10
// skip one
/* Flow control */
#define INST_COMPARE  12
#define INST_JUMP     13
#define INST_IDJUMP   14
#define INST_RJUMP    15
/* Integer operations */
#define INST_ADD      16
#define INST_ADDI     17
#define INST_SUB      18
#define INST_SUBI     19
#define INST_MULT     20
#define INST_MULTI    21
#define INST_DIV      22
#define INST_DIVI     23
#define INST_LSHIFT   24
#define INST_LSHIFTI  25
#define INST_RSHIFT   26
#define INST_RSHIFTI  27
#define INST_NOT      28
// skip one
#define INST_AND      30
#define INST_ANDI     31
#define INST_OR       32
#define INST_ORI      33
#define INST_XOR      34
#define INST_XORI     35
// skip one
/* Port I/O */
#define INST_PREAD    37
// skip one
#define INST_PWRITE   39
// skip many
/* Interrupts */
#define INST_SETI     250
#define INST_IRQ      251
#define INST_CLRI     252
// skip one
#define INST_HALT     254

#endif
