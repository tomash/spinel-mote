/* baremetal/stm32f103/stm32f103.ld -- STM32F103C8 behind the Maple /
   STM32duino USB bootloader: the bootloader keeps 0x08000000-0x08001FFF and
   jumps to the vector table at 0x08002000, so the app has 56 KB of the
   64 KB. Flash only with `dfu-util -a 2` (that slot); never write page 0. */
MEMORY { FLASH (rx) : ORIGIN = 0x08002000, LENGTH = 56K
         RAM (rwx)  : ORIGIN = 0x20000000, LENGTH = 20K }
ENTRY(Reset_Handler)
SECTIONS {
  .text : { KEEP(*(.isr_vector)) *(.text .text.*) *(.rodata .rodata.*) } > FLASH
  .ARM.exidx : { *(.ARM.exidx* .gnu.linkonce.armexidx.*) } > FLASH
  .init_array : { __init_array_start = .; KEEP(*(SORT_BY_INIT_PRIORITY(.init_array.*))) KEEP(*(.init_array .ctors)) __init_array_end = .; } > FLASH
  .data : { __data_start = .; *(.data .data.*) . = ALIGN(4); __data_end = .; } > RAM AT > FLASH
  __data_load = LOADADDR(.data);
  .bss (NOLOAD) : { __bss_start = .; *(.bss .bss.* COMMON) . = ALIGN(4); __bss_end = .; } > RAM
  end = .; _end = .;
  __stack_top = ORIGIN(RAM) + LENGTH(RAM);
}
