// Instruction Definition

The FC-1 assembler is interestingly reusable.  These are docs for the format it uses so I can remember them when I look back on this code in six months.

The base assembler code makes very few assumptions about the underlying platform.  All instructions are defined in the text file `instructions.adef`.  This file uses a very simple format.  See the included file (FC-1 instruction definitions) for a comprehensive example.

Attributes are usually defined at the top of the file.  They are defined using the syntax

  *attribute val [val2 [val3 [...]]]

Currently supported attributes are:

  instsize number
    - the minimum size of one opcode, in bits
  fixwidth true|false
    - whether opcodes are always `instsize` bits long (doesn't change
      anything at the time of writing).
  register prefix min max
    - define a range of registers and the prefix used for them.  min and
      max specify the range of the number following the prefix.  For
      example, '*register a 10 15' defines a0 through a5, the attribute
      registers of the FC-1.

Instructions are defined as an opcode and a mnemonic followed by one or more arguments.  Examples follow.

  0x00 nop *pad 8
    Tells the assembler that the instruction 'nop' takes no arguments and should have an additional empty 8 bits of padding after it.

  0x02 idload 1 4 4
    Specifies that 'idload' has an opcode of 0x02, its arguments are 1 byte in size, and those arguments consist of two 4-bit numbers.

  0x03 load 4 4X 4 24
    Specifies that 'load' has an opcode of 0x3, its arguments are 4 bytes in length, and these arguments consist of 4 bits of padding, a 4 bit number, and a 24 bit number.

  0x25 pread 4 4X 4 3 1 1 3X 16?21
    Specifies the FC-1's 'pread' instruction.  Assume bits are 1-indexed.  This definition demonstrates the assembler's conditional argument capabilities.
      - The arguments total 4 bytes in length.
      - The first argument (bits 9-12) is 4 bits of padding and should be
        ignored.
      - The second argument (bits 13-16) is a 4-bit number.
      - The third argument (bits 17-19) is a 3-bit number.
      - The fourth and fifth arguments (bits 20 and 21) are booleans
        represented as 0 or 1.
      - The sixth argument is 3 bits of padding.
      - The seventh argument is 16 bits, and is only required if bit 21 is
        set - otherwise, it is 16 bits of padding.

Note that conditional arguments may only be based upon preceding bits of the same instruction.


// Assembly syntax

This assembler uses a very simple and relatively standard assembly language syntax, with the most noticeable peculiarity being its use of * to denote special directives.  Labels are denoted with a . and may be accessed anywhere in the program.  Arguments may be separated with a comma (,), one or more spaces ( ), or both.  Comments are prefixed with a semicolon (;).  See the included assembly files for examples.

Available directives are:

  *offset number
    Sets the offset at which the program expects to be run.  Defaults to 0.

  *dw[N] ...
    Insert some static data, where [N] is optionally a minimum number of bytes:
      '*dw "Hello, world!" 10 0' inserts the bytes '48 65 6C 6C 6F 2C 20 77 6F 72 6C 64 21 0A 00'.
      '*dw4 0x2' inserts '02 00 00 00'.

  *$MACRO ...
    Expand macro 'MACRO' and insert its output here.


See `examples/macro.fca` for example usage.
