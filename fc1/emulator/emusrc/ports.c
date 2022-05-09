#include "ports.h"
#include "interrupts.h"
#include <dlfcn.h>
#include <dirent.h>
#include <err.h>
#include <errno.h>
#include <string.h>
#include <stdio.h>

void load_port(char* file) {
  char fullname[256+sizeof(PORT_SCAN_DIR)] = PORT_SCAN_DIR;
  strcpy(&fullname+sizeof(PORT_SCAN_DIR)+1, file);
}

void ports_init() {
  // load ports from PORT_SCAN_DIR using dlopen()/dlsym() magic
  struct dirent* dent;
  DIR* dirfd;
  if ((dirfd = opendir(PORT_SCAN_DIR)) == NULL) {
    err(1, "could not open %s", PORT_SCAN_DIR);
  }

  while ((dent = readdir(dirfd)) != NULL) {
    printf("[emulator] loading port from %s/%s\n", PORT_SCAN_DIR, dent->d_name);
    load_port(dent->d_name);
  }
  closedir(dirfd);
}

unsigned char port_read(char port) {
}

unsigned short port_read2(char port) {
}

void port_write(char port, unsigned char byte) {
}

void port_write2(char port, unsigned short bytes) {
}
