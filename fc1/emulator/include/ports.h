#ifndef ports_h
#define ports_h

#define PORT_FLAG_PSEL    0x7
#define PORT_FLAG_NBYTE   0x8
#define PORT_FLAG_USEREG  0x10
#define PORT_FLAG_REMAIN  0xFFFF00

typedef unsigned char (*port_reader) ();
typedef int (*port_writer) (unsigned char);
typedef int (*port_isready) ();

struct Port {
  int registered;
  char id;
  port_reader read;
  port_writer write;
  port_isready isready;
};

void port_register_device(char id, port_reader reader, port_writer writer,
    port_isready isready);

void ports_init();
unsigned char port_read(char port);
unsigned short port_read2(char port);
void port_write(char port, unsigned char byte);
void port_write2(char port, unsigned short bytes);

#endif
