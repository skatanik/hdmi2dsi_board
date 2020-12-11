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

#define OUTPORT 0x10000000
#define WRITE_REG(x,y)          *((volatile uint32_t*)x) = (uint32_t)y
#define READ_REG(x,y)           y = (uint32_t)*((volatile uint32_t*)x)

typedef struct
{
    uint32_t destination_addr_reg;
    uint32_t pixels_number_reg;
    uint32_t control_reg;
}td_hdmi_recv_struct;

#define HDMI_RECV  ((td_hdmi_recv_struct *) 0x01001000)

/*
 */
// riscv32-unknown-elf-elf2hex --bit-width 32 --input test_riscv.elf --output test_riscv.hex

int main(void)
{


    volatile uint32_t y;

    WRITE_REG(OUTPORT, 0x1234);

    WRITE_REG(OUTPORT, 0x5678);

    WRITE_REG(OUTPORT, 0xffff);

    WRITE_REG(0x00005000, 0x64337d);

    READ_REG(0x00005000, y);

    WRITE_REG(OUTPORT, y);

    WRITE_REG(OUTPORT, y);

    WRITE_REG(OUTPORT, y);

    HDMI_RECV->destination_addr_reg = 0x0010000;
    HDMI_RECV->pixels_number_reg = 640*480;

    HDMI_RECV->control_reg = 1;

    WRITE_REG(0x11000000, 0x1); // run external hdmi

  return 0;
}
