/* baremetal/qemu/qemu.ld -- measure.ld's layout for qemu-riscv32 user mode:
   flash moved off page 0 (the loader maps segments at their addresses). */
MEMORY { FLASH (rx) : ORIGIN = 0x00010000, LENGTH = 4M
         RAM (rwx)  : ORIGIN = 0x20000000, LENGTH = 4M }
ENTRY(_start)
SECTIONS {
  .text : { KEEP(*(.init)) *(.text .text.*) *(.rodata .rodata.* .srodata .srodata.*) } > FLASH
  /* constructors: the generated program registers its runtime hooks from
     them (inspect, JSON, GC roots); crt0 runs the table before main */
  .init_array : { __init_array_start = .; KEEP(*(SORT_BY_INIT_PRIORITY(.init_array.*))) KEEP(*(.init_array .ctors)) __init_array_end = .; } > FLASH
  .data : { __data_start = .; *(.data .data.* .sdata .sdata.*) __data_end = .; } > RAM
  .bss : { __bss_start = .; *(.bss .bss.* .sbss .sbss.* COMMON) __bss_end = .; } > RAM
  end = .; _end = .;
  __global_pointer$ = __data_start + 0x800;
}
