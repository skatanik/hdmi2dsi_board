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

// static inline void USART_send_byte_blocking(uint32_t byte)
// {
//     // WRITE_REG(0x01002Dfc, byte);
//     UART->usart_reg_txd = byte;
//     // while(USART_check_tx_busy()) {}
// }

// static inline void write_reg_addr(uint32_t byte)
// {
//     WRITE_REG(0x01002Dfc, byte);
// }

int main(void)
{
    volatile uint8_t data_recv = 55;
    volatile uint32_t led_state = 1;
    volatile uint32_t led_state_check;
    volatile int kk;
    // volatile uint32_t del;

    USART_init(100);

    // UART->usart_reg_prsc = 33;
    // UART->usart_reg_cr |= 0x3;

    while (1)
    {
        // stack_pointer = 0x01003C00-64;

        // for(; stack_pointer < 0x01003C00 + 64; stack_pointer += 4)
        // {
        //     WRITE_REG(stack_pointer, 0x778899AA);
        // }

        if(USART_read_byte_blocking(&data_recv) == 0)
        {
            WRITE_REG(0x01010600, led_state);
            led_state++;

            USART_send_byte_blocking(data_recv);

        } else {

            // WRITE_REG(0x10000000, 0xfdfdfd);
            USART_send_byte_blocking(data_recv);
            // led_state ++;
            WRITE_REG(0x01010600, 0);
            for(kk = 0; kk < 100000; kk++)
            {}
            data_recv++;

            USART_send_byte_blocking(data_recv);

            data_recv++;
            // WRITE_REG(0x01002D70, 0x01002D74);
            // // write_reg_addr(0x01002D74);
            // READ_REG(0x01002D70, led_state_check);

            // if(0x01002D74 == led_state_check)
            WRITE_REG(0x01010600, 1);

            // led_state++;
            for(kk = 0; kk < 100000; kk++)
            {}
        }
    }

    // UART->usart_reg_prsc = 100;
    // UART->usart_reg_cr |= 0x3;

    // while (1)
    // {
    //     if(UART->usart_reg_isr & (((uint32_t)1)<<1))
    //     {
    //         UART->usart_reg_isr |= (((uint32_t)1)<<1);
    //         data_recv = UART->usart_reg_rxd;
    //         UART->usart_reg_txd = data_recv;

    //         while(UART->usart_reg_isr & ((uint32_t)0x20)) {}
    //         WRITE_REG(0x01010600, led_state);
    //         led_state++;
    //     }

    // }

  return 0;
}

