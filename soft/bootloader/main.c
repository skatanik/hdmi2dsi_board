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
// WRITE_REG(0x01010600, 1);
/*
 */
// riscv32-unknown-elf-elf2hex --bit-width 32 --input test_riscv.elf --output test_riscv.hex

typedef enum
{
    STATE_WAIT_FB,          // wait for hello byte, answer
    STATE_WAIT_COMM_BYTE,   // wait for command byte
    STATE_WAIT_PACKET_NUM,  // wait for packet number byte
    STATE_WAIT_DS_BYTES,    // wait for 16 bit data size   // wait for 16 bit data size
    STATE_WAIT_DATA_BYTE,   // wait for data bytes
    STATE_WAIT_CRC          // wait for 16 bit CRC data
} td_state_enum;

int main(void)
{
    td_state_enum current_state = STATE_WAIT_FB;
    uint8_t input_byte;
    uint8_t number_of_packets;
    int packets_counter;
    uint16_t packet_size = 0;
    uint16_t received_crc = 0;
    int bytes_counter = 0;
    uint8_t first_packet_flag = 0;
    uint8_t last_packet_flag = 0;
    uint32_t global_data_counter;
    USART_init(100);

    while (1)
    {
        if(USART_read_byte_blocking(&input_byte) == 0)     // wait for data to receive
        {   // if data is received process it
            // check current state
            switch(current_state)
            {
                case STATE_WAIT_FB:
                    if(input_byte == 0x46) // hello byte
                    {
                        USART_send_byte_blocking(input_byte = 0x20); // hello back
                        current_state = STATE_WAIT_COMM_BYTE;
                    }
                    break;
//************************************************************************************
                case STATE_WAIT_COMM_BYTE:
                    if(input_byte == 0x21) // write first packet
                    {
                        current_state = STATE_WAIT_PACKET_NUM;
                        packets_counter = 0;
                        first_packet_flag = 1;
                    } else if(input_byte == 0x22) // write not the first packet
                    {
                        packets_counter ++;
                        current_state = STATE_WAIT_PACKET_NUM;
                    } else
                    {
                        current_state = STATE_WAIT_FB;
                        USART_send_byte_blocking(input_byte = 0x70); // smth is wrong
                    }
                    // add_to_CRC()
                    break;
//************************************************************************************
                case STATE_WAIT_PACKET_NUM:
                    if(first_packet_flag)
                    {
                        number_of_packets = input_byte;
                        packets_counter++;
                        first_packet_flag = 0;
                    }
                    else
                    {
                        packets_counter++;
                        if(packets_counter == number_of_packets)
                            last_packet_flag = 1;
                    }

                    current_state = STATE_WAIT_DS_BYTES;
                    // add_to_CRC()
                    break;
//************************************************************************************
                case STATE_WAIT_DS_BYTES:
                    if(bytes_counter == 0)
                    {
                        packet_size = 0;
                        packet_size = ((uint16_t)input_byte << 8);
                        bytes_counter++;
                    } else
                    {
                        packet_size += input_byte;
                        current_state = STATE_WAIT_DATA_BYTE;
                    }
                    // add_to_CRC()
                    break;
//************************************************************************************
                case STATE_WAIT_DATA_BYTE:
                    // assemble word, then write it somewhere
                    // add_to_CRC()
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
                        // calc_CRC();


                    }
                    break;
//************************************************************************************
                default:

                    break;
            }

        }

    }

  return 0;
}
