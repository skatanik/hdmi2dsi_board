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
#include "lib_sys_timer.h"
#include "crc_16.h"

int main(void)
{
    uint8_t data_recv;
    uint8_t led_state = 0;

    USART_init(100);

    while (1)
    {
        if(USART_read_byte_blocking(&data_recv) == 0)
        {
            WRITE_REG(0x01010600, led_state);
            led_state = ~led_state;

            USART_send_byte_blocking(data_recv);

        }
    }

  return 0;
}

