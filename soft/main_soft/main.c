/*
 ============================================================================
 Name        : main.c
 Author      : skt
 Version     :
 Copyright   : Your copyright notice
 Description : Hello RISC-V World in C
 ============================================================================
 */

// #include <stdint.h>
#include "bsp.h"
#include "lib_usart.h"
#include "lib_sys_timer.h"
#include "crc_16.h"

uint32_t stack_pointer;

int main(void)
{
    volatile uint8_t data_recv = 55;
    volatile uint32_t led_state = 1;
    volatile uint32_t led_state_check;
    volatile int kk;
    // volatile uint32_t del;

    USART_init(100);

    while (1)
    {

        if(USART_read_byte_blocking(&data_recv) == 0)
        {
            WRITE_REG(0x01010600, led_state);
            led_state++;

            USART_send_byte_blocking(data_recv);

        } else {

            // USART_send_byte_blocking(data_recv);
            // printf("Hello from board");
            // led_state ++;
            WRITE_REG(0x01010600, 0);
            for(kk = 0; kk < 50000; kk++)
            {}
            // data_recv++;

            USART_send_byte_blocking(data_recv);

            data_recv++;
            // WRITE_REG(0x01002D70, 0x01002D74);

            WRITE_REG(0x01010600, 1);

            // led_state++;
            for(kk = 0; kk < 50000; kk++)
            {}
        }
    }

  return 0;
}

