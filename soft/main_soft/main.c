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

    // GPIO->gpio_cr |= 1<<2; // set PWR EN
    // GPIO->gpio_cr |= 1<<1; // set BL_en

    GPIO->gpio_cr ^= 0;

    GPIO->gpio_cr |= 1<<8; // Remove RESET

    while(!(GPIO->gpio_cr & (1<<16))) // wait until there is pwren signal from the display
    {}

    GPIO->gpio_cr |= 1<<2; // enable diff power

    // send sleep out CMD
    DSI->dsi_reg_cmd = 0x11;
    DSI->dsi_reg_cr|= 1<<3;
    while(!(DSI->dsi_reg_isr & 0x00000002)) {};


    // run DSI clk
    DSI->dsi_reg_cr |= 0x00000002;
    while(!(DSI->dsi_reg_isr & 0x00000002)) {};

    // send Display ON
    DSI->dsi_reg_cmd = 0x29;
    DSI->dsi_reg_cr |= 1<<3;
    while(!(DSI->dsi_reg_isr & 0x00000002)) {};


    // // run lanes
    DSI->dsi_reg_cr |= 0x00000004;
    while(!(DSI->dsi_reg_isr & 0x00000004)) {};

    // // PIX_READER->control_reg = 1;
    // // run assembler
    DSI->dsi_reg_cr |= 0x00000001;

    GPIO->gpio_cr |= 1<<1; // backlight enable

    while (1)
    {
        GPIO->gpio_cr ^= 1;

        for(kk = 0; kk < 50000; kk++)
        {}
        // data_recv++;

        if(!USART_read_byte_blocking(&data_recv))
        {
            // if(data_recv == 0x21)
            //     GPIO->gpio_cr |= 1<<2;
            // else if(data_recv == 0x20)
            //     GPIO->gpio_cr &= ~(1<<2);

            if(data_recv == 0x11)
                GPIO->gpio_cr |= 1<<1;
            else if(data_recv == 0x10)
                GPIO->gpio_cr &= ~(1<<1);
        }

        data_recv++;
        // WRITE_REG(0x01002D70, 0x01002D74);

        GPIO->gpio_cr ^= 1;

        // led_state++;
        for(kk = 0; kk < 50000; kk++)
        {}
    }

  return 0;
}

