/* baremetal/crt0.S -- reset entry for the CH32V2 image: gp, stack at the
   top of the 20 KB SRAM, .data copied from flash, .bss zeroed, the
   constructors run (the generated program registers runtime hooks from
   them), then main. */
    .section .init
    .globl _start
_start:
    .option push
    .option norelax
    la gp, __global_pointer$
    .option pop
    li sp, 0x20005000
    la a0, __data_load
    la a1, __data_start
    la a2, __data_end
1:  bgeu a1, a2, 2f
    lw t0, 0(a0)
    sw t0, 0(a1)
    addi a0, a0, 4
    addi a1, a1, 4
    j 1b
2:  la a1, __bss_start
    la a2, __bss_end
3:  bgeu a1, a2, 4f
    sw zero, 0(a1)
    addi a1, a1, 4
    j 3b
4:  call sp_bm_run_ctors
    call main
5:  j 5b

/* run __init_array_start..__init_array_end in order */
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
