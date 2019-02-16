#include <stdint.h>

void
_delay_loop_2(uint16_t __count) // Copied from util/delay_basic.h
{
        __asm__ volatile (
                "1: sbiw %0,1" "\n\t"
                "brne 1b"
                : "=w" (__count)
                : "0" (__count)
        );
}
