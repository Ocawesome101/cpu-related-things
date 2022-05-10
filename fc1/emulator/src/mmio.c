// Memory-mapped I/O

#include "mmio.h"

// uses """"DMA"""" for slightly better performance
unsigned char* memdata;
int registered = 0;
mmio_Device* devices[MMIO_DEVICE_COUNT];
mmio_Range ranges[MMIO_DEVICE_COUNT];

void mmio_init(unsigned char* mem) {
  memdata = mem;
}

// find the device whose range encompasses that address
int mmio_find(mmio_Device* device, int address) {
  for (int i = 0; i < registered; i++) {
    mmio_Device* check = devices[i];
    if (address >= check->range->start && address <= check->range->end) {
      device->range = check->range;
      device->refresh = check->refresh;
      return 0;
    }
  }
  return 1;
}

// expects range->start and range->end to be set
int mmio_getrange(mmio_Range* range) {
  // disallow overlapping devices
  mmio_Device dummy;
  int total = mmio_find(&dummy, range->start) + mmio_find(&dummy, range->end);
  if (total != 2) {
    return -1;
  }

  // TODO: might need to find a different way of doing this
  range->data = memdata + range->start;
  return 0;
}

// register a device
int mmio_register(mmio_Device* device) {
  if (registered == MMIO_DEVICE_COUNT) {
    return -1;
  }

  devices[registered] = device;
  registered++;
  return 0;
}

// refresh all devices
int mmio_update() {
  for (int i = 0; i < registered; i++) {
    devices[i]->refresh();
  }
}
