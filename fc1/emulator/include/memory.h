#ifndef memory_h
#define memory_h

#define MEMORY_SIZE 1024*1024*16

int memory_init();
unsigned int memory_read(int address, int length);
int memory_reads(int address, int length, unsigned char* buffer);
int memory_write(int address, unsigned int value, int length);
int memory_writes(int address, char* buffer, int length);

#endif
