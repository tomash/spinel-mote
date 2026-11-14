/* baremetal/setjmp_armv7m.S -- the pair baremetal/include/setjmp.h declares,
   for Cortex-M3 (Thumb-2): r4-r11, sp, lr, 10 words, no FPU state. */
	.syntax unified
	.thumb
	.text
	.globl sp_bm_setjmp
	.type sp_bm_setjmp, %function
	.thumb_func
sp_bm_setjmp:
	stmia   r0!, {r4-r11}
	str     sp, [r0], #4
	str     lr, [r0]
	movs    r0, #0
	bx      lr
	.size sp_bm_setjmp, . - sp_bm_setjmp

	.globl sp_bm_longjmp
	.type sp_bm_longjmp, %function
	.thumb_func
sp_bm_longjmp:
	ldmia   r0!, {r4-r11}
	ldr     r2, [r0], #4
	mov     sp, r2
	ldr     lr, [r0]
	movs    r0, r1
	it      eq
	moveq   r0, #1
	bx      lr
	.size sp_bm_longjmp, . - sp_bm_longjmp
