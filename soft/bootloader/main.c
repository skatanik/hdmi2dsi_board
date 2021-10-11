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

#define WAIT_TIMEOUT 11600000       // 0.5 sec

#define FW_REG_VAL 0x59dbf24b
#define FW_TIMER_INIT_VAL   30

// WRITE_REG(0x01010600, 1);
/*
 */


typedef enum
{
    STATE_WAIT_FB,          // wait for hello byte, answer
    STATE_WAIT_COMM_BYTE,   // wait for command byte
    STATE_WAIT_DS_BYTES,    // wait for 16 bit data size   // wait for 16 bit data size
    STATE_WAIT_DATA_BYTE,   // wait for data bytes
    STATE_WAIT_CRC          // wait for 16 bit CRC data
} td_state_enum;

typedef void (*voidfunc_t)();

int main(void)
{
    uint32_t first_timestamp;
    uint32_t second_timestamp;
    uint32_t timeout_counter = WAIT_TIMEOUT;

    td_state_enum current_state = STATE_WAIT_FB;
    uint8_t input_byte;
    uint16_t packet_size = 0;
    uint16_t received_crc = 0;
    uint16_t packet_crc;
    int bytes_counter = 0;
    uint32_t data_start_pointer = USER_START;
    uint32_t word_to_write;

    uint8_t debug_led = 1;

    voidfunc_t f = (voidfunc_t)USER_START;
    voidfunc_t f_sec = (voidfunc_t)USER_START_SEC;

    uint32_t wait_timer = FW_TIMER_INIT_VAL;
    uint8_t main_firmware_flag = 0;

    USART_init(100);  // 115200

    // first_timestamp = SYS_TIMER_read_state();

    USART_send_byte_blocking(0x20);

    uint32_t data_in_fw_reg = 0;
    READ_REG(FIRMWARE_REG_ADDR, data_in_fw_reg);

    if(data_in_fw_reg == FW_REG_VAL)
        main_firmware_flag = 1;

    while (!main_firmware_flag || (wait_timer>0)) // waint until timer ends or if there is no firmware forever
    {
        wait_timer--;
        if(USART_read_byte_blocking(&input_byte) == 0)     // wait for data to receive
        {
            wait_timer = FW_TIMER_INIT_VAL;
            // if data is received process it
            // check current state
            switch(current_state)
            {
                case STATE_WAIT_FB:
                    if(input_byte == 0x46) // hello byte
                    {
                        USART_send_byte_blocking(input_byte + 0x20); // hello back
                        current_state = STATE_WAIT_COMM_BYTE;
                        packet_crc = 0xffff;
                    }
                    break;
//************************************************************************************
                case STATE_WAIT_COMM_BYTE:
                    if(input_byte == 0x21) // write first packet
                    {
                        current_state = STATE_WAIT_DS_BYTES;
                        packet_crc = crc16_byte(packet_crc, input_byte);
                        // WRITE_REG(0x10000000, (packet_crc));
                    } else
                    {
                        current_state = STATE_WAIT_FB;
                        USART_send_byte_blocking(0x70); // smth is wrong
                    }
                    break;
//************************************************************************************
                case STATE_WAIT_DS_BYTES:
                    if(bytes_counter == 0)
                    {
                        packet_size = 0;
                        packet_size = ((uint16_t)input_byte << 8);
                        bytes_counter++;
                        // USART_send_byte_blocking(input_byte);
                    } else
                    {
                        packet_size += input_byte;
                        current_state = STATE_WAIT_DATA_BYTE;
                        bytes_counter = 0;
                        word_to_write = 0;
                        // USART_send_byte_blocking(input_byte);
                    }
                    packet_crc = crc16_byte(packet_crc, input_byte);
                    break;
//************************************************************************************
                case STATE_WAIT_DATA_BYTE:
                    // assemble word, then write it somewhere
                    word_to_write += (input_byte << ((bytes_counter % 4)*8));
                    bytes_counter++;

                    if(bytes_counter % 4 == 0)
                    {
                        WRITE_REG(data_start_pointer, word_to_write);
                        data_start_pointer +=4;
                        word_to_write = 0;
                    }

                    if(bytes_counter == packet_size)
                    {
                        current_state = STATE_WAIT_CRC;
                        bytes_counter = 0;
                    }

                    packet_crc = crc16_byte(packet_crc, input_byte);

                    WRITE_REG(0x01010600, debug_led);
                    debug_led = ~debug_led;


                    break;
//************************************************************************************
                case STATE_WAIT_CRC:
                    if(bytes_counter == 0)
                    {
                        received_crc = 0;
                        received_crc = ((uint16_t)input_byte << 8);
                        bytes_counter++;

                    } else
                    {
                        received_crc += input_byte;

                        // USART_send_byte_blocking(packet_crc);
                        // USART_send_byte_blocking(packet_crc>>8);
                        // USART_send_byte_blocking(" ");
                        // USART_send_byte_blocking(received_crc);
                        // USART_send_byte_blocking(received_crc>>8);

                        // WRITE_REG(0x10000000, (packet_crc));

                        if(packet_crc == received_crc)
                        {
                            WRITE_REG(FIRMWARE_REG_ADDR, FW_REG_VAL); // write fw reg val
                            USART_send_byte_blocking(0x88); // send success
                            // run new code
                            f();
                        }
                        else// fail
                        {
                            current_state = STATE_WAIT_COMM_BYTE;
                            USART_send_byte_blocking(0x71); // smth is wrong
                        }
                    }
                    break;
//************************************************************************************
                default:

                    break;
            }

        }
        // else if(current_state != STATE_WAIT_FB)
        // {
        //     USART_send_byte_blocking(input_byte = 0x72); // exit because of uart timeout during receiving
        //     f_sec();
        // }

        // second_timestamp = first_timestamp;
        // first_timestamp = SYS_TIMER_read_state();

        // if(SYS_TIMER_read_count_flag())
        // {
        //     timeout_counter -= second_timestamp - (0xffffff - first_timestamp);
        // } else {
        //     timeout_counter -= second_timestamp - first_timestamp;
        // }

        // if(timeout_counter < 0) // timeout
        // {
        //     while (1)
        //     {
        //         WRITE_REG(0x01010600, debug_led);
        //         debug_led = ~debug_led;
        //         for(volatile int kk = 0; kk < 50000; kk++)
        //         {}
        //     }

        //     // f_sec();
        // }
    }
    // if we got here than there is a valid main firmvare and timer is out, so lets run the main soft
    f();

  return 0;
}
