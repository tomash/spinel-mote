/* shim/esp32/src/ucontext_armv7m.S -- Cortex-M3/M4 (Thumb-2, soft-float)
 * coroutine context switch, the counterpart of ucontext.S (RV32).
 *
 * Saves the AAPCS callee-saved set: r4-r11, sp, lr. r0-r3, r12 are
 * caller-saved; no FPU registers (Cortex-M3 has none; an M4F build with
 * -mfloat-abi=hard would add s16-s31 here).
 *
 * Same struct as include/ucontext.h (bytes from ucp):
 *   +0 uc_link  +4 ss_sp  +8 ss_flags  +12 ss_size
 *   +16 __regs: [0] lr  [1] sp  [2..9] r4..r11  ([10..13] unused)
 */
	.syntax unified
	.thumb
	.text

	.globl getcontext
	.type getcontext, %function
	.thumb_func
getcontext:
	str     lr, [r0, #16]
	str     sp, [r0, #20]
	add     r1, r0, #24
	stmia   r1, {r4-r11}
	movs    r0, #0
	bx      lr
	.size getcontext, . - getcontext

	.globl setcontext
	.type setcontext, %function
	.thumb_func
setcontext:
	add     r1, r0, #24
	ldmia   r1, {r4-r11}
	ldr     lr, [r0, #16]
	ldr     r1, [r0, #20]
	mov     sp, r1
	movs    r0, #0
	bx      lr
	.size setcontext, . - setcontext

	.globl swapcontext
	.type swapcontext, %function
	.thumb_func
swapcontext:            /* r0 = save into, r1 = load from */
	str     lr, [r0, #16]
	str     sp, [r0, #20]
	add     r2, r0, #24
	stmia   r2, {r4-r11}
	add     r2, r1, #24
	ldmia   r2, {r4-r11}
	ldr     lr, [r1, #16]
	ldr     r2, [r1, #20]
	mov     sp, r2
	movs    r0, #0
	bx      lr
	.size swapcontext, . - swapcontext

/* void makecontext(ucontext_t *ucp, void (*func)(void), int argc, ...)
 * spinel passes argc == 0. The new stack's top (8-byte aligned, AAPCS)
 * holds [top-8] = func, [top-4] = uc_link; sp enters at top-8. */
	.globl makecontext
	.type makecontext, %function
	.thumb_func
makecontext:
	ldr     r2, [r0, #4]          /* ss_sp */
	ldr     r3, [r0, #12]         /* ss_size */
	add     r2, r2, r3
	bic     r2, r2, #7            /* top, 8-byte aligned */
	str     r1, [r2, #-8]         /* func */
	ldr     r3, [r0, #0]
	str     r3, [r2, #-4]         /* uc_link */
	sub     r2, r2, #8
	str     r2, [r0, #20]         /* sp */
	ldr     r3, =__start_context  /* a Thumb address: bit 0 set */
	str     r3, [r0, #16]         /* lr */
	movs    r3, #0
	add     r1, r0, #24
	str     r3, [r1, #0]
	str     r3, [r1, #4]
	str     r3, [r1, #8]
	str     r3, [r1, #12]
	str     r3, [r1, #16]
	str     r3, [r1, #20]
	str     r3, [r1, #24]
	str     r3, [r1, #28]
	bx      lr
	.size makecontext, . - makecontext
	.ltorg

/* the first code a makecontext'd coroutine runs: sp at the top-8 frame */
	.globl __start_context
	.type __start_context, %function
	.thumb_func
__start_context:
	ldr     r0, [sp]
	blx     r0                    /* func(); returns here when done */
	ldr     r0, [sp, #4]          /* uc_link */
	cbz     r0, 1f
	bl      setcontext            /* resume the link; does not return */
1:	wfi                           /* no link: spinel never gets here */
	b       1b
	.size __start_context, . - __start_context
