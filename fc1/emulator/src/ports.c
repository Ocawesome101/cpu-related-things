#include "ports.h"
#include "interrupts.h"
#include <stdio.h>
#include <err.h>

struct Port ports[6];

void port_register_device(char id, port_reader reader, port_writer writer,
    port_status isready, port_status getdevid) {
  if (ports[id].registered != 0) {
    errx(1, "[emulator] attempt to double-register port %c", id);
  }

  ports[id].registered = 1;
  ports[id].read = reader;
  ports[id].write = writer;
  ports[id].isready = isready;
  ports[id].getdevid = getdevid;

  printf("[emulator] device registered on port %d\n", id);
}

void ports_init() {
  for (int i = 0; i < 6; i++) {
    ports[i].registered = 0;
    ports[i].id = i;
  }
}

unsigned char port_read(char port) {
  if (port > 5 || ports[port].registered == 0) {
    return 0;
  }
  return (unsigned char)(ports[port].read());
}

unsigned short port_read2(char port) {
  if (port > 5 || ports[port].registered == 0) {
    return 0;
  }
  return (unsigned short)(ports[port].read() << 8)
       + (unsigned short)(ports[port].read());
}

void port_write(char port, unsigned char byte) {
  if (!(port > 5 || ports[port].registered == 0)) {
    ports[port].write(byte);
  }
}

void port_write2(char port, unsigned short bytes) {
  if (!(port > 5 || ports[port].registered == 0)) {
    ports[port].write((unsigned char)(bytes >> 8));
    ports[port].write((unsigned char)bytes);
  }
}

int port_isready(char port) {
  if (port > 5 || ports[port].registered == 0) {
    return 0;
  }
  return ports[port].isready();
}

int port_getdevid(char port) {
  if (port > 5 || ports[port].registered == 0) {
    return 0;
  }
  return ports[port].getdevid();
}
