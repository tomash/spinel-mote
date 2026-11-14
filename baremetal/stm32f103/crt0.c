/* baremetal/stm32f103/crt0.c -- reset and vectors for the STM32F103 behind
 * the Maple bootloader: VTOR to our table, .data from flash, .bss cleared,
 * constructors (the runtime installs its hooks from them), main. A fault
 * blinks PC13 fast, so a crash is visible without a console. */
#include <stdint.h>
#define REG(a) (*(volatile uint32_t *)(a))
extern uint32_t __data_load[], __data_start[], __data_end[], __bss_start[], __bss_end[], __stack_top[];
extern void (*__init_array_start[])(void), (*__init_array_end[])(void);
int main(void);
void board_halt(int status);
extern uint32_t vectors[];

static void led_init(void) {
  REG(0x40021018) |= 1u << 4;                      /* RCC_APB2ENR: IOPC */
  uint32_t crh = REG(0x40011004);                  /* GPIOC_CRH */
  crh &= ~(0xFu << 20); crh |= 0x2u << 20;         /* PC13 out push-pull 2 MHz */
  REG(0x40011004) = crh;
}
static void spin(uint32_t n) { for (volatile uint32_t i = 0; i < n; i++) { } }

void Reset_Handler(void) {
  REG(0xE000ED08) = (uint32_t)vectors;             /* SCB->VTOR */
  for (uint32_t *s = __data_load, *d = __data_start; d < __data_end; ) *d++ = *s++;
  for (uint32_t *d = __bss_start; d < __bss_end; ) *d++ = 0;
  for (void (**f)(void) = __init_array_start; f < __init_array_end; f++) (*f)();
  board_halt(main());
}
void Fault_Handler(void) {
  led_init();
  for (;;) { REG(0x40011010) = 1u << 13; spin(150000); REG(0x40011010) = 1u << 29; spin(150000); }
}
void Default_Handler(void) { for (;;) { } }

__attribute__((section(".isr_vector"), used)) uint32_t vectors[16] = {
  (uint32_t)__stack_top, (uint32_t)Reset_Handler,
  (uint32_t)Default_Handler,                        /* NMI */
  (uint32_t)Fault_Handler, (uint32_t)Fault_Handler, /* HardFault, MemManage */
  (uint32_t)Fault_Handler, (uint32_t)Fault_Handler, /* BusFault, UsageFault */
  0, 0, 0, 0,
  (uint32_t)Default_Handler, (uint32_t)Default_Handler, 0, /* SVC, DebugMon */
  (uint32_t)Default_Handler, (uint32_t)Default_Handler,    /* PendSV, SysTick */
};

/* the board's console and exit: no UART wired yet, so output goes nowhere;
   an exit leaves the LED on (status 0) or blinks it slowly (non-zero) */
void board_putchar(int c) { (void)c; }
__attribute__((noreturn)) void board_halt(int status) {
  led_init();
  for (;;) {
    REG(0x40011010) = 1u << 29;                    /* PC13 low: LED on */
    if (status) { spin(3000000); REG(0x40011010) = 1u << 13; }
    spin(3000000);
  }
}
