#ifndef interrupts_h
#define interrupts_h

#define INT_TIMER 0
#define INT_IODVC 1
#define INT_NSJMP 2

// faults
#define INT_GENFAULT 3
#define INT_DBLFAULT 4
#define INT_TRPFAULT 5
#define INT_STKOVERF 6
#define INT_SEGFAULT 7
#define INT_ILGLINST 8

void interrupts_init();
int interrupts_fire(int code, int par1, int par2);
int interrupts_set(int enable);

#endif
