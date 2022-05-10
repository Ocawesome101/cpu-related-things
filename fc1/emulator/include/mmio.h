#ifndef mmio_h
#define mmio_h

// tweak this if necessary
#define MMIO_DEVICE_COUNT 16

typedef struct mmio_range {
  unsigned char* data;
  int start;
  int end;
} mmio_Range;

typedef struct mmio_device {
  mmio_Range* range;
  int (*refresh) (void);
} mmio_Device;

void mmio_init(unsigned char* mem);
int mmio_find(mmio_Device* device, int address);
int mmio_getrange(mmio_Range* range);
int mmio_register(mmio_Device* device);
int mmio_update();

#endif
