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
    volatile uint32_t addr_mem;
    volatile int kk;
    int mode_on = 0;
    // volatile uint32_t del;

    GPIO->gpio_cr = 0;

    USART_init(100);

    // GPIO->gpio_cr |= 1<<2; // set PWR EN
    // GPIO->gpio_cr |= 1<<1; // set BL_en

    // GPIO->gpio_cr ^= 0;

    // GPIO->gpio_cr |= 1<<9; // PANIC_L
    // GPIO->gpio_cr |= 1<<10; // HIFA
    // GPIO->gpio_cr |= 1<<11; // PIFA

    GPIO->gpio_cr |= 1<<8; // Remove RESET

    for(kk = 0; kk < 5000; kk++)
        {}

    while(!(GPIO->gpio_cr & (1<<16))) // wait until there is pwren signal from the display
    {}

    // GPIO->gpio_cr |= 1<<2; // enable diff power
    for(kk = 0; kk < 5000; kk++)
        {}

    DSI->dsi_reg_tr1 = 3 + (1 << 8) + (2 << 16);
    DSI->dsi_reg_tr2 = 2 + (15 << 8);
    // Enable lines
    DSI->dsi_reg_cr |= 1<<1;
    while(!(DSI->dsi_reg_isr & (1<<1))) {};

    // send sleep out CMD
    DSI->dsi_reg_cmd = 0x001105;
    DSI->dsi_reg_cr|= 1<<3;
    while(!(DSI->dsi_reg_isr & (1<<4))) {};

     for(kk = 0; kk < 5000; kk++)
        {}
    // run DSI clk
    DSI->dsi_reg_cr |= 1<<2;
    while(!(DSI->dsi_reg_isr & (1<<1))) {};

    for(kk = 0; kk < 5000; kk++)
        {}

    // // Shut Down Peripheral Command
    // DSI->dsi_reg_cmd = 0x003205;
    // DSI->dsi_reg_cr |= 1<<3;
    // while(!(DSI->dsi_reg_isr & (1<<4))) {};
    // for(kk = 0; kk < 500; kk++)
    //     {}

    // send Display ON
    DSI->dsi_reg_cmd = 0x002905;
    DSI->dsi_reg_cr |= 1<<3;
    while(!(DSI->dsi_reg_isr & (1<<4))) {};
    for(kk = 0; kk < 5000; kk++)
        {}

    // // exit idle mode
    // DSI->dsi_reg_cmd = 0x003805;
    // DSI->dsi_reg_cr |= 1<<3;
    // while(!(DSI->dsi_reg_isr & (1<<4))) {};
    // for(kk = 0; kk < 500; kk++)
    //     {}
    // // enter normal mode
    // DSI->dsi_reg_cmd = 0x001305;
    // DSI->dsi_reg_cr |= 1<<3;
    // while(!(DSI->dsi_reg_isr & (1<<4))) {};
    // for(kk = 0; kk < 500; kk++)
    //     {}

    // run lanes

    // PIX_READER->control_reg = 1;

    // DSI->dsi_reg_cr |= 1<<3;
    // while(!(DSI->dsi_reg_isr & (1<<1))) {};


    // run assembler



     PATTERN_GENERATOR->pg_source = 1;

    while (1)
    {
        // DSI->dsi_reg_cmd = 0x29;
        // DSI->dsi_reg_cr |= 1<<3;
        // while(!(DSI->dsi_reg_isr & (1<<4))) {};

        // GPIO->gpio_cr ^= 1;

        // for(kk = 0; kk < 50000; kk++)
        // {}
        // data_recv++;

        if(!USART_read_byte_blocking(&data_recv))
        {
            // if(data_recv == 0x21)
            //     GPIO->gpio_cr |= 1<<2;
            // else if(data_recv == 0x20)
            //     GPIO->gpio_cr &= ~(1<<2);

            if(data_recv == 0x11)
            {
                    PATTERN_GENERATOR->pg_cr = 1;
                    DSI->dsi_reg_cr |= 1;
                    mode_on = 1;

                    for(kk = 0; kk < 500000; kk++){}

                    GPIO->gpio_cr |= 1<<1; // backlight enable
            }
            else if(data_recv == 0x10)
            {
                uint32_t data_reg;

                data_reg = GPIO->gpio_cr >> 16;
                DSI->dsi_reg_cr &= ~1;
                PATTERN_GENERATOR->pg_cr = 0;
                mode_on = 0;
                USART_send_byte_blocking(data_reg);

                GPIO->gpio_cr &= ~(1<<1); // backlight enable
            }
        }


        // WRITE_REG(0x01002D70, 0x01002D74);
        int flag_fail = 0;
        if(mode_on)
        {    for(int k = 0; k < 65000; k ++)
            {
                addr_mem = k*4;
                WRITE_REG(addr_mem, addr_mem);
                READ_REG(addr_mem, kk);
                if(kk != addr_mem)
                    flag_fail = 1;
            }

            if(flag_fail == 0)
            {
                GPIO->gpio_cr ^= 1;
                for(kk = 0; kk < 50000; kk++){}
                GPIO->gpio_cr ^= 1;
                for(kk = 0; kk < 50000; kk++){}
            }
            else
                return 0;
            }

        // led_state++;

    }

  return 0;
}

