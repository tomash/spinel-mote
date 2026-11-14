/* baremetal/qemu/board.c -- the board layer under qemu-riscv32 user mode:
 * console bytes through write(2), board_halt through exit(2), and malloc's
 * break over a fixed array the size of what a CH32V203 has left for the
 * heap (QEMU_HEAP_KB, default 16), so a run sees the chip's memory pressure.
 * The CH32's own registers are absent: programs here must not touch MMIO. */
#include <stddef.h>
#include <stdint.h>
#include <errno.h>
#ifndef QEMU_HEAP_KB
#define QEMU_HEAP_KB 16
#endif
static long sys3(long n, long a, long b, long c) {
  register long a0 __asm__("a0") = a, a1 __asm__("a1") = b, a2 __asm__("a2") = c, a7 __asm__("a7") = n;
  __asm__ volatile("ecall" : "+r"(a0) : "r"(a1), "r"(a2), "r"(a7) : "memory");
  return a0;
}
static char obuf[256]; static int on;
static void oflush(void) { if (on) { sys3(64, 1, (long)obuf, on); on = 0; } }
void board_putchar(int c) { obuf[on++] = (char)c; if (c == '\n' || on == sizeof obuf) oflush(); }
__attribute__((noreturn)) void board_halt(int status) { oflush(); sys3(93, status, 0, 0); for (;;) { } }

static unsigned char heap[QEMU_HEAP_KB * 1024] __attribute__((aligned(8)));
static size_t brk_off;
size_t qemu_heap_peak;
void *_sbrk(ptrdiff_t inc) {
  if (inc < 0 ? (size_t)-inc > brk_off : brk_off + (size_t)inc > sizeof heap) { errno = ENOMEM; return (void *)-1; }
  void *p = heap + brk_off; brk_off += inc;
  if (brk_off > qemu_heap_peak) qemu_heap_peak = brk_off;
  return p;
}
