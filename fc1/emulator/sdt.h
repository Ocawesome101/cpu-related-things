#ifndef sdt_h
#define sdt_h

#define SDT_FLAG_PROTECT  0x1
#define SDT_FLAG_NOJUMP   0x2

typedef struct sdt_entry {
  char index;
  char flags;
  int start;
  int end;
} sdt_Entry;

typedef struct sdt_state {
  int base;
  unsigned short length;
  int entry;
} sdt_State;

void sdt_init();
int sdt_read_table(sdt_State* state);
int sdt_read_entry(sdt_State* state, sdt_Entry* entry);
int sdt_get_segment(sdt_Entry* retentry, int address);

#endif
