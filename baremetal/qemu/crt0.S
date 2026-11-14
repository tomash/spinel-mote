/* baremetal/qemu/crt0.S -- qemu-riscv32 (Linux user mode) entry for the
   bare-metal image: the kernel's stack (the loader maps .data and zeroes
   .bss), the constructors as on the chip, main's status to exit(2). */
    .section .init
    .globl _start
_start:
    .option push
    .option norelax
    la gp, __global_pointer$
    .option pop
    call sp_bm_run_ctors
    call main
    call board_halt    /* flushes the console, then exit(2) with main's status */
1:  j 1b

    .text
    .globl sp_bm_run_ctors
sp_bm_run_ctors:
    addi sp, sp, -16
    sw ra, 12(sp)
    sw s0, 8(sp)
    sw s1, 4(sp)
    la s0, __init_array_start
    la s1, __init_array_end
6:  bgeu s0, s1, 7f
    lw t0, 0(s0)
    jalr t0
    addi s0, s0, 4
    j 6b
7:  lw ra, 12(sp)
    lw s0, 8(sp)
    lw s1, 4(sp)
    addi sp, sp, 16
    ret
