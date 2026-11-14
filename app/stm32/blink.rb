# app/stm32/blink.rb -- bare-metal blink for the STM32F103C8 blue pill
# (WeAct, behind its USB bootloader). PC13 is the on-board LED, active low.
# Same register map as the CH32V203: RCC APB2ENR, GPIOC CRH, BSRR.
#
# Exercises the runtime on the chip, not just the pin: a rescued exception
# (setjmp/longjmp), blocks, an object. The pattern, forever: three short
# blinks, then six long ones (the rescued message is 30 characters, /5).
# (String#split would add ~90 KB of runtime: docs/stm32f103.md.)

module Pill
  ffi_source <<~C
    #include <stdint.h>
    #define REG(a) (*(volatile uint32_t *)(a))
    int pill_led_init(void) {
        REG(0x40021018) |= 1u << 4;                     /* RCC_APB2ENR: IOPC */
        uint32_t crh = REG(0x40011004);
        crh &= ~(0xFu << 20);
        crh |= 0x2u << 20;                              /* PC13 push-pull 2 MHz */
        REG(0x40011004) = crh;
        return 0;
    }
    int pill_led(int on) {
        REG(0x40011010) = on ? (1u << 29) : (1u << 13); /* active low */
        return 0;
    }
    int pill_delay_ms(int ms) {
        for (volatile uint32_t i = 0; i < (uint32_t)ms * 6000u; i++) { }
        return 0;
    }
  C
  ffi_func :pill_led_init, [], :int
  ffi_func :pill_led, [:int], :int
  ffi_func :pill_delay_ms, [:int], :int
end

def pulse(ms)
  Pill.pill_led(1)
  Pill.pill_delay_ms(ms)
  Pill.pill_led(0)
  Pill.pill_delay_ms(ms)
end

def longs
  raise ArgumentError, "hello from ruby on a blue pill"
rescue ArgumentError => e
  e.message.size / 5
end

Pill.pill_led_init
loop do
  3.times { pulse(80) }
  Pill.pill_delay_ms(400)
  longs.times { pulse(300) }
  Pill.pill_delay_ms(1200)
end
