#ifndef INST_H
#define INST_H

/* instruction classes */
#define CLASS_LOAD        0x0
#define CLASS_STORE       0x1
#define CLASS_BRANCH      0x2
#define CLASS_ARITHMETIC  0x3
#define CLASS_IO          0x4
#define CLASS_INTERRUPT   0xF

/* load-type SUB field bitmask */

#define LT_LOW        0x1
#define LT_HIGH       0x2
#define LT_BOTH       0x3
#define LT_INDIRECT   0x4
#define LT_IMMEDIATE  0x8

/* store-type SUB bitmask */

#define ST_LOW        0x1
#define ST_HIGH       0x2
#define ST_BOTH       0x3
#define ST_INDIRECT   0x4

/* branch-type SUB bitmask */

#define BT_IMMEDIATE  0x1
#define BT_ALWAYS     0x8

#define BT_RGT    0x0
#define BT_AGT    0x1
#define BT_REQ    0x2
#define BT_AEQ    0x3
#define BT_RNE    0x4
#define BT_ANE    0x5
//      BT_NOP    0x6
//      BT_NOP    0x7
#define BT_RJMP   0x8
#define BT_AJMP   0x9

/* arithmetic-type SUB field options */

//      AR_NOP  0x0
#define AR_ADD  0x1
#define AR_SUB  0x2
#define AR_MUL  0x3
#define AR_DIV  0x4
#define AR_MOD  0x5
//      AR_NOP  0x6
//      AR_NOP  0x7
#define AR_AND  0x8
#define AR_BOR  0x9
#define AR_XOR  0xA
#define AR_NOT  0xB
#define AR_RLS  0xC
#define AR_ILS  0xD
#define AR_RRS  0xE
#define AR_ILS  0xF


/* IO-type SUB instructions */

#define IO_WRP  0x0
#define IO_RRP  0x1
#define IO_WIP  0x2
#define IO_RIP  0x3

/* interrupt-type SUB field */

#define INT_FRI   0x0
#define INT_FII   0x1

#endif
