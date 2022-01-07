#ifndef interrupts_h
#define interrupts_h

#define INT_TIMER 0
#define INT_IODVC 1
#define INT_FAULT 2
#define INT_NSJMP 3

#define FAULT_GENFAULT 0
#define FAULT_DBLFAULT 1
#define FAULT_TRPFAULT 2
#define FAULT_STKOVERF 3
#define FAULT_SEGFAULT 4
#define FAULT_ILGLINST 5

void interrupts_init();
int interrupts_fire(int code, int par1, int par2);

#endif
