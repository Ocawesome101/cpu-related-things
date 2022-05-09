#include "ports.h"
#include "interrupts.h"
#include <stdio.h>
#include <err.h>

struct Port ports[6];

void port_register_device(char id, port_reader reader, port_writer writer,
    port_isready isready) {
  if (ports[id].registered != 0) {
    errx(1, "[emulator] attempt to double-register port %c", id);
  }

  ports[id].registered = 1;
  ports[id].read = reader;
  ports[id].write = writer;
  ports[id].isready = isready;

  printf("[emulator] device registered on port %c\n", id);
}

void ports_init() {
  for (int i = 0; i < 6; i++) {
    ports[i].registered = 0;
    ports[i].id = i;
  }
}

unsigned char port_read(char port) {
  if (port > 5 || ports[port].registered == 0) {
  }
}

unsigned short port_read2(char port) {
}

void port_write(char port, unsigned char byte) {
}

void port_write2(char port, unsigned short bytes) {
}
