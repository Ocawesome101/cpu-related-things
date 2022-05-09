#include "devices.h"
#include <dlfcn.h>
#include <dirent.h>
#include <err.h>
#include <errno.h>
#include <string.h>
#include <stdio.h>

void load_device(char* file) {
  char fullname[256+sizeof(DEVICE_SCAN_DIR)] = DEVICE_SCAN_DIR;
  strcat(&fullname, file);

  dlerror();

  void* dlfd = dlopen(&fullname, RTLD_NOW | RTLD_LOCAL);
  char* new = dlerror();
  if (dlfd == NULL) {
    errx(1, "dlopen failed: %s", new);
  }

  dlerror();

  int (*device_open)(void);
  device_open = (int (*)(void)) dlsym(dlfd, "device_open");

  new = dlerror();
  dlclose(dlfd);

  if (device_open == NULL) {
    errx(1, "dlsym failed: %s", &fullname, new);
  }

  ( *device_open ) ();
}

void devices_init() {
  // load devices from DEVICE_SCAN_DIR using dlopen()/dlsym() magic
  struct dirent* dent;
  DIR* dirfd;
  if ((dirfd = opendir(DEVICE_SCAN_DIR)) == NULL) {
    err(1, "could not open %s", DEVICE_SCAN_DIR);
  }

  while ((dent = readdir(dirfd)) != NULL) {
    if (dent->d_name[0] != '.') {
      printf("[emulator] loading device %s%s\n", DEVICE_SCAN_DIR,
          dent->d_name);
      load_device(dent->d_name);
    }
  }
  closedir(dirfd);
}
