#ifndef memory_h
#define memory_h

#define MEMORY_SIZE 1024*1024*16

int memory_init();
int memory_set(int address, char value[]);
int memory_get(int address, char* value);

#endif
