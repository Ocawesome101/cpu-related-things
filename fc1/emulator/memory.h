#ifndef memory_h
#define memory_h

#define MEMORY_SIZE 1024*1024*16

int memory_init();
int memory_read(int address, int length);
int memory_reads(int address, int length, char* buffer);
int memory_write(int address, int value, int length);

#endif
