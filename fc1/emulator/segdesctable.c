// segment descriptor table

#include "segdesctable.h"
#include "memory.h"
#include "registers.h"

void sdt_init() {}

int sdt_read_table(sdt_State* state) {
  int sdt_address = memory_read(registers_get(REG_SDT), 3);
  unsigned short sdt_length = (unsigned short)memory_read(sdt_address, 2);
  state->base = sdt_address;
  state->length = sdt_length;
  state->entry = 0;
  return 0;
}

int sdt_read_entry(sdt_State* state, sdt_Entry* entry) {
  if (state->entry == state->length) {
    return 1; // reached the end of the SDT
  }
  int address = state->base + state->entry * 7;
  entry->index = state->entry;
  entry->flags = (char)memory_read(address, 1);
  entry->start = (int)memory_read(address+1, 3);
  entry->end = (int)memory_read(address+1, 3);
  state->entry += 1;
  return 0;
}

int sdt_get_segment(sdt_Entry* retentry, int address) {
  sdt_State state;
  // initialize SDT state
  sdt_read_table(&state);
  // loop through SDT entries until we find the one containing this address
  sdt_Entry entry;
  while(sdt_read_entry(&state, &entry) == 0) {
    if (address >= entry.start && address <= entry.end) {
      retentry->index = entry.index;
      retentry->flags = entry.flags;
      retentry->start = entry.start;
      retentry->end = entry.end;
      break;
    }
  }
  return 0;
}
