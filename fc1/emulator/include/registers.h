#ifndef regs_h
#define regs_h

// symbolic names
#define REG_R0  0
#define REG_R1  1
#define REG_R2  2
#define REG_R3  3
#define REG_R4  4
#define REG_R5  5
#define REG_R6  6
#define REG_R7  7
#define REG_R8  8
#define REG_R9  9
#define REG_A0  10
#define REG_A1  11
#define REG_A2  12
#define REG_A3  13
#define REG_A4  14
#define REG_A5  15

#define REG_PC  REG_A0
#define REG_SR  REG_A1
#define REG_SI  REG_A2
#define REG_SDT REG_A3
#define REG_IVT REG_A4
#define REG_CMP REG_A5

int registers_init();
int registers_get(char id);
int registers_set(char id, int value);

#endif
