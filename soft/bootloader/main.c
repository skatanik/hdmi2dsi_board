/*
 ============================================================================
 Name        : main.c
 Author      : skt
 Version     :
 Copyright   : Your copyright notice
 Description : Hello RISC-V World in C
 ============================================================================
 */

#include <stdint.h>
#include "bsp.h"
#include "lib_usart.h"

/*
 */
// riscv32-unknown-elf-elf2hex --bit-width 32 --input test_riscv.elf --output test_riscv.hex

int main(void)
{
    volatile uint32_t y;
    volatile uint32_t led = 1;
    volatile uint32_t z = 0x01000800;
    volatile int ind;
    volatile uint8_t read_reg;
    volatile uint8_t data_to_send = 0xAA;


    USART_init(100);

    while (1)
    {
        USART_send_byte_blocking(data_to_send);
        read_reg = USART_read_byte_blocking();

        if(read_reg != data_to_send)
        {
            WRITE_REG(0x01010600, 1);
            for (y = 0; y < 20; y++) {y++; y--;}
            WRITE_REG(0x01010600, 0);
            for (y = 0; y < 10; y++) {y++; y--;}
        }

    }

  return 0;
}
