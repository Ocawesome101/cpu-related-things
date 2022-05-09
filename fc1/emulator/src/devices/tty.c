// TTY tty
// uses port 0

#include "ports.h"
#define _GNU_SOURCE
#include <poll.h>
#include <time.h>
#include <stdio.h>

unsigned char tty_reader() {
  return (unsigned char)getchar();
}

int tty_writer(unsigned char byte) {
  putchar((int)byte);
  return 0;
}

int tty_isready() {
  struct pollfd fds[] = {
    { 0, POLLIN, 0 }
  };

  struct timespec timeout = { 0, 0 };

  int ready = ppoll(&fds, 1, &timeout, 0);
  if (ready > 0) {
    return 1;
  } else {
    return 0;
  }
}

int device_open(void) {
  printf("test\n");
  port_register_device(0, &tty_reader, &tty_writer, &tty_isready);
  return 0;
}
