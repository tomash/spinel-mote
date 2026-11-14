/* baremetal/include/setjmp.h --
 * setjmp/longjmp sized for an integer-only core: RISC-V rv32i/rv32imac
 * (CH32V2/V3 without the FPU) or Cortex-M3 (STM32F103).
 * newlib's riscv jmp_buf reserves 12 doubles for the FP registers whatever
 * the core, and is an array of long long, so it is 304 bytes on rv32 where
 * setjmp stores 56. The runtime keeps SP_EXC_STACK_MAX of them statically
 * (sp_exc_stack: 2.4 KB at 8), so this header, found ahead of newlib's by
 * -I baremetal/include for the runtime and the app TU alike, saves ~2 KB of
 * RAM. The pair lives in baremetal/setjmp.S (ra, sp, s0-s11). */
#ifndef SP_BAREMETAL_SETJMP_H
#define SP_BAREMETAL_SETJMP_H
#if defined(__riscv_flen) || (defined(__ARM_FP) && __ARM_FP)
#error "baremetal/include/setjmp.h saves no FP registers: drop it for a core with an FPU"
#endif
#if defined(__riscv)
typedef long jmp_buf[14];   /* ra, sp, s0-s11: baremetal/setjmp.S */
#elif defined(__thumb2__)
typedef long jmp_buf[10];   /* r4-r11, sp, lr: baremetal/setjmp_armv7m.S (newlib: 160 B) */
#else
#error "baremetal/include/setjmp.h: no pair for this core"
#endif
typedef jmp_buf sigjmp_buf;
__attribute__((returns_twice)) int sp_bm_setjmp(jmp_buf env);
__attribute__((noreturn)) void sp_bm_longjmp(jmp_buf env, int val);
#define setjmp(env) sp_bm_setjmp(env)
#define longjmp(env, val) sp_bm_longjmp(env, val)
#define _setjmp(env) sp_bm_setjmp(env)
#define _longjmp(env, val) sp_bm_longjmp(env, val)
#define sigsetjmp(env, save) ((void)(save), sp_bm_setjmp(env))
#define siglongjmp(env, val) sp_bm_longjmp(env, val)
#endif
